# Contract API — Chat xem trước AI Agent

## Endpoint

`POST /api/v1/ai/chat/preview`

## Authorization

- Bắt buộc Bearer JWT hợp lệ.
- Caller đã xác thực là người gửi thử nghiệm; client không gửi hoặc chọn danh tính người dùng khác.
- Request không xác thực nhận `401`; không đủ quyền theo policy hiện hữu nhận `403`.

## Request

```json
{
  "agent": {
    "name": "Thảo CSKH",
    "role": "Nhân viên AI chăm sóc khách hàng",
    "instructions": "Hỗ trợ khách hàng sau bán và giải đáp chính sách bảo hành."
  },
  "messages": [
    {
      "role": "user",
      "content": "Tôi cần hướng dẫn thanh toán."
    }
  ]
}
```

| Field | Type | Bắt buộc | Quy tắc |
|---|---|---:|---|
| `agent.name` | string | Có | Sau trim không rỗng |
| `agent.role` | string | Có | Sau trim không rỗng |
| `agent.instructions` | string | Có | Sau trim không rỗng |
| `messages` | array | Có | Có tối thiểu một phần tử, giữ thứ tự hội thoại |
| `messages[].role` | string | Có | Chỉ `user` hoặc `agent` |
| `messages[].content` | string | Có | Sau trim không rỗng |

## Success response — 200

```json
{
  "reply": "Anh/chị có thể chọn phương thức thanh toán phù hợp tại bước xác nhận đơn hàng.",
  "model": "configured"
}
```

| Field | Type | Ý nghĩa |
|---|---|---|
| `reply` | string | Câu trả lời không rỗng từ AI Agent cho tin nhắn cuối cùng |
| `model` | string | Nhãn model đã xử lý, có thể vắng mặt; không dùng làm nội dung hiển thị nghiệp vụ |

## Error responses

Mọi lỗi trả JSON `{ "message": "...", "code": "..." }`. Không echo prompt, lịch sử chat, thông tin cấu hình Agent, token hoặc response thô của provider.

| HTTP | Code | Khi xảy ra |
|---:|---|---|
| 400 | `AI_PREVIEW_REQUEST_INVALID` | Context Agent hoặc messages thiếu/không hợp lệ |
| 401 | Theo authentication middleware | Thiếu hoặc JWT không hợp lệ |
| 403 | Theo authorization middleware | Caller không có quyền dùng endpoint |
| 502 | `AI_RESPONSE_INVALID` | Provider trả payload không dùng được hoặc reply rỗng |
| 503 | `AI_SERVICE_UNAVAILABLE` | Provider/Agent Service chưa sẵn sàng |
| 504 | `AI_REQUEST_TIMEOUT` | Không nhận được kết quả trong thời gian `Ai:Ollama:TimeoutSeconds` đã cấu hình |

## Compatibility

Contract mới, additive. Không thay đổi `POST /api/v1/ai/chat/summarize`, CRUD `/api/v1/agents`, hoặc hub direct-message. Consumer đầu tiên là `AgentCreateWizardComponent`.
