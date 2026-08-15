# Conversation contract

## Response

Response conversation thêm field additive:

```json
{ "id": "uuid", "conversationSource": 1 }
```

| Code | Meaning |
|---:|---|
| `1` | `Production` — hội thoại thật với end-user |
| `2` | `Preview` — test trên màn cấu hình Agent |
| `3` | `Playground` — test trên màn độc lập |
| `4` | `Api` — khởi tạo qua API |
| `null` | Legacy chưa có evidence nguồn |

## Compatibility

- Request create hiện tại không cho client tự chọn source.
- Consumer cũ bỏ qua field mới vẫn đọc được response.
- Consumer mới xử lý `null` như “chưa phân loại”, không hiển thị thành `Production`.
- Field không xuất hiện trên message hoặc realtime event trong feature này.
