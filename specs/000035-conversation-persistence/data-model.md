# Data model: Lưu trữ và tích hợp hội thoại

## Conversation

| Thuộc tính | Ý nghĩa | Quy tắc |
|---|---|---|
| `id` | Định danh conversation | UUID, ổn định qua FE/BE |
| `tenant_id` | Tenant sở hữu dữ liệu | Bắt buộc; lấy/scoped từ server context |
| `created_by` | Người tạo conversation | Bắt buộc; không tin giá trị thay thế từ client |
| `title` | Tên hiển thị tùy chọn | Có thể rỗng; không dùng làm định danh |
| `status` | Vòng đời conversation | MVP dùng `active`; mở rộng theo business status |
| `last_sequence_no` | Sequence cao nhất đã commit | Bắt đầu từ 0; chỉ tăng khi message được ghi nhận |
| `last_message_id` | Message cuối đã commit | Denormalized, không phải source of truth |
| `last_message_at` | Thời điểm message cuối | Dùng cho danh sách conversation |
| `created_at`, `updated_at` | Thời điểm tạo/cập nhật | UTC/timestamp with time zone |

## Message

| Thuộc tính | Ý nghĩa | Quy tắc |
|---|---|---|
| `id` | Định danh message | UUID |
| `tenant_id` | Tenant sở hữu message | Phải khớp conversation |
| `conversation_id` | Conversation chứa message | Bắt buộc |
| `sequence_no` | Thứ tự nghiệp vụ | Duy nhất trong conversation, tăng dần |
| `client_message_id` | Khóa correlate/idempotency từ caller | Nullable cho message nội bộ; unique trong conversation khi có |
| `role` | Vai trò xử lý | `system`, `user`, `assistant`, `tool` |
| `actor_type` | Tác nhân thật sự tạo | `end_user`, `ai_agent`, `human_agent`, `system`, `tool`, `automation` |
| `actor_id` | Định danh tác nhân | Nullable cho system/automation không có identity |
| `content_type` | Loại nội dung | MVP `text` |
| `content` | Nội dung message | User message không rỗng; failure có thể không có content |
| `status` | Trạng thái message | `pending`, `completed`, `failed`, `cancelled` |
| `parent_message_id` | Quan hệ message cha nếu cần | Nullable, không dùng để thay sequence |
| `metadata` | Extension data | JSONB, mặc định object rỗng; không chứa core business fields |
| `created_at`, `updated_at` | Thời điểm | UTC/timestamp with time zone |

## Quan hệ và invariants

- Một conversation có nhiều message; message không được dùng lại cho conversation khác.
- `tenant_id` phải được kiểm tra ở application layer cho cả conversation và message; không dựa vào client.
- `(conversation_id, sequence_no)` duy nhất.
- `last_sequence_no` phải bằng sequence lớn nhất đã commit tại thời điểm transaction hoàn tất.
- `last_message_id`/`last_message_at` là projection phục vụ list query; lịch sử message là source of truth.
- `role` và `actor_type` không được suy luận lẫn nhau.
- Retry cùng `client_message_id` trả về message đã tồn tại nếu payload tương đương; payload khác bị từ chối để tránh ghi đè.

## State transitions

```text
pending ──> completed
   │  └──> failed
   └──────> cancelled
```

Chỉ application flow được phép chuyển trạng thái; message `failed/cancelled` không được FE hiểu là assistant response thành công.
