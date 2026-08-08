# Kiến trúc realtime

Tài liệu này mô tả trạng thái realtime hiện tại của Flex Agent và phân biệt rõ
phần demo MVP đã triển khai với các hạng mục kiến trúc production chưa triển khai.

## 1. Phạm vi hiện tại

Realtime hiện tại là demo hai chiều giữa màn tạo Agent trong
`flex-microfrontend` và `flex-agent-service`:

| Luồng | Mô tả | Trạng thái |
| --- | --- | --- |
| FE → BE | Người dùng gửi chat từ `/agents/create`; `ApplicationHub` nhận, ghi log và trả acknowledgement | Đã triển khai |
| BE → FE | Gọi endpoint test để broadcast `demoNotification`; FE hiển thị `alert` | Đã triển khai |
| Public widget | Widget cho website tenant, session token và tenant isolation | Chưa triển khai |
| Chat streaming | `MessageChunk`, `MessageCompleted`, `MessageFailed` và model gateway | Chưa triển khai |

Demo không phải là chat nghiệp vụ hoàn chỉnh và chưa lưu conversation.

## 2. Thành phần và endpoint

```text
Browser
  └── flex-microfrontend: http://localhost:4200
        └── AgentCreateWizardComponent (/agents/create)
              └── ApplicationRealtimeService
                    │ SignalR/WebSocket
                    ▼
              flex-agent-service: http://localhost:7001
                    ├── /hubs/application
                    └── POST /api/v1/realtime-demo/notify
```

Các thành phần chính:

- `flex-agent-service/src/Flex.Agent.Api/Hubs/ApplicationHub.cs`: SignalR hub.
- `flex-agent-service/src/Flex.Agent.Api/Hubs/AgentRealtimeConnectionRegistry.cs`: theo dõi số connection đang hoạt động trong instance hiện tại.
- `flex-agent-service/src/Flex.Agent.Api/Controllers/RealtimeDemoController.cs`: endpoint test broadcast.
- `flex-microfrontend/src/app/core/services/application-realtime.service.ts`: quản lý lifecycle SignalR và phát RxJS stream.
- `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.ts`: tích hợp chat preview.

`RealtimeConnectionLifecycleService` điều phối connection theo authentication
lifecycle. `AuthenticationService` chỉ phát sự kiện `authenticated` hoặc
`loggedOut`; `ApplicationRealtimeService` chịu trách nhiệm transport.
`AgentCreateWizardComponent` chỉ subscribe/unsubscribe các stream và không tự
gọi `connect()` hoặc `disconnect()`.

## 3. Authentication khi kết nối

Authentication được thực hiện ngay trong lúc SignalR handshake; không có bước
connect anonymous rồi gửi token bằng một event riêng.

```text
FE lấy JWT từ AuthenticationService
        │
        ▼
ApplicationRealtimeService.withUrl(..., accessTokenFactory)
        │
        ▼
/hubs/application?access_token=<JWT>
        │
        ▼
JWT Bearer middleware validate issuer, audience, lifetime và signing key
        │
        ▼
[Authorize] ApplicationHub cho phép hoặc từ chối connection
```

FE cấu hình token tại `accessTokenFactory`. BE đọc `access_token` từ query
chỉ khi request đi tới `/hubs/application`; các API HTTP vẫn dùng header:

```http
Authorization: Bearer <access-token>
```

Query token là đặc thù của browser WebSocket/SignalR. Access log, proxy và
telemetry phải redaction query string chứa token. Không ghi JWT vào log.

## 4. Authorization hiện tại và giới hạn

`ApplicationHub` hiện có `[Authorize]`, vì vậy chỉ principal đã xác thực mới
được mở connection. Demo chưa có resource authorization vì chưa có
conversation, tenant hoặc group nghiệp vụ.

Đã thực hiện:

- Không nhận `userId`, `tenantId` hoặc role từ payload chat.
- Không gửi token trong từng event.
- Validate authentication trước khi vào hub.
- Chặn message rỗng sau khi trim.

Chưa thực hiện và không được hiểu là đã có trong demo:

- Kiểm tra user có quyền truy cập conversation/agent hay không.
- Tenant isolation và lọc dữ liệu theo tenant.
- `Context.UserIdentifier` để định tuyến theo user.
- Group membership và kiểm tra quyền trước khi join group.
- Role policy cụ thể như `editor`.

Khi bổ sung nghiệp vụ, mọi command phải lấy identity từ server context:

```csharp
var userId = Context.UserIdentifier;
```

Server phải kiểm tra quyền trước khi thực hiện command hoặc thêm connection
vào group. Không tin `userId` do client gửi lên.

## 5. Contract realtime của demo

### 5.1 Client gọi server

FE gọi method SignalR:

```text
ApplicationRealtimeService.sendMessage(message)
    → connection.invoke("SendMessage", message)
    → ApplicationHub.SendMessage(string? message)
```

Payload hiện tại chỉ là chuỗi message đã được trim. Demo chưa có
`conversationId`, `agentId` hoặc `mode`.

### 5.2 Server trả acknowledgement

Sau khi nhận message hợp lệ, hub ghi structured log rồi gửi về đúng connection
đã gọi:

```text
event: messageReceived
payload: {
  type: "messageReceived",
  message: string,
  occurredAt: string
}
```

Hub dùng `Clients.Caller`, vì vậy acknowledgement không broadcast cho các
client khác.

### 5.3 Endpoint broadcast test

```http
POST http://localhost:7001/api/v1/realtime-demo/notify
Authorization: Bearer <access-token>
Content-Type: application/json
```

```json
{
  "message": "Thông báo test từ Agent Service"
}
```

Controller broadcast event:

```text
event: demoNotification
payload: {
  type: "demoNotification",
  message: string,
  occurredAt: string
}
```

FE nhận event và gọi `window.alert`. Response HTTP trả `connectedClients`,
là số connection đang được registry ghi nhận trong instance hiện tại.

## 6. Connection identity và lifecycle

SignalR tự tạo `Context.ConnectionId` cho từng tab hoặc thiết bị kết nối.

```text
OnConnectedAsync    → registry.Add(connectionId)
OnDisconnectedAsync → registry.Remove(connectionId)
```

Registry hiện chỉ lưu `connectionId` và `Count`. Nó chưa lưu mapping:

```text
userId → nhiều connectionId
```

Đây là giới hạn chấp nhận được cho demo. `ConnectionId` là định danh tạm
thời của socket, không phải user ID và có thể thay đổi sau reconnect.

FE sử dụng automatic reconnect với các mốc:

```text
0ms, 1000ms, 3000ms, 5000ms
```

Service phát các trạng thái:

```text
connecting → connected → reconnecting → connected
                         └──────────→ disconnected
```

Flow lifecycle hiện tại:

```text
Login thành công
    ↓
AuthenticationService.setAuthToken(...)
    ↓
RealtimeConnectionLifecycleService
    ↓
ApplicationRealtimeService.refreshAuthentication()
    ↓
START CONNECTION tới /hubs/application
```

Khi authentication service nhận access token mới, `setAuthToken` dừng
connection hiện tại và mở lại connection bằng token mới. Bản thân frontend
chưa triển khai refresh token; việc lấy access token mới vẫn do auth flow hiện
tại đảm nhiệm.

```text
Token mới được lưu
    ↓
STOP connection cũ
    ↓
accessTokenFactory lấy token mới
    ↓
CONNECT lại ApplicationHub
```

Khi mất mạng, SignalR tự reconnect theo các mốc đã cấu hình. Khi logout hoặc
token hết hạn, `AuthenticationService` phát sự kiện `loggedOut`; coordinator
gọi `disconnect()` trước khi token bị xóa và điều hướng về màn login.

`AgentCreateWizardComponent` không quản lý connection. Nếu người dùng mở lại
màn `/agents/create` khi đã đăng nhập, service toàn cục đã được khởi động từ
`RealtimeConnectionLifecycleService.initialize()` và sự kiện từ
`initOnStartup()` hoặc `setAuthToken()`.

## 7. CORS và transport

Policy `LocalFrontend` cho phép browser từ:

```text
http://localhost:4200
```

với mọi header và method, đồng thời cho phép credentials. CORS chỉ là cơ chế
giới hạn JavaScript chạy trong browser; không thay thế JWT authorization và
không chặn Postman/curl.

SignalR ưu tiên WebSocket và có thể dùng transport fallback theo khả năng
của client/server. Các header `Upgrade`, `Connection` và
`Sec-WebSocket-*` do browser/SignalR tự tạo; FE không tự set các header này.

## 8. Logging và quan sát hiện tại

Hub ghi event `RealtimeDemoMessageReceived` với:

- `ConnectionId`;
- `MessageLength`;
- `OccurredAt`.

Controller ghi event `RealtimeDemoNotificationSent` với:

- `ConnectedClients`;
- `OccurredAt`.

Nội dung message, JWT, secret và connection string không được ghi vào log.

Chưa có trong demo:

- `userId`, `tenantId`, `traceId`, `correlationId`;
- latency, duration và outcome chuẩn hóa;
- metrics/alert dashboard;
- distributed connection registry.

## 9. Production target chưa triển khai

Các hạng mục sau là hướng phát triển, không phải trạng thái hiện tại:

1. Thêm conversation và persistent message state.
2. Thêm authorization theo user, tenant, agent và conversation.
3. Dùng `Context.UserIdentifier` và `Clients.User(...)` cho user có nhiều tab/thiết bị.
4. Dùng SignalR groups cho resource đã kiểm tra quyền.
5. Bổ sung public widget với session token ngắn hạn.
6. Bổ sung streaming events như `MessageChunk`, `MessageCompleted` và `MessageFailed`.
7. Bổ sung rate limit, timeout, backpressure và idempotency.
8. Khi scale-out, dùng Redis backplane hoặc managed SignalR service.
9. Cấu hình proxy/HAProxy giữ WebSocket upgrade và timeout tunnel phù hợp.
10. Bổ sung distributed tracing, metrics và cảnh báo production.

Gateway có thể validate token trước, nhưng realtime service vẫn phải tự enforce
authentication và authorization.

## 10. Tiêu chí kiểm thử hiện tại

- Mở `http://localhost:4200/agents/create` sau khi đăng nhập.
- Xác nhận trạng thái `Connected` ở panel preview.
- Gửi message và kiểm tra event `messageReceived`/log backend.
- Gọi `POST /api/v1/realtime-demo/notify` và kiểm tra `alert` trên FE.
- Gọi endpoint khi không có client và kiểm tra `connectedClients = 0`.
- Kiểm tra reconnect sau khi Agent Service tạm dừng và khởi động lại.

Các kiểm thử về tenant isolation, conversation authorization, streaming,
proxy, multi-instance và Redis chỉ được thêm sau khi các capability tương ứng
được triển khai.

## 11. Tài liệu liên quan

- [Demo specification](../../specs/000031-agent-realtime/spec.md)
- [Realtime demo contract](../../specs/000031-agent-realtime/contracts/realtime-demo.md)
- [Realtime demo quickstart](../../specs/000031-agent-realtime/quickstart.md)
- [System map](./system-map.md)
