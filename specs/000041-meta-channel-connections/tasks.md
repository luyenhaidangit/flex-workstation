# Tasks: Kết nối kênh Instagram và Facebook qua Meta

**Đầu vào**: Design documents từ `specs/000041-meta-channel-connections/`

**Điều kiện tiên quyết**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/http-api.md`, `quickstart.md`

**Nguyên tắc thực thi**: Test tự động phải được viết trước implementation trong mỗi phase. Không commit secret, không chạy `liquibase update` trên database thật nếu chưa xác nhận target và authorization vận hành.

## Phase 1: Setup

**Mục đích**: Xác nhận baseline và chuẩn bị cấu hình mẫu cho ba repository bị ảnh hưởng.

- [ ] T001 Chạy baseline backend bằng `dotnet build Flex.Agent.sln` tại `flex-agent-service/` và ghi nhận kết quả trước thay đổi.
- [ ] T002 Chạy baseline backend bằng `dotnet test Flex.Agent.sln` tại `flex-agent-service/` và ghi nhận nhóm test Instagram/Facebook hiện hữu.
- [ ] T003 [P] Chạy baseline frontend bằng `ng test --watch=false` và `ng build` tại `flex-microfrontend/`.
- [ ] T004 [P] Bổ sung các key cấu hình mẫu `Meta:ApiVersion`, `Meta:GraphApiBaseUrl`, `Meta:OAuthBaseUrl`, `Meta:FrontendCallbackBaseUrl`, scopes và `Channels:FacebookEnabled` trong `flex-agent-service/src/Flex.Agent.Api/appsettings.Example.json` mà không thêm giá trị secret thật.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Mục đích**: Hoàn tất boundary Meta, session, authorization, schema additive và UI connection shell trước mọi user story.

**CRITICAL**: Không bắt đầu implementation user story trước khi phase này hoàn tất.

### Tests trước implementation

- [ ] T005 [P] Tạo unit test cho URL/expiry/error contract của `MetaOAuthService` trong `flex-agent-service/tests/Flex.Agent.Tests/Integrations/Meta/MetaOAuthServiceTests.cs`.
- [ ] T006 [P] Tạo unit test cho mapping managed Pages/linked Instagram/error/timeout của `MetaGraphService` trong `flex-agent-service/tests/Flex.Agent.Tests/Integrations/Meta/MetaGraphServiceTests.cs`.
- [ ] T007 [P] Tạo unit test cho TTL 10 phút, agent/channel/method binding, single-use và state transition của session trong `flex-agent-service/tests/Flex.Agent.Tests/Integrations/Meta/IntegrationSessionStoreTests.cs`.
- [ ] T008 [P] Tạo permission test cho owner/admin/configurator, viewer/member và cross-agent access trong `flex-agent-service/tests/Flex.Agent.Tests/Integrations/Meta/AgentChannelAuthorizationTests.cs`.
- [ ] T009 [P] Tạo Angular service test cho URL, query params, response mapping và việc không lưu credential trong `flex-microfrontend/src/app/features/agent-catalog/services/agent-channel-connection.service.spec.ts`.
- [ ] T010 [P] Tạo Angular component test cho candidate selection, invalid candidate và error/retry state trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-channel-connection-result-modal/agent-channel-connection-result-modal.component.spec.ts`.

### Shared implementation

- [ ] T011 Tạo `MetaOptions` dùng `IOptions` cho API version, base URLs, redirect URI, scopes và callback URL trong `flex-agent-service/src/Flex.Agent.Infrastructures/Integrations/Meta/MetaOptions.cs`.
- [ ] T012 Tạo port `IMetaOAuthService` với authorization URL và code exchange trong `flex-agent-service/src/Flex.Agent.Application/Abstractions/Integrations/Meta/IMetaOAuthService.cs`.
- [ ] T013 Tạo port `IMetaGraphService` với managed Pages và linked Instagram provider-neutral models trong `flex-agent-service/src/Flex.Agent.Application/Abstractions/Integrations/Meta/IMetaGraphService.cs`.
- [ ] T014 Tạo port `IIntegrationSessionStore` cho create/get/transition/consume session trong `flex-agent-service/src/Flex.Agent.Application/Abstractions/Integrations/Meta/IIntegrationSessionStore.cs`.
- [ ] T015 Tạo provider-neutral records cho Meta user, Page, Instagram account và discovery candidate trong `flex-agent-service/src/Flex.Agent.Application/Abstractions/Integrations/Meta/Models/MetaModels.cs`.
- [ ] T016 Implement `MetaOAuthService` bằng `HttpClientFactory`, `QueryHelpers`, `MetaOptions` và cancellation token trong `flex-agent-service/src/Flex.Agent.Infrastructures/Integrations/Meta/MetaOAuthService.cs`.
- [ ] T017 Implement `MetaGraphService` với provider JSON models nội bộ, pagination/error mapping và không trả access token qua Application contract trong `flex-agent-service/src/Flex.Agent.Infrastructures/Integrations/Meta/MetaGraphService.cs`.
- [ ] T018 Implement `IntegrationSessionStore` trên `IMemoryCache`, TTL 10 phút, single-use state và encrypted temporary credential trong `flex-agent-service/src/Flex.Agent.Infrastructures/Integrations/Meta/IntegrationSessionStore.cs`.
- [ ] T019 Tạo shared agent-scope authorization helper/policy để kiểm tra principal trước mọi command/query trong `flex-agent-service/src/Flex.Agent.Application/Common/Authorization/AgentChannelAuthorization.cs`.
- [ ] T020 Đăng ký `MetaOptions`, Meta HTTP clients, session store và authorization dependency trong `flex-agent-service/src/Flex.Agent.Api/Channels/Instagram/DependencyInjection.cs`.
- [ ] T021 Tạo migration additive cho `agentdb`, gồm preflight schema compatibility, `facebook_page_connections`, index lookup và unique `facebook_page_id`, trong `flex-database/agentdb/migrations/V1.4__create_meta_channel_connections.sql` (phụ thuộc T011, T018).
- [ ] T022 Tạo changeset release mới trỏ đúng tới `V1.4__create_meta_channel_connections.sql` trong `flex-database/agentdb/changelog/releases/1.4.0/changelog.xml` (phụ thuộc T021).
- [ ] T023 Include release `1.4.0` đúng một lần trong `flex-database/agentdb/changelog/db.changelog-master.xml` (phụ thuộc T022).
- [ ] T024 Tạo enum `ConnectionStatus` với mã canonical `active`, `disconnected`, `error` trong `flex-agent-service/src/Flex.Agent.Domain/Channels/ConnectionStatus.cs`.
- [ ] T025 Tạo model chung cho channel, candidate, connection status và public connection response trong `flex-microfrontend/src/app/features/agent-catalog/models/channel-connection.model.ts`.
- [ ] T026 Implement `AgentChannelConnectionService` cho connect/result/complete/list/disconnect của Instagram và Facebook bằng `HttpClient`/`environment.agentApiBaseUrl` trong `flex-microfrontend/src/app/features/agent-catalog/services/agent-channel-connection.service.ts`.
- [ ] T027 Tạo modal discovery/selection dùng `isVisible`, close output, eligible/invalid states và inline retry trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-channel-connection-result-modal/agent-channel-connection-result-modal.component.ts`, `.html`, `.scss` (phụ thuộc T025, T026).
- [ ] T028 Khai báo `AgentChannelConnectionResultModalComponent` trong `flex-microfrontend/src/app/features/agent-catalog/agent-catalog.module.ts` (phụ thuộc T027).
- [ ] T029 Mở rộng `AgentEditorWizardComponent` để đọc callback query `channel`, `sessionId`, `status`, tải discovery và không đưa token/raw state vào UI trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.ts`, `.html` (phụ thuộc T025, T026, T028).
- [ ] T030 Mở rộng `AgentStepPublishComponent` để truyền channel selection/connect request tới wizard trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-step-publish/agent-step-publish.component.ts`, `.html` (phụ thuộc T029).
- [ ] T031 Cập nhật `AgentInstagramConnectModalComponent` để giữ tên component hiện hữu nhưng emit channel/resource choice cho cả Instagram và Facebook theo design system trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-instagram-connect-modal/agent-instagram-connect-modal.component.ts`, `.html` (phụ thuộc T030).

**Checkpoint**: Meta boundary, session store, migration artifact, authorization và frontend connection shell đã sẵn sàng; chưa có user story nào được coi là hoàn tất.

---

## Phase 3: User Story 1 - Kết nối tài khoản Instagram (Priority: P1) — MVP

**Goal**: Người dùng có quyền cấu hình agent có thể kết nối Instagram Professional account qua Meta, discovery candidate, chọn một account và hoàn tất liên kết mà không tạo duplicate.

**Independent Test**:

1. Dùng Meta test user có Facebook Page liên kết Instagram Business/Creator; mở `/agents/{agentId}/edit` và chọn Instagram.
2. Hoàn tất connect → callback → result, xác nhận candidate metadata hiển thị và token không xuất hiện.
3. Chọn một candidate → complete → refresh; xác nhận `active` đúng agent, repeat complete bị idempotent/conflict đúng contract, invalid callback/resource bị từ chối.

### Tests for User Story 1

- [ ] T032 [P] [US1] Tạo unit/integration test cho Instagram Meta discovery, lọc linked Professional account, session candidate và complete trong `flex-agent-service/tests/Flex.Agent.Tests/Integrations/Instagram/InstagramMetaConnectionServiceTests.cs`.
- [ ] T033 [P] [US1] Tạo API contract test cho các route Instagram hiện hữu `/api/channels/instagram/connect`, callback, result, pages confirm và list trong `flex-agent-service/tests/Flex.Agent.Tests/Integrations/Instagram/InstagramConnectionContractTests.cs`.
- [ ] T034 [P] [US1] Tạo security test cho invalid state, expired/replayed session, cross-agent candidate và thiếu permission trong `flex-agent-service/tests/Flex.Agent.Tests/Integrations/Instagram/InstagramConnectionSecurityTests.cs`.
- [ ] T035 [P] [US1] Tạo component test cho Instagram connect/result/callback query/selection trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.spec.ts` (phụ thuộc T029, T030).

### Implementation for User Story 1

- [ ] T036 [P] [US1] Tạo `IInstagramConnectionService` và các context/result contracts cho Meta method trong `flex-agent-service/src/Flex.Agent.Application/Abstractions/Integrations/Instagram/IInstagramConnectionService.cs` và `flex-agent-service/src/Flex.Agent.Application/Abstractions/Integrations/Instagram/Models/InstagramConnectionModels.cs`.
- [ ] T037 [P] [US1] Tạo `ConnectInstagramCommand` và result contract trong `flex-agent-service/src/Flex.Agent.Application/Integrations/Instagram/Connect/ConnectInstagramCommand.cs`.
- [ ] T038 [US1] Implement `ConnectInstagramCommandHandler` để authorize agent, tạo session bound với `instagram`/`meta` và gọi `IMetaOAuthService` trong `flex-agent-service/src/Flex.Agent.Application/Integrations/Instagram/Connect/ConnectInstagramCommandHandler.cs` (phụ thuộc T014, T019, T036, T037).
- [ ] T039 [US1] Tạo `CallbackInstagramCommand` và callback result contract trong `flex-agent-service/src/Flex.Agent.Application/Integrations/Instagram/Callback/CallbackInstagramCommand.cs`.
- [ ] T040 [US1] Implement `CallbackInstagramCommandHandler` để consume state một lần, exchange code, discovery managed Pages và linked Instagram account trong `flex-agent-service/src/Flex.Agent.Application/Integrations/Instagram/Callback/CallbackInstagramCommandHandler.cs` (phụ thuộc T016, T017, T018, T039).
- [ ] T041 [US1] Tạo `CompleteInstagramConnectionCommand` với `AgentId`, `SessionId` và `ResourceId` trong `flex-agent-service/src/Flex.Agent.Application/Integrations/Instagram/CompleteConnection/CompleteInstagramConnectionCommand.cs`.
- [ ] T042 [US1] Implement `CompleteInstagramConnectionCommandHandler` để revalidate candidate/permission/duplicate, mã hóa credential và persist `MetaAccountConnection`/`InstagramPageConnection` trong `flex-agent-service/src/Flex.Agent.Application/Integrations/Instagram/CompleteConnection/CompleteInstagramConnectionCommandHandler.cs` (phụ thuộc T021, T024, T040, T041).
- [ ] T043 [US1] Tạo `ListInstagramConnectionsQuery` trong `flex-agent-service/src/Flex.Agent.Application/Integrations/Instagram/ListConnections/ListInstagramConnectionsQuery.cs`.
- [ ] T044 [US1] Implement list query scope theo agent và map public metadata không credential trong `flex-agent-service/src/Flex.Agent.Application/Integrations/Instagram/ListConnections/ListInstagramConnectionsQueryHandler.cs` (phụ thuộc T043).
- [ ] T045 [US1] Implement Meta Instagram orchestration qua `IMetaOAuthService`, `IMetaGraphService` và `IIntegrationSessionStore` trong `flex-agent-service/src/Flex.Agent.Infrastructures/Integrations/Instagram/MetaInstagramConnectionService.cs` (phụ thuộc T016, T017, T018, T036).
- [ ] T046 [US1] Di chuyển provider response records khỏi `flex-agent-service/src/Flex.Agent.Application/Channels/Instagram/InstagramConnectionContracts.cs` vào `flex-agent-service/src/Flex.Agent.Infrastructures/Integrations/Meta/Models/` và giữ Application DTO provider-neutral.
- [ ] T047 [US1] Refactor `flex-agent-service/src/Flex.Agent.Infrastructures/Channels/Instagram/InstagramOAuthService.cs` thành adapter/compatibility implementation dùng Meta ports, configurable API version và không lộ provider DTO (phụ thuộc T011, T012, T016, T046).
- [ ] T048 [US1] Refactor `flex-agent-service/src/Flex.Agent.Infrastructures/Channels/Instagram/InstagramPageService.cs` để dùng session abstraction, complete validation, unique conflict mapping và không đổi semantics route hiện hữu (phụ thuộc T018, T042, T045).
- [ ] T049 [US1] Refactor `flex-agent-service/src/Flex.Agent.Api/Channels/Instagram/InstagramChannelController.cs` thành adapter binding/auth/mapping cho connect, callback, result, pages confirm và list (phụ thuộc T038, T040, T042, T044).
- [ ] T050 [US1] Map error codes `INVALID_STATE`, `SESSION_EXPIRED`, `INVALID_CANDIDATE` và `CONNECTION_CONFLICT` vào error envelope hiện hữu trong `flex-agent-service/src/Flex.Agent.Api/Channels/Instagram/InstagramChannelController.cs` (phụ thuộc T049).
- [ ] T051 [US1] Nối Instagram connect, result modal, complete và reload connected state vào wizard trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.ts`, `.html` (phụ thuộc T026, T027, T029, T035).
- [ ] T052 [US1] Hiển thị channel card Instagram, trạng thái connected và selection output trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-step-publish/agent-step-publish.component.ts`, `.html` (phụ thuộc T031, T051).
- [ ] T053 [US1] Cập nhật assertion cũ “chỉ có Instagram” thành các assertion Instagram connect/candidate/active state trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.spec.ts` (phụ thuộc T051, T052).
- [ ] T054 [US1] Chạy independent test Instagram theo quickstart, xác nhận callback thất bại không sửa completed connection và ghi kết quả manual tại `specs/000041-meta-channel-connections/quickstart.md` (phụ thuộc T032, T033, T034, T049, T051).

**Definition of Done**:

- Connect/callback/discovery/complete Instagram pass với Meta test app.
- Invalid state, missing permission, out-of-scope candidate và duplicate không tạo active connection.
- Route Instagram cũ, webhook contract và regression tests hiện hữu không đổi behavior.
- Independent Test của US1 pass.

**Checkpoint**: US1 là MVP có thể demo độc lập sau khi Phase 2 hoàn tất.

---

## Phase 4: User Story 2 - Kết nối trang Facebook (Priority: P1)

**Goal**: Người dùng có quyền cấu hình agent có thể kết nối một Facebook Page được Meta xác nhận qua flow chung, truy vấn trạng thái và không lẫn field Instagram-specific.

**Independent Test**:

1. Dùng Meta test user quản lý Facebook Page; chọn Facebook từ publish step và hoàn tất OAuth.
2. Xem managed Page candidates, chọn một Page hợp lệ và complete.
3. Refresh để xác nhận `facebook_page_connections` có đúng agent/resource/status; thử permission/state/duplicate failure và xác nhận không ghi active connection sai.

### Tests for User Story 2

- [ ] T055 [P] [US2] Tạo entity/mapping test cho `FacebookPageConnection`, status và unique resource trong `flex-agent-service/tests/Flex.Agent.Tests/Integrations/Facebook/FacebookPageConnectionTests.cs`.
- [ ] T056 [P] [US2] Tạo unit/integration test cho Meta Facebook discovery, candidate ownership và complete trong `flex-agent-service/tests/Flex.Agent.Tests/Integrations/Facebook/FacebookMetaConnectionServiceTests.cs`.
- [ ] T057 [P] [US2] Tạo API contract test cho connect, callback, result, complete và list Facebook trong `flex-agent-service/tests/Flex.Agent.Tests/Integrations/Facebook/FacebookConnectionContractTests.cs`.
- [ ] T058 [P] [US2] Tạo permission/security/concurrency test cho cross-agent Page, missing permission và duplicate complete trong `flex-agent-service/tests/Flex.Agent.Tests/Integrations/Facebook/FacebookConnectionSecurityTests.cs`.

### Implementation for User Story 2

- [ ] T059 [P] [US2] Tạo `FacebookPageConnection` với lifecycle fields, Meta parent và encrypted page credential trong `flex-agent-service/src/Flex.Agent.Domain/Channels/Facebook/FacebookPageConnection.cs`.
- [ ] T060 [US2] Map `FacebookPageConnection` vào `facebook_page_connections`, index agent/status/resource và unique page trong `flex-agent-service/src/Flex.Agent.Infrastructures/Persistence/AppDbContext.cs` (phụ thuộc T021, T024, T059).
- [ ] T061 [P] [US2] Tạo `IFacebookConnectionService` và public context/result models cho method `Meta` trong `flex-agent-service/src/Flex.Agent.Application/Abstractions/Integrations/Facebook/IFacebookConnectionService.cs` và `flex-agent-service/src/Flex.Agent.Application/Abstractions/Integrations/Facebook/Models/FacebookConnectionModels.cs`.
- [ ] T062 [P] [US2] Tạo `ConnectFacebookCommand` trong `flex-agent-service/src/Flex.Agent.Application/Integrations/Facebook/Connect/ConnectFacebookCommand.cs`.
- [ ] T063 [US2] Implement `ConnectFacebookCommandHandler` để tạo session bound `facebook`/`meta` và trả Meta OAuth URL trong `flex-agent-service/src/Flex.Agent.Application/Integrations/Facebook/Connect/ConnectFacebookCommandHandler.cs` (phụ thuộc T014, T019, T061, T062).
- [ ] T064 [P] [US2] Tạo `CallbackFacebookCommand` trong `flex-agent-service/src/Flex.Agent.Application/Integrations/Facebook/Callback/CallbackFacebookCommand.cs`.
- [ ] T065 [US2] Implement `CallbackFacebookCommandHandler` để consume state, lấy managed Pages và lưu candidate/session metadata trong `flex-agent-service/src/Flex.Agent.Application/Integrations/Facebook/Callback/CallbackFacebookCommandHandler.cs` (phụ thuộc T016, T017, T018, T064).
- [ ] T066 [P] [US2] Tạo `CompleteFacebookConnectionCommand` trong `flex-agent-service/src/Flex.Agent.Application/Integrations/Facebook/CompleteConnection/CompleteFacebookConnectionCommand.cs`.
- [ ] T067 [US2] Implement `CompleteFacebookConnectionCommandHandler` để revalidate candidate/scope/duplicate, mã hóa page token và persist `FacebookPageConnection` trong `flex-agent-service/src/Flex.Agent.Application/Integrations/Facebook/CompleteConnection/CompleteFacebookConnectionCommandHandler.cs` (phụ thuộc T059, T060, T065, T066).
- [ ] T068 [P] [US2] Tạo `ListFacebookConnectionsQuery` trong `flex-agent-service/src/Flex.Agent.Application/Integrations/Facebook/ListConnections/ListFacebookConnectionsQuery.cs`.
- [ ] T069 [US2] Implement list query theo agent, status và public display metadata trong `flex-agent-service/src/Flex.Agent.Application/Integrations/Facebook/ListConnections/ListFacebookConnectionsQueryHandler.cs` (phụ thuộc T060, T068).
- [ ] T070 [US2] Implement Meta Facebook orchestration dùng shared Meta ports và session store trong `flex-agent-service/src/Flex.Agent.Infrastructures/Integrations/Facebook/MetaFacebookConnectionService.cs` (phụ thuộc T016, T017, T018, T061).
- [ ] T071 [US2] Tạo `FacebookController` cho connect, callback, result, complete và list theo `contracts/http-api.md` trong `flex-agent-service/src/Flex.Agent.Api/Controllers/Integrations/FacebookController.cs` (phụ thuộc T063, T065, T067, T069).
- [ ] T072 [US2] Đăng ký Facebook service/handlers/controller dependencies và `Channels:FacebookEnabled` trong `flex-agent-service/src/Flex.Agent.Api/Channels/Instagram/DependencyInjection.cs` và `flex-agent-service/src/Flex.Agent.Api/ServiceExtensions.cs` (phụ thuộc T020, T070, T071).
- [ ] T073 [US2] Bổ sung route/resource mapping Facebook vào service dùng chung trong `flex-microfrontend/src/app/features/agent-catalog/services/agent-channel-connection.service.ts` (phụ thuộc T026, T071).
- [ ] T074 [US2] Hiển thị Facebook card, managed Page candidates và complete result trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.ts`, `.html` (phụ thuộc T051, T073).
- [ ] T075 [US2] Bổ sung lựa chọn Facebook Fanpage và connected state vào `flex-microfrontend/src/app/features/agent-catalog/components/agent-step-publish/agent-step-publish.component.ts`, `.html` (phụ thuộc T052, T074).
- [ ] T076 [US2] Cập nhật component assertions để kiểm tra cả Instagram và Facebook channel thay vì giả định chỉ một channel trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.spec.ts` (phụ thuộc T074, T075).
- [ ] T077 [US2] Chạy independent test Facebook theo quickstart, xác nhận Page đã claim không bị overwrite và error response không lộ provider credential tại `specs/000041-meta-channel-connections/quickstart.md` (phụ thuộc T055, T056, T057, T058, T071, T076).

**Definition of Done**:

- Facebook connect/callback/discovery/complete/list pass với Meta test app.
- `FacebookPageConnection` được persist đúng schema, unique conflict được map thành 409, public response không có token.
- US1 và route Instagram vẫn pass regression.
- Independent Test của US2 pass.

**Checkpoint**: Hai P1 connection flows có thể test/triển khai theo thứ tự sau Foundation; US2 phụ thuộc UI shell và service được hoàn thiện ở US1.

---

## Phase 5: User Story 3 - Ngắt kết nối kênh (Priority: P2)

**Goal**: Người dùng có quyền quản lý có thể ngắt Instagram hoặc Facebook connection, vô hiệu hóa việc sử dụng credential và lặp lại thao tác an toàn.

**Independent Test**:

1. Dùng agent có một Instagram hoặc Facebook connection `active`, chọn disconnect từ connected state.
2. Xác nhận status chuyển `disconnected`, credential reference cục bộ được cleanup theo policy và list không còn coi connection là active.
3. Gửi lại DELETE cùng `connectionId`; xác nhận không tạo thay đổi/lỗi nghiệp vụ mới và user không thể disconnect connection của agent khác.

### Tests for User Story 3

- [ ] T078 [P] [US3] Tạo integration test cho status transition, credential cleanup, completed connection isolation và repeated disconnect của Instagram trong `flex-agent-service/tests/Flex.Agent.Tests/Integrations/Instagram/InstagramDisconnectTests.cs`.
- [ ] T079 [P] [US3] Tạo integration test cho status transition, credential cleanup và repeated disconnect của Facebook trong `flex-agent-service/tests/Flex.Agent.Tests/Integrations/Facebook/FacebookDisconnectTests.cs`.
- [ ] T080 [P] [US3] Tạo API contract test cho `DELETE /api/channels/instagram/connections/{id}` và `DELETE /api/channels/facebook/connections/{id}` trong `flex-agent-service/tests/Flex.Agent.Tests/Integrations/ConnectionDisconnectContractTests.cs`.
- [ ] T081 [P] [US3] Tạo Angular test cho connected-state disconnect, success reload, forbidden response và repeated request trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.spec.ts`.

### Implementation for User Story 3

- [ ] T082 [US3] Tạo `DisconnectInstagramConnectionCommand` và handler idempotent trong `flex-agent-service/src/Flex.Agent.Application/Integrations/Instagram/Disconnect/DisconnectInstagramConnectionCommand.cs` và `DisconnectInstagramConnectionCommandHandler.cs` (phụ thuộc T048, T078).
- [ ] T083 [US3] Tạo `DisconnectFacebookConnectionCommand` và handler idempotent trong `flex-agent-service/src/Flex.Agent.Application/Integrations/Facebook/Disconnect/DisconnectFacebookConnectionCommand.cs` và `DisconnectFacebookConnectionCommandHandler.cs` (phụ thuộc T067, T079).
- [ ] T084 [US3] Nối route DELETE Instagram hiện hữu vào disconnect handler, giữ response compatibility và agent scope trong `flex-agent-service/src/Flex.Agent.Api/Channels/Instagram/InstagramChannelController.cs` (phụ thuộc T082).
- [ ] T085 [US3] Nối route DELETE Facebook vào disconnect handler, trả trạng thái idempotent theo contract trong `flex-agent-service/src/Flex.Agent.Api/Controllers/Integrations/FacebookController.cs` (phụ thuộc T083).
- [ ] T086 [US3] Thêm connected-state list/disconnect action, confirmation và reload error state vào `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.ts`, `.html` (phụ thuộc T026, T074, T082, T083).
- [ ] T087 [US3] Thêm lifecycle audit/log fields `actor`, `agentId`, `channel`, `connectionId`, `outcome`, `reason`, `traceId` cho Instagram start/callback/complete/disconnect trong `flex-agent-service/src/Flex.Agent.Application/Integrations/Instagram/` và adapter API (phụ thuộc T049, T082, T084).
- [ ] T088 [US3] Thêm lifecycle audit/log fields tương ứng cho Facebook trong `flex-agent-service/src/Flex.Agent.Application/Integrations/Facebook/` và `flex-agent-service/src/Flex.Agent.Api/Controllers/Integrations/FacebookController.cs` (phụ thuộc T071, T083, T085).
- [ ] T089 [US3] Hoàn tất UI assertions cho disconnect và trạng thái `disconnected` trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.spec.ts` (phụ thuộc T086).
- [ ] T090 [US3] Chạy independent test disconnect Instagram/Facebook theo quickstart, kiểm tra repeated DELETE, cross-agent denial và credential không xuất hiện trong log tại `specs/000041-meta-channel-connections/quickstart.md` (phụ thuộc T078, T079, T080, T081, T084, T085, T089).

**Definition of Done**:

- Disconnect hợp lệ vô hiệu hóa connection; request lặp idempotent.
- Không xóa Meta credential còn được connection khác sử dụng và không sửa connection đã hoàn tất khác.
- Permission, audit/log và UI connected state được kiểm tra.
- Independent Test của US3 pass.

**Checkpoint**: Tất cả user stories trong scope đã có flow hoàn chỉnh.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Mục đích**: Kiểm tra chéo migration, security, observability, regression và release readiness.

- [ ] T091 [P] Chạy `liquibase --changelog-file=changelog/db.changelog-master.xml validate` và `update-sql` tại `flex-database/agentdb/`, review generated SQL không có destructive operation hoặc sửa changeset cũ (phụ thuộc T023).
- [ ] T092 [P] Chạy backend security/log review test, xác nhận error response và structured log không chứa OAuth code, raw state, token, app secret, encryption key hoặc credential reference trong `flex-agent-service/tests/Flex.Agent.Tests/Integrations/Meta/` (phụ thuộc T087, T088).
- [ ] T093 [P] Chạy `ng test --watch=false` và `ng build` tại `flex-microfrontend/`, xác nhận supported browser flow và không duplicate toast khi interceptor xử lý lỗi (phụ thuộc T089).
- [ ] T094 Chạy `dotnet build Flex.Agent.sln` và `dotnet test Flex.Agent.sln` tại `flex-agent-service/`, xác nhận toàn bộ Instagram OAuth/page/webhook/security tests và `MessengerRegressionTests` pass (phụ thuộc T090, T092).
- [ ] T095 Chạy smoke test staging với Meta test app cho connect/callback/result/complete/list/disconnect của cả hai channel, kiểm tra p95 internal step dưới 3 giây và audit/metric/log sau release theo `specs/000041-meta-channel-connections/quickstart.md` (phụ thuộc T091, T093, T094).
- [ ] T096 Xác nhận rollout/rollback: migration `agentdb` đã chạy trước service, `Channels:FacebookEnabled` có thể tắt độc lập, existing Instagram route/schema không đổi và không có automatic destructive rollback trong release checklist tại `specs/000041-meta-channel-connections/quickstart.md` (phụ thuộc T095).

---

## Validation Commands

- Build backend: `cd flex-agent-service; dotnet build Flex.Agent.sln`
- Run tests: `cd flex-agent-service; dotnet test Flex.Agent.sln`
- Run API contract tests: `cd flex-agent-service; dotnet test Flex.Agent.sln --filter FullyQualifiedName~ConnectionContract`
- Run frontend checks: `cd flex-microfrontend; ng test --watch=false; ng build`
- Run migration validation: `cd flex-database/agentdb; liquibase --changelog-file=changelog/db.changelog-master.xml validate; liquibase --changelog-file=changelog/db.changelog-master.xml update-sql`
- Run staging smoke check: thực hiện các bước trong `specs/000041-meta-channel-connections/quickstart.md` với Meta test app; không dùng Meta production trong validation tự động.

## Dependencies & Execution Order

### Phase Dependencies

- Phase 1 không phụ thuộc phase khác; T001/T002 nên chạy tuần tự để có baseline backend, T003/T004 có thể chạy song song với baseline.
- Phase 2 phụ thuộc baseline Setup; T005–T010 phải viết trước T011–T031. T021–T023 phải hoàn tất trước các handler persist.
- Phase 3 US1 phụ thuộc toàn bộ Phase 2; T032–T035 phải hoàn tất trước T036–T054.
- Phase 4 US2 phụ thuộc Phase 2 và UI/service shell của US1; T055–T058 phải hoàn tất trước T059–T077.
- Phase 5 US3 phụ thuộc US1 và US2 completed vì disconnect dùng cả hai aggregate/controller; T078–T081 phải hoàn tất trước T082–T090.
- Final Phase phụ thuộc tất cả story phase; chỉ T091–T093 có thể chạy song song, T094 phụ thuộc test/security, T095–T096 chạy tuần tự sau build/validation.

### Dependency Graph

```text
Setup T001-T004
  → Foundation T005-T031
      ├→ US1 T032-T054
      └→ US2 T055-T077 (UI integration phụ thuộc T051-T052)
          └→ US3 T078-T090
              → Polish T091-T096
```

### Parallel Opportunities

- Foundation: T005, T006, T007, T008, T009, T010 khác file và có thể chạy song song; T011–T015 cũng có thể chia theo file sau khi test task được tạo.
- US1: T032, T033, T034, T035 có thể chạy song song; T036, T037, T039, T041, T043 là các contract/model file khác nhau có thể chuẩn bị song song trước handler tương ứng.
- US2: T055, T056, T057, T058 có thể chạy song song; T059, T061, T062, T064, T066, T068 là các file model/command khác nhau có thể chuẩn bị song song.
- US3: T078, T079, T080, T081 có thể chạy song song; T082 và T083 có thể chạy song song vì khác channel/file, sau đó T084/T085 và UI T086 tích hợp theo dependency.
- Không đánh dấu `[P]` cho task sửa cùng file tổng hợp như `AppDbContext.cs`, `DependencyInjection.cs`, `InstagramChannelController.cs`, `FacebookController.cs` hoặc `agent-editor-wizard.component.spec.ts`.

## Parallel Example: User Story 1

```text
Task T032: Test Instagram Meta discovery trong flex-agent-service/tests/Flex.Agent.Tests/Integrations/Instagram/InstagramMetaConnectionServiceTests.cs
Task T033: Test contract route Instagram trong flex-agent-service/tests/Flex.Agent.Tests/Integrations/Instagram/InstagramConnectionContractTests.cs
Task T034: Test security state/candidate trong flex-agent-service/tests/Flex.Agent.Tests/Integrations/Instagram/InstagramConnectionSecurityTests.cs
Task T035: Test Angular wizard Instagram trong flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.spec.ts
```

## Parallel Example: User Story 2

```text
Task T055: Test Facebook entity trong flex-agent-service/tests/Flex.Agent.Tests/Integrations/Facebook/FacebookPageConnectionTests.cs
Task T056: Test Facebook Meta discovery trong flex-agent-service/tests/Flex.Agent.Tests/Integrations/Facebook/FacebookMetaConnectionServiceTests.cs
Task T057: Test contract Facebook trong flex-agent-service/tests/Flex.Agent.Tests/Integrations/Facebook/FacebookConnectionContractTests.cs
Task T058: Test Facebook permission/concurrency trong flex-agent-service/tests/Flex.Agent.Tests/Integrations/Facebook/FacebookConnectionSecurityTests.cs
```

## Implementation Strategy

### MVP First — User Story 1

1. Hoàn tất Setup và Foundation, bao gồm migration preview/validation nhưng chưa apply database production.
2. Hoàn tất US1 Instagram, chạy independent test và regression.
3. Demo MVP connect Instagram bằng Meta test app; dừng tại checkpoint nếu US2/US3 chưa được phê duyệt triển khai tiếp.

### Incremental Delivery

1. Foundation → US1 Instagram → validate/deploy demo.
2. US2 Facebook → validate/deploy additive.
3. US3 Disconnect cho cả hai channel → validate lifecycle.
4. Polish → staging smoke → production release khi migration, permission và rollback readiness pass.

## Traceability Matrix

| Source | Covered by tasks |
|--------|------------------|
| US-001 | T032–T054 |
| AC-001/AC-002/AC-003/AC-004 | T038, T040, T042, T050, T054 |
| US-002 | T055–T077 |
| AC-005/AC-006/AC-007 | T063, T065, T067, T071, T077 |
| US-003 | T078–T090 |
| AC-008/AC-009 | T082–T090 |
| FR-001 | T019, T038, T063, T054, T077 |
| FR-002 / BR-002 | T014, T018, T038–T040, T063–T065 |
| FR-003 / BR-003 | T006, T017, T040, T045, T065, T070 |
| FR-004 / FR-005 | T042–T045, T067–T071 |
| FR-006 / FR-007 | T078–T090 |
| FR-008 | T005–T008, T034, T050, T058, T065, T077 |
| FR-009 / BR-004 | T021, T042, T058, T067, T077 |
| FR-010 / SEC-003 | T007, T016–T018, T042, T067, T087–T092 |
| BR-001 / SEC-001 / SEC-002 | T008, T019, T034, T058, T080, T082–T085 |
| NFR-001 | T005–T006, T091, T095 |
| NFR-002 | T034, T042, T067, T078, T079, T090 |
| NFR-003 | T050, T071, T086, T095 |
| NFR-004 | T035, T076, T093, T095 |

## Checklist chất lượng trước khi implement

- [x] Không còn task ví dụ hoặc placeholder trong output cuối.
- [x] Không còn `TXXX`, `Phase N` hoặc phase user story không tồn tại trong `spec.md`.
- [x] Toàn bộ task được đánh số tuần tự từ `T001` đến `T096`.
- [x] Mỗi task có path cụ thể hoặc command cụ thể.
- [x] Task sửa file có sẵn đã nêu rõ class, method, section, endpoint group hoặc config key.
- [x] Task phụ thuộc task khác đã ghi rõ dependency task ID khi cần.
- [x] Mỗi user story có Independent Test cụ thể.
- [x] Mỗi user story có automated test task; manual validation bổ sung cho Meta test app/staging.
- [x] Mỗi user story có Definition of Done cụ thể.
- [x] Mỗi `US`/`FR` P1/P2 và requirement ảnh hưởng code/data/API/permission có task tương ứng.
- [x] Mỗi FR nhiều điều kiện có task mô tả từng vế: reject, revalidate, persist, idempotency và cleanup.
- [x] Traceability Matrix đã map source quan trọng sang task ID thực tế.
- [x] Migration, permission, contract, observability, rollout/rollback đều có task.
- [x] Task `[P]` không sửa cùng file và không phụ thuộc task chưa hoàn tất.
- [x] Dependency graph và parallel examples phản ánh conflict file thực tế.
- [x] Không có task tài liệu vì `plan.md` không nêu cập nhật còn lại sau implementation.
