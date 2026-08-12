# Kế hoạch triển khai: Tích hợp chat AI tại màn Agent

**Branch**: `000033-ai-chat-integration` | **Ngày**: 2026-08-11 | **Đặc tả**: [spec.md](spec.md)

**Đầu vào**: Đặc tả tính năng từ [spec.md](spec.md).

## Tóm tắt

**Yêu cầu chính từ spec**: Thay cuộc chat trực tiếp người–người tại `/agents/create` bằng phiên hỏi–đáp với AI Agent đang được cấu hình; hiển thị trạng thái chờ, lỗi/timeout và giữ hội thoại trong phiên.

**Hướng tiếp cận kỹ thuật dự kiến**: Thêm preview API đồng bộ qua API Gateway, dùng lại `IChatModelClient`/Ollama của `flex-agent-service`. Angular wizard gửi context bản nháp và lịch sử phiên, quản lý pending/error cục bộ, không dùng SignalR direct-message.

**Kết quả sau research**: Direct-message SignalR không thể dùng vì chỉ chuyển tin giữa user và không có Agent/correlation. Agent wizard chưa lưu `instructions`, nên request preview phải mang draft context. Không thay schema hoặc persistence.

## Phạm vi kỹ thuật

**Trong phạm vi**:

- `flex-microfrontend`: thay state/markup direct chat trong `AgentCreateWizardComponent`; thêm service/model typed gọi preview API; hiển thị pending, lỗi, retry và reset phiên.
- `flex-agent-service`: thêm use case preview, DTO và endpoint authorized `POST /api/v1/ai/chat/preview`; tái dùng `IChatModelClient` và adapter Ollama.
- `flex-api-gateway` và bản mount runtime trong `flex-environment`: thêm route additive `/api/v1/ai/**` đến Agent Service.
- Unit, integration/controller, contract và manual E2E cho luồng success, validation, quyền, unavailable và timeout.

**Ngoài phạm vi kỹ thuật**:

- Streaming/SignalR chat AI, lưu lịch sử, audit persistence, migration/schema, tệp đính kèm và voice input.
- Thay đổi direct-message hub hoặc các luồng hội thoại khách hàng thật.
- Chỉnh sửa global timeout/config của endpoint tóm tắt AI hiện có.

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: TypeScript / Angular 16 (`flex-microfrontend`); C# / .NET 9 (`flex-agent-service`); .NET YARP (`flex-api-gateway`).

**Service/App liên quan**: `AgentCreateWizardComponent`, API Gateway, `Flex.Agent.Api`, `Flex.Agent.Application`, `Flex.Agent.Infrastructures`.

**Convention skill áp dụng**: `flex-frontend-engineering` cho FE; `flex-dotnet-engineering` và `flex-naming-convention` cho BE.

**Phụ thuộc chính**: Angular HttpClient/interceptor, JWT, API Gateway, ASP.NET Core controller, `IChatModelClient`, Ollama adapter; không thêm SDK/provider mới.

**Lưu trữ**: Không áp dụng — phiên và draft context chỉ transient.

**Kiểm thử**: Angular unit/component test nếu harness hiện có; xUnit/controller integration và fake `IChatModelClient`; contract/manual E2E.

**Nền tảng chạy**: Browser; API Gateway và Agent Service container/local service; Ollama trong hạ tầng hiện có.

**Đơn vị deploy**: `flex-microfrontend`, `flex-agent-service`, `flex-api-gateway`; cập nhật mount config của `flex-environment`.

**Loại project**: Admin web + web API + gateway configuration.

**Mục tiêu hiệu năng**: 95% preview nhận câu trả lời hoặc lỗi rõ ràng trong 15 giây.

**Ràng buộc**: Không log câu hỏi, lịch sử, instructions, response, Authorization header hay secret; chỉ một request preview pending trong UI.

**Quy mô/Phạm vi**: Một màn wizard, một endpoint mới và một gateway route additive; không persistence.

## Kiểm tra constitution

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| Scope Gate | Pass | Pass | Chỉ preview synchronous trên wizard; loại trừ chat vận hành, streaming và storage. |
| Traceability Gate | Pass | Pass | US/FR P1/P2 map tới FE, API, gateway và test. |
| Test Gate | Pass | Pass | Có unit, controller integration, contract và E2E/manual. |
| Security Gate | Pass | Pass | JWT qua gateway; bỏ impersonation dropdown; không log content. |
| Compatibility Gate | Pass | Pass | API/route mới additive; hub/summary/CRUD không đổi. |
| Observability Gate | Pass | Pass | Metadata log, metric latency/error/timeout và correlation. |
| Complexity Gate | Pass | Pass | HTTP synchronous dùng primitives sẵn có; không thêm SignalR command, queue hay storage. |
| Database / Migration (Constitution VI) | Không áp dụng | Không áp dụng | Không tạo/sửa/lưu dữ liệu; không cần `system-map.md` migration analysis. |

## Câu hỏi kỹ thuật cần research

- **TQ-001 — Đã giải quyết**: Có tái sử dụng SignalR `SendMessage` không? Không; dùng HTTP preview API vì hub chỉ là người–người.
- **TQ-002 — Đã giải quyết**: Làm sao preview phản ánh Agent chưa phát hành? Request gửi `name`, `role`, `instructions` bản nháp cùng history transient.
- **TQ-003 — Đã giải quyết**: Ai là người gửi thử nghiệm? Caller JWT/profile hiện tại; bỏ dropdown người nhận hard-code để không mạo danh.
- **TQ-004 — Đã giải quyết**: Có cần database/migration? Không; state chỉ tồn tại trong FE/request.
- **TQ-005 — Đã giải quyết**: Route AI đến FE qua đâu? Thêm `/api/v1/ai/**` qua gateway để interceptor gắn JWT theo `apiBaseUrl`.

Chi tiết quyết định: [research.md](research.md).

## Thiết kế tổng quan

**Luồng chính**:

1. Caller đã xác thực mở `/agents/create`, nhập draft Agent và gửi câu hỏi văn bản hợp lệ.
2. FE thêm tin nhắn user `pending`, khóa gửi tiếp và gọi gateway `POST /api/v1/ai/chat/preview` với Agent draft cùng history.
3. Gateway định tuyến request kèm JWT tới `AIController`; controller validate/authorize, gọi `AgentPreviewChatService`.
4. Use case tạo system instruction từ draft, chuyển history thành `ChatRequest`, tái dùng `IChatModelClient` với timeout `Ai:Ollama:TimeoutSeconds`.
5. FE nhận `reply`, đổi pending thành completed và thêm tin Agent; nếu lỗi, giữ history/câu hỏi, hiển thị lỗi và cho retry.

**Component/module tham gia**:

- `flex-microfrontend/.../agent-create-wizard.component.{ts,html,scss}`: state/view preview, pending/error/retry; không còn subscription direct message.
- `flex-microfrontend/.../services/agent-preview.service.ts` và `models/agent-preview.model.ts`: typed HTTP contract, DTO mapping.
- `flex-api-gateway/.../yarp*.json`, `flex-environment/mounts/flex-api-gateway/yarp.json`: route `/api/v1/ai/**`.
- `Flex.Agent.Api/Controllers/AIController.cs`, DTOs: HTTP boundary và status mapping.
- `Flex.Agent.Application/AI/AgentPreviewChatService.cs`: validation, prompt/history orchestration, deadline/error mapping.
- `Flex.Agent.Application/AI/IChatModelClient.cs` và `Flex.Agent.Infrastructures/AI/OllamaChatModelClient.cs`: tái sử dụng không đổi public behavior.

**Điểm mở rộng/thay đổi chính**:

- `AgentPreviewChatService` là use case riêng, không mở generic public chat API và không đổi `ConversationSummaryService`.
- Preview request gửi only text history và draft fields cần định hướng AI; avatar/attachments/voice không vào contract.
- FE state tách `pending`/`failed` khỏi message hiển thị để retry không nhân bản câu hỏi.

**Luồng thay thế/lỗi chính**:

- Input/draft/history invalid → `400 AI_PREVIEW_REQUEST_INVALID` và inline error.
- Missing/invalid JWT hoặc insufficient permission → 401/403, FE theo auth/error behavior hiện hữu, không lộ content.
- Provider unavailable/invalid/timeout → 503/502/504, giữ session và enable retry.
- User hủy navigation/request → propagate cancellation, không thêm reply giả.

**Thay đổi boundary giữa service/module**:

- FE → Gateway: contract [agent-preview-chat-api.md](contracts/agent-preview-chat-api.md).
- Gateway → Agent Service: proxy route additive.
- API → Application: DTO HTTP sang preview use case.
- Application → Infrastructure: `IChatModelClient` chỉ nhận internal `ChatRequest`; DTO API/provider không lan qua boundary.

**Idempotency/Concurrency**:

- Không có side effect bền; không cần idempotency key.
- FE chỉ cho một request pending trong một wizard session; retry chỉ cho phép sau result lỗi.
- BE xử lý request trùng độc lập và không retry downstream tự động.

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---|---|---|---|---|---|---|---|
| US-001 / FR-001 | P1 | Đủ rõ | Bỏ direct-message, gọi preview AI có draft/history | FE wizard; `AIController`, `AgentPreviewChatService` | `POST /api/v1/ai/chat/preview` | Transient session | Component + controller integration success |
| US-001 / FR-002 | P1 | Đủ rõ | Caller JWT là test sender; context Agent lấy từ Reactive Form | FE preview service/wizard | Preview request | `AgentPreviewContext` transient | Request mapping + auth test |
| US-001 / FR-003 | P1 | Đủ rõ | Render user/agent roles theo local response, không theo sender của hub | FE template/state | Success `reply` DTO | `PreviewMessage` transient | Component/E2E multi-turn order |
| US-001 / FR-004 | P1 | Đủ rõ | Pending state, disable send, cancellation/timeout cấu hình | FE wizard; application service | 504 contract | Pending message state | Component + timeout integration |
| US-002 / FR-005 | P2 | Đủ rõ | Hiển thị unavailable/status, không fake Agent message | FE error mapper; controller mapping | 503 contract | Không áp dụng | 503 integration/manual |
| US-002 / FR-006 | P2 | Đủ rõ | Preserve history, expose retry only after error | FE preview state | 502/503/504 contracts | Không áp dụng | Component/E2E error-retry |
| US-002 / FR-007 | P2 | Đủ rõ | Remove `directMessages$` use for preview, use typed response only | FE wizard/realtime subscription cleanup | Không dùng `message.created` | Không áp dụng | Regression hub non-use |
| SEC-001 / SEC-002 | P1 | Đủ rõ | `[Authorize]`, gateway JWT forwarding, caller identity; metadata-only telemetry | Gateway, `AIController`, logger | 401/403 | Không lưu | Security integration/log review |
| NFR-001 / NFR-003 | P1 | Đủ rõ | Per-use-case 15s deadline, correlation, UI response/error path | Application service, FE | 504 contract | Không áp dụng | Timeout test/manual browser |

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---|---|---|---|
| Database/Migration | Không áp dụng | Không persistence/schema | Xác nhận diff không có migration/entity/DbContext |
| API/Contract | Thêm preview endpoint và gateway route | Additive; consumer mới wizard | Contract + gateway smoke test |
| Permission/Security | JWT endpoint; caller identity thay hard-code dropdown | Không cho user gửi với identity khác | 401/403 + UI/auth regression |
| Logging/Audit | Thêm metadata log/metric preview | Rủi ro lộ prompt/chat | Log schema review + automated log assertion khi khả thi |
| UI/UX | Thay recipient/direct-chat bằng AI preview state | Không ảnh hưởng tab/CRUD/publish | Browser manual/component regression |
| Job/Worker/Integration | Sync call đến provider qua adapter | Unavailable/timeout | Fake-client integration, 502/503/504 cases |

## API/Contract Detail

**Có thay đổi contract không**: Có — thêm endpoint và gateway route, không thay contract hiện hữu.

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|---|---|---|---|---|
| `POST /api/v1/ai/chat/preview` | API | Request Agent draft + history; response reply | Có, mới hoàn toàn | `AgentCreateWizardComponent` |
| `/api/v1/ai/**` | Gateway route | Proxy tới Agent Service | Có, thêm route | FE preview API |
| `IChatModelClient` | Internal port | Tái sử dụng, không đổi signature | Có | Preview + summary use case |

Contract chi tiết: [agent-preview-chat-api.md](contracts/agent-preview-chat-api.md).

## Permission Matrix

| Vai trò/Scope | Xem | Tạo | Sửa | Xóa | Duyệt/Xử lý | Ghi chú |
|---|---|---|---|---|---|---|
| Người dùng đã xác thực có quyền màn Agent | Có session hiện tại | Gửi preview | Không | Không | Nhận phản hồi preview | Identity là JWT caller; không chọn người khác |
| Người chưa xác thực | Không | Không | Không | Không | Không | Middleware trả 401 |
| Người không đủ quyền | Không | Không | Không | Không | Không | Policy hiện hữu trả 403 khi áp dụng |

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Không áp dụng.

**Database đích**: Không áp dụng — data preview chỉ transient trong browser/request.

**Repo chứa migration**: Không áp dụng — Constitution VI đã được đánh giá.

**Migration**: Không áp dụng.

**Backfill/Cleanup**: Không áp dụng.

**Tương thích dữ liệu cũ**: Không áp dụng.

**Rủi ro dữ liệu**: Không lưu nhưng nội dung có thể nhạy cảm; không log/chat persistence.

**Cách xác minh**: Kiểm tra diff không chạm schema/migration; review log smoke test chỉ có metadata.

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|---|---|---|---|---|
| DEC-001 | HTTP preview endpoint qua gateway | Khớp request–response MVP, JWT interceptor và error contract | SignalR direct/custom command | Không gọi AI hoặc vượt scope streaming/correlation |
| DEC-002 | Gửi draft context + history client-side | Test được config chưa phát hành, không persistence | Chỉ last message / lưu server session | Thiếu định hướng hoặc mở rộng retention/schema |
| DEC-003 | Caller JWT là test sender | Không impersonation/dropdown hard-code | `testUserId` do FE chọn | Không có authority để validate selection |
| DEC-004 | `AgentPreviewChatService` tái dùng `IChatModelClient`, timeout theo `Ai:Ollama:TimeoutSeconds` | Tận dụng adapter/error handling và cấu hình theo môi trường | Provider call controller/deadline hard-code | Coupling hoặc cắt request sớm hơn cấu hình |
| DEC-005 | Success DTO trực tiếp, error DTO AI hiện hữu | Nhất quán `AIController` | `Result<T>` CRUD envelope | Trộn pattern không cần thiết |

## Chiến lược kiểm thử

**Unit test**:

- `AgentPreviewChatService`: validate draft/messages, build system/history messages, reply empty, cancellation/timeout cấu hình/error mapping.
- Angular preview mapper/state: optimistic pending, success order, error preserves history, retry và reset.

**Integration test**:

- `AIController` với fake `IChatModelClient`: 200, 400, 502, 503, 504; bảo đảm summary endpoint còn pass.
- Gateway route smoke với authorized request ở môi trường local/staging phù hợp.

**Contract test**:

- Validate request/response/error JSON theo [agent-preview-chat-api.md](contracts/agent-preview-chat-api.md).
- Consumer FE test DTO mapping, không gọi route AI trực tiếp ngoài gateway.

**Permission/security test**:

- Anonymous 401, policy 403 khi có policy; request không có `testUserId`/identity tùy ý.
- Verify telemetry/error không echo message, instructions, reply, token hoặc header.

**E2E/manual test**:

- Thực hiện success, pending, multi-turn, unavailable, timeout, retry và reset theo [quickstart.md](quickstart.md).

**Regression test**:

- FE build/test; `dotnet test` Agent Service; API Gateway config load; direct-message hub và CRUD Agent không đổi.

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/000033-ai-chat-integration/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── contracts/
    └── agent-preview-chat-api.md
```

### Source code

```text
flex-microfrontend/
└── src/app/features/agent-catalog/
    ├── components/agent-create-wizard/
    │   ├── agent-create-wizard.component.ts
    │   ├── agent-create-wizard.component.html
    │   └── agent-create-wizard.component.scss
    ├── models/agent-preview.model.ts
    └── services/agent-preview.service.ts

flex-agent-service/
├── src/Flex.Agent.Api/
│   ├── Controllers/AIController.cs
│   └── DTOs/AgentPreviewChatDtos.cs
├── src/Flex.Agent.Application/AI/
│   ├── AgentPreviewChatService.cs
│   └── AgentPreviewChatExceptions.cs
└── tests/Flex.Agent.Tests/AI/
    ├── AgentPreviewChatServiceTests.cs
    └── AIControllerIntegrationTests.cs

flex-api-gateway/src/Flex.ApiGateway/
├── yarp.json
└── yarp.Development.json

flex-environment/mounts/flex-api-gateway/
└── yarp.json
```

**Quyết định cấu trúc**: Chỉ thêm service/model gần wizard FE và use case/DTO gần AI use case BE hiện có; không tạo repo, project, database hay abstraction chung mới.

## Rollout & Rollback

**Kế hoạch rollout**:

1. Deploy Agent Service có endpoint preview cùng cấu hình provider hiện có.
2. Deploy gateway route `/api/v1/ai/**` và xác minh route với JWT ở staging.
3. Deploy FE bundle sau khi gateway/API sẵn sàng.
4. Smoke test success/error theo quickstart; theo dõi latency và error/timeout rate ban đầu.

**Tương thích ngược**: Additive endpoint/route; hub direct-message, CRUD Agent và `chat/summarize` không thay đổi.

**Feature flag/config**: Không thêm feature-flag framework. Route gateway/config triển khai là điểm kiểm soát tắt/bật theo môi trường nếu quy trình vận hành hiện có hỗ trợ.

**Thực thi migration/backfill khi rollout**:

- Không áp dụng.

**Rollback code/config**:

- Roll back FE bundle trước để dừng consumer; sau đó rollback gateway route hoặc Agent Service deployment. Không thay đổi direct-message hub.

**Rollback dữ liệu/migration**:

- Không áp dụng — không có persistence/schema; rollback code/config là đủ.

**Điều kiện kích hoạt rollback**:

- Tỷ lệ 5xx/504 vượt ngưỡng vận hành, leak nội dung nhạy cảm trong telemetry, lỗi quyền, hoặc gateway route gây ảnh hưởng endpoint khác.

## Observability & Debug

**Log cần có**:

- `ai.preview.completed` / `ai.preview.failed`: `traceId`, tenant/user identifier theo convention an toàn, `durationMs`, `outcome`, `failureKind`, HTTP status và model label không nhạy cảm.

**Dữ liệu không được log**:

- Nội dung question/history, `instructions`, prompt system, reply AI, bearer token, Authorization header, endpoint/provider credential.

**Metric cần theo dõi**:

- Preview request count; p50/p95 duration; tỷ lệ 2xx/4xx/502/503/504; unavailable/timeout count; FE retry count nếu telemetry hiện có hỗ trợ.

**Trace/Correlation**:

- Dùng `traceId`/correlation hiện hữu từ gateway đến Agent Service và phản chiếu an toàn trong lỗi/log metadata.

**Cách kiểm tra sau release**:

- Smoke test endpoint qua gateway bằng JWT; thực hiện một preview UI success và one provider-unavailable; kiểm tra dashboard/log metadata không có content.

**Tình huống debug chính**:

- 401/403: kiểm tra token/policy/gateway forwarding; 404: kiểm tra YARP route ở cả development/runtime mount; 503/504: health/config provider; reply sai: xác nhận form draft/history mapping nhưng không in content vào log.

## Theo dõi độ phức tạp

Không có vi phạm constitution cần biện minh. Use case riêng là cần thiết để không thay đổi semantics của summary endpoint và không làm controller gọi provider trực tiếp.

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật chặn thiết kế/task generation đã được resolve trong research.
- [x] Thiết kế tổng quan đã mô tả luồng chính, component/module tham gia, điểm thay đổi và boundary.
- [x] Idempotency/concurrency/retry đã được đánh giá.
- [x] Mỗi `US`/`FR` P1/P2 có mapping sang module/path, contract, data và kiểm thử.
- [x] Tác động database, API contract, permission, logging/audit và integration đã được đánh giá.
- [x] Contract/API thay đổi có consumer và cách kiểm tra compatibility.
- [x] Dữ liệu/migration/backfill/compatibility đã rõ: Không áp dụng.
- [x] Database đích/repo migration đã xác định: Không áp dụng (Constitution VI).
- [x] Quyết định kỹ thuật có lý do chọn và phương án bị loại.
- [x] Chiến lược kiểm thử bao phủ unit, integration, contract, permission/security, E2E/manual và regression.
- [x] Rollout, rollback, feature/config và backward compatibility đã rõ.
- [x] Observability/debug có log field, dữ liệu cấm log, metric/trace và smoke check.
- [x] Không còn cây thư mục mẫu/generic; toàn bộ path là path thật trong repository.
- [x] Constitution gate không còn blocker trước `/speckit-tasks`.
