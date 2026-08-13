# Contract: Conversation HTTP API

Base path: `/api/v1/conversations`  
Authorization: Bearer JWT; tenant và actor lấy từ server context.

## Create conversation

`POST /api/v1/conversations`

```json
{ "title": "Trao đổi với Agent" }
```

Response `201`:

```json
{
  "id": "uuid",
  "tenantId": "uuid",
  "createdBy": "uuid",
  "title": "Trao đổi với Agent",
  "status": "active",
  "lastSequenceNo": 0,
  "lastMessageId": null,
  "lastMessageAt": null,
  "createdAt": "2026-08-13T12:00:00Z",
  "updatedAt": "2026-08-13T12:00:00Z"
}
```

## List conversations

`GET /api/v1/conversations?limit=50&cursor=<opaque>`

Response `200`: `{ "items": [ConversationSummary], "nextCursor": "..." }`.
Danh sách scoped theo tenant/quyền và sắp xếp theo `lastMessageAt`/`updatedAt` giảm dần.

## Get messages

`GET /api/v1/conversations/{conversationId}/messages?limit=50&beforeSequenceNo=<number>`

Response `200`: `{ "items": [MessageResponse], "nextCursor": "..." }`.
FE hiển thị kết quả theo `sequenceNo` tăng dần sau khi nhận page.

## Create message

`POST /api/v1/conversations/{conversationId}/messages`

```json
{
  "clientMessageId": "uuid",
  "contentType": "text",
  "content": "Hello",
  "metadata": {}
}
```

BE tự gán `role=user`, `actorType=end_user`, `actorId` từ JWT. Client không được gửi role/actor để override. Response `201` hoặc `200` khi idempotent replay:

```json
{
  "id": "uuid",
  "conversationId": "uuid",
  "sequenceNo": 1,
  "role": "user",
  "actorType": "end_user",
  "actorId": "uuid",
  "contentType": "text",
  "content": "Hello",
  "status": "completed",
  "metadata": {},
  "createdAt": "2026-08-13T12:00:01Z"
}
```

Errors: `400` invalid content, `401/403` unauthorized, `404` conversation ngoài scope, `409` idempotency key khác payload, `504` timeout khi AI flow chờ model.

## Compatibility

Đây là contract mới. `POST /api/v1/ai/chat` giữ path và response hiện có; persistence là side effect được bổ sung bên trong flow, không làm client cũ phải gửi thêm field.
