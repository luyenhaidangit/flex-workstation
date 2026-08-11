# Tasks: Tích hợp chat AI tại màn Agent

**Đầu vào**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [agent-preview-chat-api.md](contracts/agent-preview-chat-api.md), [quickstart.md](quickstart.md)

**Tests**: Test Gate bắt buộc. Test tự động được viết trước implementation; manual validation bao phủ provider/gateway/browser thực tế mà unit test không thay thế được.

**Tổ chức**: Task được nhóm theo user story để có thể kiểm thử và bàn giao độc lập sau Foundation.

## Phase 1: Setup — Gateway route dùng chung

**Mục đích**: Mở đường đi có xác thực từ FE tới Agent Service trước khi consumer được tạo.

- [ ] T001 Thêm route và cluster mapping `/api/v1/ai/**` đến `agent-service` trong `flex-api-gateway/src/Flex.ApiGateway/yarp.json` theo pattern route `/api/v1/agents/**` hiện có.
- [ ] T002 [P] Thêm route và cluster mapping `/api/v1/ai/**` đến `agent-service` trong `flex-api-gateway/src/Flex.ApiGateway/yarp.Development.json` để local gateway định tuyến preview API.
- [ ] T003 [P] Thêm route và cluster mapping `/api/v1/ai/**` đến `agent-service` trong `flex-environment/mounts/flex-api-gateway/yarp.json` để runtime mount không lệch cấu hình gateway.

**Checkpoint**: Ba cấu hình gateway có route AI additive, không đổi route agents/channels hiện hữu.

---

## Phase 2: Foundational — Không áp dụng

Không có foundation code dùng chung ngoài gateway route: persistence, migration, SignalR command, feature flag và policy mới đều ngoài phạm vi. Mỗi user story sở hữu DTO/use case/UI riêng của nó.

---

## Phase 3: User Story 1 — Gửi câu hỏi để nhận trả lời từ AI Agent (P1)

**Mục tiêu**: Người dùng đã xác thực gửi câu hỏi từ wizard và nhận phản hồi thực của Agent bản nháp, với thứ tự hội thoại và trạng thái pending rõ ràng.

**Independent Test**:

1. Đăng nhập, mở `/agents/create`, nhập name/role/instructions, gửi câu hỏi hợp lệ và xác nhận request qua gateway trả `200` với `reply`.
2. Xác nhận câu hỏi hiển thị ngay, UI khóa gửi trong lúc pending, sau đó reply hiển thị dưới vai trò Agent; gửi lượt thứ hai và xác nhận thứ tự hội thoại.
3. Xác nhận SignalR `SendMessage` và event `message.created` không còn được sử dụng bởi khung preview.

### Tests cho User Story 1

- [ ] T004 [P] [US1] Tạo unit test trước implementation cho validation draft/history, dựng `ChatRequest`, reply rỗng và cancellation deadline trong `flex-agent-service/tests/Flex.Agent.Tests/AI/AgentPreviewChatServiceTests.cs`.
- [ ] T005 [P] [US1] Tạo integration/contract test trước implementation cho `POST /api/v1/ai/chat/preview` success, request invalid và JWT authorization trong `flex-agent-service/tests/Flex.Agent.Tests/AI/AgentPreviewChatControllerIntegrationTests.cs` theo `specs/000033-ai-chat-integration/contracts/agent-preview-chat-api.md`.
- [ ] T006 [P] [US1] Tạo Angular service test trước implementation cho mapping request Agent draft/history và response `reply` trong `flex-microfrontend/src/app/features/agent-catalog/services/agent-preview.service.spec.ts`.

### Implementation cho User Story 1

- [ ] T007 [P] [US1] Tạo interfaces `AgentPreviewContext`, `PreviewMessage`, `AgentPreviewRequest` và `AgentPreviewResponse` trong `flex-microfrontend/src/app/features/agent-catalog/models/agent-preview.model.ts` theo contract preview.
- [ ] T008 [P] [US1] Tạo request/response DTO và validation contract preview trong `flex-agent-service/src/Flex.Agent.Api/DTOs/AgentPreviewChatDtos.cs` cho `agent.name`, `agent.role`, `agent.instructions` và ordered `messages`.
- [ ] T009 [P] [US1] Tạo exception types preview cho invalid request và timeout/error mapping trong `flex-agent-service/src/Flex.Agent.Application/AI/AgentPreviewChatExceptions.cs`.
- [ ] T010 [US1] Implement `AgentPreviewChatService` trong `flex-agent-service/src/Flex.Agent.Application/AI/AgentPreviewChatService.cs`: validate DTO model, tạo system instruction từ draft, chuyển history thành `ChatRequest`, tái sử dụng `IChatModelClient`, hủy request sau 15 giây và không retry downstream (phụ thuộc T004, T008, T009).
- [ ] T011 [US1] Mở endpoint `[HttpPost("chat/preview")]` và map `400 AI_PREVIEW_REQUEST_INVALID`, `502`, `503`, `504` trong `flex-agent-service/src/Flex.Agent.Api/Controllers/AIController.cs` mà không đổi `chat/summarize` (phụ thuộc T005, T010).
- [ ] T012 [US1] Implement `AgentPreviewService` gọi `${environment.apiBaseUrl}/api/v1/ai/chat/preview` và typed response/error mapping trong `flex-microfrontend/src/app/features/agent-catalog/services/agent-preview.service.ts` (phụ thuộc T006, T007, T001, T002, T003).
- [ ] T013 [US1] Thay state và `onSendMessage()` của `AgentCreateWizardComponent` trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.ts` bằng preview session cục bộ: lấy caller profile, build draft/history, optimistic user pending, một request duy nhất và append reply Agent; gỡ subscription/call `directMessages$`/`SendMessage` chỉ dùng cho preview (phụ thuộc T011, T012).
- [ ] T014 [US1] Thay dropdown “Người nhận”, copy direct-message và binding preview trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.html` bằng caller hiện tại, empty state AI, pending indicator và send disable (phụ thuộc T013).
- [ ] T015 [US1] Bổ sung style cho pending bubble/typing indicator và trạng thái gửi bị khóa trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.scss` (phụ thuộc T014).
- [ ] T016 [US1] Thực hiện kịch bản success và multi-turn mục “Luồng thành công” trong `specs/000033-ai-chat-integration/quickstart.md`, ghi kết quả/manual evidence vào phần checklist thực thi của chính file đó (phụ thuộc T001–T015).

**Definition of Done**:

- Contract 200 và validation request đã pass test.
- Wizard chỉ hiển thị response từ preview API là Agent; không còn tin direct-message lẫn vào.
- Một câu hỏi pending không thể được gửi trùng và history nhiều lượt đúng thứ tự.

---

## Phase 4: User Story 2 — Nhận biết Agent chưa sẵn sàng hoặc xảy ra lỗi (P2)

**Mục tiêu**: Khi provider/Agent Service không sẵn sàng, timeout hoặc trả response không dùng được, người dùng nhận lỗi dễ hiểu, không có reply giả và có thể thử lại mà không mất history.

**Independent Test**:

1. Dùng fake client trả unavailable, invalid response và timeout; xác nhận API trả lần lượt 503, 502, 504 theo contract.
2. Trên wizard, xác nhận lỗi giữ nguyên câu hỏi/history, không tạo bubble Agent và retry gửi lại chính xác sau khi lỗi.

### Tests cho User Story 2

- [ ] T017 [P] [US2] Tạo integration test trước implementation cho mapping `AI_RESPONSE_INVALID`, `AI_SERVICE_UNAVAILABLE`, `AI_REQUEST_TIMEOUT` và không echo chat content trong `flex-agent-service/tests/Flex.Agent.Tests/AI/AgentPreviewChatErrorIntegrationTests.cs`.
- [ ] T018 [P] [US2] Tạo component test trước implementation cho pending-to-error, giữ history, retry và reset preview session trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.spec.ts`.

### Implementation cho User Story 2

- [ ] T019 [US2] Hoàn thiện nhánh failure/retry/cancellation và thông điệp lỗi thân thiện trong `AgentCreateWizardComponent` tại `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.ts`; chỉ mở lại send sau terminal result và không nhân bản user message khi retry (phụ thuộc T013, T017, T018).
- [ ] T020 [US2] Thêm vùng lỗi có thao tác thử lại, trạng thái Agent chưa sẵn sàng và reset session giữ đúng accessibility/binding trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.html` (phụ thuộc T014, T019).
- [ ] T021 [US2] Thực hiện các kịch bản unavailable, timeout, input rỗng và quyền truy cập trong `specs/000033-ai-chat-integration/quickstart.md`, ghi kết quả/manual evidence và lý do các case provider thực không tự động hóa được (phụ thuộc T017–T020).

**Definition of Done**:

- 502/503/504 và 401/403 không lộ prompt/history/instructions/reply.
- UI không hiển thị reply giả, không mất history và retry chỉ tạo một request mới sau lỗi.

---

## Phase 5: Polish & cross-cutting concerns

**Mục đích**: Hoàn thiện observability, bảo đảm route/config hợp lệ và xác minh regression/rollout.

- [ ] T022 Bổ sung metadata-only logs `ai.preview.completed` và `ai.preview.failed` với `traceId`, duration, outcome, failureKind và model label; loại trừ content/instructions/reply/token trong `flex-agent-service/src/Flex.Agent.Application/AI/AgentPreviewChatService.cs` (phụ thuộc T010).
- [ ] T023 Tạo test kiểm tra preview telemetry/error không chứa message, instructions, reply hoặc Authorization data trong `flex-agent-service/tests/Flex.Agent.Tests/AI/AgentPreviewChatTelemetryTests.cs` (phụ thuộc T022).
- [ ] T024 Chạy `dotnet test Flex.Agent.sln`, `dotnet build Flex.ApiGateway.sln`, `npm run build`, và `npm test -- --watch=false --browsers=ChromeHeadless` từ các repo tương ứng; ghi pass/fail và command output tóm tắt vào `specs/000033-ai-chat-integration/quickstart.md` (phụ thuộc T001–T023).
- [ ] T025 Thực hiện smoke qua gateway bằng JWT, kiểm tra route không ảnh hưởng `/api/v1/agents/**`/`/api/v1/channels/**`, và ghi rollout/rollback evidence vào `specs/000033-ai-chat-integration/quickstart.md` (phụ thuộc T024).

---

## Dependencies & thứ tự thực hiện

```text
T001, T002, T003 (gateway route)
        └─ T012 (FE preview HTTP service)

T004, T005, T006, T007, T008, T009 (test/model/DTO độc lập)
        └─ T010 (BE use case) → T011 (API) → T013 (wizard state) → T014 → T015 → T016
        └─ T012 ───────────────────────────────┘

T017, T018 → T019 → T020 → T021
T010 → T022 → T023
T001–T023 → T024 → T025
```

### User story dependencies

- **US-001 (P1)**: Bắt đầu sau T001–T003; là MVP hoàn chỉnh.
- **US-002 (P2)**: Dùng flow preview của US-001, bắt đầu sau T013/T014; không có persistence hoặc migration dependency.

## Parallel opportunities

- T001, T002 và T003 có thể cùng thực hiện vì chạm các config file khác nhau.
- T004–T009 có thể thực hiện song song theo file riêng; T010 chỉ bắt đầu khi DTO/exception/test BE cần thiết sẵn sàng.
- T017 và T018 có thể thực hiện song song; T019/T020 phải tuần tự vì cùng wizard state/template.
- T022 và work FE US-2 có thể thực hiện song song sau khi T010/T013 hoàn tất, vì chạm file khác nhau.

## Validation commands

- Backend test: `dotnet test Flex.Agent.sln` (workdir `flex-agent-service`)
- Backend build: `dotnet build Flex.Agent.sln` (workdir `flex-agent-service`)
- Gateway build: `dotnet build Flex.ApiGateway.sln` (workdir `flex-api-gateway`)
- Frontend build: `npm run build` (workdir `flex-microfrontend`)
- Frontend test: `npm test -- --watch=false --browsers=ChromeHeadless` (workdir `flex-microfrontend`)
- Manual/gateway smoke: thực hiện theo [quickstart.md](quickstart.md), vì cần JWT và AI provider của môi trường.

## Traceability matrix

| Source | Covered by tasks |
|---|---|
| US-001 / AC-001, AC-003, AC-004 | T004–T016 |
| FR-001, FR-002 | T010–T014 |
| FR-003 | T007, T013–T015 |
| FR-004 / AC-002 | T013–T016, T018 |
| US-002 / AC-005, AC-006 | T017–T021 |
| FR-005, FR-006, FR-007 | T017–T021 |
| BR-001 đến BR-004 | T010, T013, T014, T019, T020 |
| SEC-001, SEC-002 | T005, T011, T017, T023, T025 |
| NFR-001 | T004, T010, T017, T021, T024 |
| NFR-002, NFR-003 | T014–T016, T024, T025 |
| Rollout/rollback/observability | T001–T003, T022–T025 |

## Implementation strategy

### MVP first

1. Hoàn thành gateway route T001–T003.
2. Hoàn thành US-001 T004–T016.
3. Dừng và xác minh độc lập một phiên hỏi–đáp nhiều lượt qua gateway.

### Incremental delivery

1. Deliver US-001 để thay direct chat bằng preview AI thực.
2. Deliver US-002 để hoàn thiện unavailable/timeout/error/retry.
3. Hoàn tất telemetry, regression và rollout smoke qua Phase 5.

## Checklist chất lượng trước khi implement

- [x] Không còn task ví dụ hoặc placeholder.
- [x] Task ID tuần tự từ T001 đến T025; mọi task có path hoặc command cụ thể.
- [x] Mỗi user story có independent test và definition of done.
- [x] P1/P2, contract, permission, observability, rollout/rollback và test strategy đã map vào task.
- [x] Không có migration/schema task vì `data-model.md` xác định không persistence.
- [x] Task `[P]` không sửa cùng file và không phụ thuộc nhau.
