# Mô hình dữ liệu — Chat AI cơ bản

## Kết luận persistence

MVP không tạo, sửa hoặc lưu entity/database/schema. Theo BR-003, mọi request được xử lý độc lập và chỉ tồn tại trong vòng đời HTTP.

## Contract dữ liệu transient

| Đối tượng | Thuộc tính nghiệp vụ | Validation | Vòng đời |
|---|---|---|---|
| `ConversationSummaryRequest` | `conversation` | Bắt buộc, sau khi trim phải không rỗng | HTTP request → use case |
| `ChatRequest` | User message và instruction tóm tắt do use case tạo | Không truyền raw provider DTO qua application boundary | Use case → provider port |
| `ChatResponse` | Nội dung phản hồi text | Phải không rỗng để xem là thành công | Provider port → use case |
| `ConversationSummaryResponse` | `summary` | Chỉ trả khi summary không rỗng | HTTP response |

## Quan hệ và trạng thái

```text
ConversationSummaryRequest (1) → ChatRequest (1) → ChatResponse (0..1) → ConversationSummaryResponse (0..1)
```

- Input không hợp lệ kết thúc ở 400 và không tạo `ChatRequest` tới provider.
- `ChatResponse` rỗng/không hợp lệ kết thúc ở lỗi 502, không tạo response thành công.
- Không có khóa, ID lưu trữ, foreign key, migration, backfill hay cleanup.
