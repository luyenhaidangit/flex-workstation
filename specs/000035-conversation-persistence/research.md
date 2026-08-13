# Research: Lưu trữ và tích hợp hội thoại

## R1 — Database đích và repo sở hữu migration

**Decision**: Dùng PostgreSQL `agentdb`; migration thuộc `flex-database/agentdb/`.

**Rationale**: `docs/architecture/system-map.md` xác nhận `agentdb` là database chuyên biệt cho Agent Platform/Agent Catalog và xác nhận `flex-database` là repo migration dùng chung. `flex-agent-service` hiện đã kết nối `agentdb` qua `AppDbContext` và connection string `Database=agentdb`. Tiền lệ `000028-agent-publish-channels` dùng `flex-database/agentdb/migrations/` cùng Liquibase release.

**Alternatives considered**:
- `flexdb`: loại vì đây là control-plane/shared tenant registry, không phải datastore nghiệp vụ Agent.
- MySQL database-per-tenant: loại vì conversation runtime hiện thuộc Agent Platform và code hiện tại dùng `agentdb`; feature MVP chưa yêu cầu tách database theo tenant.
- EF Core migration trong `flex-agent-service`: loại vì Constitution VI và convention `agentdb` quy định migration ở `flex-database`.

## R2 — Persistence boundary

**Decision**: `flex-agent-service` sở hữu application flow và EF Core mapping; SQL schema/version do `flex-database` sở hữu. Không tạo foreign key xuyên database/service.

**Rationale**: Giữ domain/application không phụ thuộc SQL file, đồng thời giữ một source of truth migration theo database repository. `ChatService` hiện là điểm chung của AI flow và `ConversationHistoryProvider` đang là placeholder, nên đây là vertical slice nhỏ nhất để thay thế.

**Alternative**: Tạo service/repository mới tách riêng thành microservice — loại vì chưa có boundary deploy/scale/failure độc lập và làm tăng complexity ngoài MVP.

## R3 — Tạo sequence và retry

**Decision**: Application mở transaction, khóa row conversation, đọc `last_sequence_no`, cấp sequence kế tiếp, ghi message và cập nhật denormalized latest-message state trước khi commit. Mỗi request ghi message mang `client_message_id` để retry trả lại bản ghi đã có.

**Rationale**: Tránh race condition của `MAX(sequence_no)+1`; giữ message và conversation summary nhất quán. Unique key trên `(conversation_id, sequence_no)` và idempotency key là lớp bảo vệ cuối.

**Alternative**: PostgreSQL sequence độc lập — loại vì cần sequence theo từng conversation và khó correlate retry theo nghiệp vụ.

## R4 — FE/BE transport

**Decision**: Dùng REST cho create/list/detail/send; dùng SignalR `ApplicationHub` chỉ phát event `conversation.message.created` sau commit khi cần cập nhật client đang mở. Giữ `POST /api/v1/ai/chat` tương thích và cho ChatService dùng flow persistence chung.

**Rationale**: FE đã có HTTP/auth convention và realtime abstraction trung tâm. REST là nguồn khôi phục state sau reconnect; SignalR không được coi là durable storage theo `docs/architecture/realtime-architecture.md`.

**Alternative**: Chỉ dùng SignalR cho gửi message — loại vì retry/reconnect và tải lại lịch sử sẽ phụ thuộc socket.

## R5 — Phân biệt role/actor

**Decision**: Lưu `role` và `actor_type` thành hai thuộc tính độc lập; BE gán actor của user từ authenticated context, không tin `actor_id`/actor type do FE gửi. AI response dùng cùng message model với `role=assistant`, `actor_type=ai_agent`.

**Rationale**: Khớp BR-002/BR-005 và tránh suy luận từ `is_bot` hoặc nhãn UI. Tên public giữ vocabulary canonical `Conversation`, `Message`, `ActorType`, `Role`.

## R6 — Metadata và content MVP

**Decision**: MVP lưu text content và JSONB metadata; provider/model/channel-specific data nằm trong metadata. System prompt không tự động ghi thành message nếu chỉ là cấu hình; chỉ ghi khi application flow xác định đó là phần audit của conversation.

**Rationale**: Core schema ổn định, extension không làm phình bảng; phù hợp spec §3/BR-006.

## R7 — Naming review

**Decision**: Dùng `Conversation`, `Message`, `ConversationRepository`, `MessageResponse`, `CreateMessageRequest`, `MessageCreated` và `ConversationController`; không dùng `ChatManager`/`Helper`.

**Result**: Không có ERROR về naming. Các public field `role`, `actor_type`, `actor_id`, `sequence_no` là vocabulary đã được stakeholder xác nhận và có compatibility requirement.
