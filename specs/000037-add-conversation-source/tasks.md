# Tasks: Phân loại nguồn hội thoại

**Đầu vào**: `spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/conversation-contract.md`, `quickstart.md`

**Mục tiêu MVP**: Tạo conversation mới với source hợp lệ, lưu source trong `public.conversation`, trả source trong API và giữ an toàn cho conversation lịch sử.

## Phase 1: Setup

**Mục đích**: Xác nhận baseline repo, migration release và các test path trước khi sửa.

- [x] T001 [P] Ghi nhận baseline migration `flex-database/agentdb/migrations/V1.3__create_chat_conversation_message.sql`, changelog release hiện tại và test commands trong `specs/000037-add-conversation-source/quickstart.md` (FR-001, NFR-002)
- [x] T002 [P] Xác nhận `flex-agent-service/src/Flex.Agent.Api/Controllers/ConversationsController.cs` là ingress hiện tại của FE và ghi mapping `Production` trong `specs/000037-add-conversation-source/research.md` (BR-002)

## Phase 2: Foundational (Blocking Prerequisites)

**Mục đích**: Hoàn tất enum, persistence schema và command context dùng chung cho cả hai user story.

- [x] T003 [P] Tạo enum `ConversationSource` với mã cố định `Production=1`, `Preview=2`, `Playground=3`, `Api=4` trong `flex-agent-service/src/Flex.Agent.Domain/Conversations/ConversationSource.cs` (FR-002, BR-001..BR-005)
- [x] T004 [P] Gộp column nullable `conversation_source` và check constraint `NULL` hoặc `1..4` vào `flex-database/agentdb/migrations/V1.3__create_chat_conversation_message.sql` (FR-002, FR-006)
- [x] T005 Cập nhật Liquibase changelog release `1.3.0` để tạo bảng và source trong một changeset (phụ thuộc T004; Constitution VI)
- [x] T006 [P] Thêm `ConversationSource` vào `CreateConversationCommand` hoặc trusted creation context trong `flex-agent-service/src/Flex.Agent.Application/Conversations/ConversationContracts.cs`, không thêm source tùy ý vào request client (FR-001, FR-003, SEC-002)
- [x] T007 [P] Map enum nullable/required và column name `conversation_source` trong `flex-agent-service/src/Flex.Agent.Infrastructures/Persistence/AppDbContext.cs` (phụ thuộc T003, T004; FR-001, FR-006)

## Phase 3: User Story 1 — Phân loại hội thoại khi khởi tạo (P1) — MVP

**Mục tiêu**: Mỗi conversation mới nhận đúng source từ trusted ingress và giữ source bất biến.

**Independent Test**:

1. Tạo conversation qua ingress hiện tại và các test context cho bốn mã.
2. Đọc row và response để xác nhận source đúng, ngoài enum bị từ chối.
3. Gửi lại cùng thao tác và xác nhận không có source mâu thuẫn hoặc conversation trùng.

### Tests for User Story 1

- [x] T008 [P] [US1] Viết unit tests cho mã hợp lệ, mã ngoài `1..4` và source bất biến trong `flex-agent-service/tests/Flex.Agent.Tests/Conversations/ConversationSourceTests.cs` (FR-002, FR-005, BR-006)
- [x] T009 [P] [US1] Mở rộng repository tests xác nhận create lưu đủ bốn source và retry không đổi source trong `flex-agent-service/tests/Flex.Agent.Tests/Conversations/ConversationRepositoryTests.cs` (AC-001..AC-003, NFR-001)
- [x] T010 [P] [US1] Mở rộng controller tests xác nhận current FE ingress gán `Production` và client không thể override source trong `flex-agent-service/tests/Flex.Agent.Tests/Conversations/ConversationsControllerTests.cs` (FR-003, SEC-002)

### Implementation for User Story 1

- [x] T011 [US1] Thêm thuộc tính nullable `ConversationSource` và invariant bất biến vào constructor/domain state trong `flex-agent-service/src/Flex.Agent.Domain/Conversations/Conversation.cs` (phụ thuộc T003; FR-001, FR-005)
- [x] T012 [US1] Truyền source từ `CreateConversationCommand` vào `Conversation` trong `flex-agent-service/src/Flex.Agent.Infrastructures/Repositories/ConversationRepository.cs` (phụ thuộc T006, T011; AC-001..AC-003)
- [x] T013 [US1] Gán source tại trusted ingress hiện tại và từ chối source client tự khai trong `flex-agent-service/src/Flex.Agent.Api/Controllers/ConversationsController.cs` (phụ thuộc T006, T012; FR-003, SEC-002)
- [x] T014 [US1] Chạy focused tests `dotnet test flex-agent-service/tests/Flex.Agent.Tests/Flex.Agent.Tests.csproj --filter FullyQualifiedName~Conversations` và xác nhận T008–T010 fail trước implementation rồi pass sau implementation (phụ thuộc T008–T013; AC-001..AC-003)

## Phase 4: User Story 2 — Diễn giải dữ liệu hội thoại theo nguồn (P2)

**Mục tiêu**: Consumer có quyền đọc source; conversation lịch sử chưa phân loại vẫn đọc được dưới dạng `null`.

**Dependencies**: US2 phụ thuộc Phase 2 và T011–T013 để có dữ liệu source mới; không phụ thuộc UI mới.

**Independent Test**:

1. Đọc conversation mới và legacy qua API.
2. Xác nhận response có `conversationSource` đúng hoặc `null`.
3. Xác nhận unauthorized/tenant khác không nhận source.

### Tests for User Story 2

- [x] T015 [P] [US2] Thêm test response contract kiểm tra `conversationSource` có mã `1..4` hoặc `null` trong `flex-agent-service/tests/Flex.Agent.Tests/Conversations/ConversationsControllerTests.cs` (AC-004, AC-005, FR-004, FR-006)
- [x] T016 [P] [US2] Thêm repository regression test đọc legacy conversation có source `NULL` mà không gán `Production` trong `flex-agent-service/tests/Flex.Agent.Tests/Conversations/ConversationRepositoryTests.cs` (AC-005, BR-007)
- [x] T017 [P] [US2] Tạo contract/type validation cho field source trong `flex-microfrontend/src/app/core/conversations/conversation.models.ts` và kiểm tra `null`/`1..4` (FR-004, NFR-003)

### Implementation for User Story 2

- [x] T018 [US2] Thêm `ConversationSource` vào `ConversationResponse` và mapper `From` trong `flex-agent-service/src/Flex.Agent.Api/DTOs/ConversationDtos.cs` (phụ thuộc T011, T015; FR-004, contracts/conversation-contract.md)
- [x] T019 [US2] Bảo đảm list conversation trả source nullable mà không đổi tenant filter/order trong `flex-agent-service/src/Flex.Agent.Infrastructures/Repositories/ConversationRepository.cs` (phụ thuộc T007, T016; FR-004, SEC-001)
- [x] T020 [US2] Cập nhật TypeScript `ConversationSource` và thuộc tính nullable trong `flex-microfrontend/src/app/core/conversations/conversation.models.ts` (phụ thuộc T017, T018; contract compatibility)
- [x] T021 [US2] Chạy API/FE contract validation và focused tests cho response source, legacy null và authorization theo `specs/000037-add-conversation-source/quickstart.md` (phụ thuộc T015–T020; AC-004, AC-005)

## Phase 5: Polish & Cross-Cutting Concerns

- [x] T022 [P] Thêm structured logging source code (`traceId`, `tenantId`, `conversationId`, `conversationSource`, `creationIngress`, `result`) và loại trừ message content trong `flex-agent-service/src/Flex.Agent.Api/Controllers/ConversationsController.cs` (NFR-003, Observability Gate)
- [x] T023 [P] Cập nhật migration/contract smoke validation trong `specs/000037-add-conversation-source/quickstart.md` để kiểm tra constraint, old rows `NULL`, invalid source và rollback rehearsal (FR-002, FR-006, Compatibility Gate)
- [x] T024 Chạy `liquibase --changelog-file=changelog/db.changelog-master.xml validate` và `update-sql` tại `flex-database/agentdb`; ghi nhận apply/rollback trên database disposable chưa thực hiện vì chưa có database đích được xác nhận (phụ thuộc T004, T005; Data & Migration Safety)
- [x] T025 Chạy full verification `dotnet test flex-agent-service/tests/Flex.Agent.Tests/Flex.Agent.Tests.csproj`, Angular type/build check tại `flex-microfrontend`, và `rtk git diff --check` (phụ thuộc T014, T021–T024; Release Gate)

## Dependencies & Execution Order

### Dependency graph

```text
T001, T002
   ↓
T003, T004, T006
   ↓
T005, T007
   ↓
T008, T009, T010
   ↓
T011 → T012 → T013 → T014
                       ↓
              T015, T016, T017
                       ↓
              T018, T019, T020 → T021
                       ↓
              T022, T023, T024 → T025
```

### User story completion order

1. Phase 1–2 bắt buộc.
2. US1 (P1) hoàn thành MVP.
3. US2 (P2) triển khai sau US1 vì cần response/source persistence.
4. Phase 5 hoàn thiện cross-cutting và release validation.

## Parallel Opportunities

- T001 và T002 có thể chạy song song.
- T003, T004 và T006 có thể chạy song song vì khác repo/file.
- T008, T009 và T010 có thể viết test song song trước implementation.
- T015, T016 và T017 có thể viết test/contract song song sau foundation.
- T022 và T023 có thể chạy song song sau US2; T024 cần migration hoàn tất.

## Traceability Matrix

| Requirement/Scenario | Tasks |
|---|---|
| US-001, AC-001..AC-003 | T003, T006, T008–T014 |
| US-002, AC-004..AC-005 | T015–T021 |
| FR-001..FR-003 | T003, T006, T007, T011–T014 |
| FR-004..FR-006 | T004, T007, T015–T021, T024 |
| BR-001..BR-007 | T003, T008–T013, T016 |
| SEC-001..SEC-002 | T010, T013, T015, T019, T021 |
| NFR-001..NFR-003 | T009, T014, T017, T022, T025 |
| Migration/compatibility/observability | T004, T005, T023, T024, T025 |

## Validation Commands

- `dotnet test flex-agent-service/tests/Flex.Agent.Tests/Flex.Agent.Tests.csproj --filter FullyQualifiedName~Conversations`
- `dotnet test flex-agent-service/tests/Flex.Agent.Tests/Flex.Agent.Tests.csproj`
- Angular type/build command defined by `flex-microfrontend/package.json` and documented in `quickstart.md`
- Disposable PostgreSQL migration apply/rollback rehearsal for `flex-database/agentdb`
- `rtk git diff --check`

## Implementation Strategy

1. Hoàn thành foundation và migration additive.
2. Deliver US1 trước: source domain → persistence → trusted ingress, đạt MVP.
3. Deliver US2: API/FE response và legacy null compatibility.
4. Hoàn thiện observability, migration rehearsal và full verification.

## Checklist chất lượng

- [x] Mỗi user story có phase, goal và independent test.
- [x] Mọi task có checkbox, ID tuần tự, story label đúng phase và path/command cụ thể.
- [x] Test task bao phủ source mapping, invalid source, spoofing, legacy null, authorization và migration.
- [x] Migration schema và business code được tách task.
- [x] Contract/API consumer và backward compatibility có task.
- [x] Rollout, rollback, observability và smoke validation có task.
- [x] MVP scope là US1; US2 là phase bổ sung.
