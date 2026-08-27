# Research: Kết nối kênh Instagram và Facebook qua Meta

**Feature**: `000041-meta-channel-connections`
**Ngày**: 2026-08-27

## Phạm vi nghiên cứu

Nghiên cứu chỉ xử lý các điểm có thể làm thay đổi kiến trúc, schema, contract hoặc rollout. Messaging/webhook và content operations không được nghiên cứu vì đã bị loại khỏi `spec.md` §15.

## TQ-001 — Boundary dùng chung giữa Instagram và Facebook

### Quan sát

- `flex-agent-service` đã có `Flex.Agent.Application`, `Flex.Agent.Domain`, `Flex.Agent.Infrastructures` và `Flex.Agent.Api`; Application đã dùng MediatR.
- `InstagramOAuthService` hiện đang trộn OAuth URL, `HttpClient`, provider response models và cache state trong flow Instagram.
- Cả hai channel đều cần Meta OAuth và managed Page discovery, nhưng kết quả domain khác nhau: Instagram cần linked Professional account; Facebook cần Page.

### Quyết định

Tạo hai port dùng chung trong Application:

- `IMetaOAuthService`: build authorization URL và exchange code.
- `IMetaGraphService`: lấy managed pages và linked Instagram account.

Provider JSON models, endpoint, `HttpClient`, API version và mapping nằm trong Infrastructure. Instagram/Facebook connection services giữ riêng orchestration và public result models. Session state được truy cập qua `IIntegrationSessionStore` để controller không biết cache key.

### Phương án loại

- Controller/handler gọi `HttpClient` trực tiếp: vi phạm boundary và khó test.
- `IChannelConnectionService<T>` generic: chưa có channel thứ ba thực tế, làm mất traceability của các rule discovery khác nhau.
- Tạo resolver/implementation `Direct` ngay: không có trong MVP và là abstraction chưa được sử dụng.

## TQ-002 — Meta flow, API version và permission

### Bằng chứng

Code hiện tại gọi Graph API qua `graph.facebook.com`, dùng `/me`, `/me/accounts` và lookup linked Instagram account. Tài liệu Meta hiện mô tả Instagram API với Facebook Login cho Instagram Professional account liên kết với Facebook Page; collection chính thức của Meta trên Postman cũng thể hiện việc lấy Page access token từ `/me/accounts`.

Tham khảo:

- [Meta Instagram API documentation trên Postman](https://www.postman.com/meta/instagram/documentation/6yqw8pt/instagram-api)
- [Meta Instagram API with Facebook Login](https://developers.facebook.com/docs/instagram-platform/instagram-api-with-facebook-login/)
- [Meta Pages API getting started](https://developers.facebook.com/docs/pages-api/getting-started)

Meta Developer docs trả rate limit trong lần truy cập trực tiếp của môi trường nghiên cứu; vì vậy không chốt một API version mới chỉ từ tài liệu web. Version và scopes phải configurable, được kiểm chứng với Meta App cụ thể ở staging.

### Quyết định

- Reuse Meta/Facebook Login flow cho cả Facebook Page và Instagram linked account trong MVP.
- `MetaOptions` chứa base URLs, API version, redirect URI và scopes; không hardcode trong service.
- `IMetaGraphService` trả provider-neutral records; không trả raw Page/Instagram response.
- Task implementation phải xác nhận permissions thực tế của Meta App (ví dụ Page listing, Page metadata/messaging nếu flow hiện hữu yêu cầu, và Instagram basic/management permissions) trước khi release; thiếu permission trả lỗi hướng dẫn, không tạo connection.

### Phương án loại

Instagram Login/direct flow bị loại khỏi MVP vì spec yêu cầu flow qua Meta và hiện chưa có provider client/acceptance criteria cho direct account. Việc thêm scope messaging bị loại vì messaging nằm ngoài phạm vi feature này.

## TQ-003 — Database đích và migration owner

### Bằng chứng

`docs/architecture/system-map.md` xác định PostgreSQL `agentdb` phục vụ Agent Platform/Agent Catalog và migration/schema owner là `flex-database/agentdb`. `flex-database` dùng Liquibase SQL-first và release changelog. `flex-agent-service` có `AddInstagramTables.sql`, nhưng đây là legacy service-local artifact, không phải entry point Liquibase của `agentdb`.

### Quyết định

- Database đích: PostgreSQL `agentdb`.
- Repo migration: `flex-database`, folder `agentdb`.
- Tạo release kế tiếp và SQL migration `V1.4__create_meta_channel_connections.sql` (hoặc số release thực tế kế tiếp nếu repo đã tiến hành trong lúc implement).
- Không sửa changeset đã chạy, không include SQL copy từ service repo, không chạy `liquibase update` trong bước planning.

## TQ-004 — Tương thích schema/route Instagram hiện hữu

### Quan sát

- `AppDbContext` và `InstagramPageService` đang map `meta_account_connections`/`instagram_page_connections`.
- API hiện có route `/api/channels/instagram/connect`, callback, result, confirm, list và disconnect.
- `flex-database/agentdb` chưa có migration Meta/Instagram tương ứng; deployment state của legacy tables không thể suy ra chắc chắn chỉ từ file repo.

### Quyết định

- Giữ tên bảng và route Instagram hiện hữu trong MVP.
- Migration mới có preflight/validation rõ: nếu legacy table đã tồn tại thì xác nhận định nghĩa tương thích; chỉ bổ sung object thiếu, không drop/rename.
- Thêm `facebook_page_connections` thay vì tái cấu trúc ngay thành một generic `channel_connections` table.
- Controller Instagram hiện hữu trở thành adapter mỏng gọi Application use case; không thay đổi route/payload công khai.

### Rủi ro còn lại

Trước staging migration vẫn phải xác nhận schema thực tế và lịch sử đã chạy của `AddInstagramTables.sql`. Đây là điều kiện triển khai, không phải lý do để chọn sai migration owner.

## TQ-005 — Callback và Angular editor

### Quan sát

`app-routing.module.ts` đã có `/agents/:id/edit`, `/agents/:id/settings` và `/publish`; `AgentEditorWizard` hiện là màn hình cấu hình agent. Modal connect hiện chỉ emit lựa chọn cục bộ và chưa gọi API.

### Quyết định

Backend callback redirect về editor route được cấu hình, gắn `channel`, `sessionId` opaque và `status` bằng query string. Wizard đọc query params sau khi load, gọi result endpoint, hiển thị candidate và complete qua service. Không đưa token hoặc raw OAuth state vào URL/frontend.

## Tóm tắt quyết định cho plan

1. Shared boundary: Meta OAuth/Graph + session store; orchestration riêng theo channel.
2. API version/permissions cấu hình hóa và phải smoke test với Meta App trước release.
3. `agentdb`/`flex-database` là source of truth migration.
4. Instagram compatibility được ưu tiên; Facebook thêm table/route mới.
5. MVP không triển khai Direct Instagram, messaging hay webhook.
