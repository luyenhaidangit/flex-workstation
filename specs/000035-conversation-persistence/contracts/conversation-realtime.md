# Contract: Conversation realtime event

Transport: existing `ApplicationHub` tại `/hubs/application`.

## Server event

Event: `conversation.message.created`

```json
{
  "messageId": "uuid",
  "conversationId": "uuid",
  "tenantId": "uuid",
  "sequenceNo": 2,
  "role": "assistant",
  "actorType": "ai_agent",
  "actorId": "uuid",
  "status": "completed",
  "contentType": "text",
  "content": "Xin chào",
  "occurredAt": "2026-08-13T12:00:02Z"
}
```

Event chỉ publish sau khi persistence commit thành công. HTTP history là nguồn khôi phục khi reconnect; event không thay thế database.

## Authorization and delivery

- Chỉ subscriber đã được authorize conversation mới nhận event.
- `tenantId`, `actorId` và sequence do server tạo; client không dùng payload để tự cấp quyền.
- FE correlate bằng `messageId`, `conversationId`, `sequenceNo`; nếu đã có message thì bỏ qua duplicate.
- Existing direct-message event `message.created` vẫn giữ nguyên cho consumer hiện hữu; event mới không đổi payload cũ.
