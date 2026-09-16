# Meta Graph API Reference — flex-agent-service

## Mục đích và phạm vi

Tài liệu tham chiếu kỹ thuật cho toàn bộ request/response mà `flex-agent-service` gửi tới Meta
Graph API (Facebook/Instagram/Messenger). Dùng khi debug tích hợp, đối chiếu response thật từ
Graph API Explorer, hoặc thêm endpoint mới. Đây **không phải** tài liệu nghiệp vụ — xem
`docs/business/13-meta-channel-connections.md` cho luồng nghiệp vụ kết nối kênh.

Nguồn: `flex-agent-service/src/Flex.Agent.Infrastructures/Integrations/Meta/` và
`flex-agent-service/src/Flex.Agent.Infrastructures/Channels/Instagram/`. Đường dẫn file trong tài
liệu này là tương đối so với root của repo `flex-agent-service`.

## Cấu hình chung

`MetaOptions` (`src/Flex.Agent.Application/Abstractions/Integrations/Meta/MetaOptions.cs`):

| Field | Default | Ý nghĩa |
|---|---|---|
| `ApiVersion` | `v26.0` | Version Graph API dùng trong mọi URL — đổi ở config, không hardcode |
| `GraphApiBaseUrl` | `https://graph.facebook.com` | Base cho hầu hết request (trừ video upload) |
| `OAuthBaseUrl` | `https://www.facebook.com` | Base cho dialog OAuth (`/dialog/oauth`) |
| `AppId` / `AppSecret` | — | Định danh app, dùng để build `client_id`, `client_secret`, `appsecret_proof`, App Access Token |

Video upload dùng domain riêng, không qua `GraphApiBaseUrl`:
`https://rupload.facebook.com/video-upload/{ApiVersion}/{videoId}`.

**Xác thực**: đa số client set header `Authorization: Bearer {accessToken}` qua
`MetaGraphHttpClient.SendAsync`. Riêng `MetaAuthClient` (OAuth) truyền token qua query string
(`access_token=...`), dùng `MetaGraphHttpClient.SendOAuthAsync` — không set header.

**Lỗi**: mọi response không thành công được `MetaGraphHttpClient` parse thành `MetaErrorInfo`
(`code`, `error_subcode`, `type`, `fbtrace_id` từ envelope `{ "error": {...} }` của Graph API) rồi
bọc trong `MetaException`. Xem `MetaGraphHttpClient.cs:36-99`.

**Phân trang**: các list dùng cursor-based paging chuẩn của Graph API — đọc `paging.next` cho tới
khi null (`MetaGraphHttpClient.ListEdgeAsync`, `MetaGraphHttpClient.cs:102-120`). Response không có
`paging.next` (ví dụ khi số item dưới `limit` mặc định) nghĩa là đã hết trang, không phải lỗi.

---

## 1. OAuth & App-level — `MetaAuthClient.cs`

Auth: token truyền qua query string, không set header. Interface: `IMetaAuthClient`.

| Method | HTTP | Path | Query/Body chính | Response field chính |
|---|---|---|---|---|
| `BuildLoginUrl` | — | `{OAuthBaseUrl}/{v}/dialog/oauth` | `client_id, redirect_uri, state, scope, response_type=code` (+ `config_id`, `display`, `auth_type=rerequest`, `extras`) | (chỉ build URL, không gọi) |
| `GetCurrentUserAsync` | GET | `{GraphApiBaseUrl}/{v}/me` | `fields=id,name,picture`, `access_token` | `id`, `name`, `picture.data.url` |
| `ExchangeCodeAsync` | GET | `{GraphApiBaseUrl}/{v}/oauth/access_token` | `client_id, client_secret, redirect_uri, code` | `access_token` (→ `MetaAccessToken.Value`) |
| `ExchangeForLongLivedTokenAsync` | GET | `.../oauth/access_token` | `client_id, client_secret, grant_type=fb_exchange_token, fb_exchange_token` | `access_token` |
| `GetAppAccessTokenAsync` | GET | `.../oauth/access_token` | `client_id, client_secret, grant_type=client_credentials` | `access_token` |
| `GetClientCodeAsync` | GET | `{GraphApiBaseUrl}/{v}/oauth/client_code` | `client_id, client_secret, redirect_uri, access_token` | `code` |
| `DebugTokenAsync` | GET | `{GraphApiBaseUrl}/{v}/debug_token` | `input_token`, `access_token={AppId}\|{AppSecret}` | `data` → `MetaTokenDebugInfo` |
| `GetPermissionsAsync` | GET | `{GraphApiBaseUrl}/{v}/{userId}/permissions` | `access_token` (App token) | `data[]` → `MetaPermission` |
| `RevokePermissionAsync` | DELETE | `.../{userId}/permissions` hoặc `.../{userId}/permissions/{permission}` | `access_token` (App token) | `success` |
| `GetBusinessesAsync` | GET | `{GraphApiBaseUrl}/{v}/{userId}/businesses` | `fields=id,name,verification_status`, `access_token` (App token) | `data[]` → `MetaBusiness` |
| `GetSystemUserTokenAsync` | GET | `{GraphApiBaseUrl}/{v}/{systemUserId}/access_token` | `business_app, scope, appsecret_proof, access_token` (App token) | `access_token` |
| `SubscribeAppAsync` | POST | `{GraphApiBaseUrl}/{v}/{objectId}/subscribed_apps` | `access_token` (**App token**), `subscribed_fields` (tuỳ chọn) | `success` |
| `UnsubscribeAppAsync` | DELETE | `.../{objectId}/subscribed_apps` | `access_token` (**App token**) | `success` |

> `SubscribeAppAsync`/`UnsubscribeAppAsync` dùng **App Access Token** (`AppAccessTokenParam`), khác
> với `InstagramPageService.SubscribeWebhookAsync` (mục 4) vốn cần **Page Access Token** — hai
> method này không thể gộp trực tiếp, xem phần Debt.

---

## 2. Facebook Page — `FacebookPageClient.cs`

Auth: header `Authorization: Bearer {accessToken}`. Interface: `IFacebookPageClient`.

### Hồ sơ Page

| Method | HTTP | Path | Query/Body chính | Response field chính |
|---|---|---|---|---|
| `ListManagedPagesAsync` | GET | `{v}/{userId}/accounts` | `fields=id,name,category,access_token,tasks,fan_count,followers_count,instagram_business_account{id,username},picture` | `data[]` → `FacebookPage`, phân trang |
| `GetAsync` | GET | `{v}/{pageId}` | `fields` (mặc định `id,name,category,fan_count,followers_count`) | `FacebookPage` |
| `UpdateAsync` | POST | `{v}/{pageId}` | form fields tuỳ ý | `success` |
| `GetSubscribedFieldsAsync` | GET | `{v}/{pageId}/subscribed_apps` | — | `data[0].subscribed_fields` |

#### Ví dụ thực tế — `ListManagedPagesAsync` (`GET /me/accounts`)

> Access token trong response gốc đã được thay bằng `<PAGE_ACCESS_TOKEN_REDACTED>` — không lưu
> token thật vào source control theo quy tắc repo.

```bash
curl -G "https://graph.facebook.com/v26.0/me/accounts" \
  --data-urlencode "fields=id,name,category,access_token,tasks,fan_count,followers_count,instagram_business_account{id,username},picture" \
  --data-urlencode "access_token=<USER_ACCESS_TOKEN>"
```

```json
{
  "data": [
    {
      "id": "1249293121600899",
      "name": "Đăng test misa",
      "category": "Blog cá nhân",
      "access_token": "<PAGE_ACCESS_TOKEN_REDACTED>",
      "fan_count": 0,
      "followers_count": 0,
      "picture": {
        "data": {
          "height": 50,
          "is_silhouette": false,
          "url": "https://scontent.fhan5-6.fna.fbcdn.net/...",
          "width": 50
        }
      },
      "tasks": ["MANAGE", "CREATE_CONTENT", "MODERATE", "MESSAGING", "ADVERTISE", "ANALYZE"]
    },
    {
      "id": "1222872987578733",
      "name": "MISAAgentwork Test",
      "category": "Blog cá nhân",
      "access_token": "<PAGE_ACCESS_TOKEN_REDACTED>",
      "fan_count": 0,
      "followers_count": 0,
      "instagram_business_account": { "id": "17841453926494688" },
      "picture": {
        "data": {
          "height": 50,
          "is_silhouette": false,
          "url": "https://scontent.fhan5-10.fna.fbcdn.net/...",
          "width": 50
        }
      },
      "tasks": ["MANAGE", "CREATE_CONTENT", "MODERATE", "MESSAGING", "ADVERTISE", "ANALYZE"]
    },
    {
      "id": "1078537938666264",
      "name": "TestAcc",
      "category": "Trang dành cho fan",
      "access_token": "<PAGE_ACCESS_TOKEN_REDACTED>",
      "fan_count": 0,
      "followers_count": 0,
      "picture": {
        "data": {
          "height": 50,
          "is_silhouette": false,
          "url": "https://scontent.fhan5-8.fna.fbcdn.net/...",
          "width": 50
        }
      },
      "tasks": ["MODERATE", "MESSAGING", "ANALYZE", "ADVERTISE", "CREATE_CONTENT", "MANAGE"]
    },
    {
      "id": "110405491574664",
      "name": "Cloud",
      "category": "Phần mềm",
      "access_token": "<PAGE_ACCESS_TOKEN_REDACTED>",
      "fan_count": 0,
      "followers_count": 0,
      "instagram_business_account": { "id": "17841477335479742" },
      "picture": {
        "data": {
          "height": 50,
          "is_silhouette": false,
          "url": "https://scontent.fhan5-10.fna.fbcdn.net/...",
          "width": 50
        }
      },
      "tasks": ["MANAGE", "CREATE_CONTENT", "MODERATE", "MESSAGING", "ADVERTISE", "ANALYZE"]
    }
  ],
  "paging": {
    "cursors": {
      "before": "QVFIVHNaNjM1WFduMWMtelJLbW1DWmhZAVXgtWmJ3RF8tNmZAEcmZAzdmR5VEhfbTBXemY2V0xLelRIRS14ekIxVTVKOUJhcnJWSHczallnd2pLOVZA4Q2psRjB3",
      "after": "QVFIVHdFQURnTU42VGRabEFWdUhyeDJISmZAobEVlVl95VTNma1FjaWdaekxKc0YyVGRPN2RGNmw5RUl5RDBQbGhYMERuRE5XbkFKNmlJelNRQmE5aWxnbUh3"
    }
  }
}
```

Ghi chú: `paging` chỉ có `cursors`, **không có `next`** — đúng hành vi khi số Page trả về dưới
`limit` mặc định (4 Page ở đây); `MetaGraphHttpClient.ListEdgeAsync` sẽ dừng vòng lặp ngay sau lần
gọi đầu, không có trang tiếp theo. `instagram_business_account` chỉ xuất hiện ở 2/4 Page (có liên
kết IG Business/Creator) — field nullable trong record `FacebookPage`, không cần xử lý đặc biệt.

> Response mẫu trên được chụp **trước khi đổi field sang dạng expand** — lúc đó
> `instagram_business_account` chỉ trả `{ "id": "..." }`. Sau khi đổi field thành
> `instagram_business_account{id,username}` (2026-09), 2 Page có liên kết IG sẽ trả thêm
> `username`, ví dụ: `"instagram_business_account": { "id": "17841453926494688", "username": "..." }`.
>
> **`account_type` KHÔNG nằm trong field expand này** — đã thử và bị Graph API trả lỗi
> `(#100) Tried accessing nonexisting field (account_type)`. Đối chiếu tài liệu chính thức của
> Meta (Page reference, IG User reference trong Instagram Platform docs, Instagram Platform
> changelog — 2026-09) xác nhận `account_type` **không còn là field hợp lệ trên IG User node**,
> không phải vấn đề nested expansion. Vì `instagram_business_account` chỉ trả giá trị khi IG
> account là Business/Creator (personal account không thể link Page qua API), sự tồn tại của field
> này đã tự đảm bảo BR-001 — không cần biết chính xác BUSINESS hay CREATOR nữa. Đã xoá hẳn field
> này xuyên toàn bộ chuỗi (không giữ lại dạng nullable): `InstagramOwner.AccountType`,
> `ValidPageDto.AccountType`, `ConnectionCandidate.InstagramAccountType`,
> `CandidateCacheEntry.InstagramAccountType`, `FacebookDiscoveryCandidate.InstagramAccountType`,
> `InstagramPageConnection.InstagramAccountType`, và cột DB `instagram_page_connections.instagram_account_type`
> — bỏ thẳng khỏi CREATE TABLE trong `AddInstagramTables.sql` (migration chưa từng apply ở môi
> trường nào nên sửa trực tiếp, không tạo migration ALTER riêng). `ProcessInstagramCallbackCommand`
> chỉ lọc theo `igAccount is null`.

### Đăng nội dung

| Method | HTTP | Path | Query/Body chính | Response field chính |
|---|---|---|---|---|
| `PublishPostAsync` | POST | `{v}/{pageId}/feed` | `message, link, published, scheduled_publish_time, place, tags, attached_media[i]` | `FacebookPostResult` (`id`) |
| `PublishPhotoAsync` | POST | `{v}/{pageId}/photos` | multipart (`source` file) hoặc form (`url`) + `caption, alt_text_custom, published` | `FacebookPostResult` |
| `PublishVideoAsync` | POST (3 phase) | `{v}/{pageId}/videos` (start/finish) + `https://rupload.facebook.com/video-upload/{v}/{videoId}` (transfer, header `Authorization: OAuth {token}`, `offset`, `file_size`) | phase `start`: `file_size`; phase `finish`: `upload_session_id, title, description, scheduled_publish_time` | `video_id`, `upload_session_id`, `start_offset`/`end_offset` mỗi chunk |
| `UpdatePostAsync` | POST | `{v}/{postId}` | `message` | `success` |
| `DeletePostAsync` | DELETE | `{v}/{postId}` | — | `success` |
| `ListFeedAsync` | GET | `{v}/{pageId}/feed` | `fields` (mặc định `id,message,story,created_time,permalink_url,is_published,scheduled_publish_time,full_picture`), `since, until, limit` | `data[]` → `FacebookPost`, phân trang |

### Lịch đăng

| Method | HTTP | Path | Query/Body chính | Response field chính |
|---|---|---|---|---|
| `ListScheduledPostsAsync` | GET | `{v}/{pageId}/scheduled_posts` | `fields=id,message,created_time,is_published,scheduled_publish_time` | `data[]`, phân trang |
| `PublishScheduledPostAsync` | POST | `{v}/{postId}` | `is_published=true` | `success` |

### Comment & Like

| Method | HTTP | Path | Query/Body chính | Response field chính |
|---|---|---|---|---|
| `ListCommentsAsync` | GET | `{v}/{objectId}/comments` | `fields=id,message,created_time,from,like_count,comment_count,is_hidden,parent`, `order` | `data[]`, phân trang |
| `CreateCommentAsync` | POST | `{v}/{objectId}/comments` | `message, attachment_url` | `id` |
| `DeleteCommentAsync` | DELETE | `{v}/{commentId}` | — | `success` |
| `HideCommentAsync` | POST | `{v}/{commentId}` | `is_hidden` | `success` |
| `LikeAsync` | POST | `{v}/{objectId}/likes` | (body rỗng) | `success` |
| `UnlikeAsync` | DELETE | `{v}/{objectId}/likes` | — | `success` |

### Insights

| Method | HTTP | Path | Query/Body chính | Response field chính |
|---|---|---|---|---|
| `GetPageInsightsAsync` | GET | `{v}/{pageId}/insights` | `metric, period, since, until, date_preset` | `data[]` → `FacebookInsightMetric` |
| `GetPostInsightsAsync` | GET | `{v}/{postId}/insights` | `metric` | `data[]` → `FacebookInsightMetric` |

> **Debt đã biết**: 18/19 method của `IFacebookPageClient` chưa có caller thực trong solution
> (grep xác nhận, 2026-09) — chỉ `ListManagedPagesAsync` đang được gọi thật (từ
> `ProcessFacebookCallbackCommand` và `ProcessInstagramCallbackCommand`). File 405 dòng, chưa tách
> theo resource (profile/content/comment/insight) vì chưa có nhu cầu thực; quyết định giữ nguyên đã
> được xác nhận rõ ràng, tách khi có caller thật cho từng nhóm.

---

## 3. Messenger — `MessengerClient.cs`

Auth: header `Authorization: Bearer {accessToken}`. Interface: `IMessengerClient`.

| Method | HTTP | Path | Query/Body chính | Response field chính |
|---|---|---|---|---|
| `SendAsync` / `SendTextAsync` | POST | `{v}/{pageId}/messages` | JSON `MessengerSendRequest` (`messaging_type, recipient.id, message.text, tag`) | `MessengerSendResult` |
| `SendSenderActionAsync` | POST | `{v}/{pageId}/messages` | JSON `{ recipient.id, sender_action }` | (raw `JsonElement`) |
| `GetUserProfileAsync` | GET | `{v}/{psid}` | `fields` (mặc định `id,first_name,last_name,profile_pic,locale,timezone`) | `MessengerUserProfile` |
| `ListConversationsAsync` | GET | `{v}/{pageId}/conversations` | `fields=id,link,updated_time,message_count,unread_count,participants`, `user_id` | `data[]`, phân trang |
| `ListMessagesAsync` | GET | `{v}/{conversationId}/messages` | `fields=id,message,created_time,from,to` | `data[]`, phân trang |
| `DeleteMessageAsync` | DELETE | `{v}/{messageId}` | — | `success` (Meta không có API thu hồi chính thức, chỉ hỗ trợ giới hạn) |
| `SetPersistentMenuAsync` | POST | `{v}/{pageId}/messenger_profile` | JSON `{ persistent_menu }` | `success` |
| `SetGetStartedAsync` | POST | `.../messenger_profile` | JSON `{ get_started: { payload } }` | `success` |
| `SetGreetingAsync` | POST | `.../messenger_profile` | JSON `{ greeting: [...] }` | `success` |
| `DeleteMessengerProfileAsync` | DELETE | `.../messenger_profile` | JSON `{ fields: [...] }` | `success` |
| `CreatePersonaAsync` | POST | `{v}/{pageId}/personas` | JSON `{ name, profile_picture_url }` | `id` |
| `ListPersonasAsync` | GET | `{v}/{pageId}/personas` | — | `data[]`, phân trang |
| `DeletePersonaAsync` | DELETE | `{v}/{personaId}` | — | `success` |
| `PassThreadControlAsync` | POST | `{v}/{pageId}/pass_thread_control` | JSON `{ recipient.id, target_app_id, metadata }` | `success` |
| `TakeThreadControlAsync` | POST | `{v}/{pageId}/take_thread_control` | JSON `{ recipient.id, metadata }` | `success` |
| `RequestThreadControlAsync` | POST | `{v}/{pageId}/request_thread_control` | JSON `{ recipient.id, metadata }` | `success` |
| `GetThreadOwnerAsync` | GET | `{v}/{pageId}/thread_owner` | `recipient` | `data[0]` → `MessengerThreadOwner` |

> `SendAsync` không hỗ trợ truyền thêm header tuỳ chỉnh (ví dụ `X-Correlation-ID`) — đây là lý do
> `InstagramWebhookHandler.SendReplyAsync` (mục 4) chưa gọi qua interface này, xem Debt.

---

## 4. Channels/Instagram — nghiệp vụ DM và webhook

Các service này **không dùng chung `MetaGraphHttpClient`** — gọi `HttpClient` trực tiếp qua
`IOptions<MetaOptions>` để build base URL (đã đồng bộ `ApiVersion`, trước đây hardcode `v21.0`, xem
Decision Log của thay đổi liên quan).

### `InstagramOAuthService.cs` — trùng lặp với Integrations/Meta (debt)

| Method | HTTP | Path | Query | Response field chính | Trùng với |
|---|---|---|---|---|---|
| `GetPageAccessTokenAsync` | GET | `{v}/{pageId}` | `fields=access_token, access_token` | `access_token` | không có tương đương trực tiếp trong `IFacebookPageClient` |
| `GetMeAsync` | GET | `{v}/me` | `fields=id,name,picture, access_token` | `MetaMeResponse` | `MetaAuthClient.GetCurrentUserAsync` |
| `GetManagedPagesAsync` | GET | `{v}/me/accounts` | `fields=id,name,access_token,picture, access_token` | `MetaPageListResponse.Data` | `FacebookPageClient.ListManagedPagesAsync` (field set khác, không phân trang) |
| `GetLinkedInstagramAccountAsync` | GET | `{v}/{pageId}` | `fields=instagram_business_account, access_token` | `MetaPageIgResponse.InstagramBusinessAccount` | `FacebookPageClient.ListManagedPagesAsync` (field expand `instagram_business_account{id,username}`, không phân trang) |
| `GetIgAccountInfoAsync` | GET | `{v}/{igAccountId}` | `fields=id,username,account_type,profile_picture_url, access_token` | `MetaIgAccountInfoResponse` | `FacebookPageClient.ListManagedPagesAsync` (field expand, thiếu `profile_picture_url` — chưa có caller nào cần) |

> **Debt đã biết**: các call này dùng DTO riêng (`MetaMeResponse`, `MetaPageItem`, `MetaIgAccountRef`,
> `MetaIgAccountInfoResponse`) khác với DTO trong `Integrations/Meta`, và không dùng
> `MetaGraphHttpClient` nên không có structured error (`MetaErrorInfo`) hay xử lý pagination chuẩn.
> Gộp về `Integrations/Meta` cần đổi shared DTO dùng xuyên suốt luồng Instagram OAuth — rủi ro cao
> hơn lợi ích tức thời, chưa thực hiện.
>
> **Debt bổ sung (2026-09)**: `GetIgAccountInfoAsync` request field `account_type` — field này đã
> bị Meta gỡ khỏi IG User node (xem mục 2, Debt & follow-up tổng hợp), request này sẽ lỗi
> `(#100) nonexisting field` nếu có caller thật gọi tới. Hiện chưa có caller (grep xác nhận) nên
> chưa gây lỗi runtime, nhưng phải sửa field trước khi ai đó nối caller vào.

### `InstagramPageService.cs`

| Method | HTTP | Path | Query/Body chính | Response field chính |
|---|---|---|---|---|
| `SubscribeWebhookAsync` (private) | POST | `{v}/{igAccountId}/subscribed_apps` | form `access_token` (**Page token**), `subscribed_fields=messages,messaging_postbacks` | (chỉ log warning nếu fail, không parse response) |
| `UnsubscribeWebhookAsync` (private) | DELETE | `.../subscribed_apps` | `access_token` (**Page token**) | (tương tự) |

> Dùng **Page Access Token**, khác `MetaAuthClient.SubscribeAppAsync`/`UnsubscribeAppAsync` (App
> token, mục 1) — không thể gộp trực tiếp, xem Debt ở mục 1.

### `InstagramWebhookHandler.cs`

| Method | HTTP | Path | Body | Response field chính |
|---|---|---|---|---|
| `SendReplyAsync` (private) | POST | `{v}/{igAccountBusinessId}/messages` | JSON `{ recipient.id, message.text }`, header `X-Correlation-ID` (tracing nội bộ) | (chỉ log success/fail, không parse body) |

> Không gọi qua `IMessengerClient.SendAsync` vì interface đó chưa hỗ trợ truyền header tuỳ chỉnh —
> xem Debt ở mục 3.

---

## Debt & follow-up tổng hợp

| Debt | Vị trí | Điều kiện nên xử lý |
|---|---|---|
| `IFacebookPageClient` 18/19 method chưa có caller | `FacebookPageClient.cs` (405 dòng) | Tách theo resource khi từng nhóm (content-publish, comment, insight...) có caller thật |
| `InstagramOAuthService` trùng logic Graph call với `Integrations/Meta` | `Channels/Instagram/InstagramOAuthService.cs` | Khi cần sửa đồng thời cả 2 nơi (dấu hiệu drift), hoặc khi refactor DTO dùng chung |
| ~~`ListManagedPagesAsync` gọi N+1 request để lấy `account_type` của IG account~~ | `ProcessInstagramCallbackCommand.cs` | **Đã xử lý (2026-09)**: đổi sang expand `instagram_business_account{id,username}` ngay trong `/me/accounts`; xoá `IInstagramClient`/`InstagramClient` (không còn caller) |
| ~~`account_type` không còn là field hợp lệ trên IG User node~~ (Meta đã gỡ — xác nhận qua Page reference, IG User reference, Instagram Platform changelog + lỗi Graph API thật `(#100) nonexisting field`) | Toàn bộ chuỗi `AccountType`/`instagram_account_type` | **Đã xử lý (2026-09)**: xoá hẳn field xuyên toàn bộ chuỗi có caller thật — `InstagramOwner`, `ValidPageDto`, `ConnectionCandidate`, `CandidateCacheEntry`, `FacebookDiscoveryCandidate`, `InstagramPageConnection`, cột DB (migration `DropInstagramAccountType.sql`). `ProcessInstagramCallbackCommand` chỉ lọc theo `instagram_business_account` có giá trị hay không (đã tự đảm bảo Business/Creator). `InstagramOAuthService.GetIgAccountInfoAsync` vẫn còn field chết nhưng chưa có caller — xem debt ở mục 4 |
| `IMessengerClient.SendAsync` không truyền được header tuỳ chỉnh | `Application/Abstractions/.../IMessengerClient.cs` | Thêm overload nhận `extraHeaders`/`correlationId` khi có nhu cầu thứ 2 ngoài Instagram DM |
| `IMetaAuthClient.SubscribeAppAsync`/`UnsubscribeAppAsync` chỉ nhận App token | `Application/Abstractions/.../IMetaAuthClient.cs` | Thêm overload nhận `accessToken` tường minh khi cần gộp với `InstagramPageService` |
| Không có resilience (retry/backoff) cho HTTP client gọi Meta | toàn bộ `Integrations/Meta` | Thêm khi có bằng chứng lỗi transient thực tế (log `meta.graph.transport_error`/`timeout`) |
| `rupload.facebook.com` hardcode, không qua `MetaOptions` | `FacebookPageClient.RuploadVideoEndpoint` | Domain riêng theo tài liệu Meta, không đổi theo môi trường — chấp nhận được, không phải bug |
| Không có test cho `Integrations/Meta` | toàn repo (`tests/` chưa tồn tại) | Thêm khi có test project đầu tiên cho `Flex.Agent.Infrastructures` |
