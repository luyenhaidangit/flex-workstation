# Tasks: Lưu trữ và tích hợp hội thoại

**Input**: `spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`  
**Branch**: `000035-conversation-persistence`

## Phase 1: Setup

**Mục đích**: Chuẩn bị release migration, test scope và cấu trúc feature tối thiểu.

- [X] T001 Tạo release directory `flex-database/agentdb/changelog/releases/1.3.0/` và xác nhận master changelog sẽ include đúng một release mới cho feature `000035`.
- [X] T002 [P] Tạo thư mục test backend `flex-agent-service/tests/Flex.Agent.Tests/Conversations/` và test fixture PostgreSQL dùng chung cho conversation integration tests.
- [X] T003 [P] Tạo thư mục Angular feature `flex-microfrontend/src/app/core/conversations/` cho models và API service, giữ dependency direction qua `HttpClient`/auth interceptor hiện có.

## Phase 2: Foundational (Blocking Prerequisites)

**Mục đích**: Hoàn tất schema, domain, persistence boundary, authorization và contract types trước mọi user story.

**Checkpoint**: Migration preview được, domain/persistence compile được, tenant scope và transaction boundary đã có thể test; sau đó các story mới bắt đầu.

- [X] T004 [P] Tạo `flex-agent-service/src/Flex.Agent.Domain/Entities/Conversation.cs` với các thuộc tính conversation, status `active`, latest-message projection và invariant `last_sequence_no >= 0` theo `data-model.md` (FR-001, BR-004).
- [X] T005 [P] Tạo `flex-agent-service/src/Flex.Agent.Domain/Entities/Message.cs` với `role`, `actor_type`, `actor_id`, `sequence_no`, `client_message_id`, `status`, metadata và content rules; không suy luận `actor_type` từ `role` (FR-006, FR-007, BR-002).
- [X] T006 [P] Tạo `specs/000035-conversation-persistence/rollback.md` mô tả migration additive, không drop production tables, forward-fix/restore và điều kiện rollback theo plan.
- [X] T007 Tạo `flex-database/agentdb/migrations/V1.3__create_chat_conversation_message.sql` tạo schema `chat`, hai bảng, unique `(conversation_id, sequence_no)`, scoped idempotency key và index list/history; không thêm FK xuyên database (FR-003, FR-008, Constitution VI).
- [X] T008 Tạo `flex-database/agentdb/changelog/releases/1.3.0/changelog.xml` include migration `V1.3__create_chat_conversation_message.sql`, cập nhật `flex-database/agentdb/changelog/db.changelog-master.xml` và chạy `validate`/`update-sql` trên database test (FR-001, FR-003).
- [X] T009 Tạo mapping `Conversation`/`Message` trong `flex-agent-service/src/Flex.Agent.Infrastructures/Persistence/AppDbContext.cs` và configuration/query indexes để EF dùng schema `chat`, JSONB metadata và UTC timestamps (FR-003, FR-010).
- [X] T010 [P] Tạo `flex-agent-service/src/Flex.Agent.Application/Conversations/ConversationContracts.cs` chứa use-case records/interfaces cho create, list, get messages, append message và result/error semantics; không đưa EF/HTTP type vào application layer.
- [X] T011 Tạo writer implementation tại `flex-agent-service/src/Flex.Agent.Infrastructures/Repositories/ConversationRepository.cs` làm transaction boundary: validate tenant/conversation, khóa row conversation, cấp sequence từ `last_sequence_no`, insert message, update `last_message_*`, commit trước publish (FR-003, FR-004, BR-003, BR-004).
- [X] T012 [P] Tạo `flex-agent-service/src/Flex.Agent.Api/DTOs/ConversationDtos.cs` theo `contracts/conversation-api.md`, map camelCase JSON và không cho client override `tenantId`, `createdBy`, `role`, `actorType`, `actorId` (FR-005, SEC-002).
- [X] T013 Thực hiện conversation authorization trong `flex-agent-service/src/Flex.Agent.Api/Controllers/ConversationsController.cs` và repository scope checks; resolve tenant/user từ claims, không tin `conversationId` là bằng chứng quyền (SEC-001, SEC-002).
- [X] T014 [P] Tạo `flex-microfrontend/src/app/core/conversations/conversation.models.ts` theo API/event contracts, giữ riêng `role` và `actorType`, có loading/error/idempotency fields cho UI.
- [X] T015 [P] Tạo `flex-microfrontend/src/app/core/conversations/conversation-api.service.ts` cho create/list/history/send với page size tối đa 50, dùng HTTP/auth convention hiện có và không tự tạo token/tenant context.
- [X] T016 [P] Kiểm thử contract/API mapping trong `flex-agent-service/tests/Flex.Agent.Tests/Conversations/ConversationsControllerTests.cs` cho create/append response, validation claims và độc lập `role`/`actorType` (FR-005, FR-006, AC-001..AC-006).

## Phase 3: User Story 1 — Mở và tiếp tục conversation (P1) — MVP

**Goal**: Người dùng tạo conversation, xem danh sách/lịch sử và gửi message text; message có sequence ổn định và FE/BE dùng cùng contract.

**Independent Test**:

1. Tạo conversation bằng `POST /api/v1/conversations` với JWT tenant hợp lệ.
2. Gửi message text bằng `POST /api/v1/conversations/{id}/messages`, xác nhận `sequenceNo=1`, `role=user`, `actorType=end_user`.
3. Tải list/history sau refresh, xác nhận đúng tenant, đúng thứ tự và latest summary.

**Definition of Done**:

- Create/list/history/send API và FE flow hoàn tất theo contract.
- Transaction append và tenant isolation tests pass.
- FE hiển thị loading/empty/error state và không gửi message rỗng.
- Independent Test US1 pass mà không cần US2/US3.

### Tests for User Story 1

- [X] T017 [P] [US1] Kiểm thử create/tenant-scoped flow trong `flex-agent-service/tests/Flex.Agent.Tests/Conversations/ConversationsControllerTests.cs` và `ConversationRepositoryTests.cs` cho AC-001, AC-002, AC-004 (FR-001, FR-002).
- [X] T018 [P] [US1] Kiểm thử append và latest projection trong `flex-agent-service/tests/Flex.Agent.Tests/Conversations/ConversationRepositoryTests.cs` cho AC-003 và `last_sequence_no/last_message_id` (FR-003, FR-004).
- [X] T019 [P] [US1] Kiểm thử missing tenant claim và actor scoping trong `flex-agent-service/tests/Flex.Agent.Tests/Conversations/ConversationsControllerTests.cs` (SEC-001, SEC-002).

### Implementation for User Story 1

- [X] T020 [US1] Triển khai create/list/get-history/append và mapping projection trong `flex-agent-service/src/Flex.Agent.Infrastructures/Repositories/ConversationRepository.cs`; dùng `last_sequence_no`, không truy vấn `MAX(sequence_no)` (FR-001, FR-002, FR-003).
- [X] T021 [US1] Tạo `flex-agent-service/src/Flex.Agent.Api/Controllers/ConversationsController.cs` với `POST/GET /api/v1/conversations` và `GET /api/v1/conversations/{conversationId}/messages`, map 400/401/403/404 theo contract (FR-001, FR-002, SEC-001).
- [X] T022 [US1] Bổ sung `POST /api/v1/conversations/{conversationId}/messages` vào `flex-agent-service/src/Flex.Agent.Api/Controllers/ConversationsController.cs`, gán user actor từ claims, gọi writer và trả idempotent/durable `MessageResponse` (FR-005, AC-003).
- [X] T023 [US1] Đăng ký `ConversationService`, writer/repository và authorization trong `flex-agent-service/src/Flex.Agent.Api/Extensions/ServiceExtensions.cs`, giữ `AppDbContext` scoped và cancellation propagation (FR-001..FR-005).
- [X] T024 [US1] Kiểm thử empty content/active status/sequence/latest projection trong `flex-agent-service/tests/Flex.Agent.Tests/Conversations/ConversationRepositoryTests.cs` (BR-001, BR-003).
- [ ] T025 [US1] Tích hợp `conversation-api.service.ts` vào `flex-microfrontend/src/app/pages/chat/chat.component.ts`, thay dữ liệu mock bằng list/history/send API và giữ các trạng thái loading, empty, error, retry theo Skote/Bootstrap hiện có (US-001, AC-002, AC-004).
- [ ] T026 [US1] Cập nhật `flex-microfrontend/src/app/pages/chat/chat.component.html` và `chat.component.scss` để render message theo `role`/`actorType`, skeleton/empty/error state và validation text tiếng Việt; không thêm UI framework mới (FR-005, NFR-003).
- [ ] T027 [US1] Tạo Angular unit tests `flex-microfrontend/src/app/pages/chat/chat.component.spec.ts` cho create/list/history/send, message rỗng, loading/empty/error và không gửi trùng khi request đang pending (AC-002, AC-003, NFR-003).

## Phase 4: User Story 2 — Nhận phản hồi AI và nhận diện tác nhân (P1)

**Goal**: User và AI Agent dùng cùng message model; AI response được persist sau khi hoàn tất, có `role=assistant`, `actorType=ai_agent`, và client nhận event sau commit.

**Independent Test**:

1. Gọi `POST /api/v1/ai/chat` với conversation đã tồn tại.
2. Xác nhận user message và assistant message xuất hiện cùng conversation, sequence tăng liên tục.
3. Xác nhận FE render assistant theo `role` và actor theo `actorType`, không dùng `is_bot`/sender label để suy luận.

**Definition of Done**:

- AI user/assistant messages được persist trong cùng conversation và đúng sequence.
- `role`/`actorType` độc lập trong HTTP và realtime contract tests.
- Existing AI API/direct-message event regression tests pass.
- Independent Test US2 pass với model response hợp lệ.

### Tests for User Story 2

- [ ] T028 [P] [US2] Tạo integration test `flex-agent-service/tests/Flex.Agent.Tests/Conversations/AIConversationPersistenceTests.cs` cho AI success: persist user trước model, persist assistant completed sau response hợp lệ, cùng conversation và sequence (FR-006, FR-007, AC-005).
- [ ] T029 [P] [US2] Tạo regression test `flex-agent-service/tests/Flex.Agent.Tests/AI/AIControllerChatTests.cs` cho `POST /api/v1/ai/chat` giữ request/response cũ, timeout/unavailable không tạo assistant completed (FR-007, FR-009).
- [ ] T030 [P] [US2] Tạo contract test `flex-agent-service/tests/Flex.Agent.Tests/Conversations/ConversationRealtimeContractTests.cs` kiểm tra event `conversation.message.created` có role/actorType/sequence và chỉ phát sau commit (FR-005..FR-007).

### Implementation for User Story 2

- [ ] T031 [US2] Cập nhật `flex-agent-service/src/Flex.Agent.Application/Chat/Services/ChatService.cs` để dùng conversation writer cho user message, gọi model, persist assistant completed với actor `ai_agent`, và ghi failed/cancelled theo error semantics (FR-007, FR-009, AC-005).
- [X] T032 [US2] Cập nhật `flex-agent-service/src/Flex.Agent.Application/Chat/Context/ConversationHistoryProvider.cs` để đọc message theo `sequence_no`, map role hợp lệ vào `Microsoft.Extensions.AI.ChatMessage`, scoped tenant/conversation (FR-002, FR-007).
- [X] T033 [US2] Tạo `flex-agent-service/src/Flex.Agent.Application/Conversations/IConversationEventPublisher.cs` và implementation mỏng tại `flex-agent-service/src/Flex.Agent.Api/Hubs/ConversationEventPublisher.cs` để publish sau commit, không đưa business logic vào Hub (R4, AC-005).
- [ ] T034 [US2] Cập nhật `flex-agent-service/src/Flex.Agent.Api/Hubs/ApplicationHub.cs` và `RealtimeEventNames.cs` thêm `conversation.message.created` với authorization/resource routing, giữ nguyên `message.created` direct event (FR-007, compatibility).
- [X] T035 [US2] Cập nhật `flex-microfrontend/src/app/core/realtime/realtime-event.model.ts` và `application-realtime.service.ts` để nhận event conversation, dedupe theo `messageId`, expose stream cho chat feature và giữ direct-message stream hiện hữu (AC-006).
- [ ] T036 [US2] Cập nhật `flex-microfrontend/src/app/pages/chat/chat.component.ts` để merge realtime event theo `conversationId`/`sequenceNo`, hiển thị actor metadata độc lập với role và reload HTTP khi reconnect (FR-007, NFR-003).

## Phase 5: User Story 3 — Khôi phục và xử lý lỗi khi tải/gửi (P2)

**Goal**: Timeout, retry, concurrent request và reconnect không làm mất lịch sử, duplicate message hoặc sai sequence; FE hiển thị lỗi có thể hành động.

**Independent Test**:

1. Gửi hai request đồng thời và retry cùng `clientMessageId`.
2. Xác nhận chỉ có một message tương ứng, sequence không trùng và payload khác cùng key trả `409`.
3. Mô phỏng timeout/reconnect, tải lại history và xác nhận lịch sử durable, không phụ thuộc event đã bỏ lỡ.

**Definition of Done**:

- Concurrent append và idempotent replay không tạo duplicate hoặc sequence conflict.
- Timeout/permission/validation trả lỗi an toàn, không leak content/exception.
- FE retry/reconnect reloads durable history và dedupe event.
- Independent Test US3 pass.

### Tests for User Story 3

- [ ] T037 [P] [US3] Tạo concurrency integration test `flex-agent-service/tests/Flex.Agent.Tests/Conversations/ConversationConcurrencyTests.cs` chạy append đồng thời trên cùng conversation, xác nhận unique sequence và latest projection (FR-008, AC-008, NFR-002).
- [ ] T038 [P] [US3] Tạo idempotency integration test `flex-agent-service/tests/Flex.Agent.Tests/Conversations/MessageIdempotencyTests.cs` cho replay cùng payload và conflict khác payload, xác nhận `200/409` theo contract (FR-008, AC-008).
- [ ] T039 [P] [US3] Tạo error/permission test `flex-agent-service/tests/Flex.Agent.Tests/Conversations/ConversationFailureAndSecurityTests.cs` cho invalid content, 401/403/404, timeout/cancel và response không leak exception/content (FR-009, SEC-003).
- [ ] T040 [US3] Tạo Angular test `flex-microfrontend/src/app/pages/chat/chat.component.spec.ts` cho retry sau timeout, không gửi lặp khi pending, reconnect rồi history reload và dedupe event (AC-007, AC-008).

### Implementation for User Story 3

- [X] T041 [US3] Hoàn thiện `flex-agent-service/src/Flex.Agent.Infrastructures/Repositories/ConversationRepository.cs` với idempotency lookup trước lock/append, conflict detection, cancellation/timeout handling và transaction isolation phù hợp (FR-008, AC-008).
- [ ] T042 [US3] Hoàn thiện error mapping tại `flex-agent-service/src/Flex.Agent.Api/Controllers/ConversationsController.cs` và `AIController.cs` cho invalid/timeout/unavailable/idempotency conflict, không trả exception nội bộ (FR-009, SEC-003).
- [ ] T043 [US3] Cập nhật `flex-microfrontend/src/app/core/conversations/conversation-api.service.ts` và `conversation.models.ts` để giữ `clientMessageId` qua retry, phân biệt request pending/unknown outcome và xử lý 409/504 theo thông báo tiếng Việt (AC-007, AC-008).
- [ ] T044 [US3] Cập nhật `flex-microfrontend/src/app/pages/chat/chat.component.ts` và `chat.component.html` cho retry/tải lại history sau timeout hoặc reconnect, giữ message cũ và không hiển thị failed assistant như completed (FR-009, AC-007).
- [ ] T045 [US3] Thêm permission policy test cho SignalR conversation event trong `flex-agent-service/tests/Flex.Agent.Tests/Conversations/ConversationRealtimePermissionTests.cs`, xác nhận tenant/resource unauthorized không join/nhận event (SEC-001, SEC-002).

## Phase 6: Polish & Cross-Cutting Concerns

**Mục đích**: Kiểm tra release, observability, compatibility, hiệu năng và tài liệu vận hành.

- [ ] T046 [P] Thêm structured logging tại `flex-agent-service/src/Flex.Agent.Application/Conversations/ConversationMessageWriter.cs` và `ConversationsController.cs` cho operation/result/correlation fields; tuyệt đối không log content, metadata nhạy cảm, token hoặc secret (SEC-003, Observability Gate).
- [ ] T047 [P] Thêm metric/trace instrumentation cho history latency, append error, idempotent replay, sequence conflict, authorization denied và event publish failure tại `flex-agent-service/src/Flex.Agent.Api/Logging/` hoặc abstraction logging hiện có (NFR-001, Observability Gate).
- [ ] T048 Chạy validation command trong `specs/000035-conversation-persistence/quickstart.md`, gồm Liquibase `validate/update-sql`, `dotnet build`, `dotnet test`, API smoke và kiểm tra schema/index; ghi kết quả vào release checklist, không chạy migration production.
- [ ] T049 [P] Chạy Angular checks từ `flex-microfrontend/package.json` cho unit/build feature chat, xác nhận không phá vỡ `ApplicationRealtimeService` direct-message regression và UI dùng SharedModule/Bootstrap convention (NFR-003, regression).
- [ ] T050 Kiểm tra backward compatibility của `POST /api/v1/ai/chat`, event `message.created`, existing Agent CRUD và migration rollback/recovery theo `specs/000035-conversation-persistence/rollback.md`; nếu lỗi chỉ dùng forward-fix, không drop tables (Compatibility/Release Gate).
- [ ] T051 Chạy security review cuối cho conversation API/event: tenant isolation, actor server-side, log redaction, error response và content/metadata exposure; ghi kết quả trong task handoff trước release (SEC-001..003).

## Dependencies & Execution Order

### Phase Dependencies

- Phase 1 không phụ thuộc phase khác.
- Phase 2 phụ thuộc Phase 1 và chặn mọi user story.
- US1 phụ thuộc Phase 2; đây là MVP đầu tiên.
- US2 phụ thuộc US1 vì dùng conversation/message writer, API và history đã có.
- US3 phụ thuộc Phase 2 và các writer/API/FE component của US1; có thể bắt đầu test concurrency sau khi writer contract ổn định, nhưng implementation hoàn tất sau US1.
- Phase 6 phụ thuộc các story đã hoàn tất.

### User Story Dependencies

- **US1 (P1)**: Phase 2 → US1; độc lập và là MVP.
- **US2 (P1)**: Phase 2 + US1 writer/history/API; mở rộng AI flow và realtime.
- **US3 (P2)**: Phase 2 + US1 API/writer + US2 event/AI error behavior; tập trung reliability.

### Parallel Opportunities

- Phase 1: T002 và T003 có thể chạy song song; T001 độc lập nhưng cần hoàn tất trước T008.
- Phase 2: T004, T005, T006, T010, T012, T014, T015, T016 có thể chạy song song nếu không cùng sửa file; T007/T008 phải trước T009.
- US1: T017, T018, T019, T024 có thể viết song song; T020–T023 theo dependency; T025–T027 bắt đầu sau T015 và API contract ổn định.
- US2: T028–T030 có thể chạy song song; T031/T032 trước T035/T036; T033/T034 không chạy song song với task khác sửa `ApplicationHub.cs`.
- US3: T037–T040 có thể chạy song song; T041/T042 không chạy song song vì cùng writer/controller; T043/T044 có thể song song sau API error contract.
- Phase 6: T046, T047, T049 có thể song song; T048–T051 cần chạy sau khi implementation merge.

## Traceability Matrix

| Source | Covered by tasks |
|---|---|
| US-001 | T017–T027 |
| US-002 | T028–T036 |
| US-003 | T037–T045 |
| FR-001/FR-002 | T007–T008, T017, T020–T021 |
| FR-003/FR-004 | T007–T011, T018, T020–T022 |
| FR-005 | T012, T015–T016, T022, T030 |
| FR-006/FR-007 | T005, T024, T028–T036 |
| FR-008 | T007, T011, T037–T041 |
| FR-009 | T005, T029, T039, T042, T044 |
| FR-010/BR-006 | T005, T009, T012, T014, T016 |
| BR-001/BR-002 | T005, T013, T019, T024, T045, T051 |
| BR-003/BR-004 | T004, T007, T011, T018, T020, T037 |
| BR-005 | T028, T031, T032 |
| SEC-001/SEC-002 | T013, T019, T045, T051 |
| SEC-003 | T039, T042, T046, T051 |
| NFR-001/NFR-002 | T037, T047, T048 |
| NFR-003/NFR-004 | T025–T027, T035–T036, T040, T049 |
| SC-001..SC-004 | T017–T019, T028–T030, T037–T040, T048 |
| API contract | T012, T016, T021–T022, T030, T042 |
| Realtime contract | T033–T036, T045 |
| Data model/migration | T004–T011, T048, T050 |

## Implementation Strategy

### MVP First

1. Hoàn tất Phase 1–2 và validate migration trên database test.
2. Hoàn tất US1: create/list/history/send, kiểm tra tenant isolation và transaction ordering.
3. Dừng để chạy Independent Test US1; chỉ khi pass mới mở rộng AI/realtime.

### Incremental Delivery

1. US1 cung cấp durable conversation/message MVP.
2. US2 nối AI response và event, giữ API cũ tương thích.
3. US3 harden retry/concurrency/reconnect/error.
4. Phase 6 chạy release/security/observability checks.

## Validation Commands

- Migration validation: `liquibase --changelog-file=changelog/db.changelog-master.xml validate` và `update-sql` từ `flex-database/agentdb`.
- Backend build: `dotnet build Flex.Agent.sln --configuration Release` từ `flex-agent-service`.
- Backend tests: `dotnet test Flex.Agent.sln --configuration Release` từ `flex-agent-service`.
- Frontend checks: commands trong `flex-microfrontend/package.json` cho `test`/`build` và manual chat smoke.
- End-to-end smoke: các bước trong `specs/000035-conversation-persistence/quickstart.md`.

## Checklist chất lượng trước khi implement

- [x] Không còn task ví dụ hoặc placeholder trong output cuối.
- [x] Toàn bộ task được đánh số tuần tự từ T001 đến T051.
- [x] Mỗi task có path cụ thể hoặc command cụ thể.
- [x] Task sửa file có sẵn nêu rõ class/method/endpoint/config cần sửa.
- [x] Task phụ thuộc task khác được thể hiện trong Dependencies hoặc mô tả task.
- [x] Mỗi user story có Independent Test và Definition of Done tương ứng.
- [x] Mỗi FR P1/P2, business/security rule và risk chính có task.
- [x] Migration, contract, permission, observability, rollout/rollback và compatibility có task.
- [x] Task `[P]` không đánh dấu các task cùng sửa một file hoặc có dependency.
