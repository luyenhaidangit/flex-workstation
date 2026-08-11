# Tasks: Chat AI cơ bản

**Đầu vào**: Design documents từ `specs/000032-ai-chat-basics/`

**Điều kiện tiên quyết**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/chat-summary-api.md`, `quickstart.md`.

**Tests**: Test Gate bắt buộc. Các test được viết trước implementation của user story tương ứng và phải fail trước khi feature code hoàn chỉnh.

**Tổ chức**: Task được nhóm theo user story để từng increment có thể kiểm tra độc lập.

## Phase 1: Setup

**Mục đích**: Tạo application boundary tối thiểu, khớp solution .NET 9 hiện có.

- [x] T001 Tạo project `Flex.Agent.Application` target `net9.0` trong `flex-agent-service/src/Flex.Agent.Application/Flex.Agent.Application.csproj` với nullable và implicit usings được bật.
- [x] T002 Thêm project `Flex.Agent.Application` vào `flex-agent-service/Flex.Agent.sln` trong solution folder `src` (phụ thuộc T001).
- [x] T003 Khai báo project reference từ API và Infrastructure đến Application trong `flex-agent-service/src/Flex.Agent.Api/Flex.Agent.Api.csproj` và `flex-agent-service/src/Flex.Agent.Infrastructures/Flex.Agent.Infrastructures.csproj` (phụ thuộc T001).
- [x] T004 Khai báo project reference trực tiếp đến Application cho test project trong `flex-agent-service/tests/Flex.Agent.Tests/Flex.Agent.Tests.csproj` (phụ thuộc T001).

---

## Phase 2: Foundational

**Mục đích**: Hoàn tất contract nội bộ và configuration dùng chung trước mọi user story.

**CRITICAL**: Hoàn tất phase này trước Phase 3 và Phase 4.

- [x] T005 [P] Tạo port `IChatModelClient` cùng record provider-agnostic `ChatRequest` và `ChatResponse` trong `flex-agent-service/src/Flex.Agent.Application/AI/IChatModelClient.cs`, `flex-agent-service/src/Flex.Agent.Application/AI/ChatRequest.cs` và `flex-agent-service/src/Flex.Agent.Application/AI/ChatResponse.cs` theo `data-model.md`.
- [x] T006 [P] Tạo các exception application cho timeout, provider unavailable và response không hợp lệ trong `flex-agent-service/src/Flex.Agent.Application/AI/ChatModelExceptions.cs` để API không phụ thuộc exception/DTO của provider.
- [x] T007 Tạo `OllamaOptions` gồm endpoint, model và timeout trong `flex-agent-service/src/Flex.Agent.Infrastructures/AI/OllamaOptions.cs`; không đặt credential hay endpoint production trong source (phụ thuộc T003).

**Checkpoint**: Application port và configuration model đã compile; implementation có thể đi theo từng story.

---

## Phase 3: User Story 1 — Tóm tắt hội thoại (Priority: P1) MVP

**Goal**: Người dùng đã xác thực gửi hội thoại hợp lệ và nhận summary; các lỗi downstream được chuẩn hóa, không lộ nội dung nhạy cảm.

**Independent Test**:

1. Với fake `IChatModelClient`, gửi request hợp lệ tới `POST /api/v1/ai/chat/summarize` bằng JWT test và nhận HTTP 200 có `summary` không rỗng.
2. Mô phỏng unavailable, timeout và payload rỗng từ client để nhận lần lượt 503, 504 và 502 theo contract.
3. Kiểm tra log chỉ có metadata duration/outcome, không có conversation, summary, prompt, bearer token hay body provider.

### Tests for User Story 1

- [x] T008 [P] [US1] Viết test cho success, `ChatResponse` rỗng và exception từ provider của `ConversationSummaryService` trong `flex-agent-service/tests/Flex.Agent.Tests/AI/ConversationSummaryServiceTests.cs` theo BR-002/BR-003 (phụ thuộc T005, T006).
- [x] T009 [P] [US1] Viết test `HttpMessageHandler` cho serialization request OpenAI-compatible, response hợp lệ, 5xx, timeout và payload lỗi của `OllamaChatModelClient` trong `flex-agent-service/tests/Flex.Agent.Tests/AI/OllamaChatModelClientTests.cs` theo FR-003/NFR-001 (phụ thuộc T005, T006, T007).
- [x] T010 [US1] Viết integration/contract test cho 200, 401, 502, 503 và 504 của `POST /api/v1/ai/chat/summarize` trong `flex-agent-service/tests/Flex.Agent.Tests/AI/AIControllerIntegrationTests.cs` theo `contracts/chat-summary-api.md` (phụ thuộc T004, T005, T006).

### Implementation for User Story 1

- [x] T011 [US1] Implement `ConversationSummaryService` trong `flex-agent-service/src/Flex.Agent.Application/AI/ConversationSummaryService.cs`: tạo instruction tóm tắt nội bộ, gọi `IChatModelClient.ChatAsync` với `CancellationToken`, chỉ chấp nhận summary không rỗng và không retry downstream (phụ thuộc T005, T006, T008).
- [x] T012 [US1] Implement `OllamaChatModelClient` trong `flex-agent-service/src/Flex.Agent.Infrastructures/AI/OllamaChatModelClient.cs`: map contract application sang `/v1/chat/completions`, áp timeout/configuration, propagate cancellation và map 5xx/timeout/payload lỗi sang exception application (phụ thuộc T005, T006, T007, T009).
- [x] T013 [P] [US1] Tạo `ConversationSummaryRequest` và `ConversationSummaryResponse` trong `flex-agent-service/src/Flex.Agent.Api/DTOs/ConversationSummaryDtos.cs` đúng schema public tại `contracts/chat-summary-api.md`.
- [x] T014 [US1] Đăng ký `OllamaOptions`, typed `HttpClient`, `IChatModelClient` và `ConversationSummaryService` trong method `AddInfrastructure` của `flex-agent-service/src/Flex.Agent.Api/Extensions/ServiceExtensions.cs` (phụ thuộc T011, T012).
- [x] T015 [P] [US1] Bổ sung section cấu hình mẫu không nhạy cảm cho endpoint, model `qwen2.5:1.5b` và timeout trong `flex-agent-service/src/Flex.Agent.Api/appsettings.Example.json` (phụ thuộc T007).
- [x] T016 [US1] Thay MVC placeholder bằng `[ApiController]`, `[Authorize]` và action `POST /api/v1/ai/chat/summarize` trong `flex-agent-service/src/Flex.Agent.Api/Controllers/AIController.cs`; map exception application sang error code/status 502/503/504 theo contract (phụ thuộc T011, T013, T014, T010).
- [x] T017 [US1] Thêm structured log thành công/thất bại an toàn trong `flex-agent-service/src/Flex.Agent.Application/AI/ConversationSummaryService.cs` với `traceId`, provider, model, duration và `failureKind`; cấm log conversation, summary, prompt hoặc HTTP body (phụ thuộc T011).
- [x] T018 [US1] Chạy `dotnet test Flex.Agent.sln --configuration Release --filter FullyQualifiedName~AI` tại `flex-agent-service/` và xử lý toàn bộ failure của US-001 (phụ thuộc T008, T009, T010, T016, T017).

**Checkpoint**: User Story 1 có thể test độc lập qua fake provider và endpoint authenticated, không cần Ollama thật.

---

## Phase 4: User Story 2 — Nhận phản hồi khi dữ liệu đầu vào không hợp lệ (Priority: P2)

**Goal**: Người dùng nhận hướng dẫn tức thì khi conversation rỗng; provider không bị gọi.

**Independent Test**:

1. Gửi `conversation` rỗng hoặc chỉ có khoảng trắng bằng JWT test.
2. Nhận HTTP 400 và code `AI_CONVERSATION_REQUIRED`.
3. Fake `IChatModelClient` xác nhận không có invocation.

### Tests for User Story 2

- [x] T019 [US2] Bổ sung test empty/whitespace input và assertion fake client không được gọi trong `flex-agent-service/tests/Flex.Agent.Tests/AI/ConversationSummaryServiceTests.cs` theo AC-003/BR-001 (phụ thuộc T008).
- [x] T020 [US2] Bổ sung integration/contract test HTTP 400 và code `AI_CONVERSATION_REQUIRED` trong `flex-agent-service/tests/Flex.Agent.Tests/AI/AIControllerIntegrationTests.cs` theo AC-003 (phụ thuộc T010).

### Implementation for User Story 2

- [x] T021 [US2] Thêm validation trim input trong `ConversationSummaryService` tại `flex-agent-service/src/Flex.Agent.Application/AI/ConversationSummaryService.cs` để từ chối conversation rỗng trước lời gọi `IChatModelClient` (phụ thuộc T011, T019).
- [x] T022 [US2] Ánh xạ validation error thành HTTP 400/code `AI_CONVERSATION_REQUIRED` trong action summarize của `flex-agent-service/src/Flex.Agent.Api/Controllers/AIController.cs` (phụ thuộc T016, T020, T021).
- [x] T023 [US2] Chạy `dotnet test Flex.Agent.sln --configuration Release --filter FullyQualifiedName~AI` tại `flex-agent-service/` và xác nhận toàn bộ case US-002 pass (phụ thuộc T019, T020, T022).

**Checkpoint**: Cả success path và input validation hoạt động độc lập qua test/fake provider.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Mục đích**: Xác minh security, observability, rollout và regression theo plan.

- [x] T024 Review `AIController`, `ConversationSummaryService` và `OllamaChatModelClient` trong `flex-agent-service/src/Flex.Agent.Api/Controllers/AIController.cs`, `flex-agent-service/src/Flex.Agent.Application/AI/ConversationSummaryService.cs` và `flex-agent-service/src/Flex.Agent.Infrastructures/AI/OllamaChatModelClient.cs` để xác nhận error response/log không chứa conversation, summary, prompt, token, secret hay upstream body (phụ thuộc T017, T022).
- [x] T025 Chạy `dotnet build Flex.Agent.sln --configuration Release`, `dotnet test Flex.Agent.sln --configuration Release` và `git diff --check` tại `flex-agent-service/`; ghi nhận rõ các lệnh pass/fail và test còn không thực hiện (phụ thuộc T018, T023).
- [ ] T026 Thực hiện smoke test success, empty input và provider unavailable theo `specs/000032-ai-chat-basics/quickstart.md` với Ollama/Qwen đã healthy; kiểm tra log metadata và latency/error/timeout trong 30 phút đầu (phụ thuộc T025).

---

## Dependencies & Execution Order

```text
Setup (T001–T004)
  → Foundation (T005–T007)
    → US1 tests (T008–T010)
      → US1 implementation (T011–T017)
        → US1 validation (T018)
          → US2 tests/implementation/validation (T019–T023)
            → Polish & rollout validation (T024–T026)
```

- US-002 phụ thuộc US-001 vì cùng service/controller và bổ sung rule validation cho endpoint đã được thiết lập.
- Không có migration/schema task vì `data-model.md` xác nhận feature không persistence.

## Parallel Opportunities

- Sau T001: T002 và T004 có thể chạy song song; T003 cần completion T001.
- Sau foundation: T005 và T006 song song; sau đó T007.
- Trong US-001: T008, T009 và T010 có thể được viết song song; T013 và T015 có thể chạy song song với phần implementation không đụng file.
- Không parallel các task cùng sửa `ConversationSummaryService.cs`, `AIController.cs`, `ServiceExtensions.cs` hoặc cùng test file.

## Implementation Strategy

1. Hoàn tất Setup/Foundation để project graph, port và error taxonomy compile.
2. Deliver US-001 với fake provider trước; chứng minh HTTP contract/error mapping không cần hạ tầng Ollama.
3. Bổ sung US-002 để chặn invalid input trước downstream call.
4. Chỉ sau automated validation mới dùng Ollama/Qwen thật cho smoke check.

## Validation Commands

- Build backend: `dotnet build Flex.Agent.sln --configuration Release` tại `flex-agent-service/`.
- Run tests: `dotnet test Flex.Agent.sln --configuration Release` tại `flex-agent-service/`.
- Run AI tests: `dotnet test Flex.Agent.sln --configuration Release --filter FullyQualifiedName~AI` tại `flex-agent-service/`.
- Contract/API checks: chạy test trong `tests/Flex.Agent.Tests/AI/AIControllerIntegrationTests.cs`.
- Migration: Không áp dụng — feature không có schema/persistence.
- Smoke: theo `specs/000032-ai-chat-basics/quickstart.md`.

## Traceability Matrix

| Source | Covered by tasks |
|--------|------------------|
| US-001 / AC-001 | T008–T018 |
| US-001 / AC-002 | T009, T010, T012, T016, T018 |
| US-002 / AC-003 | T019–T023 |
| FR-001 | T010, T013, T016, T018 |
| FR-002 / BR-002 | T008, T011, T012, T016 |
| FR-003 | T006, T009, T012, T016 |
| FR-004 | T005, T011, T012, T014 |
| FR-005 / BR-001 | T019, T020, T021, T022 |
| BR-003 | T008, T011, T017 |
| SEC-001 / SEC-002 | T010, T016, T024 |
| NFR-001 / NFR-003 | T009, T012, T017, T024, T026 |

## Checklist chất lượng

- [x] Mọi task có checkbox, ID tuần tự và path hoặc command cụ thể.
- [x] Mọi user story có phase và independent test riêng.
- [x] Test task phủ contract, validation, authorization, timeout, provider failure và rủi ro dữ liệu nhạy cảm trong log.
- [x] Không có task migration/schema vì feature không persistence.
- [x] Dependencies và cơ hội parallel đã được chỉ rõ.
- [x] Không còn placeholder/template task trong danh sách.

