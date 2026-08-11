# Kế hoạch triển khai: Chat AI cơ bản

**Branch**: `000032-ai-chat-basics` | **Ngày**: 2026-08-11 | **Đặc tả**: [spec.md](spec.md)

**Đầu vào**: Đặc tả tính năng từ [spec.md](spec.md).

## Tóm tắt

**Yêu cầu chính từ spec**: Người dùng đã đăng nhập gửi một hội thoại để tóm tắt, nhận bản tóm tắt hoặc lỗi có thể hành động; luồng nghiệp vụ không phụ thuộc vào dịch vụ mô hình nền.

**Hướng tiếp cận kỹ thuật dự kiến**: Bổ sung một vertical slice `POST /api/v1/ai/chat/summarize` vào `flex-agent-service`. `AIController` chỉ là HTTP boundary; use case `ConversationSummaryService` gọi port `IChatModelClient`; infrastructure cung cấp `OllamaChatModelClient` qua typed `HttpClient`. Cấu hình giữ base URL, model và timeout ngoài source để thay provider mà không sửa use case.

**Kết quả sau research**: Ollama hỗ trợ phần tương thích OpenAI cho chat completions, nên client đầu tiên dùng contract chat chuẩn hóa thay vì contract Ollama riêng. Repository đã có .NET 9, JWT auth, `AddHttpClient` và test xUnit; `AIController` hiện chỉ là MVC placeholder. Không có dữ liệu bền hoặc migration trong MVP này.

## Phạm vi kỹ thuật

**Trong phạm vi**:

- `flex-agent-service`: thêm project `Flex.Agent.Application` cho use case, port AI và model contract nội bộ.
- Chuyển `AIController` thành authenticated API controller; expose duy nhất endpoint tóm tắt hội thoại.
- Thêm `OllamaChatModelClient`, typed `HttpClient`, options cấu hình và ánh xạ lỗi provider an toàn.
- Thêm test unit/integration-controller và contract test cho payload HTTP nội bộ.
- Cập nhật sample configuration và quickstart; không đưa URL có credential hoặc secret vào source.

**Ngoài phạm vi kỹ thuật**:

- UI, lưu lịch sử, streaming, chat nhiều lượt, tệp đính kèm, RAG và tool calling.
- Migration/schema, audit persistence, queue/worker, retry tự động và thay đổi `flex-environment`.
- Tích hợp OpenAI/Azure OpenAI/vLLM thật; thiết kế port là điều kiện để thêm provider sau này.

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: C# / .NET 9 (`net9.0`).

**Service/App liên quan**: `flex-agent-service`, project `Flex.Agent.Api`, `Flex.Agent.Domain`, `Flex.Agent.Infrastructures`, test project `Flex.Agent.Tests`; hạ tầng Ollama đã được khôi phục bởi feature `000027-restore-ollama-core`.

**Convention skill áp dụng**: `flex-dotnet-engineering`, `flex-naming-convention`.

**Phụ thuộc chính**: ASP.NET Core Controllers/JWT hiện hữu, `IHttpClientFactory`, Ollama OpenAI-compatible chat endpoint; không thêm SDK provider trong MVP.

**Lưu trữ**: Không áp dụng — yêu cầu và kết quả chỉ tồn tại trong vòng đời HTTP response.

**Kiểm thử**: xUnit, `Microsoft.AspNetCore.Mvc.Testing`, unit test use case/client và integration test controller với handler giả.

**Nền tảng chạy**: ASP.NET Core service trong container hoặc local development; Ollama là dịch vụ nội bộ đã có trong `flex-environment`.

**Đơn vị deploy**: `flex-agent-service`.

**Loại project**: Web API đa tenant.

**Mục tiêu hiệu năng**: 95% yêu cầu phải hoàn tất hoặc trả lỗi rõ ràng trong 30 giây theo NFR-001/SC-001.

**Ràng buộc**: Không log nội dung hội thoại, prompt đầy đủ, response AI, authorization header hoặc cấu hình nhạy cảm. Request bị hủy phải hủy downstream call; không tự retry để tránh kéo dài request và tạo output không xác định.

**Quy mô/Phạm vi**: Một endpoint và một use case P1/P2; một provider Ollama đầu tiên; không có state chia sẻ.

## Kiểm tra constitution

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| Scope Gate | Pass | Pass | Chỉ tóm tắt một lần; loại trừ storage, streaming và provider bổ sung. |
| Traceability Gate | Pass | Pass | US/FR P1/P2 được map tới endpoint, application port, client và test. |
| Test Gate | Pass | Pass | Có unit, controller integration, provider contract và smoke guide. |
| Security Gate | Pass | Pass | JWT bắt buộc; content không được log; lỗi provider được chuẩn hóa. |
| Compatibility Gate | Pass | Pass | Endpoint mới, không đổi contract hiện hữu; provider bị cô lập sau port. |
| Observability Gate | Pass | Pass | Log/metric chỉ chứa metadata và correlation ID. |
| Complexity Gate | Pass | Pass | Một port là cần thiết để cách ly dependency biến động; không thêm mediator/repository/event bus. |
| Database / Migration (Constitution VI) | Không áp dụng | Không áp dụng | Không tạo, sửa hoặc lưu dữ liệu. |

## Câu hỏi kỹ thuật cần research

- **TQ-001 — Đã giải quyết**: Có dùng protocol riêng của Ollama hay OpenAI-compatible chat contract? Chọn OpenAI-compatible chat contract, vì Ollama công bố hỗ trợ `/v1/chat/completions`; port nội bộ vẫn không lộ DTO provider.
- **TQ-002 — Đã giải quyết**: Cách quản lý HTTP client? Chọn typed `HttpClient` qua factory, theo pattern `AddHttpClient` đã tồn tại trong repo; base URL và timeout lấy từ options.
- **TQ-003 — Đã giải quyết**: Có migration hay lịch sử tóm tắt không? Không; MVP trả kết quả đồng bộ và không persistence theo MVP-003/BR-003.
- **TQ-004 — Đã giải quyết**: Có retry khi downstream lỗi không? Không retry trong request. Timeout, cancellation, 5xx và response không hợp lệ được map sang lỗi an toàn để caller chủ động gửi lại.

## Thiết kế tổng quan

**Luồng chính**:

1. Client đã xác thực gửi `POST /api/v1/ai/chat/summarize` với `conversation` không rỗng.
2. `AIController` kiểm tra model binding/authorization rồi gọi `ConversationSummaryService` cùng `CancellationToken` của request.
3. Use case kiểm tra nội dung, xây dựng yêu cầu tóm tắt bằng contract nội bộ và gọi `IChatModelClient.ChatAsync`.
4. `OllamaChatModelClient` chuyển contract nội bộ thành OpenAI-compatible chat request, gọi Ollama qua typed `HttpClient`, kiểm tra status và trích text không rỗng.
5. Use case trả `ConversationSummaryResponse`; controller trả 200. Lỗi validation, timeout, service unavailable hoặc response lỗi được map thành status/code an toàn.

**Component/module tham gia**:

- `Flex.Agent.Api/Controllers/AIController.cs`: HTTP boundary, authorize và HTTP status mapping.
- `Flex.Agent.Application/AI/ConversationSummaryService.cs`: orchestration của use case; không biết Ollama hay `HttpClient`.
- `Flex.Agent.Application/AI/IChatModelClient.cs`: port ổn định cho lời gọi chat.
- `Flex.Agent.Application/AI/ChatRequest.cs`, `ChatResponse.cs`: contract nội bộ provider-agnostic.
- `Flex.Agent.Infrastructures/AI/OllamaChatModelClient.cs`: adapter Ollama duy nhất.
- `Flex.Agent.Api/Extensions/ServiceExtensions.cs`: composition root cho options và typed client.

**Điểm mở rộng/thay đổi chính**:

- `IChatModelClient` là boundary có lý do rõ: chặn DTO/SDK của Ollama lan vào controller/use case và cho phép thêm adapter provider khác mà không sửa business flow.
- `OllamaOptions` gồm endpoint, model và timeout; cấu hình development dùng model đã có `qwen2.5:1.5b` nhưng không hardcode endpoint hoặc secret vào source.
- Chỉ chấp nhận một user message đầu vào cho MVP; use case tự xác định chỉ dẫn tóm tắt, không tin prompt hệ thống do client cung cấp.

**Luồng thay thế/lỗi chính**:

- Conversation rỗng/chỉ khoảng trắng → 400 `AI_CONVERSATION_REQUIRED`.
- JWT không hợp lệ/thiếu → middleware hiện hữu trả 401/403 trước controller.
- Cancellation từ client → dừng downstream request, không cố trả response mới.
- Provider timeout → 504 `AI_REQUEST_TIMEOUT`.
- Provider không sẵn sàng/lỗi 5xx → 503 `AI_SERVICE_UNAVAILABLE`.
- Provider trả payload lỗi hoặc nội dung trống → 502 `AI_RESPONSE_INVALID`.

**Thay đổi boundary giữa service/module**:

- API → Application: DTO HTTP sang use case model.
- Application → Infrastructure: chỉ `IChatModelClient`; không reference DTO/provider SDK.
- Infrastructure → Ollama: HTTP OpenAI-compatible contract có thể thay sau composition root.

**Idempotency/Concurrency**:

- Yêu cầu không có state hay side effect bền nên không cần idempotency key.
- Những request trùng lặp được xử lý độc lập theo BR-003; không cache/gộp request ở MVP.
- Không retry downstream tự động vì kết quả sinh có thể khác giữa các lần gọi.

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|------------|----------------------|---------------------|--------------|-------------|----------|
| US-001 / FR-001 | P1 | Đủ rõ | Authorized controller nhận hội thoại và gọi use case | `src/Flex.Agent.Api/Controllers/AIController.cs` | `POST /api/v1/ai/chat/summarize` | Không lưu | Integration: request hợp lệ → 200 |
| US-001 / FR-002 | P1 | Đủ rõ | Use case + port trả summary text không rỗng | `src/Flex.Agent.Application/AI/*` | `ConversationSummaryResponse` | `ChatResponse` transient | Unit: success/empty response |
| US-001 / FR-003 | P1 | Đủ rõ | Adapter phân loại timeout/upstream/invalid response; controller map status/code | `src/Flex.Agent.Infrastructures/AI/*`, controller | Error payload chuẩn | Không áp dụng | Unit + integration: 502/503/504 |
| US-001 / FR-004 | P1 | Đủ rõ | Mọi dependency provider chỉ sau `IChatModelClient`; registration là điểm thay adapter | Application + `ServiceExtensions.cs` | Internal port | Không áp dụng | Architecture/unit test with fake client |
| US-002 / FR-005 | P2 | Đủ rõ | Validate conversation sau trim trước khi gọi provider | `ConversationSummaryService.cs` | 400 `AI_CONVERSATION_REQUIRED` | Không áp dụng | Unit + controller integration |
| SEC-001 / SEC-002 | P1 | Đủ rõ | `[Authorize]`, không echo/lộ content trong lỗi/log | `AIController.cs`, middleware hiện hữu | 401/403 | Không áp dụng | Attribute + unauthenticated integration test |
| NFR-001 / NFR-003 | P1 | Đủ rõ | Bounded timeout, token propagation, safe telemetry | typed client/options | 504 / metadata logs | Không áp dụng | Timeout handler test + log review |

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---------|------------------|--------------------------|---------------|
| Database/Migration | Không áp dụng | Không có persistence hay schema | Không có migration trong diff |
| API/Contract | Thêm endpoint và DTO mới | Additive; consumer mới duy nhất | Contract/integration tests theo `contracts/chat-summary-api.md` |
| Permission/Security | Dùng JWT `[Authorize]` hiện hữu | Rủi ro truy cập khi thiếu attribute | Test anonymous 401 và authorized success |
| Logging/Audit | Thêm log metadata cho success/failure | Rủi ro lộ hội thoại/prompt | Test/review log fields không có content/secret |
| UI/UX | Không áp dụng | Không sửa frontend trong MVP | Smoke bằng HTTP client |
| Job/Worker/Integration | Synchronous call tới Ollama | Timeout/unavailable provider | Fake-handler integration và quickstart Ollama |

## API/Contract Detail

**Có thay đổi contract không**: Có — thêm endpoint HTTP additive; không đổi endpoint hiện hữu.

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|----------|------|----------|---------------------|------------------------|
| `POST /api/v1/ai/chat/summarize` | API | Thêm request `conversation` và response `summary` | Có | Frontend/consumer AI mới |
| `IChatModelClient` | Internal application port | Thêm abstraction provider | Có, không có consumer hiện hữu | `ConversationSummaryService`, adapter provider |

Chi tiết payload/status/error code nằm tại [contracts/chat-summary-api.md](contracts/chat-summary-api.md).

## Permission Matrix

| Vai trò/Scope | Xem | Tạo | Sửa | Xóa | Duyệt/Xử lý | Ghi chú |
|---------------|-----|-----|-----|-----|-------------|---------|
| Người dùng đã xác thực | Có (response của request hiện tại) | Có (gửi yêu cầu) | Không | Không | Có (yêu cầu tóm tắt) | Không lưu lịch sử/kết quả |
| Người chưa xác thực | Không | Không | Không | Không | Không | Middleware JWT chặn trước controller |

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Không áp dụng.

**Database đích**: Không áp dụng — request/response chỉ in-memory trong vòng đời HTTP.

**Repo chứa migration**: Không áp dụng — không có migration; Constitution VI đã được đánh giá.

**Migration**:
- Không áp dụng.

**Backfill/Cleanup**:
- Không áp dụng.

**Tương thích dữ liệu cũ**:
- Không áp dụng.

**Rủi ro dữ liệu**:
- Không lưu dữ liệu. Rủi ro là lộ nội dung hội thoại qua telemetry, được giảm bằng danh sách field log cấm.

**Cách xác minh**:
- Xác nhận diff không chứa DbContext/entity/migration; kiểm tra log của smoke test không có nội dung gửi lên.

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| DEC-001 | Port `IChatModelClient` trong project Application và adapter `OllamaChatModelClient` trong Infrastructure | Cô lập vendor volatility, giữ business layer testable và đáp ứng yêu cầu đổi provider không sửa use case | Gọi Ollama trực tiếp từ controller/service | Coupling bị rải rác, thay provider phải sửa nhiều nơi |
| DEC-002 | Thêm project `Flex.Agent.Application` mỏng | Repository chưa có application boundary; use case và port là boundary thực, không phải abstraction chỉ dùng một lần | Đặt use case/provider port trong controller hoặc Domain | Controller sẽ ôm business policy; Domain không nên phụ thuộc integration port |
| DEC-003 | Typed `HttpClient`, options configuration và OpenAI-compatible chat request | Khớp `AddHttpClient` hiện hữu; endpoint/model/timeout có thể thay bằng config | Static `HttpClient`, SDK Ollama-specific hoặc provider call rải rác | Quản lý lifetime kém, lock-in hoặc vi phạm boundary |
| DEC-004 | `POST /api/v1/ai/chat/summarize` và DTO tóm tắt chuyên biệt | Chính xác scope MVP, không mở public generic chat API trước khi có use case | Generic `/chat` cho mọi tác vụ | Mở rộng contract ngoài scope và khó xác định chính sách prompt |
| DEC-005 | Không retry tự động; deadline 30 giây | Giữ semantic dễ hiểu, giảm tải và không tạo nhiều bản tóm tắt không xác định | Retry backoff trong HTTP request | Không cần thiết với request không bền và tăng latency |

## Chiến lược kiểm thử

**Unit test**:

- `ConversationSummaryService`: trim/validate input, tạo request, success, response rỗng và lỗi port.
- `OllamaChatModelClient`: serializes request tối thiểu, đọc summary, maps non-success/malformed response/timeout.

**Integration test**:

- `AIController` qua `WebApplicationFactory` với `IChatModelClient` fake: 200 hợp lệ, 400 input rỗng, 401 anonymous, 502/503/504 cho lỗi adapter đã chuẩn hóa.

**Contract test**:

- Kiểm tra request/response/error JSON của API công khai khớp [contracts/chat-summary-api.md](contracts/chat-summary-api.md).
- Kiểm tra handler giả nhận OpenAI-compatible request đúng model/messages, không cần gọi Ollama trong CI.

**Permission/security test**:

- Xác nhận `AIController` có `[ApiController]`, `[Authorize]`; anonymous không vào được use case.
- Review telemetry/exception response không echo `conversation`, prompt hay headers nhạy cảm.

**E2E/manual test**:

- Theo [quickstart.md](quickstart.md), chạy hạ tầng đã có Ollama/Qwen, gửi hội thoại mẫu và kiểm tra 200; dừng Ollama để kiểm tra lỗi an toàn.

**Regression test**:

- `dotnet test Flex.Agent.sln`, build Release solution, và xác nhận `AgentsController`, SignalR và channel tests vẫn pass.

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/000032-ai-chat-basics/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── contracts/
    └── chat-summary-api.md
```

### Source code (repository root)

```text
flex-agent-service/
├── Flex.Agent.sln                                      # [MODIFY] thêm Application project
├── src/
│   ├── Flex.Agent.Api/
│   │   ├── Controllers/AIController.cs                  # [MODIFY]
│   │   ├── DTOs/ConversationSummaryDtos.cs              # [ADD]
│   │   ├── Extensions/ServiceExtensions.cs              # [MODIFY]
│   │   └── appsettings.Example.json                     # [MODIFY]
│   ├── Flex.Agent.Application/
│   │   ├── Flex.Agent.Application.csproj                # [ADD]
│   │   └── AI/
│   │       ├── IChatModelClient.cs                      # [ADD]
│   │       ├── ChatRequest.cs                           # [ADD]
│   │       ├── ChatResponse.cs                          # [ADD]
│   │       ├── ConversationSummaryService.cs            # [ADD]
│   │       └── ChatModelExceptions.cs                   # [ADD]
│   └── Flex.Agent.Infrastructures/
│       └── AI/
│           ├── OllamaChatModelClient.cs                 # [ADD]
│           └── OllamaOptions.cs                         # [ADD]
└── tests/
    └── Flex.Agent.Tests/
        └── AI/
            ├── ConversationSummaryServiceTests.cs       # [ADD]
            ├── OllamaChatModelClientTests.cs            # [ADD]
            └── AIControllerIntegrationTests.cs          # [ADD]
```

**Quyết định cấu trúc**: `Flex.Agent.Application` chỉ chứa policy/use case và port. `Flex.Agent.Infrastructures` thực thi port bằng HTTP. API là composition root; Domain và database không bị chạm.

## Rollout & Rollback

**Kế hoạch rollout**:

1. Cấu hình endpoint/model/timeout cho môi trường đích bằng secret/configuration store; không commit giá trị nhạy cảm.
2. Deploy `flex-agent-service` với endpoint mới bị giới hạn bởi JWT hiện hữu.
3. Smoke test request hợp lệ và kiểm tra metric/log metadata.
4. Theo dõi tỷ lệ lỗi/timeout trong giai đoạn đầu.

**Tương thích ngược**: Endpoint mới additive; không thay đổi API hoặc database hiện có.

**Feature flag/config**: Không bắt buộc feature flag. `Ai:Ollama:Enabled` có thể là cấu hình tắt/bật môi trường nếu nền tảng triển khai đã có cơ chế config an toàn; không tự thêm framework flag.

**Thực thi migration/backfill khi rollout**:
- Không áp dụng.

**Rollback code/config**:
- Revert deployment `flex-agent-service` hoặc đặt `Ai:Ollama:Enabled=false` nếu đã dùng cấu hình này; endpoint mới dừng phục vụ mà không ảnh hưởng endpoint cũ.

**Rollback dữ liệu/migration**:
- Không áp dụng.

**Điều kiện kích hoạt rollback**:
- Tỷ lệ 5xx/504 vượt ngưỡng vận hành đã thống nhất, lỗi auth bất thường, hoặc phát hiện log chứa nội dung hội thoại.

## Observability & Debug

**Log cần có**:

- `ai.summary.completed`: `traceId`, `userId` (nếu policy cho phép), `provider`, `model`, `durationMs`, `outcome`.
- `ai.summary.failed`: các field trên cùng `failureKind` và HTTP status downstream; không log content/prompt/body.

**Dữ liệu không được log**:

- Nội dung hội thoại, prompt hệ thống, bản tóm tắt, bearer token, API key, endpoint có credential và HTTP body của provider.

**Metric cần theo dõi**:

- Request count, success/failure count theo `failureKind`, duration histogram và timeout rate cho luồng summary.

**Trace/Correlation**:

- Dùng trace/request correlation hiện hữu của ASP.NET Core; propagate `CancellationToken`, không thêm ID persistence.

**Cách kiểm tra sau release**:

- Gửi smoke request được xác thực; kiểm tra 200, duration dưới 30 giây hoặc lỗi chuẩn hóa; đối chiếu metric/log metadata không chứa content.

**Tình huống debug chính**:

- 401/403: kiểm tra JWT/middleware trước controller.
- 503/504: kiểm tra availability/model readiness của Ollama và option endpoint/timeout.
- 502: kiểm tra thay đổi payload provider mà không in content response vào log.

## Theo dõi độ phức tạp

| Vi phạm | Vì sao cần | Phương án đơn giản hơn bị loại vì |
|---------|------------|-----------------------------------|
| Thêm project `Flex.Agent.Application` | Use case và port cần boundary ổn định giữa business policy và provider AI biến động | Đặt port/use case ở API hoặc Domain làm sai ownership/dependency direction |

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật chặn thiết kế/task generation đã được resolve trong research hoặc ghi rủi ro rõ ràng.
- [x] Thiết kế tổng quan đã mô tả luồng chính, component/module tham gia, điểm thay đổi và boundary nếu có.
- [x] Các tình huống idempotency/concurrency/retry đã được đánh giá hoặc ghi `Không áp dụng`.
- [x] Mỗi `US`/`FR` P1/P2 hoặc FR ảnh hưởng code/data/API/permission có mapping sang module/path, API/contract, data/entity và kiểm thử.
- [x] Tác động tới database, API contract, permission, logging/audit và integration đã được đánh giá hoặc ghi `Không áp dụng`.
- [x] Các contract/API/event thay đổi đã có consumer bị ảnh hưởng và cách kiểm tra compatibility.
- [x] Dữ liệu/migration/backfill/compatibility đã rõ hoặc ghi `Không áp dụng`.
- [x] Database đích và repo chứa migration đã được xác định, đối chiếu `docs/architecture/system-map.md`, hoặc ghi `Không áp dụng` (Constitution VI).
- [x] Quyết định kỹ thuật chính đã có lý do chọn và phương án bị loại.
- [x] Chiến lược kiểm thử đã bao phủ unit, integration, contract, permission/security, E2E/manual và regression khi liên quan.
- [x] Rollout, rollback code/config, rollback dữ liệu/migration, feature flag/config và backward compatibility đã rõ hoặc ghi `Không áp dụng`.
- [x] Observability/debug plan có log field, dữ liệu không được log, metric/trace và cách kiểm tra sau release.
- [x] Không còn cây thư mục mẫu/generic; toàn bộ path trong cấu trúc source code là path thật trong repository.
- [x] Constitution gate không còn blocker trước khi chuyển sang `/speckit-tasks`.
