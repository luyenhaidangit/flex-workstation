# Quickstart validation: Conversation source

## Prerequisites

- PostgreSQL `agentdb` đang chạy; database hiện mới áp dụng đến release `1.2.0`.
- `flex-agent-service` và test dependencies đã restore.

## Validation scenarios

1. Chạy `liquibase --changelog-file=changelog/db.changelog-master.xml validate` và `update-sql` tại `flex-database/agentdb`; chỉ apply V1.3 khi database disposable được xác nhận.
2. Tạo conversation qua current authenticated FE flow; response có `conversationSource = 1`.
3. Chạy tests cho bốn mã `1..4`, mã không hợp lệ và source bất biến.
4. Đọc legacy row có source `NULL`; GET list/detail thành công và trả `null`.
5. Gửi request/header tự khai source; server không dùng giá trị client làm authority.
6. Kiểm tra tenant không có quyền vẫn nhận lỗi authorization hiện có và không lộ source.
7. Build TypeScript consumer; model chấp nhận `1..4` và `null`.

## Verification evidence

- `liquibase validate`: pass.
- `liquibase update-sql`: pass, sinh changeset `1.3.0` tạo bảng và source, không ghi vào database.
- Database apply/rollback rehearsal: chưa thực hiện vì chưa có database disposable được xác nhận.

## Expected outcomes

- Row mới có đúng source do trusted ingress quyết định.
- Không có row mới mang mã ngoài `1..4`.
- Legacy row không bị gán nhầm `Production`.
- API/FE cũ không lỗi do field additive.
