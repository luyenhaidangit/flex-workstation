# Tasks: Phát hành AI Agent trên Instagram Business

**Đầu vào**: Design documents từ `specs/000022-instagram-business/`

**Điều kiện tiên quyết**: plan.md, spec.md, data-model.md, contracts/instagram-api.md, research.md, quickstart.md

---

## Phase 1: Setup

**Mục đích**: Đăng ký channel type mới và module DI cho Instagram channel — dùng chung bởi cả 3 user story.

- [x] T001 [P] Thêm giá trị `InstagramBusiness` vào channel type enum tại `src/Channels/ChannelType.cs`
- [x] T002 Tạo file DI registration `src/Channels/Instagram/DependencyInjection.cs` với skeleton đăng ký `InstagramOAuthService`, `InstagramPageService`, `InstagramWebhookHandler`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Mục đích**: Schema, entity, và encryption service — bắt buộc hoàn tất trước bất kỳ user story nào.

**CRITICAL**: Không bắt đầu user story work cho tới khi phase này hoàn tất.

- [x] T003 [P] Tạo migration `20260729_AddInstagramTables` tại `src/Data/Migrations/20260729_AddInstagramTables.cs` (tạo bảng `meta_account_connections`, `instagram_page_connections`; UNIQUE index trên `facebook_page_id`; indexes trên `agent_id` và `instagram_business_account_id` theo data-model.md)
- [x] T004 [P] Tạo rollback note tại `specs/000022-instagram-business/rollback.md` (hướng dẫn `DROP TABLE instagram_page_connections; DROP TABLE meta_account_connections;` nếu cần rollback migration T003)
- [x] T005 [P] Tạo entity class `MetaAccountConnection` tại `src/Channels/Instagram/MetaAccountConnection.cs` (columns: id, agent_id, meta_user_id, meta_user_name, meta_user_avatar_url, encrypted_access_token, token_type, created_at, updated_at theo data-model.md)
- [x] T006 [P] Tạo entity class `InstagramPageConnection` tại `src/Channels/Instagram/InstagramPageConnection.cs` (columns: id, meta_account_connection_id, agent_id, facebook_page_id, facebook_page_name, facebook_page_avatar_url, instagram_business_account_id, instagram_account_type, encrypted_page_access_token, status, active_hours_config, last_customer_dm_at, connected_at, disconnected_at, created_at, updated_at; enum status "active"/"disconnected"/"error")
- [x] T007 [P] Tạo hoặc extend `ChannelTokenEncryptionService` tại `src/Channels/Shared/ChannelTokenEncryptionService.cs` với phương thức `EncryptToken(string plainToken): string` và `DecryptToken(string encryptedToken): string` dùng AES (SEC-003) — tái sử dụng nếu đã có cho Facebook channel

**Checkpoint**: Foundational đã sẵn sàng. User story implementation có thể bắt đầu.

---

## Phase 3: User Story 1 — Kết nối Instagram Business và phát hành agent (Priority: P1) MVP

**Goal**: Người dùng có thể hoàn thành luồng OAuth 3 bước, xem popup kết quả 2 tab, chọn pages hợp lệ và nhìn thấy connected-state UI trong Customer Studio.

**Independent Test**:

1. Đăng nhập Customer Studio với tài khoản owner của agent → Tab "Phát hành" → channel card "Instagram Business" hiển thị với 3 bước hướng dẫn và nút "Kết nối ngay".
2. Bấm "Kết nối ngay" → đăng nhập Facebook với tài khoản test → cấp quyền → popup "Kết quả kết nối" xuất hiện với tab "Hợp lệ" chứa pages có Instagram Business Account.
3. Chọn 1 page → "Xác nhận" → connected-state UI xuất hiện với page đã chọn nhóm theo tài khoản Meta, label "Đã phát hành" màu xanh.
4. Kiểm tra DB: `SELECT status FROM instagram_page_connections WHERE agent_id = '{agent-uuid}'` → có row với `status = 'active'`.

### Tests for User Story 1

> **NOTE**: Viết test trước, đảm bảo test fail trước implementation.

- [ ] T008 [P] [US1] Tạo unit test `tests/Channels/Instagram/InstagramPageServiceTests.cs` với test case `ClassifyPages_PageConnectedByOtherAgent_MarksAsInvalid()` và `ClassifyPages_PageNotConnected_MarksAsValid()` (phải fail trước khi implement T013)
- [ ] T009 [P] [US1] Tạo unit test `tests/Channels/Instagram/InstagramOAuthServiceTests.cs` với test case `ValidateState_ExpiredState_ReturnsFalse()` và `ValidateState_ValidUnusedState_ReturnsTrue()` (phải fail trước khi implement T011)
- [ ] T010 [P] [US1] Tạo unit test `tests/Channels/Shared/ChannelTokenEncryptionServiceTests.cs` với test case `EncryptDecrypt_RoundTrip_ReturnsOriginalToken()` và `Decrypt_TamperedCiphertext_ThrowsException()` (phải fail trước khi implement T007)

### Implementation for User Story 1

- [x] T011 [P] [US1] Tạo `InstagramOAuthService` với phương thức `CreateOAuthUrl(agentId, state): string` (tạo Meta OAuth URL với scope `pages_manage_metadata,pages_messaging,instagram_manage_messages,instagram_basic`) và `ValidateState(state, agentId): bool` (check server-side session/cache, expire 10 phút) tại `src/Channels/Instagram/InstagramOAuthService.cs`
- [x] T012 [P] [US1] Tạo DTOs: `ConnectRequest`, `ConnectResponse`, `ConnectionResultResponse` (valid[], invalid[], metaAccountInfo), `ConfirmPagesRequest`, `ConfirmPagesResponse` (connected[], metaAccountConnectionId, metaUserName, metaUserAvatarUrl) tại `src/Channels/Instagram/Dtos/`
- [x] T013 [P] [US1] Implement `InstagramPageService.ClassifyPages(longLivedUserToken, agentId)` — gọi Graph API `GET /me/accounts`, với mỗi page gọi `GET /{page-id}?fields=instagram_business_account`, lấy account_type; query DB `instagram_page_connections` để phân loại Hợp lệ (chưa ai giữ hoặc agent này đang giữ) / Không hợp lệ (agent khác giữ) tại `src/Channels/Instagram/InstagramPageService.cs` (phụ thuộc T005, T006)
- [x] T014 [US1] Implement `InstagramOAuthService.ExchangeCodeForTokens(code): (shortLivedToken, longLivedToken)` — 2-bước exchange: `code → short-lived user token`, `short-lived → long-lived user token (60 ngày)` theo flow §3 trong research.md tại `src/Channels/Instagram/InstagramOAuthService.cs` (phụ thuộc T011 — same file)
- [x] T015 [US1] Implement endpoint `POST /api/channels/instagram/connect` (validate agentId, tạo CSRF state, gọi `CreateOAuthUrl`, trả về `{oauthUrl, state}`) tại `src/Channels/Instagram/InstagramChannelController.cs` (phụ thuộc T011, T012)
- [x] T016 [US1] Implement endpoint `GET /api/channels/instagram/callback` (validate state, gọi `ExchangeCodeForTokens`, gọi `ClassifyPages`, lưu kết quả vào cache với TTL 10 phút và sessionKey, redirect frontend về `?sessionKey={key}`) tại `src/Channels/Instagram/InstagramChannelController.cs` (phụ thuộc T013, T014, T015 — same file)
- [x] T017 [US1] Implement endpoint `GET /api/channels/instagram/connect/result` (đọc kết quả từ cache theo sessionKey, trả về `ConnectionResultResponse`) tại `src/Channels/Instagram/InstagramChannelController.cs` (phụ thuộc T016 — same file)
- [x] T018 [US1] Implement `InstagramPageService.ConfirmPages(agentId, sessionKey, selectedPageIds[])` — upsert `MetaAccountConnection` (UNIQUE meta_user_id+agent_id), upsert `InstagramPageConnection` cho từng page được chọn, mã hoá page access token bằng T007, gọi `POST /{instagram-business-account-id}/subscribed_apps` để subscribe webhook tại `src/Channels/Instagram/InstagramPageService.cs` (phụ thuộc T013 — same file; T007 — encryption)
- [x] T019 [US1] Implement endpoint `POST /api/channels/instagram/pages/confirm` (validate selectedPageIds không rỗng, validate sessionKey còn hạn, gọi `ConfirmPages`, trả về `ConfirmPagesResponse`; 409 nếu race condition page vừa bị agent khác giữ) tại `src/Channels/Instagram/InstagramChannelController.cs` (phụ thuộc T018, T017 — same file)
- [x] T020 [US1] Implement endpoint `GET /api/channels/instagram/connections` (query `instagram_page_connections` grouped theo `meta_account_connection_id`, trả về `{isPublished, accounts[], activeHoursConfig}`) tại `src/Channels/Instagram/InstagramChannelController.cs` (phụ thuộc T019 — same file)
- [x] T021 [US1] Thêm permission attribute `[RequireAgentRole(Owner, Admin)]` (hoặc middleware tương đương) cho các action `Connect`, `Callback`, `ConfirmPages`, `ListConnections` trong `src/Channels/Instagram/InstagramChannelController.cs` (phụ thuộc T015, T019, T020 — same file)
- [x] T022 [US1] Thêm audit log `instagram.page.connected {agentId, pageId, pageName, userId}` sau khi `ConfirmPages` tạo kết nối thành công trong `src/Channels/Instagram/InstagramPageService.cs` (phụ thuộc T018 — same file)
- [ ] T023 [P] [US1] Tạo frontend component `InstagramChannelCard.tsx` (hiển thị 3-step instructions tùy chỉnh được, nút "Kết nối ngay" trigger `initiateConnect()` + redirect sang Meta OAuth URL) tại `src/components/publish/InstagramChannelCard.tsx`
- [ ] T024 [P] [US1] Tạo frontend component `ConnectionResultModal.tsx` (2 tabs "Hợp lệ"/"Không hợp lệ"; tab Hợp lệ: list pages với checkbox, nút "Xác nhận"; tab Không hợp lệ: list pages với tên agent đang giữ) tại `src/components/publish/ConnectionResultModal.tsx`
- [ ] T025 [P] [US1] Tạo frontend API service với functions `initiateConnect(agentId)`, `getConnectionResult(sessionKey)`, `confirmPages(agentId, sessionKey, selectedPageIds)`, `listConnections(agentId)` tại `src/api/instagram-channel.ts`
- [ ] T026 [US1] Wire `InstagramChannelCard` và `ConnectionResultModal` vào màn hình Phát hành: thêm Instagram card vào channel list, bắt sessionKey từ OAuth redirect URL, mở `ConnectionResultModal` với kết quả, gọi `confirmPages` khi user "Xác nhận", refresh connections sau confirm tại `src/components/publish/PublishScreen.tsx` (hoặc file tương đương) (phụ thuộc T023, T024, T025)

**Definition of Done**:

- Implementation tasks T011–T026 hoàn tất.
- Independent Test chạy pass (OAuth end-to-end, popup 2 tab, confirm, connected-state).
- Unit test T008, T009, T010 pass sau implementation.
- Permission check (viewer → 403) được verify.
- Log `instagram.page.connected` xuất hiện sau kết nối.
- Không làm hỏng channel Messenger/Facebook hiện có.

**Checkpoint**: User Story 1 hoàn chỉnh và có thể test/validate độc lập.

---

## Phase 4: User Story 2 — AI Agent tự động trả lời DM (Priority: P1) MVP

**Goal**: Sau khi kết nối thành công, webhook nhận DM từ Meta, kiểm tra cửa sổ 24h và giờ hoạt động, route đến AI Agent và gửi phản hồi trong vòng 60 giây.

**Independent Test**:

1. `curl "https://{domain}/api/webhooks/instagram?hub.mode=subscribe&hub.verify_token={token}&hub.challenge=123456"` → HTTP 200, body = `"123456"`.
2. Dùng tài khoản Instagram cá nhân gửi DM đến trang Business đã kết nối.
3. Chờ ≤ 60 giây → agent trả lời trong inbox Instagram cá nhân.
4. Kiểm tra log: `instagram.webhook.dm_routed {withinWindow: true}` và `instagram.send.success`.
5. Kiểm tra DB: `SELECT last_customer_dm_at FROM instagram_page_connections WHERE facebook_page_id = '{page-id}'` → `last_customer_dm_at` được cập nhật.

### Tests for User Story 2

> **NOTE**: Viết test trước, đảm bảo test fail trước implementation.

- [ ] T027 [P] [US2] Tạo unit test `tests/Channels/Instagram/InstagramWebhookHandlerTests.cs` với test case `HandleDmEvent_WithinWindow_RoutesToAgent()`, `HandleDmEvent_OutsideWindow_SkipsSilently()`, `HandleDmEvent_InvalidSignature_Returns403()`, `HandleDmEvent_DuplicateMid_DeduplicatesEvent()` (phải fail trước khi implement T031–T034)
- [ ] T028 [P] [US2] Tạo contract test `tests/Channels/Instagram/InstagramWebhookContractTests.cs` verify: (a) payload format `{object:"instagram", entry[].messaging[].message}` đúng với handler expectations; (b) Send API request format `POST /{ig-account-id}/messages {recipient.id, message.text}` đúng theo research.md §5

### Implementation for User Story 2

- [x] T029 [P] [US2] Tạo `InstagramWebhookController.cs` với action `GET /api/webhooks/instagram` (webhook verification: validate `hub.verify_token` khớp config, trả về `hub.challenge` dưới dạng plain text 200) tại `src/Channels/Instagram/InstagramWebhookController.cs`
- [x] T030 [US2] Thêm action `POST /api/webhooks/instagram` (parse body, validate `X-Hub-Signature-256` HMAC-SHA256, gọi `_webhookHandler.HandleDmEvent(payload)` bất đồng bộ, trả về `200 OK` ngay lập tức; bỏ qua nếu `object != "instagram"`) tại `src/Channels/Instagram/InstagramWebhookController.cs` (phụ thuộc T029 — same file)
- [x] T031 [P] [US2] Implement `InstagramWebhookHandler.HandleDmEvent(payload)` — parse `entry[].messaging[]`, lookup `InstagramPageConnection` theo `instagram_business_account_id`, cập nhật `last_customer_dm_at = now()`, kiểm tra 24h window (`last_customer_dm_at > now() - 24h`), kiểm tra `active_hours_config` tại `src/Channels/Instagram/InstagramWebhookHandler.cs` (phụ thuộc T006)
- [x] T032 [US2] Thêm phương thức dedup `IsDuplicateMessage(mid): bool` trong `InstagramWebhookHandler` (kiểm tra mid đã xử lý bằng in-memory cache hoặc DB, bỏ qua nếu trùng) tại `src/Channels/Instagram/InstagramWebhookHandler.cs` (phụ thuộc T031 — same file)
- [x] T033 [US2] Implement `InstagramWebhookHandler.RouteToAgent(pageConnection, senderId, messageText)` — gọi AI Agent runtime với context `{channel: "instagram", pageId, instagramAccountId, senderId, message}`, nhận reply text tại `src/Channels/Instagram/InstagramWebhookHandler.cs` (phụ thuộc T032 — same file)
- [x] T034 [US2] Implement `InstagramWebhookHandler.SendReply(instagramAccountId, recipientId, replyText, encryptedPageToken)` — giải mã page access token bằng T007, gọi `POST https://graph.facebook.com/v21.0/{ig-account-id}/messages {recipient.id, message.text}` theo research.md §5 tại `src/Channels/Instagram/InstagramWebhookHandler.cs` (phụ thuộc T033, T007 — same file)
- [x] T035 [US2] Thêm structured log ở mỗi điểm quyết định trong `InstagramWebhookHandler`: `instagram.webhook.received {pageId, eventType, mid}`, `instagram.webhook.dm_routed {pageId, agentId, mid, withinWindow}`, `instagram.webhook.dm_skipped {pageId, reason:"outside_window"|"outside_hours"}`, `instagram.send.success {pageId, mid}`, `instagram.send.failed {pageId, errorCode, errorMessage}` tại `src/Channels/Instagram/InstagramWebhookHandler.cs` (phụ thuộc T033 — same file; không log access_token hay nội dung DM của khách)

**Definition of Done**:

- Implementation tasks T029–T035 hoàn tất.
- Independent Test chạy pass (webhook verify + DM end-to-end ≤ 60s).
- Unit test T027 pass; contract test T028 pass.
- DM ngoài cửa sổ 24h: agent KHÔNG trả lời, log `dm_skipped {reason:"outside_window"}` xuất hiện.
- Không làm hỏng webhook Facebook/Messenger hiện có.

**Checkpoint**: User Story 2 hoàn chỉnh và có thể test/validate độc lập.

---

## Phase 5: User Story 3 — Quản lý trạng thái kết nối (Priority: P2)

**Goal**: Người dùng có thể ngắt kết nối trang, thêm trang trong cùng tài khoản, thêm tài khoản Meta mới; hệ thống tự phát hiện token bị thu hồi và cập nhật trạng thái Error.

**Independent Test**:

1. Trong connected-state UI, bấm "Ngắt kết nối" cho 1 page → page biến mất (hoặc trạng thái "Chưa kết nối").
2. Gửi DM từ Instagram cá nhân → chờ 60 giây → agent KHÔNG trả lời.
3. Kiểm tra DB: `SELECT status, disconnected_at FROM instagram_page_connections WHERE id = '{connection-id}'` → `status = 'disconnected'`, `disconnected_at IS NOT NULL`.

### Tests for User Story 3

> **NOTE**: Viết test trước, đảm bảo test fail trước implementation.

- [ ] T036 [P] [US3] Tạo unit test `tests/Channels/Instagram/InstagramPageServiceDisconnectTests.cs` với test case `DisconnectPage_ActivePage_SetsStatusDisconnected()` và `DisconnectPage_AlreadyDisconnected_NoOps()` (phải fail trước khi implement T037)

### Implementation for User Story 3

- [x] T037 [US3] Implement `InstagramPageService.DisconnectPage(connectionId, agentId)` — validate connectionId thuộc agentId, gọi `DELETE /{instagram-business-account-id}/subscribed_apps` để unsubscribe webhook, set `status = "disconnected"`, `disconnected_at = now()` tại `src/Channels/Instagram/InstagramPageService.cs` (phụ thuộc T006)
- [x] T038 [US3] Implement endpoint `DELETE /api/channels/instagram/connections/{connectionId}` với permission attribute `[RequireAgentRole(Owner, Admin)]`, gọi `DisconnectPage`, trả về 204; 404 nếu connectionId không tồn tại hoặc không thuộc agent này tại `src/Channels/Instagram/InstagramChannelController.cs` (phụ thuộc T037)
- [x] T039 [US3] Thêm audit log `instagram.page.disconnected {agentId, pageId, reason:"user_action"}` sau khi `DisconnectPage` thành công trong `src/Channels/Instagram/InstagramPageService.cs` (phụ thuộc T037 — same file)
- [x] T040 [US3] Implement xử lý webhook event `deauthorize` / `instagram_api_deauthorize` trong `InstagramWebhookHandler`: lookup `InstagramPageConnection` theo `meta_user_id`, set `status = "error"`, ghi audit log `instagram.page.disconnected {reason:"token_revoked"}` tại `src/Channels/Instagram/InstagramWebhookHandler.cs` (phụ thuộc T031 — same file)
- [ ] T041 [P] [US3] Tạo frontend component `InstagramConnectedState.tsx` (danh sách kết nối grouped theo tài khoản Meta: tên user + avatar, danh sách pages mỗi account với nút "Ngắt kết nối"; nút "+Thêm trang" gọi lại `confirmPages` flow; nút "+Thêm tài khoản" khởi động lại OAuth flow; toggle giờ hoạt động) tại `src/components/publish/InstagramConnectedState.tsx`
- [ ] T042 [US3] Wire `InstagramConnectedState` vào màn hình Phát hành: chuyển từ `InstagramChannelCard` sang `InstagramConnectedState` sau khi confirm thành công; handle disconnect action gọi API delete và refresh state; handle "+Thêm tài khoản" restart OAuth tại `src/components/publish/PublishScreen.tsx` (phụ thuộc T041, T025)

**Definition of Done**:

- Implementation tasks T037–T042 hoàn tất.
- Independent Test chạy pass (disconnect → DM không được trả lời).
- Unit test T036 pass.
- Audit log `instagram.page.disconnected` xuất hiện sau ngắt kết nối.
- Webhook deauthorize → status Error được verify (manual: thu hồi quyền app trong Facebook Settings).
- Không làm hỏng US-001 và US-002 đã hoàn thành.

**Checkpoint**: Tất cả user stories hoàn chỉnh và hoạt động độc lập.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Mục đích**: Kiểm tra permission, security, regression và smoke validation sau khi tất cả stories đã xong.

- [ ] T043 [P] Tạo permission integration test `tests/Channels/Instagram/InstagramPermissionTests.cs` verify: (a) viewer role gọi `POST /api/channels/instagram/connect` → 403; (b) owner Agent A gọi `GET /api/channels/instagram/connections?agentId={Agent-B-uuid}` → 403 hoặc empty result (không thấy connections của agent khác) (SEC-001, SEC-002)
- [ ] T044 [P] Tạo security test `tests/Channels/Instagram/InstagramSecurityTests.cs` verify: (a) response body của `GET /connections` không chứa `encrypted_access_token` hay `encrypted_page_access_token`; (b) structured log không chứa giá trị token trong bất kỳ event nào của `InstagramWebhookHandler` (SEC-003)
- [ ] T045 Tạo regression test `tests/Channels/Facebook/MessengerRegressionTests.cs` verify: (a) kết nối Messenger vẫn hoạt động sau khi thêm Instagram webhook endpoint; (b) màn hình Phát hành load đúng khi chưa có kết nối Instagram nào (không crash, không ảnh hưởng channel list hiện có)
- [ ] T046 Chạy validation quickstart theo `specs/000022-instagram-business/quickstart.md` — 8 test scenarios và smoke check table (webhook verify, connect flow, invalid account, conflict check, DM reply, 24h window, disconnect, permission); ghi lại kết quả pass/fail

---

## Validation Commands

- Build backend: `dotnet build src/` (xác nhận với repo con — lệnh thực tế theo project setup)
- Run unit tests: `dotnet test tests/ --filter Category=Unit`
- Run integration tests: `dotnet test tests/ --filter Category=Integration`
- Run permission tests: `dotnet test tests/ --filter FullyQualifiedName~InstagramPermissionTests`
- Run migration: `dotnet ef database update` (hoặc lệnh migration theo project setup)
- Verify migration: `SELECT table_name FROM information_schema.tables WHERE table_name IN ('meta_account_connections','instagram_page_connections')` → 2 rows
- Verify webhook: `curl "https://{domain}/api/webhooks/instagram?hub.mode=subscribe&hub.verify_token={token}&hub.challenge=123456"` → `123456`
- Run frontend checks: `npm run build` / `npm run typecheck` (xác nhận với repo con)
- Run quickstart smoke check: theo `specs/000022-instagram-business/quickstart.md`

---

## Traceability Matrix

| Source | Covered by tasks |
|--------|------------------|
| US-001 | T008, T009, T010, T011, T012, T013, T014, T015, T016, T017, T018, T019, T020, T021, T022, T023, T024, T025, T026 |
| US-002 | T027, T028, T029, T030, T031, T032, T033, T034, T035 |
| US-003 | T036, T037, T038, T039, T040, T041, T042 |
| FR-001 (Channel card IG Business) | T023, T026 |
| FR-002 (OAuth connect flow) | T011, T014, T015, T016 |
| FR-003 (Popup 2 tab Hợp lệ/Không hợp lệ) | T013, T017, T024 |
| FR-004 (Từ chối tài khoản cá nhân) | T013, T008 |
| FR-005 (Webhook nhận DM) | T029, T030, T031 |
| FR-006 (24h window + giờ hoạt động) | T031, T027 |
| FR-007 (Ngắt kết nối) | T037, T038, T039, T036 |
| FR-008a (+Thêm trang) | T041, T042 |
| FR-008b (+Thêm tài khoản) | T041, T042 |
| FR-009 (Token revocation → status Error) | T040 |
| FR-010 / BR-005 (1 page = 1 agent UNIQUE constraint) | T003, T013, T018, T008 |
| BR-006 (24h messaging window) | T031, T027 |
| SEC-001 (Permission Owner/Admin) | T021, T038, T043 |
| SEC-002 (Cross-agent isolation) | T021, T043 |
| SEC-003 (Token mã hoá AES) | T007, T010, T018, T034, T044 |
| NFR-001 (Connect flow < 30s) | T046 (manual verify) |
| AC-005 (DM reply ≤ 60s) | T035, T046 |
| DEC-002 (UNIQUE constraint page-level) | T003, T006 |
| DEC-003 (CSRF state server-side) | T011, T009 |
| DEC-004 (Separate webhook endpoint) | T029, T030 |
| DEC-005 (24h window client-side check) | T031, T027 |

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Không có dependency, bắt đầu ngay.
- **Foundational (Phase 2)**: Phụ thuộc Setup completion, CHẶN mọi user story.
- **US-001 (Phase 3)** và **US-002 (Phase 4)**: Đều phụ thuộc Foundational. Có thể chạy song song nếu đủ người (US-001 không conflict file với US-002).
- **US-003 (Phase 5)**: Phụ thuộc US-001 (PublishScreen.tsx, InstagramConnectedState) và US-002 (InstagramWebhookHandler cho T040). Chạy sau US-001 và US-002.
- **Polish (Final Phase)**: Phụ thuộc tất cả user stories đã hoàn tất.

### User Story Dependencies

- **US-001 (P1)**: Bắt đầu sau Foundational; T014 phụ thuộc T011; T016 phụ thuộc T013, T014, T015; T018 phụ thuộc T013, T007; T019 phụ thuộc T017, T018; T020, T021 phụ thuộc T019; T022 phụ thuộc T018; T026 phụ thuộc T023, T024, T025.
- **US-002 (P1)**: Bắt đầu sau Foundational; T030 phụ thuộc T029; T032 phụ thuộc T031; T033 phụ thuộc T032, T007; T034 phụ thuộc T031; T035 phụ thuộc T032.
- **US-003 (P2)**: T037 phụ thuộc T006; T038 phụ thuộc T037; T039 phụ thuộc T037; T040 phụ thuộc T031; T042 phụ thuộc T041, T025.

### Parallel Opportunities

```
# Foundational phase — tất cả chạy song song:
T003 [P] Migration file
T004 [P] rollback.md
T005 [P] MetaAccountConnection.cs
T006 [P] InstagramPageConnection.cs
T007 [P] ChannelTokenEncryptionService.cs

# Đầu Phase 3 US-001 — tests + first implementations chạy song song:
T008 [P] InstagramPageServiceTests.cs
T009 [P] InstagramOAuthServiceTests.cs
T010 [P] ChannelTokenEncryptionServiceTests.cs
T011 [P] InstagramOAuthService.cs (phương thức CreateOAuthUrl, ValidateState)
T012 [P] Dtos/ files
T013 [P] InstagramPageService.cs (ClassifyPages)

# Sau khi Foundational xong và nếu đủ 2 developer — US-001 và US-002 song song:
Developer A: T008 → T011 → T013 → T014 → T015 → T016 → T017 → T018 → T019 → T020 → T021 → T022 → T023/T024/T025 [P] → T026
Developer B: T027 → T028 → T029/T031 [P] → T030 → T032 → T033 → T034 → T035

# Frontend US-001 — 3 components chạy song song:
T023 [P] InstagramChannelCard.tsx
T024 [P] ConnectionResultModal.tsx
T025 [P] instagram-channel.ts

# Final Phase — 2 test files chạy song song:
T043 [P] InstagramPermissionTests.cs
T044 [P] InstagramSecurityTests.cs
```

---

## Implementation Strategy

### MVP First (chỉ US-001 và US-002)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational (CRITICAL).
3. Complete Phase 3: US-001 (connect + OAuth + popup + confirm).
4. Complete Phase 4: US-002 (webhook + DM reply).
5. **STOP and VALIDATE**: Chạy quickstart kiểm tra 1-2-5-6 (webhook, connect, DM reply, 24h window).
6. Demo: người bán kết nối Instagram → gửi DM → agent trả lời.

### Incremental Delivery

1. Setup + Foundational → Foundation ready.
2. US-001 → Connected-state UI có thể demo → **checkpoint: kết nối thành công**.
3. US-002 → DM reply hoạt động → **checkpoint: AI trả lời DM**.
4. US-003 → Disconnect + status management → **checkpoint: quản lý kết nối hoàn chỉnh**.
5. Polish → Permission + security + regression + quickstart validation → **ready for production**.

### Parallel Team Strategy

Với 2 developer sau khi Foundational xong:

- Developer A: US-001 (connect flow + frontend).
- Developer B: US-002 (webhook handler + DM processing).
- Cả hai đều share T007 (ChannelTokenEncryptionService) nhưng không conflict file (A dùng trong T018 để encrypt khi lưu; B dùng trong T034 để decrypt khi gửi).
- US-001 và US-002 không conflict file (khác controller, khác handler, khác frontend component).
- US-003 bắt đầu khi US-001 và US-002 đã xong (cần `InstagramPageService.cs`, `InstagramWebhookHandler.cs`, `PublishScreen.tsx` ổn định).

---

## Checklist chất lượng trước khi implement

- [ ] Không còn placeholder `[Entity]`, `[endpoint]`, `[file]`, `TXXX` hoặc phase ví dụ trong file này.
- [ ] Toàn bộ task đánh số tuần tự từ T001 đến T046.
- [ ] Mỗi task có path cụ thể hoặc command cụ thể.
- [ ] Task sửa file có sẵn đã nêu rõ phương thức, action, section cần sửa (T014, T016–T022, T030–T035, T037–T040, T042).
- [ ] Task phụ thuộc task khác đã ghi rõ dependency task ID.
- [ ] Mỗi user story có Independent Test cụ thể với DB check / log check.
- [ ] Test task T008–T010, T027–T028, T036 map rõ với business rule / risk cụ thể.
- [ ] Mỗi user story có Definition of Done cụ thể.
- [ ] Mọi FR P1/P2 ảnh hưởng code/data/API có task tương ứng (FR-001 → T023; FR-002 → T011,T014,T015; FR-003 → T013,T017,T024; FR-004 → T013; FR-005 → T029,T030,T031; FR-006 → T031; FR-007 → T037,T038; FR-008a/b → T041; FR-009 → T040; FR-010 → T003,T013,T018).
- [ ] BR-005 (1 page = 1 agent) có cả DB constraint (T003) và application check (T013, T008).
- [ ] BR-006 (24h window) có implementation (T031) và unit test (T027).
- [ ] SEC-003 (token mã hoá) có implementation (T007, T018, T034) và test (T010, T044).
- [ ] Migration (T003), rollback (T004), permission (T021, T038, T043), observability (T035), security review (T044) đều có task.
- [ ] Task [P] không sửa cùng file và không phụ thuộc nhau.
- [ ] US-001 và US-002 có thể chạy song song (xác nhận: không conflict file).

---

## Phase 6: Convergence

Tasks bổ sung từ `speckit-converge` — lấp gap giữa code hiện tại và spec/plan.

- [x] T047 CRITICAL Fix 24h window bug trong `flex-agent-service/Channels/Instagram/InstagramWebhookHandler.cs`: lưu giá trị gốc của `LastCustomerDmAt` trước khi gán `connection.LastCustomerDmAt = now`, sau đó check `withinWindow` dựa trên giá trị gốc thay vì giá trị vừa gán — hiện tại check luôn true vì so sánh `now - now` per BR-006 (contradicts)
- [x] T048 [P] Fix deauthorize webhook handling trong `flex-agent-service/Channels/Instagram/InstagramWebhookController.cs`: thay thế TODO stub bằng parse deauthorize payload để extract `user_id` (field `signed_request` hoặc `user_id` tùy Meta format), sau đó gọi `await webhookHandler.HandleDeauthorizeAsync(metaUserId)` per FR-009 (partial)
- [x] T049 [P] Implement real permission check trong `flex-agent-service/Channels/Instagram/InstagramChannelController.cs`: thay `CanManageChannel` stub (`return true`) bằng JWT claim validation — extract agentId từ JWT scope/claim và verify caller có role owner/admin cho agentId được request per SEC-001 (partial)
- [x] T050 [P] Thêm metric emission vào `flex-agent-service/Channels/Instagram/InstagramWebhookHandler.cs`: emit counters `instagram.dm.received`, `instagram.dm.replied`, `instagram.dm.skipped_window` tại các điểm xử lý DM; thêm `instagram.send.error_rate` tại `SendReplyAsync` — sử dụng `IMetrics` hoặc `System.Diagnostics.Metrics.Counter<long>` per plan:Observability (missing)
- [x] T051 [P] Implement `GetAgentNameAsync` trong `flex-agent-service/Channels/Instagram/InstagramPageService.cs`: thay stub `$"Agent {agentId:N}"` bằng real query (inject IAgentRepository hoặc call AgentService) để lấy tên agent thật cho hiển thị trong tab "Không hợp lệ" của popup kết nối per FR-010 (partial)
- [x] T052 [P] Thêm correlationId propagation trong `flex-agent-service/Channels/Instagram/InstagramWebhookHandler.cs`: thêm field `CorrelationId` vào `AgentMessage` record, sinh `Guid.NewGuid()` tại `HandleMessagingEventAsync`, truyền qua `ProcessMessageAsync` và include trong `X-Correlation-ID` header của `SendReplyAsync` per plan:Observability (missing)
