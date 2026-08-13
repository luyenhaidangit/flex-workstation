# Rollback và recovery: Conversation persistence

- Migration `1.3.0` chỉ thêm schema, table và index; không drop hoặc rewrite dữ liệu hiện hữu.
- Rollback code/config thực hiện bằng cách tắt persistence flag hoặc deploy phiên bản backend trước đó.
- Không tự động drop `chat.conversation`/`chat.message` trên production.
- Nếu migration lỗi, dừng rollout và dùng Liquibase `update-sql`/database restore theo quy trình vận hành.
- Nếu phát hiện sequence/idempotency drift sau release, dùng forward-fix có kiểm soát và giữ nguyên lịch sử đã ghi nhận.
- Kích hoạt rollback khi có cross-tenant access, message loss, duplicate sequence diện rộng hoặc API error rate vượt ngưỡng release.
