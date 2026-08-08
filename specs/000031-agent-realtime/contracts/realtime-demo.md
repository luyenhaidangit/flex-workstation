# Contract: Agent realtime demo

## SignalR hub

**Hub**: `ApplicationHub`
**Hub URL**: `/hubs/application`

### Client → server

| Method | Arguments | Kết quả |
|---|---|---|
| `SendMessage` | `message: string` | Server validate, log và gửi `messageReceived` về client gửi |

`message` sau khi trim phải khác rỗng. Input không hợp lệ không tạo event thành công.

### Server → client

#### `messageReceived`

```json
{
  "type": "messageReceived",
  "message": "realtime smoke test",
  "occurredAt": "2026-08-08T02:00:00Z"
}
```

#### `demoNotification`

```json
{
  "type": "demoNotification",
  "message": "Thông báo test từ Agent Service",
  "occurredAt": "2026-08-08T02:00:00Z"
}
```

## HTTP endpoint

**Method**: `POST`  
**Path**: `/api/v1/realtime-demo/notify`  
**Authorization**: dùng authorization hiện có của Agent API; anonymous không được gọi.

### Request

```json
{
  "message": "Thông báo test từ BE"
}
```

`message` là tùy chọn ở mức demo; nếu rỗng, BE dùng default message an toàn.

### Success response — `200 OK`

```json
{
  "message": "Notification sent",
  "connectedClients": 1
}
```

`connectedClients` bằng `0` là kết quả hợp lệ khi chưa có FE kết nối.

### Error responses

- `401/403`: request chưa được phép.
- `400`: payload không hợp lệ nếu contract được mở rộng để bắt buộc message.
- `500`: lỗi không mong đợi khi phát event.

## Compatibility

Đây là contract mới, không thay đổi endpoint hoặc event hiện hữu. Consumer duy nhất trong MVP là `AgentRealtimeService` và quickstart developer.
