# Kế hoạch triển khai: Phân loại nguồn hội thoại

**Branch**: `[000037-add-conversation-source]` | **Ngày**: 2026-08-15 | **Đặc tả**: [spec.md](spec.md)

**Đầu vào**: Đặc tả tại `specs/000037-add-conversation-source/spec.md`

## Tóm tắt

**Yêu cầu chính từ spec**: Bổ sung nguồn khởi tạo bất biến cho `Conversation`, hỗ trợ `Production=1`, `Preview=2`, `Playground=3`, `Api=4`; lưu/trả nguồn trong contract; không suy luận hoặc hồi tố nguồn lịch sử khi không có bằng chứng.

**Hướng tiếp cận kỹ thuật dự kiến**: Thêm enum/value mapping trong Domain, truyền source qua trusted ingress, map PostgreSQL `public.conversation` trong database `agentdb`, mở rộng DTO và TypeScript model, phát hành migration nullable.

**Kết quả sau research**: Conversation nằm trong `flex-agent-service` và migration thuộc `flex-database/agentdb` theo system map và tiền lệ `000035`. API hiện tại được FE sử dụng nên mapping là `Production`; không cho client tự khai source.

## Phạm vi kỹ thuật

**Trong phạm vi**:
- `flex-agent-service`: domain enum, create command/source context, repository, EF mapping, API response và tests.
- `flex-database/agentdb`: migration/changelog thêm column nullable và constraint bốn mã.
- `flex-microfrontend`: model/API consumer đọc source; không thêm UI playground hoặc filter.
- Contract, data-model và quickstart của feature.

**Ngoài phạm vi kỹ thuật**:
- Suy đoán source lịch sử, playground/dashboard/analytics, thay đổi message/actor/role/realtime/tenant authorization.

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: .NET 9/C#, PostgreSQL, TypeScript/Angular hiện có.

**Service/App liên quan**: `flex-agent-service`, `flex-microfrontend`, `flex-database`.

**Convention skill áp dụng**: `flex-dotnet-engineering`, `flex-database-engineering`, `flex-frontend-engineering`, `flex-naming-convention`.

**Phụ thuộc chính**: EF Core, PostgreSQL `agentdb`, `/api/v1/conversations`, Angular `ConversationApiService`.

**Lưu trữ**: PostgreSQL database `agentdb`, schema mặc định `public`, table `conversation`.

**Kiểm thử**: xUnit; migration validation; Angular type/build; contract smoke test.

**Nền tảng chạy**: ASP.NET Core/container và Angular browser app.

**Đơn vị deploy**: `flex-agent-service`, migration release `flex-database`, `flex-microfrontend`.

**Loại project**: web-service + frontend client + shared database migration.

**Mục tiêu hiệu năng**: Không thêm query; p95 không tăng quá 5% trong smoke benchmark.

**Ràng buộc**: Tenant isolation giữ nguyên; migration backward-compatible; source client không phải authority.

**Quy mô/Phạm vi**: Một column và enum cho conversation; ảnh hưởng create/list response và consumer hiện có.

## Kiểm tra constitution

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| Scope Gate | Pass | Pass | Chỉ bổ sung source |
| Traceability Gate | Pass | Pass | P1/P2 map trong traceability |
| Test Gate | Pass | Pass | Unit, persistence, migration, contract, permission, regression |
| Security Gate | Pass | Pass | Trusted ingress; response sau authorization |
| Compatibility Gate | Pass | Pass | Nullable legacy; response additive |
| Observability Gate | Pass | Pass | Log source code, không log nội dung |
| Complexity Gate | Pass | Pass | Tái sử dụng flow hiện có |
| Specialist Skill Gate | Pass | Pass | Đã route specialist skills |
| Release Gate | Pass | Pass | Có rollout/rollback và smoke check |

## Câu hỏi kỹ thuật cần research

- **TQ-001**: Database/repo migration sở hữu `public.conversation` trong database `agentdb`?
- **TQ-002**: Source xác định ở đâu để tránh client tự khai?
- **TQ-003**: Tương thích conversation lịch sử và response consumer thế nào?

## Thiết kế tổng quan

**Luồng chính**:
1. Trusted ingress xác định `ConversationSource`; current FE endpoint mapping `Production`.
2. Application truyền source trong `CreateConversationCommand` tới Domain `Conversation`.
3. Repository lưu source; API trả source trong `ConversationResponse`; FE đọc cùng field.
4. Migration nullable giữ row cũ `NULL`; row mới phải nhận mã hợp lệ.

**Component/module tham gia**:
- `Flex.Agent.Domain.Conversations`: enum và invariant.
- `Flex.Agent.Application.Conversations`: create command/context.
- `Flex.Agent.Infrastructures.Persistence`/`Repositories`: conversion và persistence.
- `Flex.Agent.Api.DTOs`/`Controllers`: response; không tin source client.
- `flex-database/agentdb`: SQL migration/changelog.
- `flex-microfrontend/src/app/core/conversations`: model/API consumer.

**Boundary/failure**:
- Ngoài bốn mã bị từ chối.
- Thiếu source chỉ hợp lệ khi đọc legacy, không hợp lệ khi tạo mới.
- Retry không tạo source mâu thuẫn; message sequence flow không đổi.

## Traceability từ spec sang thiết kế kỹ thuật

| Spec | Thiết kế/artefact | Kiểm thử |
|------|-------------------|----------|
| US-001, FR-001..FR-003, BR-001..BR-006 | `ConversationSource`, create command/context, repository + EF | Domain/repository/controller tests |
| US-002, FR-004..FR-006 | `ConversationResponse`, Angular model, nullable legacy read | API/TypeScript contract + regression |
| SEC-001..SEC-002 | Trusted ingress; existing tenant auth | Unauthorized/tenant tests |
| NFR-001..NFR-003 | Single-column read/write; existing indexes | Migration/smoke validation |

## Phân tích tác động

- **Data**: `public.conversation.conversation_source` nullable integer-compatible; new rows valid source, old rows null.
- **API**: `ConversationResponse` thêm field additive; consumer cũ bỏ qua được.
- **Frontend**: model thêm source union numeric/null; không đổi layout.
- **Permission**: giữ tenant/conversation authorization.
- **Audit**: source lưu tại create, không có update path.
- **Concurrency/retry**: source đi cùng command; message flow không đổi.
- **Realtime**: không đổi event trong feature này.

## API/Contract Detail

`POST /api/v1/conversations` giữ request hiện tại; server/trusted ingress chọn source. Current browser/FE flow map `Production`; ingress riêng map `Preview`, `Playground`, `Api` khi được tích hợp. Không cho client dùng request/header tùy ý làm authority.

Response thêm:

```json
{ "id": "uuid", "conversationSource": 1 }
```

Giá trị mới là `1..4`; legacy có thể `null`. Tên wire bám serializer convention hiện tại.

## Permission Matrix

| Hành động | End-user có quyền | Admin/operator có quyền | Client không được quyền |
|-----------|-------------------|-------------------------|-------------------------|
| Tạo Production | Cho phép | Cho phép theo tenant | Từ chối |
| Tạo Preview/Playground/Api | Chỉ qua trusted ingress | Chỉ qua trusted ingress | Không tự khai source |
| Đọc source | Khi được xem conversation | Khi được xem conversation | Từ chối |
| Sửa source | Không áp dụng | Không áp dụng | Từ chối; bất biến |

## Dữ liệu & Migration

**Database đích**: PostgreSQL database `agentdb`, schema mặc định `public`, table `conversation`.

**Repo sở hữu migration**: `flex-database/agentdb`, theo `docs/architecture/system-map.md` và `flex-database/agentdb/migrations/V1.3__create_chat_conversation_message.sql`.

**Migration**: Gộp vào `V1.3__create_chat_conversation_message.sql`; bảng và `conversation_source` được tạo trực tiếp trong schema mặc định `public`.

- Add nullable column và check constraint `NULL` hoặc `1,2,3,4`.
- Không backfill row cũ.
- New application writes valid source.
- Không thêm index trong MVP; query/reporting theo source là scope riêng.
- Rollback code trước; chỉ drop column khi không còn consumer phụ thuộc.

## Quyết định kỹ thuật

| Quyết định | Lý do | Phương án loại |
|------------|-------|----------------|
| Enum `ConversationSource` mã 1..4 | Domain validation tập trung | Magic values rải rác |
| Trusted creation context | Ngăn client giả mạo | Request/header làm authority |
| Nullable legacy | Không có evidence backfill | Default Production hoặc thêm `Unknown=0` |
| Migration tại `flex-database/agentdb` | Khớp ownership | EF migration trong service |
| Không index/filter UI MVP | Chưa có use case đo được | Dashboard/index trước use case |

## Chiến lược kiểm thử

- Domain: bốn mã hợp lệ, invalid, bất biến, legacy null.
- Repository/EF: lưu/đọc/conversion/list và null legacy.
- API/contract: response field, client override bị bỏ qua/từ chối, unauthorized.
- Database: apply V1.3, constraint, old rows null, rollback rehearsal.
- Frontend: TypeScript compile với `1..4` và `null`.
- Regression/manual: create/append/idempotency/tenant và Production smoke.

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/000037-add-conversation-source/{spec,plan,research,data-model,quickstart}.md
specs/000037-add-conversation-source/contracts/conversation-contract.md
```

### Source code (repository root)

```text
flex-agent-service/src/Flex.Agent.Domain/Conversations/ConversationSource.cs
flex-agent-service/src/Flex.Agent.Domain/Conversations/Conversation.cs
flex-agent-service/src/Flex.Agent.Application/Conversations/ConversationContracts.cs
flex-agent-service/src/Flex.Agent.Infrastructures/{Persistence/AppDbContext.cs,Repositories/ConversationRepository.cs}
flex-agent-service/src/Flex.Agent.Api/{DTOs/ConversationDtos.cs,Controllers/ConversationsController.cs}
flex-agent-service/tests/Flex.Agent.Tests/Conversations/*Tests.cs
flex-database/agentdb/{migrations/V1.3__create_chat_conversation_message.sql,changelog/releases/1.3.0/changelog.xml}
flex-microfrontend/src/app/core/conversations/{conversation.models.ts,conversation-api.service.ts}
```

## Rollout & Rollback

1. Apply additive nullable migration.
2. Deploy service đọc null và ghi source hợp lệ.
3. Deploy consumer hiểu `conversationSource`.
4. Enable trusted ingress mappings; current FE là Production.
5. Smoke-test từng ingress và invalid-source rejection.

Rollback giữ response additive và đọc null; chỉ rollback migration khi xác nhận không còn code/consumer dùng column. Không xóa source đã ghi nhận trong rollback thường.

## Observability & Debug

**Log cần có**: `traceId`, `tenantId`, `conversationId`, `conversationSource`, `creationIngress`, `result`.

**Dữ liệu không được log**: Token, secret, API key, message content, prompt, PII.

**Metric cần theo dõi**: create count theo source, invalid-source rejection, null-legacy read, create failure rate.

**Trace/Correlation**: Giữ `traceId`/`correlationId` hiện có qua HTTP → application → persistence.

**Cách kiểm tra sau release**: Metric bốn source; không có mã ngoài `1..4`; smoke GET list/detail.

**Tình huống debug chính**: Ingress map sai, legacy null, constraint failure, tenant authorization failure.

## Theo dõi độ phức tạp

Không có vi phạm cần biện minh; tái sử dụng command/repository/DTO hiện có.

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase rõ.
- [x] Câu hỏi kỹ thuật đã resolve trong research.
- [x] Thiết kế tổng quan mô tả flow, component, boundary.
- [x] Idempotency/concurrency/retry đã đánh giá.
- [x] P1/P2 map sang module/path, contract, data và test.
- [x] Database/API/permission/audit/integration đã đánh giá.
- [x] Contract change có consumer và compatibility check.
- [x] Migration/backfill/compatibility rõ.
- [x] Database đích/repo migration đối chiếu system map.
- [x] Quyết định kỹ thuật có lý do và alternatives.
- [x] Test strategy bao phủ unit/integration/contract/security/manual/regression.
- [x] Rollout/rollback/backward compatibility rõ.
- [x] Observability/debug plan đầy đủ.
- [x] Không còn cây thư mục mẫu/generic.
- [x] Constitution gate không blocker.
