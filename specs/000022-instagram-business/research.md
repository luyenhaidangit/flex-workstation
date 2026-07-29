# Research: Phát hành AI Agent trên Instagram Business

**Feature**: `000022-instagram-business`  
**Ngày**: 2026-07-29  
**Phục vụ**: `plan.md` — giải đáp TQ-001 đến TQ-004

---

## §1 — Token lifecycle cho Instagram page-level access token (TQ-001)

**Quyết định**: Page access token của Instagram không có thời hạn cố định miễn là user không thu hồi quyền và ứng dụng tiếp tục được sử dụng. Không cần cơ chế auto-refresh trong MVP.

**Chi tiết**:
- Flow: short-lived user token (1h) → long-lived user token (60 ngày) → page access token (không hết hạn).
- Page access token được lấy bằng: `GET /{page-id}?fields=access_token&access_token={long_lived_user_token}`.
- Page access token chỉ bị vô hiệu khi: (a) user thu hồi quyền ứng dụng trong Facebook Settings, (b) user xoá trang, (c) ứng dụng Meta bị disable.
- Khi token bị vô hiệu, webhook event `instagram_api_deauthorize` sẽ được gửi.

**Xử lý trong hệ thống**:
- Lưu page access token (mã hoá) trong `instagram_page_connections.encrypted_page_access_token`.
- Lắng nghe webhook `deauthorize` / `instagram_api_deauthorize` để cập nhật status = Error.
- Không cần background job refresh token trong MVP.

**Phương án đã loại**: Auto-refresh bằng cron job → không cần thiết cho page token, tốn resource.

**Rủi ro còn lại**: Nếu user đổi mật khẩu Facebook, token có thể bị vô hiệu mà không có webhook. Xử lý: detect khi Send API trả lỗi OAuthException → cập nhật status Error.

---

## §2 — Instagram webhook vs Facebook Page webhook (TQ-002)

**Quyết định**: Dùng endpoint riêng `/api/webhooks/instagram`. Instagram DM events đi qua Instagram Graph API Webhook, không phải Facebook Page webhook.

**Chi tiết**:

**Instagram Graph API Webhook** (cho Instagram DM):
- Object type: `instagram`
- Subscriptions cần: `messages`, `messaging_postbacks`
- Subscribe bằng: `POST /{instagram-business-account-id}/subscribed_apps` với fields `messages,messaging_postbacks`
- Chú ý: subscribe trên Instagram Business Account ID, không phải Facebook Page ID.
- Payload example:
```json
{
  "object": "instagram",
  "entry": [{
    "id": "{instagram-business-account-id}",
    "time": 1234567890,
    "messaging": [{
      "sender": {"id": "{instagram-scoped-user-id}"},
      "recipient": {"id": "{instagram-business-account-id}"},
      "timestamp": 1234567890,
      "message": {
        "mid": "aWdfZAb...",
        "text": "Xin chào, tôi muốn đặt lịch"
      }
    }]
  }]
}
```

**Facebook Page Webhook** (hiện có, cho Messenger):
- Object type: `page`
- Hoàn toàn tách biệt với Instagram webhook.

**Xử lý**:
- Webhook verification: cả hai đều dùng `hub.mode=subscribe`, `hub.verify_token`, `hub.challenge`.
- Chữ ký: `X-Hub-Signature-256: sha256={hmac}` — cùng cơ chế, dùng app secret.
- Endpoint riêng `/api/webhooks/instagram` giúp tách biệt handler logic.

**Phương án đã loại**: Dùng chung endpoint với Facebook webhook — phức tạp routing theo `object` field, khó test độc lập.

---

## §3 — OAuth callback: lấy danh sách pages và kiểm tra Instagram Business Account (TQ-003)

**Quyết định**: Flow 5 bước sau khi nhận được `code` từ Meta.

**Flow chi tiết**:

```
1. Exchange code → short-lived user token:
   POST https://graph.facebook.com/oauth/access_token
   {client_id, client_secret, redirect_uri, code}
   → {access_token: "...", token_type: "bearer"}

2. Exchange short-lived → long-lived user token:
   GET https://graph.facebook.com/oauth/access_token
   ?grant_type=fb_exchange_token
   &client_id={app-id}
   &client_secret={app-secret}
   &fb_exchange_token={short_lived_token}
   → {access_token: "...", expires_in: 5184000}  // 60 ngày

3. Lấy danh sách Facebook Pages user quản lý:
   GET https://graph.facebook.com/me/accounts
   ?access_token={long_lived_token}
   → {data: [{id, name, access_token, category, ...}]}

4. Với mỗi page, kiểm tra có Instagram Business Account không:
   GET https://graph.facebook.com/{page-id}
   ?fields=instagram_business_account,name,picture
   &access_token={page_access_token}
   → {instagram_business_account: {id: "..."}} // hoặc không có field này

5. Với page có IG Business Account, lấy account info:
   GET https://graph.facebook.com/{instagram-business-account-id}
   ?fields=name,username,profile_picture_url,account_type
   &access_token={page_access_token}
   → {account_type: "BUSINESS" | "CREATOR"}
```

**Scope cần thiết**: `pages_manage_metadata`, `pages_messaging`, `instagram_manage_messages`, `instagram_basic`.

**Phân loại Hợp lệ / Không hợp lệ**:
- Hợp lệ: page có `instagram_business_account` + `account_type` là BUSINESS hoặc CREATOR + chưa có record trong `instagram_page_connections` (hoặc có nhưng thuộc agent này).
- Không hợp lệ: page đã có record trong `instagram_page_connections` với `agent_id` khác.
- Excluded (ẩn): page không có `instagram_business_account` (tài khoản cá nhân).

**Phương án đã loại**: Kiểm tra account_type qua Instagram Basic Display API — API này cho personal accounts, không phù hợp.

---

## §4 — 24-hour messaging window: cơ chế và xử lý (TQ-004)

**Quyết định**: Kiểm tra phía server trước khi gọi Send API, dựa trên `last_customer_dm_at` lưu trong DB.

**Chi tiết Instagram 24-hour rule**:
- Agent chỉ có thể trả lời DM trong 24 giờ kể từ tin nhắn CUỐI CÙNG của khách.
- Nếu gửi ngoài cửa sổ: Meta API trả lỗi `#10900` hoặc HTTP 400 với message "The recipient cannot receive this message" hoặc similar.
- Không có cơ chế "human agent handoff" như Messenger trong MVP.

**Luồng xử lý**:
```
Webhook nhận DM từ khách
→ Cập nhật instagram_page_connections.last_customer_dm_at = now()
→ Nếu agent muốn trả lời:
   → Kiểm tra: last_customer_dm_at > now() - 24h ?
   → Nếu có: proceed → call Send API
   → Nếu không: skip silently, log instagram.webhook.dm_skipped {reason: "outside_window"}
```

**Update `last_customer_dm_at`**: Cập nhật mỗi khi nhận webhook DM từ khách — đây là thời điểm cuối cùng khách nhắn tin, không phải thời điểm agent trả lời.

**Phương án đã loại**: Chỉ xử lý lỗi từ Meta API (không check trước) — Meta có thể không trả lỗi nhất quán; logging sẽ khó; UX không rõ ràng.

---

## §5 — Send API format cho Instagram DM

**Endpoint**: `POST https://graph.facebook.com/v21.0/{instagram-business-account-id}/messages`

**Payload**:
```json
{
  "recipient": {
    "id": "{instagram-scoped-user-id}"
  },
  "message": {
    "text": "Dạ em chào chị, chị muốn đặt lịch vào ngày nào ạ?"
  }
}
```

**Headers**: `Authorization: Bearer {page_access_token}`

**Lưu ý**: Dùng Instagram Business Account ID (không phải Facebook Page ID) làm path parameter. Sender ID trong webhook là `instagram-scoped user ID` — dùng trực tiếp làm recipient ID.

---

## §6 — Webhook registration flow

```
1. Meta App Dashboard: cấu hình Webhook URL + Verify Token + Subscribe to instagram object
2. Meta gọi GET {webhook_url}?hub.mode=subscribe&hub.verify_token={token}&hub.challenge={challenge}
3. Backend verify token → trả về hub.challenge (số nguyên)
4. Meta xác nhận webhook
5. Khi kết nối page: POST /{instagram-business-account-id}/subscribed_apps
   {access_token: {page_token}, subscribed_fields: "messages,messaging_postbacks"}
6. Khi ngắt kết nối page: DELETE /{instagram-business-account-id}/subscribed_apps
   {access_token: {page_token}}
```

**Quan trọng**: Subscribe trên Instagram Business Account ID, không phải Page ID.
