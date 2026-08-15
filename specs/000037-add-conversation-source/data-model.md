# Data model: Conversation source

## Conversation

Thực thể hiện có trong PostgreSQL database `agentdb`, schema mặc định `public`, bảng `conversation`.

| Thuộc tính | Kiểu nghiệp vụ | Bắt buộc | Quy tắc |
|---|---|---:|---|
| `id` | UUID | Có | Định danh conversation hiện có |
| `tenant_id` | UUID | Có | Giữ tenant isolation |
| `conversation_source` | `ConversationSource` | Mới: Có; legacy: Không | `1 Production`, `2 Preview`, `3 Playground`, `4 Api`; bất biến |

## Quan hệ

- Một `Conversation` có tối đa một source.
- Nhiều conversation có thể cùng một source.
- `Message` không sở hữu source.

## Migration/backfill

- Add nullable column và check constraint cho `NULL` hoặc `1..4`.
- Không backfill row cũ vì không có evidence.
- Application ghi source hợp lệ cho row mới.
