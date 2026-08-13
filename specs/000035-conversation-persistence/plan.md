# Kế hoạch triển khai: Lưu trữ và tích hợp hội thoại

**Branch**: `000035-conversation-persistence` | **Ngày**: 2026-08-13 | **Đặc tả**: [spec.md](./spec.md)

## Tóm tắt

**Yêu cầu chính từ spec**: Lưu conversation/message bền vững trong `agentdb`, sequence ổn định, retry không tạo duplicate, tách `role` khỏi `actor_type`, tích hợp FE/BE và lưu user/AI message trong cùng model.

**Hướng tiếp cận kỹ thuật**: Một vertical slice trong `flex-agent-service`: domain entities + application services + EF Core persistence + REST controllers; schema SQL/Liquibase ở `flex-database/agentdb`; Angular feature service/model ở `flex-microfrontend`, dùng HTTP làm nguồn state và SignalR event sau commit.

**Kết quả sau research**: Đã hoàn thành — xem [research.md](./research.md). Database đích là PostgreSQL `agentdb`; migration thuộc `flex-database/agentdb`.

## Phạm vi kỹ thuật

**Trong phạm vi**:
- `flex-agent-service`: Conversation/Message domain, application use cases, persistence mapping, authorization scope, AI flow persistence và API contract.
- `flex-database/agentdb`: schema `chat`, tables/indexes/constraints và Liquibase release mới.
- `flex-microfrontend`: models/API service và tích hợp vào core realtime/application chat flow theo convention Skote/Bootstrap hiện có.
- Tests cho transaction ordering, idempotency, tenant isolation, contract và FE retry/reconnect.

**Ngoài phạm vi kỹ thuật**:
- Không tạo service mới, database mới hoặc thay thế SignalR transport hiện hữu.
- Không implement streaming token, attachment, search, ticket/multichannel, retention phức tạp.
- Không sửa `flex-auth-service`; chỉ dùng claims/tenant context hiện có.

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: .NET 9/C#; Angular 16/TypeScript; PostgreSQL; Liquibase SQL-first.

**Service/App liên quan**: `flex-agent-service/src/Flex.Agent.*`; `flex-microfrontend/src/app`; `flex-database/agentdb`.

**Convention skill áp dụng**: `flex-dotnet-engineering` cho backend; `flex-frontend-engineering` cho Angular/Skote/Bootstrap; `flex-naming-convention` cho domain/API/realtime names; `flex-database/AGENTS.md` cho Liquibase.

**Phụ thuộc chính**: EF Core 9/Npgsql và `AppDbContext` hiện có; ASP.NET Core authorization; Angular HttpClient; existing `ApplicationRealtimeService`/`RealtimeConnection`; Liquibase changelog `agentdb`.

**Lưu trữ**: PostgreSQL `agentdb`, schema `chat`.

**Kiểm thử**: xUnit backend unit/integration; contract tests; Angular unit tests; FE manual/e2e smoke; Liquibase `validate`/`update-sql`.

**Nền tảng chạy**: Linux container/local Docker Compose, service API + Angular browser.

**Đơn vị deploy**: `flex-agent-service`, Angular bundle của `flex-microfrontend`, Liquibase release của `agentdb`.

**Loại project**: ASP.NET Core web API + application/domain/infrastructure; Angular web app; database migration repository.

**Mục tiêu hiệu năng**: 95% list/history thao tác hoàn tất hoặc lỗi rõ ràng trong 2 giây; query history dùng index conversation+sequence; không query `MAX(sequence_no)`.

**Ràng buộc**: tenant isolation; transaction tạo message phải atomic với conversation summary; không log content/token/secret; backward compatible với `POST /api/v1/ai/chat` và event `message.created`.

**Quy mô/Phạm vi**: MVP vài tenant, conversation/message runtime; page size tối đa 50 message trong contract.

## Kiểm tra constitution

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|---|---|---|---|
| Scope Gate | Pass | Pass | Thiết kế chỉ đáp ứng MVP/FR trong spec; không thêm multichannel/search. |
| Traceability Gate | Pass | Pass | FR P1/P2 có mapping module, contract, data và test bên dưới. |
| Test Gate | Pass | Pass | Có unit, integration DB, contract, permission, FE smoke và regression. |
| Security Gate | Pass | Pass | Tenant/actor lấy từ server context; resource authorization trước đọc/ghi. |
| Compatibility Gate | Pass | Pass | API AI cũ giữ nguyên; schema mới additive; migration forward-only. |
| Observability Gate | Pass | Pass | Log correlation/result không content; metric latency/error/idempotency; smoke query sau release. |
| Complexity Gate | Pass | Pass | Tái dùng AppDbContext, ChatService và realtime core; không thêm service/repository generic không cần thiết. |
| Release Gate | Pass | Pass | Liquibase validate/update-sql trước; deploy migration trước code; rollback code + forward-fix dữ liệu. |
| Constitution VI | Pass | Pass | `agentdb` và `flex-database/agentdb` có evidence từ system-map, AppDbContext/config và tiền lệ 000028. |

## Câu hỏi kỹ thuật cần research

- **TQ-001**: Database/repo migration nào sở hữu schema? → Resolved R1: PostgreSQL `agentdb`, `flex-database/agentdb`.
- **TQ-002**: Làm sao chống sequence race và retry duplicate? → Resolved R3: lock conversation row + transaction + `client_message_id`.
- **TQ-003**: REST hay SignalR là nguồn state? → Resolved R4: REST durable state, SignalR event sau commit.
- **TQ-004**: AI history có dùng bảng riêng không? → Resolved R5: cùng `Message` model, `assistant` + `ai_agent`.

## Thiết kế tổng quan

**Luồng chính**:
1. Request đi qua controller hoặc `ChatService`; server resolve `tenant_id`, `actor_id` và authorization từ claims/resource.
2. Application service validate content và idempotency key; mở transaction, khóa conversation, cấp sequence kế tiếp, insert message và update latest summary; commit.
3. Sau commit, publish `conversation.message.created` cho subscriber hợp lệ; HTTP response trả bản ghi durable.
4. `POST /api/v1/ai/chat` dùng cùng write service cho user message; gọi model; assistant response chỉ được persist khi kết quả hợp lệ, sau đó phát event.
5. FE tải lại bằng HTTP sau mở/reconnect; event chỉ merge theo `messageId`/`sequenceNo`, không làm nguồn khôi phục duy nhất.

**Component/module tham gia**:
- `flex-agent-service/src/Flex.Agent.Domain/Entities/Conversation.cs`, `Message.cs`: entity/invariant.
- `flex-agent-service/src/Flex.Agent.Application/Conversations`: use cases, ports, authorization orchestration.
- `flex-agent-service/src/Flex.Agent.Infrastructures/Persistence/AppDbContext.cs` và configurations/repositories: mapping/query/transaction.
- `flex-agent-service/src/Flex.Agent.Api/Controllers/ConversationsController.cs`, `DTOs/ConversationDtos.cs`: HTTP boundary.
- `flex-agent-service/src/Flex.Agent.Api/Hubs/ApplicationHub.cs` và realtime publisher: event sau commit, không business logic chính.
- `flex-microfrontend/src/app/core/conversations` hoặc feature chat tương ứng: API models/service; `core/realtime` chỉ nhận event.
- `flex-database/agentdb/migrations/` + `changelog/releases/1.3.0/`: schema source of truth.

**Luồng thay thế/lỗi chính**:
- Invalid/empty content → 400, không tăng sequence.
- Không có quyền/tenant mismatch → 401/403/404, không lộ existence ngoài scope.
- Cùng `client_message_id` và payload tương đương → trả bản ghi cũ; khác payload → 409.
- DB/model timeout → không coi message assistant là completed; trả lỗi có mã ổn định, log correlation.
- Reconnect → HTTP reload page; duplicate event bị bỏ qua.

**Thay đổi boundary giữa service/module**:
- Thêm boundary API conversation giữa FE và Agent API.
- Thêm persistence boundary `flex-agent-service` ↔ `agentdb` qua `AppDbContext`/SQL migration.
- Không thay identity provider; không có transaction xuyên database.

**Idempotency/Concurrency**:
- `client_message_id` correlate request retry.
- Transaction khóa conversation row; sequence cấp từ `last_sequence_no`.
- Unique `(conversation_id, sequence_no)` và unique scoped idempotency key.
- Commit DB trước event publish; event handler/FE dedupe theo `messageId`.
- Không retry mù thao tác non-idempotent; retry chỉ khi có idempotency key hoặc đọc lại trạng thái.

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---|---|---|---|---|---|---|---|
| US-001 / FR-001 | P1 | Đủ rõ | Create/list scoped tenant | `Application/Conversations`, `Api/Controllers/ConversationsController.cs` | conversation API | `chat.conversation` | integration + permission |
| US-001 / FR-002 | P1 | Đủ rõ | Cursor list và history page | `Application/Conversations/Queries` | GET list/messages | conversation/message indexes | integration + FE |
| US-001 / FR-003 | P1 | Đủ rõ | Atomic append + sequence allocator | `Application/Conversations`, `Infrastructure/Persistence` | POST message | `sequence_no`, unique index | concurrency integration |
| US-001 / FR-004 | P1 | Đủ rõ | Update latest projection cùng transaction | `ConversationMessageWriter` | ConversationSummary | `last_*` fields | transaction integration |
| US-001 / FR-005 | P1 | Đủ rõ | Stable DTO mapping and API service | API DTOs + FE models/service | `contracts/conversation-api.md` | Conversation/Message | contract + Angular |
| US-002 / FR-006 | P1 | Đủ rõ | Separate enums/value validation; actor server-side | Domain + DTO mapper | role/actorType fields | message columns | unit + contract |
| US-002 / FR-007 | P1 | Đủ rõ | Common model for AI/human/system/tool | Message writer + AI flow | MessageResponse/event | message | integration |
| US-003 / FR-008 | P1 | Đủ rõ | Idempotency + row lock + dedupe | writer/repository | `clientMessageId` | unique index | concurrent/retry |
| US-003 / FR-009 | P2 | Đủ rõ | Explicit message status mapping | Domain/application | status in response/event | `status` | unit + API |
| FR-010 / BR-006 | P2 | Đủ rõ | JSONB metadata passthrough with core-field boundary | EF mapping + DTO | metadata object | `metadata` JSONB | serialization |
| SEC-001..003 | P1 | Đủ rõ | Claims tenant/actor + resource authorization + redacted logs | API/application/logging | 401/403/404 | tenant columns | permission/security |
| NFR/SC-001..004 | P1/P2 | Đủ rõ | Index, page size, transaction and smoke metrics | DB/API/FE | latency/ordering | indexes/projection | load/concurrency/e2e |

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---|---|---|---|
| Database/Migration | Thêm schema `chat`, 2 tables, indexes và Liquibase release 1.3.0 | Schema mới; cần migration trước code; duplicate/dirty data không có ở fresh DB | validate/update-sql, apply trên agentdb test, query invariant |
| API/Contract | Thêm conversation API; mở rộng nội bộ AI persistence; thêm event mới | Giữ `POST /api/v1/ai/chat`, direct event cũ; contract test response/error | API/contract tests |
| Permission/Security | Mọi query/write scoped tenant + conversation; actor server-side | Rủi ro IDOR/cross-tenant | unauthorized/cross-tenant tests |
| Logging/Audit | Structured event cho create/read/send/failure; không log content | Thiếu correlation gây khó debug | log assertion/smoke |
| UI/UX | List/history/send/loading/empty/error/retry; role/actor display | Retry/reconnect có thể duplicate nếu FE không dedupe | Angular unit + manual/e2e |
| Job/Worker/Integration | AI flow ghi user/assistant; realtime publish sau commit | Model timeout và event failure không được rollback DB đã commit | integration timeout/event tests |

## API/Contract Detail

**Có thay đổi contract không**: Có.

Chi tiết normative ở [contracts/conversation-api.md](contracts/conversation-api.md) và [contracts/conversation-realtime.md](contracts/conversation-realtime.md). Consumer: `flex-microfrontend` và các client Agent API; `POST /api/v1/ai/chat` consumer cũ không phải sửa payload. Event `message.created` hiện hữu không đổi.

## Permission Matrix

| Vai trò/Scope | Xem | Tạo | Sửa | Xóa | Duyệt/Xử lý | Ghi chú |
|---|---|---|---|---|---|---|
| Authenticated tenant member có conversation scope | Có | Có | Không áp dụng MVP | Không áp dụng MVP | Gửi message | tenant/role policy server-side |
| AI Agent runtime được gọi bởi service | Theo flow nội bộ | Tạo assistant message | Cập nhật status của message do flow sở hữu | Không | Có | Không nhận identity từ client |
| Human agent có conversation scope | Có | Có | Không áp dụng MVP | Không áp dụng MVP | Gửi message | future actor, cùng model |
| User khác tenant/ngoài scope | Không | Không | Không | Không | Không | 403/404 theo resource policy |
| Unauthenticated/public client | Không áp dụng MVP | Không | Không | Không | Không | Public widget ngoài scope |

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Có.

**Database đích**: PostgreSQL `agentdb`, schema `chat`. Evidence: `docs/architecture/system-map.md` §4–5 xác nhận `agentdb` cho Agent Platform; `flex-agent-service` `AppDbContext`/`appsettings.Example.json` đang dùng `Database=agentdb`.

**Repo chứa migration**: `flex-database/agentdb`. Evidence: system map xác nhận `flex-database` là repo migration; tiền lệ `000028-agent-publish-channels` dùng `agentdb/migrations` và Liquibase release. Không đặt EF migration trong `flex-agent-service`.

**Migration**:
- Tạo `chat.conversation` và `chat.message` theo [data-model.md](data-model.md).
- Tạo unique `(conversation_id, sequence_no)`, scoped idempotency key và index list/history (`tenant_id`, conversation, sequence).
- Include file SQL vào release `1.3.0/changelog.xml`, include release trong master changelog.
- Không thêm FK tới identity/tenant database khác; service validate scope.

**Backfill/Cleanup**: Không có dữ liệu cũ cùng schema; không backfill. Chat history memory/preview cũ không được tự động biến thành durable records.

**Tương thích dữ liệu cũ**: Tables mới additive; existing `agents`, publish locations và direct realtime data không đổi.

**Rủi ro dữ liệu**: sequence drift, duplicate retry, cross-tenant read, migration drift. Mitigate bằng transaction/unique/index/permission integration tests và forward-fix.

**Cách xác minh**: Liquibase `validate`, `update-sql`; apply vào disposable `agentdb`; query indexes/constraints; chạy concurrent append và tenant isolation tests.

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|---|---|---|---|---|
| DEC-001 | PostgreSQL `agentdb` + `flex-database/agentdb` migration | Đúng system map, code hiện hữu và tiền lệ | `flexdb`/MySQL/EF migration | Sai ownership hoặc vi phạm Constitution VI |
| DEC-002 | Conversation row lock + transaction | Sequence và summary atomic | `MAX+1`, client sequence | Race condition/không tin client |
| DEC-003 | `client_message_id` idempotency | Retry không duplicate | Chỉ disable button hoặc timestamp | Không bảo vệ network retry/concurrent request |
| DEC-004 | REST durable state + SignalR notification | Khôi phục được sau reconnect | SignalR-only | Transport không phải storage |
| DEC-005 | Một Message model, role tách actor_type | Mở rộng actor/AI sạch | `is_bot`/bảng ai_message | Mất semantic và tạo suy luận ngược |
| DEC-006 | JSONB metadata cho provider/channel extension | Core schema ổn định | 50 cột provider-specific | Schema phình và coupling |

## Chiến lược kiểm thử

**Unit test**:
- Role/actor validation, status transitions, content normalization, idempotency payload comparison.
- Sequence writer quyết định transaction command và mapping DTO/event.

**Integration test**:
- PostgreSQL migration + CRUD/list/history; transaction rollback; concurrent append; latest projection; AI timeout không tạo completed assistant.

**Contract test**:
- JSON request/response/error cho conversation API; `role`/`actorType` độc lập; event schema và giữ nguyên direct event cũ.

**Permission/security test**:
- Missing JWT, tenant A đọc tenant B, conversation ngoài scope, client cố gửi actor/tenant khác, log không chứa content/token.

**E2E/manual test**:
- Create → list → open → send → AI response → refresh; loading/empty/error/retry; SignalR reconnect rồi history reload.

**Regression test**:
- Existing `AIController` chat behavior, existing `ApplicationHub.SendMessage`, Agent CRUD/publish location và Angular realtime lifecycle.

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/000035-conversation-persistence/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── contracts/
    ├── conversation-api.md
    └── conversation-realtime.md
```

### Source code

```text
flex-agent-service/
├── src/Flex.Agent.Domain/Entities/Conversation.cs
├── src/Flex.Agent.Domain/Entities/Message.cs
├── src/Flex.Agent.Application/Conversations/
├── src/Flex.Agent.Application/Chat/Services/ChatService.cs
├── src/Flex.Agent.Infrastructures/Persistence/AppDbContext.cs
├── src/Flex.Agent.Infrastructures/Repositories/ConversationRepository.cs
├── src/Flex.Agent.Api/Controllers/ConversationsController.cs
├── src/Flex.Agent.Api/DTOs/ConversationDtos.cs
├── src/Flex.Agent.Api/Hubs/ApplicationHub.cs
└── tests/Flex.Agent.Tests/Conversations/

flex-microfrontend/
├── src/app/core/conversations/conversation-api.service.ts
├── src/app/core/conversations/conversation.models.ts
├── src/app/core/realtime/application-realtime.service.ts
├── src/app/pages/chat/ (màn chat hiện hữu)
└── src/app/features/agent-catalog/components/agent-create-wizard/ (preview AI hiện hữu)

flex-database/agentdb/
├── changelog/db.changelog-master.xml
├── changelog/releases/1.3.0/changelog.xml
└── migrations/V1.3__create_chat_conversation_message.sql
```

**Quyết định cấu trúc**: Reuse layer/project hiện có; không tạo project mới. Domain giữ invariant; Application giữ use-case/transaction boundary; Infrastructure giữ EF mapping/query; API/Hub chỉ boundary; FE dùng core service/realtime abstraction; migration tập trung ở `flex-database/agentdb`.

## Rollout & Rollback

**Kế hoạch rollout**:
1. Validate và preview Liquibase release 1.3.0 trên disposable/test `agentdb`.
2. Apply additive schema trước deploy backend.
3. Deploy backend với persistence feature gated/configured; smoke create/list/send/history.
4. Deploy FE sau khi API contract pass; bật AI persistence cho flow cũ.

**Tương thích ngược**: API AI cũ giữ request/response; event direct cũ giữ nguyên; schema mới không yêu cầu backfill.

**Feature flag/config**: `Chat:PersistenceEnabled` cho phép tắt write mới trong rollout; khi tắt, API phải trả trạng thái rõ ràng hoặc giữ behavior legacy theo quyết định release, không âm thầm mất message.

**Thực thi migration/backfill khi rollout**: Migration additive chạy trước code; không backfill.

**Rollback code/config**: Tắt flag hoặc deploy version backend trước đó; FE cũ vẫn dùng API AI cũ.

**Rollback dữ liệu/migration**: Không drop schema production; dùng forward-fix/restore theo vận hành database. Vì tables mới additive, rollback code không cần rollback migration.

**Điều kiện kích hoạt rollback**: cross-tenant access, duplicate/sequence conflict, message loss, p95 history > 2s, error rate API/DB vượt ngưỡng release hoặc AI flow thay đổi response ngoài contract.

## Observability & Debug

**Log cần có**:
- `conversation.created`, `message.appended`, `message.idempotent_replay`, `message.append_failed`, `conversation.history_read`.
- Fields: `traceId`, `correlationId`, `tenantId`, `userId`, `conversationId`, `messageId`, `sequenceNo`, `actorType`, `status`, `durationMs`, `outcome`.

**Dữ liệu không được log**: message content, metadata có thể chứa PII, JWT/access token, secret, connection string, model prompt/response nguyên văn.

**Metric cần theo dõi**:
- conversation/message create success/error rate; history latency p50/p95; idempotent replay count; sequence conflict count; authorization denied; AI persistence failure; event publish failure.

**Trace/Correlation**: Propagate `traceId`/`correlationId` từ HTTP/SignalR → application writer → DB/model → event; event mang `messageId`/`conversationId` để correlate.

**Cách kiểm tra sau release**: quickstart HTTP smoke, query count/index/schema, check log/metric không lộ content, gửi retry và reconnect.

**Tình huống debug chính**: sequence conflict, retry duplicate, cross-tenant rejection, AI timeout, event sau commit thất bại, FE bỏ lỡ event.

## Theo dõi độ phức tạp

Không có vi phạm constitution cần biện minh. `ConversationRepository` chỉ được tạo nếu cần bảo vệ transaction/query boundary; không thêm generic repository/mediator/event bus mới. Event publisher dùng abstraction hiện có nếu đủ; nếu chưa có thì tạo một port hẹp phục vụ publish sau commit.

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật đã resolve trong research; không còn blocker.
- [x] Thiết kế tổng quan mô tả luồng, component, boundary và lỗi.
- [x] Idempotency/concurrency/retry đã được thiết kế.
- [x] US/FR P1/P2 có mapping module/path, contract, data và test.
- [x] Database, API, permission, logging/audit và integration đã được đánh giá.
- [x] Contract mới có consumer và compatibility strategy.
- [x] Migration/backfill/compatibility đã rõ.
- [x] Database đích/repo migration đã xác định theo system-map và tiền lệ.
- [x] Quyết định kỹ thuật có rationale và alternatives.
- [x] Chiến lược test bao phủ các lớp liên quan.
- [x] Rollout/rollback/flag/backward compatibility đã rõ.
- [x] Observability/debug có log, redaction, metric, trace và smoke check.
- [x] Cấu trúc source code dùng path thật, không giữ cây generic.
- [x] Constitution gate pass.
