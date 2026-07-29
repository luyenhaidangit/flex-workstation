# Contract: Instagram Channel API

**Feature**: `000022-instagram-business`  
**Ngày**: 2026-07-29  
**Loại**: REST API (Backend ↔ Frontend) + Webhook (Meta → Backend)

---

## Tổng quan

5 REST endpoints cho Customer Studio frontend + 1 webhook endpoint nhận event từ Meta.

Tất cả REST endpoints:
- Base path: `/api/channels/instagram`
- Auth: Bearer token (JWT của người dùng)
- Content-Type: `application/json`
- Lỗi: chuẩn `{error: {code, message}}`

---

## 1. Initiate OAuth Connection

**POST** `/api/channels/instagram/connect`

Khởi động luồng kết nối Instagram Business. Backend tạo OAuth URL và state.

**Request**:
```json
{
  "agentId": "uuid"
}
```

**Response 200**:
```json
{
  "oauthUrl": "https://www.facebook.com/v21.0/dialog/oauth?client_id=...&redirect_uri=...&scope=...&state=...",
  "state": "uuid-csrf-token"
}
```

**Lỗi**:
- 401: Chưa xác thực.
- 403: Role không đủ quyền (phải là owner/admin của agent).
- 404: Agent không tìm thấy.

---

## 2. OAuth Callback

**GET** `/api/channels/instagram/callback`

Meta redirect về endpoint này sau khi user cấp quyền. Backend xử lý và trả kết quả về frontend.

**Query params** (từ Meta):
```
?code=exchange_code&state=uuid-csrf-token
```

**Xử lý** (không có request body):
1. Validate `state`.
2. Exchange `code` → tokens.
3. Lấy danh sách pages + kiểm tra IG Business Account.
4. Phân loại Hợp lệ / Không hợp lệ.
5. Lưu kết quả vào session/cache với TTL 10 phút.

**Response**: Redirect về frontend với `?sessionKey={key}` để frontend gọi tiếp endpoint lấy kết quả.

**Frontend gọi tiếp** — **GET** `/api/channels/instagram/connect/result?sessionKey={key}`:

**Response 200**:
```json
{
  "valid": [
    {
      "facebookPageId": "123456",
      "facebookPageName": "The Coffee House",
      "facebookPageAvatarUrl": "https://...",
      "instagramBusinessAccountId": "789012",
      "instagramUsername": "thecoffeehouse_vn",
      "accountType": "BUSINESS",
      "currentStatus": "not_connected"
    },
    {
      "facebookPageId": "234567",
      "facebookPageName": "Paradise Coffee Núi Trúc",
      "facebookPageAvatarUrl": "https://...",
      "instagramBusinessAccountId": "890123",
      "instagramUsername": "paradisecafe_nuitruc",
      "accountType": "CREATOR",
      "currentStatus": "already_connected_this_agent"
    }
  ],
  "invalid": [
    {
      "facebookPageId": "345678",
      "facebookPageName": "FPT Shop",
      "facebookPageAvatarUrl": "https://...",
      "reason": "connected_by_other_agent",
      "connectedAgentName": "Phương Linh"
    }
  ],
  "metaAccountInfo": {
    "metaUserId": "111222333",
    "metaUserName": "Minh Tâm",
    "metaUserAvatarUrl": "https://..."
  }
}
```

**Lỗi**:
- 400: state không hợp lệ hoặc đã hết hạn.
- 400: user cancel (`error=access_denied` từ Meta).

---

## 3. Confirm Selected Pages

**POST** `/api/channels/instagram/pages/confirm`

Người dùng đã chọn pages trong popup → tạo kết nối.

**Request**:
```json
{
  "agentId": "uuid",
  "sessionKey": "uuid-from-callback",
  "selectedPageIds": ["123456", "234567"]
}
```

**Response 200**:
```json
{
  "connected": [
    {
      "connectionId": "uuid",
      "facebookPageId": "123456",
      "facebookPageName": "The Coffee House",
      "facebookPageAvatarUrl": "https://...",
      "status": "active"
    }
  ],
  "metaAccountConnectionId": "uuid",
  "metaUserName": "Minh Tâm",
  "metaUserAvatarUrl": "https://..."
}
```

**Lỗi**:
- 409: page đã bị agent khác kết nối trong thời gian chờ (race condition). Frontend hiển thị lại popup với danh sách updated.
- 400: selectedPageIds rỗng.
- 400: sessionKey hết hạn.

**Idempotency**: Nếu gọi lại với cùng pageId đã connected → upsert, không tạo duplicate.

---

## 4. List Connections

**GET** `/api/channels/instagram/connections?agentId={uuid}`

Lấy danh sách kết nối Instagram của agent (grouped theo tài khoản Meta).

**Response 200**:
```json
{
  "isPublished": true,
  "accounts": [
    {
      "metaAccountConnectionId": "uuid",
      "metaUserName": "Minh Tâm",
      "metaUserAvatarUrl": "https://...",
      "pages": [
        {
          "connectionId": "uuid",
          "facebookPageId": "123456",
          "facebookPageName": "The Coffee House",
          "facebookPageAvatarUrl": "https://...",
          "status": "active",
          "connectedAt": "2026-07-29T10:00:00Z"
        }
      ]
    }
  ],
  "activeHoursConfig": {
    "mode": "always",
    "start": "00:00",
    "end": "23:59"
  }
}
```

---

## 5. Disconnect Page

**DELETE** `/api/channels/instagram/connections/{connectionId}`

Ngắt kết nối 1 Facebook Page khỏi agent.

**Response 204**: No content.

**Xử lý phía backend**:
1. Validate connectionId thuộc agentId của user hiện tại.
2. Unsubscribe webhook: `DELETE /{instagram-business-account-id}/subscribed_apps`.
3. Cập nhật `status = "disconnected"`, `disconnected_at = now()`.
4. Ghi audit log.

**Lỗi**:
- 404: connectionId không tìm thấy hoặc không thuộc agent này.
- 403: không đủ quyền.

---

## 6. Webhook Inbound (Meta → Backend)

**POST** `/api/webhooks/instagram`

Meta gọi endpoint này khi có DM mới.

**Headers**:
```
X-Hub-Signature-256: sha256={hmac-sha256-of-body-with-app-secret}
Content-Type: application/json
```

**Verification request** (GET, khi Meta verify webhook):
```
GET /api/webhooks/instagram?hub.mode=subscribe&hub.verify_token={configured_token}&hub.challenge=1234567
→ Response 200: body = "1234567" (echo challenge)
```

**DM Event payload**:
```json
{
  "object": "instagram",
  "entry": [
    {
      "id": "{instagram-business-account-id}",
      "time": 1722211200,
      "messaging": [
        {
          "sender": { "id": "{instagram-scoped-user-id}" },
          "recipient": { "id": "{instagram-business-account-id}" },
          "timestamp": 1722211200000,
          "message": {
            "mid": "aWdfZAbcdef...",
            "text": "Xin chào, tôi muốn đặt lịch"
          }
        }
      ]
    }
  ]
}
```

**Backend xử lý**:
1. Validate `X-Hub-Signature-256`.
2. Parse `object` = "instagram".
3. Lookup `instagram_page_connections` theo `instagram_business_account_id`.
4. Cập nhật `last_customer_dm_at`.
5. Check 24h window + giờ hoạt động.
6. Route DM đến AI Agent runtime (xem plan.md — luồng chính).
7. Trả về `200 OK` ngay lập tức (trước khi process để tránh Meta timeout 20s).

**Response**: `200 OK` (body rỗng hoặc `{"status":"ok"}`).

**Quan trọng**: Luôn trả về 200 ngay cả khi bỏ qua event — Meta sẽ retry nếu nhận code khác.

---

## Breaking changes

Không có breaking change. Tất cả endpoints và webhook đều là mới (additive).

---

## Consumer

| Consumer | Endpoints sử dụng |
|----------|-------------------|
| Customer Studio Frontend | 1, 2 (redirect + result), 3, 4, 5 |
| Meta Platform (Instagram) | 6 (webhook) |
