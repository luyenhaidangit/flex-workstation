# Contract API — Tóm tắt hội thoại

## Endpoint

`POST /api/v1/ai/chat/summarize`

## Authorization

- Bắt buộc Bearer JWT hợp lệ.
- Request chưa xác thực nhận 401; request không đủ quyền nhận 403 theo middleware authorization hiện hữu.

## Request

```json
{
  "conversation": "Khách hàng hỏi về tiến độ giao hàng; nhân viên xác nhận sẽ phản hồi trước cuối ngày."
}
```

| Field | Type | Bắt buộc | Quy tắc |
|---|---|---:|---|
| `conversation` | string | Có | Sau khi trim phải không rỗng |

## Success response — 200

```json
{
  "summary": "Khách hàng cần cập nhật tiến độ giao hàng; nhân viên sẽ phản hồi trước cuối ngày."
}
```

| Field | Type | Ý nghĩa |
|---|---|---|
| `summary` | string | Bản tóm tắt không rỗng của hội thoại được gửi |

## Error responses

Mọi lỗi business/integration dùng JSON hiện hữu có `message` và `code`; không echo hội thoại, prompt, token hoặc response provider.

| HTTP | Code | Khi xảy ra |
|---:|---|---|
| 400 | `AI_CONVERSATION_REQUIRED` | `conversation` rỗng hoặc chỉ có khoảng trắng |
| 401 | Theo authentication middleware | Thiếu/không hợp lệ JWT |
| 403 | Theo authorization middleware | Không được phép truy cập |
| 502 | `AI_RESPONSE_INVALID` | Provider trả payload không dùng được hoặc summary rỗng |
| 503 | `AI_SERVICE_UNAVAILABLE` | Provider không sẵn sàng hoặc trả lỗi upstream |
| 504 | `AI_REQUEST_TIMEOUT` | Hết deadline downstream |

## Compatibility

Đây là contract mới, additive. Không sửa route/payload hiện hữu. Không hỗ trợ streaming, history hay chat nhiều lượt trong version này.
