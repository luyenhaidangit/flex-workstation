# Mô hình dữ liệu — Tích hợp chat AI tại màn Agent

## Phạm vi lưu trữ

Không có entity bền, thay đổi schema hoặc migration. Toàn bộ dữ liệu dưới đây chỉ tồn tại trong bộ nhớ của trình duyệt hoặc trong vòng đời request HTTP; không được ghi vào database hay log nội dung.

## Đối tượng tạm thời

| Đối tượng | Thuộc tính | Quy tắc kiểm tra | Vòng đời |
|---|---|---|---|
| `AgentPreviewContext` | `name`, `role`, `instructions` | `name` và `role` theo form Agent; `instructions` không rỗng | Đọc từ form tại lúc gửi, không lưu |
| `PreviewMessage` | `role`, `content`, `occurredAt`, `status` | `role` chỉ là `user` hoặc `agent`; `content` sau trim không rỗng với tin gửi/nhận thành công | Giữ trong state của wizard cho đến khi reset/rời màn |
| `PreviewRequest` | `agent`, `messages` | Có ít nhất một user message; messages theo đúng thứ tự phiên | Chỉ trong request đến Agent Service |
| `PreviewResponse` | `reply`, `model` (tùy chọn) | `reply` sau trim không rỗng | Chỉ trong response HTTP |

## Quan hệ và chuyển trạng thái

```text
AgentPreviewContext 1 ─── 1 Phiên preview (FE state)
Phiên preview       1 ─── N PreviewMessage
```

| Trạng thái tin gửi mới nhất | Sự kiện | Trạng thái tiếp theo |
|---|---|---|
| `pending` | Nhận `reply` hợp lệ | `completed`, thêm một `PreviewMessage` role `agent` |
| `pending` | 400/401/403/502/503/504 hoặc network error | `failed`, giữ câu hỏi và thông tin lỗi để thử lại |
| `failed` | Người dùng thử lại | `pending` |

## Migration và tương thích dữ liệu

- **Migration**: Không áp dụng.
- **Backfill/Cleanup**: Không áp dụng.
- **Tương thích dữ liệu cũ**: Không có dữ liệu preview được lưu; reset hoặc rời màn chỉ loại bỏ state cục bộ.
