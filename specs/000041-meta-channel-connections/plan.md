# Kế hoạch triển khai: Kết nối kênh Instagram và Facebook qua Meta

**Branch**: `000041-meta-channel-connections` | **Ngày**: 2026-08-27 | **Đặc tả**: [spec.md](./spec.md)

**Đầu vào**: Đặc tả tính năng từ `specs/000041-meta-channel-connections/spec.md`

## Tóm tắt

**Yêu cầu chính từ spec**:
- Tạo và duy trì phiên kết nối có scope theo `Agent`, kênh và phương thức Meta.
- Cho phép kết nối Instagram Business/Creator và Facebook Page qua Meta OAuth; callback phải khám phá đúng tài nguyên người dùng được quản lý.
- Cho phép chọn một tài nguyên hợp lệ, hoàn tất liên kết, truy vấn trạng thái và ngắt kết nối idempotent.
- Không để lộ credential; không tạo duplicate active connection; không làm thay đổi các kết nối đã hoàn tất khi một phiên mới thất bại.

**Hướng tiếp cận kỹ thuật dự kiến**: Giữ các route Instagram hiện có làm compatibility adapter, bổ sung Facebook Page flow, và đưa orchestration vào `Flex.Agent.Application` qua các port explicit. `IMetaOAuthService` và `IMetaGraphService` là boundary dùng chung; provider DTO/HTTP chỉ nằm trong `Flex.Agent.Infrastructures`. Hai channel có connection service riêng vì logic discovery/complete khác nhau. MVP chỉ triển khai method `Meta`; không thêm `Direct Instagram`, messaging hoặc webhook.

**Kết quả sau research**: Xem [research.md](./research.md). Quyết định cuối cùng là:
- Dùng Meta/Facebook Login flow cho cả hai resource; Instagram phải là Professional account liên kết với Facebook Page trong flow này.
- Dùng `IIntegrationSessionStore` với TTL ngắn để giữ state/candidate/token tạm; credential persisted tiếp tục được mã hóa và liên kết qua connection record.
- Dữ liệu runtime thuộc PostgreSQL `agentdb`; migration thuộc repo `flex-database/agentdb`, không thêm migration mới vào service repo.
- Giữ `MetaAccountConnection` và `InstagramPageConnection` để tương thích, thêm `FacebookPageConnection` thay vì đại tu thành generic table trong MVP.

## Phạm vi kỹ thuật

**Trong phạm vi**:
- `flex-agent-service`: application ports, Meta provider client, Instagram/Facebook connection orchestration, session state, persistence mapping, permission, audit log và API adapters.
- `flex-database`: migration mới cho `agentdb` và changelog release kế tiếp; tương thích với các bảng Instagram hiện hữu hoặc legacy deployment.
- `flex-microfrontend`: tích hợp HTTP vào `AgentEditorWizard`, hiển thị hai channel, redirect OAuth, discovery/selection/complete, connected state và disconnect.
- Unit, integration, permission/security, contract và frontend component tests cho các luồng P1/P2.

**Ngoài phạm vi kỹ thuật**:
- Gửi/nhận tin nhắn, webhook, conversation routing, posting, ads, analytics và content management.
- `Direct Instagram` hoặc provider ngoài Meta; chỉ để boundary tương lai, không đăng ký implementation chưa dùng.
- Tự động refresh token, background worker, Redis/distributed session và thay đổi các luồng webhook Instagram hiện có.
- Xóa/đổi tên các bảng hoặc route Instagram hiện hữu trong MVP.

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: Backend .NET 9/C# với nullable enabled; frontend Angular hiện hữu; database PostgreSQL + Liquibase SQL-first.

**Service/App liên quan**:
- `flex-agent-service`: solution gồm `Flex.Agent.Domain`, `Flex.Agent.Application`, `Flex.Agent.Infrastructures`, `Flex.Agent.Api`, `Flex.Agent.Tests`.
- `flex-microfrontend`: Angular `agent-catalog` và `AgentEditorWizard`.
- `flex-database/agentdb`: migration/changelog cho PostgreSQL `agentdb`.
- Meta Graph API là external provider.

**Convention skill áp dụng**:
- `flex-agent-service` → `flex-dotnet-engineering`, `flex-naming-convention`.
- `flex-database` → `flex-database-engineering`.
- `flex-microfrontend` → `flex-frontend-engineering`.

**Phụ thuộc chính**: ASP.NET Core controllers/JWT, MediatR 12.5, EF Core/Npgsql, `IMemoryCache`, `HttpClientFactory`, `System.Text.Json`, Angular `HttpClient`, `environment.agentApiBaseUrl`, Meta OAuth/Graph API.

**Lưu trữ**: PostgreSQL `agentdb` cho agent và completed channel connections; `IMemoryCache` được bọc sau `IIntegrationSessionStore` cho state/candidate tạm trong MVP; không lưu session vào database.

**Kiểm thử**: xUnit hiện hữu với EF InMemory/MVC test utilities; Angular component/service tests theo cấu hình hiện tại; contract check bằng HTTP test hoặc fixture provider giả lập; manual test với Meta test app.

**Nền tảng chạy**: ASP.NET Core web service trong môi trường container; Angular chạy trên browser được ứng dụng hỗ trợ; Meta gọi callback qua HTTPS.

**Đơn vị deploy**: `flex-agent-service`, `flex-microfrontend`, và migration release của `flex-database/agentdb`.

**Loại project**: web-service + admin-web + database migration.

**Mục tiêu hiệu năng**: Mỗi bước nội bộ phản hồi trong 3 giây theo `NFR-001`, không tính thời gian Meta OAuth; discovery phải timeout rõ ràng và không làm thay đổi connection đã hoàn tất.

**Ràng buộc**: Meta permission/app review có thể thay đổi; không log token/secret; state phải single-use, TTL 10 phút, bound với agent/channel/method; callback redirect chỉ dùng URL cấu hình an toàn.

**Quy mô/Phạm vi**: MVP cho số lượng connection nhỏ; các query list/lookup phải có index theo `agent_id`, external resource id và status. Nếu triển khai nhiều replica, `IMemoryCache` phải được thay bằng distributed store trước khi mở rộng production.

## Kiểm tra constitution

*GATE: Phải đạt trước Phase 0 research. Kiểm tra lại sau Phase 1 design.*

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| Scope Gate | Pass | Pass | Chỉ connection lifecycle; messaging/webhook và provider khác ngoài scope. |
| Traceability Gate | Pass | Pass | US/FR/BR/SEC/NFR P1/P2 được map ở bảng traceability và contract. |
| Security Gate | Pass | Pass | JWT agent scope, provider permission, single-use state, encrypted credential; không trả secret. |
| Test Gate | Pass có điều kiện | Pass | Có unit/integration/contract/permission/frontend/manual coverage; Meta sandbox phụ thuộc cấu hình ngoài repo. |
| Compatibility Gate | Pass có điều kiện | Pass | Route Instagram và bảng Instagram giữ nguyên; Facebook là additive; migration expand-only. |
| Observability Gate | Pass có điều kiện | Pass | Có structured event, correlation id, metric outcome/latency và smoke check. |
| Complexity Gate | Pass | Pass | Chỉ dùng abstraction tại boundary Meta và hai channel có orchestration khác nhau; không tạo generic integration framework. |
| Release Gate | Pass có điều kiện | Pass có điều kiện | Phải chạy migration `agentdb` trước service và xác nhận Meta app/redirect URI/permissions tại staging. |
| Database Ownership Gate | Pass có điều kiện | Pass | `agentdb` và migration owner được xác định theo `docs/architecture/system-map.md` và precedent 000026; trạng thái legacy table được xử lý bằng preflight. |
| Specialist Skill Gate | Pass | Pass | Đã route và áp dụng `flex-using-agent-skills`, `flex-dotnet-engineering`, `flex-database-engineering`, `flex-frontend-engineering`, `flex-naming-convention`. |

## Câu hỏi kỹ thuật cần research

- **TQ-001**: Boundary nào được dùng chung giữa Instagram và Facebook mà không tạo generic abstraction một lần? → Đã trả lời trong [research.md](./research.md): chỉ dùng Meta OAuth/Graph và session store; orchestration giữ riêng theo channel.
- **TQ-002**: Flow Meta hiện có và API version/permission nào có thể tái sử dụng? → Đã trả lời: tái sử dụng flow `/me`, `/me/accounts`, page token và linked Instagram account; version/scope chuyển sang configuration, phải xác nhận với Meta app trước release.
- **TQ-003**: Database đích và repo migration nào là source of truth? → Đã trả lời: PostgreSQL `agentdb`, migration tại `flex-database/agentdb`.
- **TQ-004**: Làm sao giữ tương thích với `instagram_page_connections` và route hiện tại? → Đã trả lời: không drop/rename; refactor service qua port, giữ legacy controller contract và thêm bảng Facebook additive.
- **TQ-005**: Callback quay về đâu trong Angular editor? → Đã trả lời: redirect về `/agents/{agentId}/edit` hoặc `/settings` đã cấu hình, kèm opaque `sessionId`, `channel`, `status`; wizard đọc query params và tải discovery.

## Thiết kế tổng quan

**Luồng chính**:
1. `AgentEditorWizard` yêu cầu connect cho `instagram` hoặc `facebook`; API xác nhận user có quyền cấu hình agent, tạo session state bound với agent/channel/method và trả OAuth URL.
2. Browser đi qua Meta OAuth. Callback adapter xác thực state single-use, lấy user token, gọi `IMetaGraphService` để discovery pages; Instagram flow lọc linked Professional account, Facebook flow giữ managed pages.
3. Backend lưu discovery candidates và credential tạm trong `IIntegrationSessionStore`, redirect về editor với session opaque; frontend gọi result endpoint và hiển thị candidate hợp lệ/không hợp lệ.
4. User chọn một candidate; frontend gọi complete. Application handler đọc lại candidate từ session, revalidate agent scope/resource ownership/duplicate, mã hóa credential và ghi connection trong transaction; một lỗi không được sửa completed connection khác.
5. Frontend tải connected state từ list endpoint. Disconnect gọi channel service, kiểm tra scope, đánh dấu disconnected và xóa/thu hồi credential reference cục bộ; lặp lại trả trạng thái hiện tại.

**Component/module tham gia**:
- `Flex.Agent.Application/Abstractions/Integrations/Meta`: `IMetaOAuthService`, `IMetaGraphService`, provider-neutral records và `IIntegrationSessionStore`.
- `Flex.Agent.Application/Abstractions/Integrations/Instagram` và `Facebook`: connection service ports/context/result; không chứa `HttpClient` hay provider response DTO.
- `Flex.Agent.Infrastructures/Integrations/Instagram` và `Facebook`: channel-specific connection services cho connect, callback/discovery, complete, list, disconnect; API controllers gọi qua application interfaces theo convention hiện hữu của service.
- `Flex.Agent.Infrastructures/Integrations/Meta`: `MetaOAuthService`, `MetaGraphService`, `MetaOptions`, provider JSON models; scope/version/configurable URL.
- `Flex.Agent.Infrastructures/Integrations/Instagram` và `Facebook`: orchestration implementations gọi Meta ports và persistence/session abstractions.
- `Flex.Agent.Api/Channels/Instagram`: route-compatible adapter hiện hữu; `Flex.Agent.Api/Controllers/Integrations/FacebookController.cs` và callback adapter mới.
- `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/`: start OAuth, discovery selection, complete, list và disconnect.
- `flex-database/agentdb`: completed connection schema và index/constraint.

**Điểm mở rộng/thay đổi chính**:
- Chuyển DTO Meta hiện đang nằm trong Application sang Infrastructure; Application chỉ nhận provider-neutral models.
- Tách `InstagramConnectionService` và `FacebookConnectionService`; không dùng `IChannelConnectionService` generic vì hai discovery contract khác nhau.
- Giữ `InstagramPageConnection` hiện hữu; thêm `FacebookPageConnection` với các trường page chung, tránh đưa field Instagram vào Facebook.
- Chuẩn hóa cấu hình `MetaOptions` qua `IOptions`; không hardcode API version, app secret, redirect URI trong service.
- Frontend bổ sung Facebook channel và biến modal hiện hữu thành điểm bắt đầu cho hai channel; kết quả discovery là UI state riêng.

**Luồng thay thế/lỗi chính**:
- User hủy/Meta trả lỗi → session failed, redirect lỗi có mã thân thiện, không ghi completed connection.
- State sai, hết hạn, đã dùng hoặc không khớp agent/channel/method → từ chối, không gọi bước complete.
- Không có resource hoặc thiếu permission → hiển thị hướng dẫn kiểm tra quyền/thử lại.
- Candidate bị agent khác claim trước complete → trả conflict, reload discovery; không overwrite connection hiện hữu.
- Meta timeout/5xx → lỗi retryable theo request, session không làm thay đổi dữ liệu completed.
- Disconnect không tìm thấy hoặc đã disconnected → trả trạng thái idempotent, không phát sinh lỗi nghiệp vụ mới.

**Thay đổi boundary giữa service/module**:
- `Flex.Agent.Application` sở hữu port và contract; `Flex.Agent.Infrastructures` sở hữu Meta HTTP, JSON, orchestration và EF persistence; `Flex.Agent.Api` chỉ binding/auth/mapping.
- `flex-database` là owner migration của `agentdb`; `flex-agent-service` chỉ map schema, không tạo EF migration mới.
- Frontend chỉ nhận URL/session/candidate metadata, không nhận access token.

**Idempotency/Concurrency**:
- State key single-use; complete chỉ chấp nhận session ở discovered state và candidate thuộc session.
- Unique index theo external resource bảo vệ race giữa hai complete request; map unique violation thành conflict, không retry mù.
- Complete cùng candidate cho cùng agent trả connection hiện có hoặc kết quả idempotent.
- Disconnect dùng trạng thái transition; request lặp không xóa dữ liệu đã được dùng bởi connection khác.
- Meta HTTP có timeout/cancellation; không retry POST side effect trong MVP.

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|------------|----------------------|---------------------|--------------|-------------|----------|
| US-001 / FR-001 / AC-001 | P1 | Đủ rõ | Connect command xác thực scope, tạo session bound và dựng Meta OAuth URL. | `flex-agent-service/src/Flex.Agent.Application/Integrations/Instagram/Connect/`; `flex-agent-service/src/Flex.Agent.Api/Channels/Instagram/InstagramChannelController.cs` | `POST /api/channels/instagram/connect` | `IntegrationConnectionSession` (cache) | Application unit + permission + API contract |
| US-002 / FR-001 / AC-005 | P1 | Đủ rõ | Facebook dùng command/service riêng nhưng tái sử dụng Meta OAuth port. | `flex-agent-service/src/Flex.Agent.Application/Integrations/Facebook/Connect/`; `flex-agent-service/src/Flex.Agent.Api/Controllers/Integrations/FacebookController.cs` | `POST /api/channels/facebook/connect` | Session cache | Unit + permission + contract |
| US-001/002 / FR-002 / BR-002 | P1 | Đủ rõ | State/session store lưu agent, channel, method, status, expiry; callback dùng một lần. | `flex-agent-service/src/Flex.Agent.Application/Abstractions/Integrations/Meta/IIntegrationSessionStore.cs`; `flex-agent-service/src/Flex.Agent.Infrastructures/Integrations/Meta/` | Callback route + `sessionId` result | Session state | State tampering/expiry/replay tests |
| US-001 / FR-003 / AC-002 | P1 | Đủ rõ | Meta graph adapter lấy managed pages và linked IG Professional account, trả metadata không secret. | `flex-agent-service/src/Flex.Agent.Infrastructures/Integrations/Meta/`; `flex-agent-service/src/Flex.Agent.Infrastructures/Integrations/Instagram/` | `GET /api/channels/instagram/connect/result` | Candidate cache; `MetaAccountConnection` at complete | Provider fixture + mapping/unit |
| US-002 / FR-003 / AC-006 | P1 | Đủ rõ | Facebook orchestration giữ các managed pages đủ permission. | `flex-agent-service/src/Flex.Agent.Infrastructures/Integrations/Facebook/` | `GET /api/channels/facebook/connect/result` | Candidate cache; `FacebookPageConnection` at complete | Provider fixture + mapping/unit |
| US-001/002 / FR-004/005 / AC-003/007 | P1 | Đủ rõ | Complete revalidate candidate/session/scope/duplicate, persist status and display metadata. | `flex-agent-service/src/Flex.Agent.Application/Integrations/Instagram/CompleteConnection/`; `flex-agent-service/src/Flex.Agent.Application/Integrations/Facebook/CompleteConnection/`; `flex-agent-service/src/Flex.Agent.Infrastructures/Persistence/` | `POST /api/channels/{channel}/connections/complete` | `MetaAccountConnection`, `InstagramPageConnection`, `FacebookPageConnection` | EF integration + concurrency + contract |
| US-003 / FR-006/007 / AC-008/009 | P2 | Đủ rõ | Channel-specific disconnect transitions state and cleans local credential reference idempotently. | `flex-agent-service/src/Flex.Agent.Application/Integrations/Instagram/Disconnect/`; `flex-agent-service/src/Flex.Agent.Application/Integrations/Facebook/Disconnect/`; `flex-agent-service/src/Flex.Agent.Api/Channels/Instagram/InstagramChannelController.cs` | `DELETE /api/channels/{channel}/connections/{id}` | Connection status/timestamps/credential fields | Unit + integration + repeat request |
| FR-008 / BR-003 | P1 | Đủ rõ | Reject provider error, invalid state, expired session, out-of-scope resource and missing permission before write. | `flex-agent-service/src/Flex.Agent.Application/Integrations/Instagram/`; `flex-agent-service/src/Flex.Agent.Application/Integrations/Facebook/`; `flex-agent-service/src/Flex.Agent.Infrastructures/Integrations/Meta/MetaGraphService.cs` | Error envelope/status mapping in [contracts](./contracts/http-api.md) | No completed row on failure | Negative integration + permission tests |
| FR-009 / BR-004 | P1 | Đủ rõ | Service precheck plus DB unique index per channel/resource; translate race conflict. | `flex-agent-service/src/Flex.Agent.Infrastructures/Persistence/AppDbContext.cs`; `flex-database/agentdb/migrations/V1.4__create_meta_channel_connections.sql` | `409 CONNECTION_CONFLICT` | Unique external resource indexes | Concurrent complete integration test |
| FR-010 / SEC-003 | P1 | Đủ rõ | Keep token only in encrypted internal fields/session store; map public DTO without credential. | `flex-agent-service/src/Flex.Agent.Infrastructures/Security/ChannelTokenEncryptionService.cs`; `flex-agent-service/src/Flex.Agent.Infrastructures/Integrations/Meta/` | Public DTOs omit token | Encryption, serialization and log inspection tests |
| SEC-001/002 / BR-001 | P1 | Đủ rõ | Reuse JWT principal and central agent-scope authorization in handlers; never trust arbitrary `agentId`. | `flex-agent-service/src/Flex.Agent.Application/Common/Authorization/`; `flex-agent-service/src/Flex.Agent.Api/Channels/Instagram/`; `flex-agent-service/src/Flex.Agent.Api/Controllers/Integrations/` | All protected routes | Agent ownership/role scope | Permission matrix tests |
| NFR-001/002/003/004 | P1 | Đủ rõ | Timeout/cancellation, stable error codes, no completed mutation on session failure, supported Angular route flow. | API + frontend service/wizard | Error contract + callback query contract | Existing connections unaffected | API timing/error + frontend/manual |

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---------|------------------|--------------------------|---------------|
| Database/Migration | `flex-database/agentdb` thêm Facebook connection table/index và bổ sung/chuẩn hóa các Meta/Instagram objects nếu target thiếu; service map thêm entity. | Legacy `AddInstagramTables.sql` trong service có thể đã được chạy ở một số môi trường; migration phải preflight/validate, không drop/rename/ghi đè dữ liệu. | `liquibase validate`, `update-sql`, đối chiếu schema staging; EF InMemory/integration mapping. |
| API/Contract | Giữ `/api/channels/instagram/*`; thêm `/api/channels/facebook/*`; thêm complete/list contract và error codes có version-compatible mapping. | Existing Instagram consumers không đổi route/payload; legacy multi-selection adapter phải được document, MVP UI chọn một resource. | Contract fixture + smoke call + frontend service tests. |
| Permission/Security | Authz theo agent owner/admin/configurator; provider ownership recheck; token không xuất hiện public/log/audit. | Rủi ro hiện tại controller tự kiểm tra quyền có thể lệch giữa channel; đưa check vào shared Application policy và giữ adapter mỏng. | Unauthorized/cross-agent/role tests; review serialized DTO/log fields. |
| Logging/Audit | Ghi start, callback outcome, complete, conflict, disconnect với `traceId`, `agentId`, `channel`, `connectionId`, outcome/reason. | Không log `code`, state raw, access token, app secret, credential reference hoặc user data không cần thiết. | Structured log assertion và audit record inspection. |
| UI/UX | Publish step có Instagram/Facebook, connect/discovery/selection/connected/disconnect states, inline retry guidance. | Modal hiện tại chỉ emit local method; phải nối HTTP và callback query nhưng giữ Skote/Bootstrap/isVisible pattern. | Angular component/service tests + manual browser flow. |
| Job/Worker/Integration | Meta OAuth/Graph là external synchronous integration; không thêm webhook/worker. | API version, permission review, timeout và provider error shape có thể thay đổi; config hóa và có smoke test staging. | Mock HTTP provider + Meta test app smoke test. |

## API/Contract Detail

**Có thay đổi contract không**: Có — additive cho Facebook/canonical complete/list; các route Instagram hiện tại được giữ tương thích.

Chi tiết đầy đủ ở [contracts/http-api.md](./contracts/http-api.md). Tóm tắt:

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|----------|------|----------|---------------------|------------------------|
| `POST /api/channels/instagram/connect` | API | Giữ route; handler mới delegate vào Application | Có | Frontend hiện tại/consumer nội bộ |
| `GET /api/channels/instagram/callback` | OAuth callback | Giữ route; state validation và redirect được chuẩn hóa | Có | Meta App + browser |
| `GET /api/channels/instagram/connect/result` | API | Giữ response metadata, không thêm credential | Có | Frontend |
| `POST /api/channels/instagram/pages/confirm` | API | Giữ legacy payload; adapter map sang complete use case và giới hạn theo spec | Có điều kiện | Existing Instagram UI |
| `GET /api/channels/instagram/connections` và `DELETE /api/channels/instagram/connections/{id}` | API | Giữ route và semantics status/disconnect | Có | Frontend |
| `POST /api/channels/facebook/connect` | API | Mới | Có | Frontend mới |
| `GET /api/channels/facebook/callback` | OAuth callback | Mới | Có | Meta App + browser |
| `GET /api/channels/facebook/connect/result` | API | Mới | Có | Frontend mới |
| `POST /api/channels/facebook/connections/complete` | API | Mới | Có | Frontend mới |
| `GET /api/channels/facebook/connections` và `DELETE /api/channels/facebook/connections/{id}` | API | Mới | Có | Frontend mới |

## Permission Matrix

| Vai trò/Scope | Xem | Tạo | Sửa | Xóa | Duyệt/Xử lý | Ghi chú |
|---------------|-----|-----|-----|-----|-------------|---------|
| Agent owner/configurator | Có | Có | Có | Có | Có | Chỉ trong agent được principal cấp quyền; credential không hiển thị. |
| Agent admin được ủy quyền | Có | Có | Có | Có | Có | Theo policy quản trị agent hiện hữu. |
| Viewer/member không có configure scope | Không | Không | Không | Không | Không | Không được suy ra quyền từ việc xem agent. |
| User ngoài agent/workspace | Không | Không | Không | Không | Không | Trả unauthorized/forbidden như policy hiện hữu, không tiết lộ resource tồn tại. |
| Meta provider callback | Không áp dụng | Không áp dụng | Không áp dụng | Không áp dụng | Có giới hạn | Chỉ được tiếp tục session bằng state hợp lệ; không phải user role. |
| Internal service | Đọc internal | Không áp dụng | Cập nhật status/credential | Không áp dụng | Có | Chỉ dùng trong flow được xác thực; không public API. |

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Có.

**Database đích**: PostgreSQL `agentdb`, database dùng chung hiện có của Agent Platform/Agent Catalog. Quyết định dựa trên `docs/architecture/system-map.md` mục `flex-agent-service`/`flex-database` và precedent `specs/000026-agent-service-restructure`; không tạo database mới và không dùng database riêng của service.

**Repo chứa migration**: `flex-database`, thư mục `agentdb/`, vì `system-map.md` xác định đây là source of truth cho schema Agent Platform và Constitution VI yêu cầu migration không nằm trong service repo. `flex-agent-service/src/Flex.Agent.Infrastructures/Persistence/Migrations/AddInstagramTables.sql` được xem là legacy/deployment reference, không include vào Liquibase.

**Migration**:
- Tạo release/changelog mới kế tiếp trong `flex-database/agentdb/changelog` và SQL `migrations/V1.4__create_meta_channel_connections.sql` theo convention hiện tại.
- Bảo đảm `meta_account_connections` và `instagram_page_connections` có schema mà service hiện tại đang map; nếu target đã có do legacy rollout, preflight xác nhận definition tương thích và chỉ bổ sung object còn thiếu.
- Tạo `facebook_page_connections`: `id`, `meta_account_connection_id`, `agent_id`, `facebook_page_id`, display name/avatar, encrypted page credential, lifecycle `status`, timestamps.
- Tạo index lookup theo `agent_id`, `facebook_page_id`, `status`; unique index `facebook_page_id` để một Page không bị nhiều agent claim đồng thời, nhất quán với invariant channel resource.
- Giữ status canonical lowercase (`active`, `disconnected`, `error`) trong bảng mới; EF mapping dùng enum/constant. Không tạo cross-database FK. FK trong `agentdb` chỉ dùng khi đã phù hợp với schema hiện hữu.
- Không persist `IntegrationConnectionSession` trong DB; session TTL/cache là dữ liệu tạm, không seed.

**Backfill/Cleanup**:
- Không backfill business data mới nếu Facebook table chưa tồn tại.
- Nếu preflight phát hiện bảng Instagram legacy đã có dữ liệu, không copy/delete tự động; xác nhận column/index và giữ dữ liệu nguyên trạng.
- Complete/disconnect mới phải xử lý credential reference theo chính sách; không xóa `MetaAccountConnection` nếu còn channel connection khác.

**Tương thích dữ liệu cũ**: Existing Instagram records tiếp tục được đọc từ `instagram_page_connections`; EF mapping và route không đổi tên. Facebook records chỉ ghi vào bảng mới. Migration expand-only, deploy trước application code.

**Rủi ro dữ liệu**:
- Legacy schema có thể tồn tại khác nhau giữa môi trường; preflight phải fail-fast khi definition không tương thích.
- Unique conflict có thể xảy ra đồng thời; service map thành lỗi nghiệp vụ 409.
- Credential cleanup không được xóa token dùng chung bởi connection khác; cần transaction và reference check.

**Cách xác minh**:
- Chạy `liquibase validate` và `liquibase update-sql` từ `flex-database/agentdb`.
- Review generated SQL: không có `DROP TABLE`, broad delete hoặc thay đổi changeset đã chạy.
- Staging preflight kiểm tra tables/index/columns; sau migration query `information_schema` và `liquibase status --verbose`.
- Chạy service integration tests với schema tương ứng và test complete/disconnect lặp.

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| DEC-001 | Application ports `IMetaOAuthService`/`IMetaGraphService`; provider implementation ở Infrastructure | Tách HTTP/JSON/config khỏi use case, tái sử dụng thật cho Instagram và Facebook | Gọi `HttpClient` trực tiếp từ handler/controller | Vi phạm layer boundary, khó mock và lộ provider DTO. |
| DEC-002 | Hai connection service riêng cho Instagram/Facebook | Discovery và dữ liệu resource khác nhau; trace rõ theo use case | Một `IChannelConnectionService<T>` generic | Tạo abstraction rộng trước khi có channel thứ ba, tăng complexity và mapping runtime. |
| DEC-003 | MVP chỉ đăng ký `Meta` method; chưa tạo `DirectInstagramConnectionService`/resolver | Spec chỉ yêu cầu Meta; hiện chưa có direct provider implementation thực tế | Đăng ký resolver với implementation giả hoặc Direct chưa hoàn thiện | Abstraction dùng một lần và tạo UI/API branch không có acceptance criteria. |
| DEC-004 | Giữ bảng Instagram hiện hữu, thêm `facebook_page_connections` | Giảm rủi ro regression và migration; tránh ép Facebook vào field IG-specific | Đổi toàn bộ sang `channel_connections` ngay | Cần migration/backfill/dual-read lớn, không cần cho MVP. |
| DEC-005 | `IIntegrationSessionStore` bọc `IMemoryCache`, TTL 10 phút, opaque session id | Tái sử dụng hạ tầng hiện có, session tạm không cần persistence; có boundary để thay store khi scale | Lưu token/session vào DB hoặc dùng `IMemoryCache` rải trực tiếp trong controller | DB giữ secret tạm quá lâu; controller coupling và khó kiểm soát replay. |
| DEC-006 | Giữ route Instagram và thêm route Facebook; callback redirect về editor route cấu hình | Không phá Meta redirect/consumer hiện có; frontend editor là context thực tế | Đổi toàn bộ sang route `/api/integrations/*` ngay | Breaking change không cần thiết trong feature additive. |
| DEC-007 | Migration tại `flex-database/agentdb` | Đúng ownership trong system map và Constitution VI | Thêm SQL vào `flex-agent-service` hoặc EF migration | Phân tán source of truth, trái convention workspace. |

## Chiến lược kiểm thử

**Unit test**:
- Test `MetaOAuthService` URL/expiry/config validation mà không log secret.
- Test `MetaGraphService` mapping pages/linked IG/error/timeout với fake `HttpMessageHandler`.
- Test session store TTL, agent/channel/method binding, single-use và invalid transition.
- Test Instagram/Facebook orchestration: candidate filtering, complete, duplicate, no-permission, provider error.
- Test encrypted credential round-trip và public DTO serialization không có token.

**Integration test**:
- EF InMemory hoặc PostgreSQL test fixture cho complete/list/disconnect, status transition, unique conflict và credential reference cleanup.
- API test qua `WebApplicationFactory` cho auth scope, status code/error envelope và callback redirect.
- Migration preview/validation và schema mapping test; không chạy migration production trong test.

**Contract test**:
- Kiểm tra request/response/status theo [contracts/http-api.md](./contracts/http-api.md), bao gồm legacy Instagram payload.
- Frontend service fixture kiểm tra URL, query params, response mapping và không lưu token.

**Permission/security test**:
- owner/admin thành công; viewer/member/ngoài agent bị từ chối.
- Cross-agent state/candidate/connection id bị từ chối không lộ dữ liệu.
- Callback replay, state tampering, expired state, provider permission error.
- Log/audit không chứa OAuth code, access token, app secret hoặc raw state.

**E2E/manual test**:
- Meta test app: connect Instagram linked Professional account, connect Facebook Page, select candidate, complete, refresh editor, disconnect và repeat.
- Test cancel, no resource, missing permission, resource đã claim, callback hết hạn trên browser được hỗ trợ.

**Regression test**:
- Toàn bộ `dotnet test Flex.Agent.sln`, đặc biệt các Instagram OAuth/page/webhook/security tests và `MessengerRegressionTests`.
- Angular tests cho `AgentEditorWizardComponent`, `AgentStepPublishComponent`, modal hiện hữu và service.
- Smoke test route Instagram hiện hữu và webhook contract; feature này không sửa behavior webhook/messaging.

## Tác động tài liệu nghiệp vụ

- **Kết quả Documentation Impact Gate**: CÓ CẬP NHẬT
- **Tham chiếu đánh giá**: `spec.md` §20
- **Tài liệu hiện hữu đã cập nhật**: `docs/business/13-meta-channel-connections.md`; index tại `docs/business/business-docs-index.md`.
- **Cập nhật còn lại sau implementation**: Không có task tài liệu mặc định. Nếu implementation thay đổi phương thức người dùng, scope kênh, quy tắc quyền hoặc trạng thái so với spec, phải cập nhật `spec.md` và chạy lại `$speckit-docbiz` trước khi sinh task tương ứng.

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/000041-meta-channel-connections/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── http-api.md
└── tasks.md                 # tạo bởi $speckit-tasks, chưa tạo ở bước này
```

### Source code (các repository thực tế)

```text
flex-agent-service/
├── src/
│   ├── Flex.Agent.Domain/
│   │   └── Channels/
│   │       ├── ChannelType.cs
│   │       ├── ConnectionStatus.cs
│   │       ├── Instagram/InstagramPageConnection.cs
│   │       └── Facebook/FacebookPageConnection.cs
│   ├── Flex.Agent.Application/
│   │   ├── Abstractions/Integrations/
│   │   │   ├── Meta/IMetaOAuthService.cs
│   │   │   ├── Meta/IMetaGraphService.cs
│   │   │   ├── Meta/IIntegrationSessionStore.cs
│   │   │   ├── Instagram/IInstagramConnectionService.cs
│   │   │   └── Facebook/IFacebookConnectionService.cs
│   │   └── Integrations/
│   │       ├── Instagram/Connect/
│   │       ├── Instagram/Callback/
│   │       ├── Instagram/CompleteConnection/
│   │       ├── Instagram/ListConnections/
│   │       ├── Instagram/Disconnect/
│   │       ├── Facebook/Connect/
│   │       ├── Facebook/Callback/
│   │       ├── Facebook/CompleteConnection/
│   │       ├── Facebook/ListConnections/
│   │       └── Facebook/Disconnect/
│   ├── Flex.Agent.Infrastructures/
│   │   ├── Integrations/Meta/MetaOAuthService.cs
│   │   ├── Integrations/Meta/MetaGraphService.cs
│   │   ├── Integrations/Meta/MetaOptions.cs
│   │   ├── Integrations/Instagram/MetaInstagramConnectionService.cs
│   │   ├── Integrations/Facebook/MetaFacebookConnectionService.cs
│   │   ├── Persistence/AppDbContext.cs
│   │   └── Security/ChannelTokenEncryptionService.cs
│   └── Flex.Agent.Api/
│       ├── Channels/Instagram/InstagramChannelController.cs  # compatibility adapter
│       └── Controllers/Integrations/FacebookController.cs
└── tests/Flex.Agent.Tests/
    ├── Channels/Instagram/                          # regression tests hiện hữu
    ├── Channels/Facebook/
    └── Integrations/Meta/                           # test mới

flex-microfrontend/src/app/features/agent-catalog/
├── models/channel-connection.model.ts
├── services/agent-channel-connection.service.ts
└── components/
    ├── agent-editor-wizard/agent-editor-wizard.component.ts
    ├── agent-editor-wizard/agent-editor-wizard.component.html
    ├── agent-editor-wizard/agent-editor-wizard.component.spec.ts
    ├── agent-editor-wizard/steps/agent-step-publish/agent-step-publish.component.ts
    ├── agent-editor-wizard/steps/agent-step-publish/agent-step-publish.component.html
    ├── agent-editor-wizard/steps/agent-step-publish/agent-step-publish.component.spec.ts
    ├── agent-editor-wizard/steps/agent-step-publish/channels/instagram/agent-instagram-connect-modal.component.ts
    ├── agent-editor-wizard/steps/agent-step-publish/channels/instagram/agent-instagram-connect-modal.component.html
    ├── agent-editor-wizard/steps/agent-step-publish/channels/instagram/agent-instagram-connect-modal.component.spec.ts
    └── agent-editor-wizard/steps/agent-step-publish/channels/connection-result/
        agent-channel-connection-result-modal.component.ts
        agent-channel-connection-result-modal.component.html
        agent-channel-connection-result-modal.component.scss
        agent-channel-connection-result-modal.component.spec.ts

flex-database/agentdb/
├── changelog/db.changelog-master.xml
├── changelog/releases/1.4.0/changelog.xml
└── migrations/V1.4__create_meta_channel_connections.sql
```

**Quyết định cấu trúc**: Dùng vertical slice trong `Application/Integrations/Instagram/` và `Application/Integrations/Facebook/`, cùng shared provider ports tại `Application/Abstractions/Integrations/Meta/`; không tạo project mới. Giữ các path hiện hữu khi sửa Instagram để giảm diff; thêm model/table Facebook riêng vì `InstagramPageConnection` có field Instagram-specific. `flex-database/agentdb` là nơi duy nhất sở hữu migration.

## Rollout & Rollback

**Kế hoạch rollout**:
1. Validate Meta App ID, redirect URI, app mode/review và permission configuration ở staging; không ghi secret vào repo.
2. Chạy `flex-database/agentdb` migration preview/validate, backup theo quy trình môi trường, rồi apply expand-only migration.
3. Deploy `flex-agent-service` với route Instagram tương thích và Facebook route mới; kiểm tra health/log/contract.
4. Deploy `flex-microfrontend`; bật UI Facebook sau khi API smoke pass, có thể ẩn channel bằng cấu hình nếu cần.
5. Chạy Meta test-app smoke flow và verify existing Instagram/webhook regression.

**Tương thích ngược**: Giữ endpoint/payload Instagram hiện hữu qua adapter; không drop/rename table/cột Instagram; completed records đọc được trước và sau deploy. Frontend chỉ dùng endpoint mới cho Facebook.

**Feature flag/config**: `Meta:ApiVersion`, `Meta:GraphApiBaseUrl`, `Meta:OAuthBaseUrl`, `Meta:RedirectUri`, `Meta:FrontendCallbackBaseUrl`, scopes theo channel, session TTL và token encryption key từ environment/secret manager. Có thể dùng `Channels:FacebookEnabled` để bật UI/API flow theo rollout, nhưng không dùng flag để bỏ qua authz.

**Thực thi migration/backfill khi rollout**: Migration chạy trước deploy service qua Liquibase; không chạy backfill runtime. Nếu target có legacy schema, preflight/validation phải pass trước update.

**Rollback code/config**:
- Tắt `Channels:FacebookEnabled` hoặc rollback frontend nếu Facebook flow lỗi.
- Rollback service về version trước chỉ sau khi migration additive đã kiểm tra backward compatibility; route Instagram cũ vẫn hoạt động.
- Không rollback bằng cách xóa bảng mới trong production.

**Rollback dữ liệu/migration**: Không có automatic destructive rollback. Với dữ liệu mới, dùng forward-fix hoặc restore theo quy trình backup; không drop `facebook_page_connections` nếu đã có connection. Liquibase changeset đã chạy là bất biến.

**Điều kiện kích hoạt rollback**:
- Tỷ lệ callback/complete lỗi tăng bất thường, unauthorized/cross-agent leak, token xuất hiện trong log, schema preflight fail, hoặc regression Instagram.
- Khi lỗi chỉ thuộc Facebook, tắt Facebook flag và giữ Instagram; khi có lỗi permission/security hoặc data integrity, dừng rollout toàn bộ và xử lý forward-fix.

## Observability & Debug

**Log cần có**:
- `channel_connection.started`, `.callback_succeeded`, `.callback_failed`, `.completed`, `.conflict`, `.disconnected`.
- Fields: `traceId`, `agentId`, `channel`, `method`, `sessionId` dạng hash/opaque, `connectionId`, `externalResourceId` đã được phép log, `outcome`, `failureCode`, `durationMs`.

**Dữ liệu không được log**: OAuth `code`, raw `state`, access/page token, app secret, encryption key, credential reference, full provider response và thông tin user không cần thiết.

**Metric cần theo dõi**:
- Connect/callback/complete/disconnect count theo channel/outcome.
- p50/p95 latency cho internal steps; Meta timeout/4xx/5xx; invalid state/replay/conflict count.
- Active/disconnected connection count và session expiry count.

**Trace/Correlation**: Tạo/tiếp tục `traceId` qua controller → MediatR handler → Meta HTTP; callback nhận request trace mới và gắn `sessionId` opaque/hash. Không truyền access token qua frontend.

**Cách kiểm tra sau release**:
- Health check service, `liquibase status`, query count/status/index trong `agentdb`.
- Smoke connect/callback/result/complete/list/disconnect cho cả hai channel bằng Meta test app.
- Kiểm tra structured log không có secret và error rate/latency dashboard trong thời gian canary.

**Tình huống debug chính**:
- Invalid state/redirect mismatch → đối chiếu hashed session, configured redirect URI và TTL.
- Missing page/IG candidate → kiểm tra provider permission/app review và response mapping, không log raw response.
- 409 conflict → query active owner bằng resource id, không retry complete mù.
- Schema mismatch → đối chiếu Liquibase changeset với `AppDbContext` và preflight output.
- UI không trở lại editor → kiểm tra `Meta:FrontendCallbackBaseUrl`, route/query params và Angular result loading.

## Theo dõi độ phức tạp

Không có vi phạm constitution cần biện minh. Việc có hai connection service, shared Meta ports và một bảng Facebook riêng là boundary tối thiểu được trực tiếp yêu cầu bởi hai resource flow và compatibility với code/schema Instagram hiện hữu; không tạo generic framework hoặc project mới.

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
