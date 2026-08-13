# Quickstart validation: Conversation persistence

## Prerequisites

- PostgreSQL `agentdb` đang chạy và connection của `flex-agent-service` đã cấu hình qua secret/local environment.
- Liquibase CLI/JDBC driver của `flex-database` sẵn sàng.
- JWT hợp lệ có `tenant_id`, `sub` và quyền thao tác conversation.
- Chạy FE Angular và `flex-agent-service` theo README của từng repo.

## 1. Validate migration (không cập nhật database)

Từ `flex-database/agentdb`:

```text
liquibase --changelog-file=changelog/db.changelog-master.xml validate
liquibase --changelog-file=changelog/db.changelog-master.xml update-sql
```

Kỳ vọng: changelog hợp lệ; SQL preview tạo `chat.conversation`, `chat.message`, index/constraint theo data model; không có `DROP` phá hủy dữ liệu.

## 2. Run backend tests

Từ `flex-agent-service`:

```text
dotnet build Flex.Agent.sln --configuration Release
dotnet test Flex.Agent.sln --configuration Release
```

Kỳ vọng: unit test cho sequence/idempotency và integration test với PostgreSQL pass.

## 3. Validate HTTP flow

1. `POST /api/v1/conversations` → nhận `conversation.id`.
2. `GET /api/v1/conversations` → conversation xuất hiện theo hoạt động gần nhất.
3. `POST /api/v1/conversations/{id}/messages` với `clientMessageId` mới và content `Hello` → message có `role=user`, `actorType=end_user`, sequence `1`.
4. Gọi lại bước 3 với cùng `clientMessageId` → nhận cùng message, không tạo sequence `2`.
5. `GET /api/v1/conversations/{id}/messages?limit=50` → lịch sử đúng thứ tự.
6. Gửi hai request đồng thời → sequence khác nhau, không có duplicate.

Contract chi tiết ở [contracts/conversation-api.md](contracts/conversation-api.md) và [contracts/conversation-realtime.md](contracts/conversation-realtime.md).

## 4. Validate AI integration

Gọi `POST /api/v1/ai/chat` với conversation hợp lệ. Kỳ vọng user message được lưu trước khi gọi model; assistant response chỉ được lưu khi có nội dung hợp lệ với `role=assistant`, `actorType=ai_agent`; timeout/failure không tạo assistant message thành công.

## 5. Validate FE

Mở màn chat, tải lại trang và kiểm tra lịch sử vẫn còn. Gửi lại request sau timeout; FE phải tải/đối chiếu theo `clientMessageId`, không nhân đôi message. Khi SignalR reconnect, FE tải persistent state qua HTTP thay vì chỉ chờ event đã bỏ lỡ.
