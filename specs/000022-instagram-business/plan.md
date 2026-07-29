# Kế hoạch triển khai: Phát hành AI Agent trên Instagram Business

**Branch**: `000022-instagram-business` | **Ngày**: 2026-07-29 | **Đặc tả**: [spec.md](./spec.md)

**Đầu vào**: Đặc tả tính năng từ `specs/000022-instagram-business/spec.md`

---

## Tóm tắt

**Yêu cầu chính từ spec**:
- MVP-001: Kênh "Instagram Business" trong Customer Studio, kết nối qua OAuth Meta 3 bước.
- MVP-002: AI Agent nhận và trả lời DM Instagram (cửa sổ 24h).
- MVP-003: Quản lý kết nối — xem trạng thái, ngắt kết nối, thêm trang/tài khoản.
- MVP-004: Chỉ hỗ trợ tài khoản Business/Creator đã liên kết Fanpage Facebook. Ràng buộc 1 page = 1 agent (page-level, không phải account-level).

**Hướng tiếp cận kỹ thuật dự kiến**:
Tái sử dụng cơ sở OAuth Meta đã có cho Fanpage Facebook, mở rộng thêm scope `instagram_manage_messages`. Thêm 2 bảng mới (`MetaAccountConnection`, `InstagramPageConnection`) để quản lý đa tài khoản/đa trang. Backend đăng ký Instagram webhook và route DM về luồng xử lý agent hiện có. Frontend thêm channel card, popup kết quả 2 tab, và connected-state UI theo design.

**Kết quả sau research**: Xem research.md — Instagram Graph API v21, token page-level không tự hết hạn khi user active, webhook endpoint có thể dùng chung với Facebook hoặc tách riêng.

---

## Phạm vi kỹ thuật

**Trong phạm vi**:
- Backend: Các API endpoints quản lý kênh Instagram (initiate OAuth, callback, confirm pages, list, disconnect).
- Backend: Webhook handler nhận Instagram DM event và route vào luồng agent.
- Backend: Lưu trữ `MetaAccountConnection` và `InstagramPageConnection` (token mã hoá, trạng thái, unique constraint page-level).
- Backend: Logic kiểm tra page conflict (để phân chia Hợp lệ / Không hợp lệ trong popup).
- Backend: Audit log cho kết nối/ngắt kết nối.
- Frontend: Channel card "Instagram Business" trong màn hình Phát hành.
- Frontend: Luồng 3 bước (inline instructions + nút "Kết nối ngay").
- Frontend: Popup "Kết quả kết nối" — 2 tab Hợp lệ (checkbox chọn page) và Không hợp lệ (page đã bị agent khác dùng, hiện tên agent).
- Frontend: Connected-state UI (danh sách nhóm theo tài khoản Meta, "+Thêm trang", "+Thêm tài khoản", Ngắt kết nối, Giờ hoạt động, toggle DMs).

**Ngoài phạm vi kỹ thuật**:
- Comment reply, mention reply và proactive DM (spec §15).
- Bộ lọc kênh và thống kê phiên chat trong màn hình Hội thoại.
- Cập nhật template agent hiển thị kênh IG.
- Token refresh automation (page token không hết hạn trong trường hợp thông thường — xem research.md).
- Mobile view.

---

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: .NET/C# (backend API) — phiên bản cụ thể: CẦN LÀM RÕ từ repo con.

**Service/App liên quan**:
- `customer-studio-api` (hoặc tên tương đương) — backend xử lý channel management, OAuth, webhook.
- `customer-studio-web` (hoặc tên tương đương) — frontend React/Vue hiển thị UI.
- AI Agent runtime service — nhận DM đã được route và xử lý phản hồi.

**Phụ thuộc chính**:
- Meta Graph API v21.0 (Instagram Graph API): OAuth, Page API, Messaging API, Webhooks.
- Cơ chế OAuth Meta hiện có (dùng cho Facebook/Messenger channel) — CẦN LÀM RÕ đang dùng thư viện/wrapper nào.
- Hệ thống mã hoá token (AES/asymmetric) đang dùng cho Facebook token — CẦN LÀM RÕ.
- Channel routing layer (nhận webhook → dispatch đến agent) — CẦN LÀM RÕ interface hiện tại.

**Lưu trữ**: PostgreSQL (giả định theo pattern platform, CẦN LÀM RÕ xác nhận).

**Kiểm thử**: xUnit + integration test (giả định theo flex-dotnet-conventions). Manual test với tài khoản Instagram Business thật.

**Nền tảng chạy**: Linux container / Kubernetes (giả định, CẦN LÀM RÕ).

**Đơn vị deploy**: customer-studio-api service.

**Loại project**: web-service (backend) + admin-web (frontend).

**Mục tiêu hiệu năng**:
- Luồng kết nối 3 bước hoàn thành dưới 30 giây (NFR-001).
- DM được agent trả lời trong vòng 60 giây (AC-005, NFR thực chất phụ thuộc agent latency + webhook delivery).

**Ràng buộc**: Meta webhook delivery latency ~1-5s; 24-hour messaging window bắt buộc (BR-006); tài khoản IG phải Business/Creator + liên kết Page (BR-001, BR-002).

**Quy mô/Phạm vi**: MVP — số lượng kết nối nhỏ, không có yêu cầu scale đặc biệt.

---

## Kiểm tra constitution

*GATE: Phải đạt trước Phase 0 research. Kiểm tra lại sau Phase 1 design.*

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| Scope Gate | Pass | Pass | Scope khớp MVP spec; comment/proactive đã đưa ra ngoài |
| Traceability Gate | Pass | Pass | US/FR P1/P2 đã có mapping trong bảng traceability |
| Security Gate | Pass có điều kiện | Pass | Token mã hoá (SEC-003), permission check (SEC-001); cần xác nhận cơ chế encryption thật |
| Test Gate | Pass có điều kiện | Pass | Integration test với Meta sandbox; manual test tài khoản thật |
| Compatibility Gate | Pass | Pass | Tính năng mới, không thay đổi contract/data hiện có |
| Observability Gate | Pass | Pass | Log field, metric đã xác định trong phần Observability |
| Complexity Gate | Pass | Pass | Tái sử dụng OAuth Meta hiện có; không thêm pattern mới ngoài 2 bảng mới |
| Release Gate | Pass có điều kiện | Pass | Không có migration dữ liệu cũ; cần smoke test sau deploy |

---

## Câu hỏi kỹ thuật cần research

- **TQ-001**: Instagram Graph API — token page-level có hết hạn không? Cần refresh token hay không? → Xem research.md §1.
- **TQ-002**: Instagram webhook và Facebook Page webhook có dùng chung URL endpoint không? Cách phân biệt event type? → Xem research.md §2.
- **TQ-003**: OAuth callback flow — sau khi lấy được `user_access_token`, cách lấy danh sách pages + kiểm tra `instagram_business_account` liên kết? → Xem research.md §3.
- **TQ-004**: Cơ chế 24-hour messaging window — Meta API trả lỗi gì khi agent cố gửi ngoài cửa sổ? Client cần xử lý phía nào? → Xem research.md §4.
- **TQ-005**: Cách channel routing hiện tại cho Facebook/Messenger — interface nào cần implement để thêm Instagram vào luồng? → CẦN LÀM RÕ khi tiếp cận repo con.

---

## Thiết kế tổng quan

### Luồng chính: Kết nối Instagram Business

```
[User] → Bấm "Kết nối ngay"
  → [Frontend] POST /api/channels/instagram/connect {agentId}
  → [Backend] Tạo OAuth state, trả về Meta OAuth URL
  → [Frontend] Redirect user đến Meta Login
  → [User] Đăng nhập Facebook, cấp quyền instagram_manage_messages
  → [Meta] Redirect về /api/channels/instagram/callback?code=...&state=...
  → [Backend]
      1. Validate state (CSRF protection)
      2. Exchange code → user_access_token (short-lived)
      3. Exchange → long-lived user token
      4. GET /me/accounts → danh sách Facebook Pages user quản lý
      5. Với mỗi page: GET /{page-id}?fields=instagram_business_account,account_type
      6. Lọc page có instagram_business_account (Business/Creator)
      7. Kiểm tra từng page trong DB: đã có agent khác giữ không?
      8. Phân loại: valid (chưa ai giữ hoặc agent này đang giữ) vs invalid (agent khác giữ)
      9. Lưu tạm thời vào session/cache (chờ user confirm)
      10. Redirect frontend về với kết quả
  → [Frontend] Hiển thị popup "Kết quả kết nối" (2 tab: Hợp lệ / Không hợp lệ)
  → [User] Chọn checkbox pages muốn kết nối → Bấm "Xác nhận"
  → [Frontend] POST /api/channels/instagram/pages/confirm {agentId, selectedPageIds[]}
  → [Backend]
      1. Validate pages đã chọn còn hợp lệ
      2. Tạo MetaAccountConnection (nếu chưa có cho user này + agent này)
      3. Tạo/update InstagramPageConnection cho từng page được chọn
      4. Subscribe webhook cho mỗi page (POST /{page-id}/subscribed_apps)
      5. Ghi audit log
      6. Trả về danh sách kết nối đã tạo
  → [Frontend] Chuyển sang connected-state UI
```

### Luồng chính: Nhận và trả lời DM

```
[Khách] DM đến trang Instagram
  → [Meta] POST /api/webhooks/instagram (webhook event)
  → [Backend]
      1. Validate X-Hub-Signature-256 (HMAC)
      2. Parse event: object=instagram, entry[].messaging[].message
      3. Lấy instagram-scoped user ID (sender), page ID (recipient)
      4. Lookup InstagramPageConnection → tìm agentId
      5. Kiểm tra 24h window: so sánh timestamp vs last_customer_message_at
      6. Kiểm tra giờ hoạt động của agent
      7. Route vào AI Agent runtime với context: {channel: instagram, pageId, senderId, message}
  → [AI Agent] Xử lý, tạo reply
  → [Backend] POST /{instagram-user-id}/messages (Send API)
  → [Meta] Gửi tin nhắn đến khách
```

### Component/module tham gia

| Module | Vai trò |
|--------|---------|
| `InstagramChannelController` | API endpoints: connect, callback, confirm, list, disconnect |
| `InstagramOAuthService` | OAuth flow: tạo URL, exchange code, refresh token |
| `InstagramPageService` | Quản lý page connections, conflict check, webhook subscription |
| `InstagramWebhookHandler` | Nhận webhook, validate signature, parse, route to agent |
| `ChannelTokenEncryptionService` | Mã hoá/giải mã access token (tái sử dụng từ Facebook channel) |
| Frontend: `InstagramChannelCard` | Channel card với 3-step instructions + nút kết nối |
| Frontend: `ConnectionResultModal` | Popup 2 tab (Hợp lệ/Không hợp lệ) |
| Frontend: `InstagramConnectedState` | Danh sách kết nối nhóm theo account, thêm/ngắt, giờ hoạt động |

### Điểm mở rộng/thay đổi chính

- Thêm `ChannelType.InstagramBusiness` vào enum/registry kênh hiện có.
- Extend OAuth flow hiện có để hỗ trợ thêm scope `instagram_manage_messages`.
- Thêm webhook route `/api/webhooks/instagram` (có thể cùng controller với Facebook webhook).
- Thêm 2 bảng: `MetaAccountConnections`, `InstagramPageConnections`.

### Luồng thay thế/lỗi chính

| Tình huống | Xử lý |
|-----------|--------|
| OAuth bị user cancel | Redirect về UI với lỗi "Kết nối bị huỷ" |
| Không có page nào đủ điều kiện (không có IG Business) | Popup chỉ có tab "Không hợp lệ", không có gì để chọn |
| Webhook signature không hợp lệ | Trả về 403, bỏ qua, log cảnh báo |
| DM ngoài cửa sổ 24h | Bỏ qua silently, ghi log, không gửi reply |
| Page access token hết hạn / bị thu hồi | Cập nhật status InstagramPageConnection → Error, ghi audit log, thông báo owner qua UI |
| Gửi DM thất bại (Meta API error) | Log lỗi với pageId + senderId, không retry tự động trong MVP |

### Idempotency/Concurrency

- `POST confirm pages`: nếu gọi 2 lần với cùng pageId → upsert, không tạo duplicate (UNIQUE constraint trên `FacebookPageId`).
- Webhook: nếu cùng `mid` (message ID) nhận 2 lần → deduplicate bằng message ID trước khi route.

---

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|------------|----------------------|---------------------|--------------|-------------|----------|
| US-001 / FR-001 | P1 | Đủ rõ | Thêm ChannelType.InstagramBusiness vào channel registry; render channel card với tên cố định + mô tả + cảnh báo | Frontend: `InstagramChannelCard` | GET /api/channels (danh sách channel types) | Không áp dụng | Manual: channel card xuất hiện đúng |
| US-001 / FR-002 | P1 | Đủ rõ | Backend tạo OAuth URL + state; frontend redirect; Meta callback | `InstagramOAuthService`, `InstagramChannelController` | POST /api/channels/instagram/connect | Không áp dụng | Integration: OAuth flow end-to-end với Meta sandbox |
| US-001 / FR-003 | P1 | Đủ rõ | Backend validate tài khoản, phân loại Hợp lệ/Không hợp lệ, frontend hiển thị popup 2 tab | `InstagramPageService`, `ConnectionResultModal` | GET /api/channels/instagram/callback | `InstagramPageConnections` (check uniqueness) | Integration: test với page Business + page cá nhân |
| US-001 / FR-004 | P1 | Đủ rõ | Không tạo connection nếu page không có `instagram_business_account` | `InstagramPageService` | Không áp dụng | `InstagramPageConnections` | Unit: filter logic |
| US-002 / FR-005 | P1 | Đủ rõ | Webhook handler nhận DM, route đến agent runtime | `InstagramWebhookHandler` | POST /api/webhooks/instagram (inbound) | `InstagramPageConnections` | Integration: gửi DM thật từ test account |
| US-002 / FR-006 | P1 | Đủ rõ | Kiểm tra giờ hoạt động và 24h window trước khi route đến agent | `InstagramWebhookHandler` | Không áp dụng | `InstagramPageConnections.active_hours` | Unit: logic check giờ + 24h window |
| US-003 / FR-007 | P2 | Đủ rõ | DELETE endpoint, unsubscribe webhook, cập nhật status | `InstagramChannelController`, `InstagramPageService` | DELETE /api/channels/instagram/connections/{id} | `InstagramPageConnections` | Manual + integration |
| US-003 / FR-008a | P2 | Đủ rõ | Mở lại popup confirm với page list của account hiện tại | Frontend: `InstagramConnectedState` | POST /api/channels/instagram/pages/confirm | `InstagramPageConnections` | Manual |
| US-003 / FR-008b | P2 | Đủ rõ | Khởi động lại OAuth flow với account Meta mới | Frontend → `InstagramOAuthService` | POST /api/channels/instagram/connect | `MetaAccountConnections` | Manual |
| FR-009 | P3 | Đủ rõ | Webhook deauthorize / page_update events → cập nhật status Error | `InstagramWebhookHandler` | POST /api/webhooks/instagram | `InstagramPageConnections` | Integration |
| FR-010 / BR-005 | P1 | Đủ rõ | UNIQUE constraint trên `FacebookPageId`; phân loại invalid trong callback | `InstagramPageService` | Không áp dụng | `InstagramPageConnections` UNIQUE(facebook_page_id) | Unit: conflict check |
| BR-006 | P1 | Đủ rõ | So sánh `last_customer_dm_at` với now() - 24h trước khi gửi reply | `InstagramWebhookHandler` | Không áp dụng | `InstagramPageConnections.last_customer_dm_at` | Unit: 24h window logic |
| SEC-001 | P1 | Đủ rõ | Auth middleware kiểm tra role owner/admin trước các API channel Instagram | Middleware / `InstagramChannelController` | Tất cả endpoints | Không áp dụng | Permission test |
| SEC-002 | P1 | Đủ rõ | Mọi query đều scope theo `agentId` thuộc workspace hiện tại | `InstagramPageService` | Không áp dụng | `InstagramPageConnections.agent_id` | Permission test |
| SEC-003 | P1 | Đủ rõ | Token mã hoá trước khi lưu DB; không log token | `ChannelTokenEncryptionService` | Không áp dụng | `MetaAccountConnections.encrypted_token` | Unit: mã hoá/giải mã |

---

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---------|------------------|--------------------------|---------------|
| Database/Migration | Thêm 2 bảng mới (`meta_account_connections`, `instagram_page_connections`) + UNIQUE constraint | Không ảnh hưởng schema hiện có; migration additive | Chạy migration trên staging, verify bảng + constraint |
| API/Contract | Thêm mới các endpoint `/api/channels/instagram/*` và `/api/webhooks/instagram` | Không thay đổi endpoint hiện có; additive | Smoke test endpoints mới |
| Permission/Security | Endpoints mới kế thừa middleware auth hiện có; token encrypted | Rủi ro nếu token encryption key rotation chưa được xem xét | Permission test: viewer role bị chặn; cross-agent không truy cập được |
| Logging/Audit | Thêm audit record cho kết nối/ngắt kết nối | Không ảnh hưởng audit hiện có | Verify audit records sau kết nối/ngắt kết nối |
| UI/UX | Thêm channel card Instagram trong màn hình Phát hành; popup mới | Rủi ro: gián đoạn layout channel list nếu styling không đồng nhất | Manual test: channel list hiển thị đúng; responsive |
| Job/Worker/Integration | Webhook handler mới; không có job async trong MVP | Rủi ro: webhook endpoint bị Meta verify fail khi deploy | Test Meta webhook verification (`hub.challenge`) ngay khi deploy |

---

## API/Contract Detail

**Có thay đổi contract không**: Có — thêm mới, không thay đổi contract hiện có.

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|----------|------|----------|---------------------|------------------------|
| POST /api/channels/instagram/connect | API | Mới | Có (additive) | Frontend Customer Studio |
| GET /api/channels/instagram/callback | API | Mới | Có (additive) | Meta OAuth redirect |
| POST /api/channels/instagram/pages/confirm | API | Mới | Có (additive) | Frontend Customer Studio |
| GET /api/channels/instagram/connections | API | Mới | Có (additive) | Frontend Customer Studio |
| DELETE /api/channels/instagram/connections/{id} | API | Mới | Có (additive) | Frontend Customer Studio |
| POST /api/webhooks/instagram | Webhook inbound | Mới | Có (additive) | Meta Platform |

Chi tiết contract: xem `contracts/instagram-api.md`.

---

## Permission Matrix

| Vai trò/Scope | Xem danh sách kết nối | Kết nối mới | Ngắt kết nối | Xem trạng thái token | Ghi chú |
|---------------|----------------------|-------------|--------------|---------------------|---------|
| Owner/Admin của agent | Có | Có | Có | Không (token ẩn) | Chủ sở hữu agent |
| Viewer/Member | Không | Không | Không | Không | Chỉ xem giao diện agent; không thấy channel settings |
| System (webhook handler) | Có | Không | Không | Có (internal) | Dùng service account nội bộ |

---

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Có — thêm 2 bảng mới.

**Migration**:
- Tạo bảng `meta_account_connections` (id, agent_id, meta_user_id, meta_user_name, meta_user_avatar_url, encrypted_access_token, token_type, created_at, updated_at).
- Tạo bảng `instagram_page_connections` (id, meta_account_connection_id, agent_id, facebook_page_id, facebook_page_name, facebook_page_avatar_url, instagram_business_account_id, encrypted_page_access_token, status, active_hours_config, last_customer_dm_at, connected_at, disconnected_at, created_at, updated_at).
- UNIQUE constraint: `instagram_page_connections(facebook_page_id)` — enforce BR-005.
- INDEX: `instagram_page_connections(agent_id)`, `instagram_page_connections(facebook_page_id)`.

**Backfill/Cleanup**: Không áp dụng — tính năng hoàn toàn mới, không có dữ liệu cũ.

**Tương thích dữ liệu cũ**: Không áp dụng.

**Rủi ro dữ liệu**: 
- Token bị lộ nếu mã hoá không đúng → giảm thiểu bằng SEC-003 + không log token.
- Duplicate connection nếu UNIQUE constraint thiếu → đã xử lý bằng migration.

**Cách xác minh**: Query `SELECT * FROM instagram_page_connections WHERE agent_id = ?` sau khi kết nối để kiểm tra record được tạo đúng.

---

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| DEC-001: Cấu trúc data model | 2 bảng riêng: MetaAccountConnection + InstagramPageConnection | Phản ánh đúng cấu trúc Meta (1 user quản lý nhiều page); cho phép thêm tài khoản Meta mới mà không duplicate logic; dễ mở rộng sau | Gộp vào 1 bảng duy nhất | Không tách được rõ account vs page; khó query khi cần "pages theo account" |
| DEC-002: UNIQUE constraint cấp page | UNIQUE(facebook_page_id) trên bảng instagram_page_connections | Enforce BR-005 ở tầng DB — không phụ thuộc application-level check | Application-level check only | Race condition nếu 2 request đồng thời; không đảm bảo tính toàn vẹn |
| DEC-003: OAuth state/CSRF | Server-side state (UUID stored in session/cache, expire sau 10 phút) | Ngăn CSRF attack, Meta OAuth standard | Encode state phía client | Có thể bị forge state; không an toàn |
| DEC-004: Webhook endpoint | Tách riêng `/api/webhooks/instagram` (không dùng chung với Facebook) | Dễ phân biệt event source; tránh routing logic phức tạp trong 1 handler | Dùng chung endpoint, dùng `object` field để phân biệt | Phức tạp hơn, khó test độc lập |
| DEC-005: 24h window check | Client-side check trước khi gọi Send API (so sánh `last_customer_dm_at`) | Tránh gọi API không cần thiết; dễ unit test | Chỉ xử lý lỗi từ Meta API khi gửi | Meta không trả lỗi 24h window rõ ràng trong mọi trường hợp; xử lý phía server rõ ràng hơn |

---

## Chiến lược kiểm thử

**Unit test**:
- `InstagramPageService`: logic phân loại Hợp lệ/Không hợp lệ khi có page conflict.
- `InstagramWebhookHandler`: parse DM event, 24h window check, giờ hoạt động check.
- `ChannelTokenEncryptionService`: mã hoá → lưu → giải mã đúng.
- OAuth state management: tạo, validate, expire.

**Integration test**:
- OAuth callback flow với Meta sandbox app (test user + test page).
- Webhook delivery: gửi DM từ test account → verify agent nhận được.
- Page conflict: tạo kết nối page A cho agent 1, thử kết nối page A cho agent 2 → verify bị từ chối.

**Contract test**:
- Verify Meta webhook payload format (Instagram messaging event) đúng với handler expectations.
- Verify Send API call format đúng.

**Permission/security test**:
- Viewer role: gọi POST /api/channels/instagram/connect → 403.
- Cross-agent: agent B không thấy/thay đổi được kết nối của agent A.
- Token không xuất hiện trong response body hoặc log.

**E2E/manual test**:
- Toàn bộ luồng US-001: từ bấm "Kết nối ngay" đến popup thành công + channel active.
- Gửi DM thật từ Instagram cá nhân đến trang Business đã kết nối → agent trả lời.
- Ngắt kết nối → gửi DM → agent không trả lời.

**Regression test**:
- Facebook/Messenger channel không bị ảnh hưởng (kết nối, gửi tin vẫn hoạt động).
- Màn hình Phát hành load đúng khi chưa có kênh Instagram nào.

---

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/000022-instagram-business/
├── plan.md              # File này (output của lệnh /speckit-plan)
├── research.md          # Output Phase 0
├── data-model.md        # Output Phase 1
├── quickstart.md        # Output Phase 1
├── contracts/
│   └── instagram-api.md # Output Phase 1
└── tasks.md             # Output Phase 2 (lệnh /speckit-tasks)
```

### Source code (repository root — tham chiếu, xác nhận với repo con)

```text
# Backend (customer-studio-api hoặc tương đương)
src/
├── Channels/
│   ├── Instagram/
│   │   ├── InstagramChannelController.cs
│   │   ├── InstagramOAuthService.cs
│   │   ├── InstagramPageService.cs
│   │   └── InstagramWebhookHandler.cs
│   └── Shared/
│       └── ChannelTokenEncryptionService.cs  (tái sử dụng nếu đã có)
├── Data/
│   └── Migrations/
│       └── YYYYMMDD_AddInstagramTables.cs

# Frontend (customer-studio-web hoặc tương đương)
src/
├── components/
│   └── publish/
│       ├── InstagramChannelCard.tsx
│       ├── ConnectionResultModal.tsx
│       └── InstagramConnectedState.tsx
├── api/
│   └── instagram-channel.ts
```

**Quyết định cấu trúc**: Đặt Instagram channel vào namespace/module `Channels/Instagram/` riêng biệt, tách khỏi Facebook/Messenger để dễ test và maintain độc lập. Tái sử dụng `ChannelTokenEncryptionService` nếu đã có cho Facebook.

---

## Rollout & Rollback

**Kế hoạch rollout**:
1. Deploy backend: migration (2 bảng mới) → deploy API + webhook handler.
2. Verify Meta webhook verification (`GET /api/webhooks/instagram?hub.challenge=...`) thành công.
3. Deploy frontend: channel card Instagram Business xuất hiện trong màn hình Phát hành.
4. Test smoke với tài khoản test: kết nối → gửi DM → verify trả lời.
5. Go live.

**Tương thích ngược**: Không áp dụng — tính năng hoàn toàn mới, không thay đổi contract hiện có.

**Feature flag/config**: Không bắt buộc cho MVP; có thể dùng feature toggle để bật kênh Instagram theo workspace nếu muốn rollout dần.

**Thực thi migration/backfill khi rollout**: Migration chạy trước deploy (additive, không downtime).

**Rollback code/config**: Revert deploy backend/frontend. Migration không cần rollback vì additive (bảng mới không ảnh hưởng code cũ).

**Rollback dữ liệu/migration**: Nếu cần, DROP TABLE `instagram_page_connections`, `meta_account_connections`. Không ảnh hưởng dữ liệu cũ.

**Điều kiện kích hoạt rollback**: Webhook verification thất bại liên tục; kết nối OAuth không hoàn thành; agent không nhận được DM sau 15 phút test.

---

## Observability & Debug

**Log cần có**:
- `instagram.oauth.initiated` — {agentId, state}
- `instagram.oauth.callback` — {agentId, pageCount, validCount, invalidCount}
- `instagram.page.connected` — {agentId, pageId, pageName, userId}
- `instagram.page.disconnected` — {agentId, pageId, reason: "user_action"|"token_revoked"|"page_unlinked"}
- `instagram.webhook.received` — {pageId, eventType, mid}
- `instagram.webhook.dm_routed` — {pageId, agentId, mid, withinWindow: true/false}
- `instagram.webhook.dm_skipped` — {pageId, reason: "outside_window"|"outside_hours"}
- `instagram.send.success` — {pageId, mid}
- `instagram.send.failed` — {pageId, errorCode, errorMessage}

**Dữ liệu không được log**: access_token, page_access_token, message content (nội dung DM của khách).

**Metric cần theo dõi**:
- `instagram.dm.received` (count/minute theo pageId)
- `instagram.dm.replied` (count/minute theo pageId)
- `instagram.dm.skipped_window` (count)
- `instagram.send.error_rate` (%)

**Trace/Correlation**: Truyền `correlationId` từ webhook event → agent runtime → Send API call.

**Cách kiểm tra sau release**:
- Query log `instagram.page.connected` xem có record sau deploy.
- Gửi DM test → kiểm tra `instagram.webhook.dm_routed` và `instagram.send.success`.
- Kiểm tra DM thật được trả lời trong < 60 giây.

**Tình huống debug chính**:
- DM không được trả lời: kiểm tra `instagram.webhook.dm_skipped` (outside_window/outside_hours) hoặc `instagram.send.failed`.
- Kết nối status = Error: kiểm tra `instagram.page.disconnected` với reason `token_revoked`.
- Popup Không hợp lệ hiển thị sai: kiểm tra conflict check query trong `InstagramPageService`.

---

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật chặn thiết kế/task generation đã được resolve trong research.md.
- [x] Thiết kế tổng quan đã mô tả luồng chính, component/module tham gia, điểm thay đổi và boundary.
- [x] Các tình huống idempotency/concurrency/retry đã được đánh giá (upsert, dedup webhook bằng `mid`).
- [x] Mỗi US/FR P1/P2 hoặc FR ảnh hưởng code/data/API/permission có mapping trong bảng traceability.
- [x] Tác động tới database, API contract, permission, logging/audit và integration đã được đánh giá.
- [x] Contract/API mới đã có consumer và cách kiểm tra.
- [x] Dữ liệu/migration/backfill/compatibility đã rõ.
- [x] Quyết định kỹ thuật chính đã có lý do chọn và phương án bị loại.
- [x] Chiến lược kiểm thử đã bao phủ unit, integration, contract, permission/security, E2E/manual và regression.
- [x] Rollout, rollback, feature flag và backward compatibility đã rõ.
- [x] Observability/debug plan có log field, dữ liệu không được log, metric/trace và cách kiểm tra sau release.
- [x] Cấu trúc source code đã xác định (tham chiếu, xác nhận với repo con khi implement).
- [x] Constitution gate không còn blocker.
