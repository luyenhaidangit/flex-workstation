# HTTP contract: Meta channel connections

## Quy ước chung

- Các endpoint yêu cầu JWT và agent configurator scope.
- `agentId` trong request phải khớp agent principal được phép thao tác; handler không tin body độc lập.
- Public response không chứa access token, OAuth code, raw state, encryption key hoặc credential reference.
- `sessionId` là opaque value, có TTL và chỉ dùng cho đúng agent/channel/method.
- Error body dùng shape hiện hữu của API nếu có; các mã dưới đây là business code cần map vào error envelope hiện tại.

## Instagram — compatibility endpoints

| Method/route | Request/query | Response thành công | Lỗi chính |
|---|---|---|---|
| `POST /api/channels/instagram/connect` | `{ "agentId": "uuid" }` | `{ "oauthUrl": "https://...", "state": "opaque-or-legacy-compatible" }` | `401/403`, `400 INVALID_AGENT_SCOPE` |
| `GET /api/channels/instagram/callback` | Meta `code`, `state`, hoặc `error` params | Redirect về configured editor route với `channel=instagram`, `sessionId`, `status` | `INVALID_STATE`, `SESSION_EXPIRED`, `META_AUTH_FAILED` |
| `GET /api/channels/instagram/connect/result` | `sessionKey`/`sessionId` theo compatibility mapping | `{ "valid": [...], "invalid": [...], "metaAccountInfo": {...} }` | `400 SESSION_EXPIRED`, `403 FORBIDDEN` |
| `POST /api/channels/instagram/pages/confirm` | Legacy `{ "agentId": "uuid", "sessionKey": "...", "selectedPageIds": ["..."] }` | Existing-compatible connected response | `400 INVALID_CANDIDATE`, `409 CONNECTION_CONFLICT` |
| `GET /api/channels/instagram/connections` | `agentId` theo route/policy hiện hữu | Connected Instagram list/group metadata | `401/403` |
| `DELETE /api/channels/instagram/connections/{connectionId}` | none | `204` hoặc existing status response | `401/403`; idempotent nếu disconnected |

Legacy `selectedPageIds` được giữ để không phá consumer hiện hữu; implementation phải map vào use case mới, chỉ accept candidate thuộc session và không expose token. UI của feature chọn một resource theo spec.

## Facebook — new endpoints

| Method/route | Request/query | Response thành công | Lỗi chính |
|---|---|---|---|
| `POST /api/channels/facebook/connect` | `{ "agentId": "uuid", "method": "meta" }` | `{ "sessionId": "opaque", "oauthUrl": "https://..." }` | `401/403`, `400 UNSUPPORTED_METHOD` |
| `GET /api/channels/facebook/callback` | Meta `code`, `state`, hoặc `error` params | Redirect về editor route với `channel=facebook`, `sessionId`, `status` | `INVALID_STATE`, `SESSION_EXPIRED`, `META_AUTH_FAILED` |
| `GET /api/channels/facebook/connect/result` | `agentId`, `sessionId` | `{ "sessionId": "opaque", "channel": "facebook", "candidates": [...], "status": "discovered" }` | `400 SESSION_EXPIRED`, `403 FORBIDDEN` |
| `POST /api/channels/facebook/connections/complete` | `{ "agentId": "uuid", "sessionId": "opaque", "resourceId": "page-id" }` | `{ "connectionId": "uuid", "channel": "facebook", "resource": {...}, "status": "active" }` | `400 INVALID_CANDIDATE`, `409 CONNECTION_CONFLICT`, `422 PROVIDER_PERMISSION_REVOKED` |
| `GET /api/channels/facebook/connections` | `agentId` | `{ "connections": [...] }` | `401/403` |
| `DELETE /api/channels/facebook/connections/{connectionId}` | none | `204` hoặc `{ "status": "disconnected" }` | `401/403`; repeated request idempotent |

## Shared data shapes

Candidate:

```json
{
  "resourceId": "external-id",
  "resourceType": "facebook_page",
  "name": "Page name",
  "avatarUrl": "https://...",
  "instagramAccount": null,
  "eligibility": "eligible",
  "reason": null
}
```

Instagram candidate có thể có `instagramAccount: { "id": "...", "username": "...", "accountType": "BUSINESS" }` và `facebookPageId`. Invalid candidate chỉ trả reason/display metadata cần thiết, không trả provider token.

Error business codes:

| Code | HTTP | Ý nghĩa |
|---|---:|---|
| `INVALID_AGENT_SCOPE` | 403 | User không có quyền trên agent. |
| `INVALID_STATE` | 400 | State sai, replay hoặc không khớp session. |
| `SESSION_EXPIRED` | 400 | Session quá TTL hoặc đã kết thúc. |
| `META_AUTH_FAILED` | 400/502 | User hủy hoặc Meta token exchange thất bại. |
| `PROVIDER_PERMISSION_REVOKED` | 422 | Resource không còn quyền quản lý. |
| `INVALID_CANDIDATE` | 400 | Resource không thuộc discovery session/không đủ điều kiện. |
| `CONNECTION_CONFLICT` | 409 | Resource đã có active owner hoặc complete race. |
| `UNSUPPORTED_METHOD` | 400 | Method không được đăng ký trong MVP. |

## Compatibility và kiểm tra consumer

- Không đổi route Instagram trong feature này.
- Frontend mới dùng Facebook contracts và compatibility Instagram service.
- Meta App redirect URI phải trỏ đúng callback route của từng channel; cấu hình staging/prod không commit vào repo.
- Contract test phải xác nhận response không serialize các field encrypted/token và status/error code ổn định.
