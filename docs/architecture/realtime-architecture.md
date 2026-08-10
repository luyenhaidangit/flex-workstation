# Kiến trúc Realtime

## 1. Mục tiêu tài liệu

Tài liệu này định nghĩa **kiến trúc mục tiêu (target architecture)** cho các chức năng realtime của hệ thống Flex Agent.

Mục tiêu của tài liệu là làm **architecture contract** để các source code frontend, backend, gateway và hạ tầng triển khai realtime theo cùng một mô hình thống nhất.

Tài liệu không mô tả trạng thái một implementation cụ thể đã triển khai đến đâu. Thay vào đó, nó xác định:

- các thành phần realtime cần có;
- trách nhiệm của từng thành phần;
- luồng kết nối, authentication và authorization;
- contract giao tiếp giữa client và server;
- cách định tuyến event theo user, tenant và resource;
- lifecycle của connection;
- yêu cầu reliability, scale-out, security và observability;
- tiêu chí kiểm thử mà một implementation realtime cần đáp ứng.

---

## 2. Nguyên tắc kiến trúc

Một hệ thống realtime phải tuân theo các nguyên tắc sau:

1. **Realtime transport không thay thế business layer.**  
   Hub/WebSocket endpoint chịu trách nhiệm nhận command, xác định caller, kiểm tra các điều kiện realtime cần thiết và chuyển yêu cầu vào application/business layer. Không đặt toàn bộ nghiệp vụ trực tiếp trong Hub.

2. **Authentication được xác lập ngay khi tạo connection.**  
   Không connect anonymous rồi gửi token bằng một realtime event riêng.

3. **Authorization luôn dựa trên identity từ server context.**  
   Không tin `userId`, `tenantId`, role hoặc quyền truy cập do client tự khai báo.

4. **ConnectionId không phải UserId.**  
   Một user có thể có nhiều connection đồng thời từ nhiều tab hoặc thiết bị.

5. **Event phải có contract rõ ràng.**  
   Tên event, payload, error model và lifecycle event phải được định nghĩa trước khi implement.

6. **Resource realtime phải được cô lập theo tenant và quyền truy cập.**  
   Việc join group hoặc subscribe resource chỉ được thực hiện sau authorization.

7. **Reconnect là một phần của kiến trúc, không phải edge case.**  
   Client phải xử lý reconnect, token thay đổi và restore subscription/group state.

8. **Scale-out không được phụ thuộc vào memory của một instance.**  
   Khi chạy nhiều instance phải có cơ chế phân phối realtime state/event giữa các node.

9. **Logging không được làm lộ secret hoặc nội dung nhạy cảm.**  
   JWT, access token, secret và connection string không được ghi log.

---

## 3. Kiến trúc tổng thể

```text
┌─────────────────────────────────────────────────────────────┐
│                         Frontend                            │
│                                                             │
│  Feature Component                                          │
│        │                                                    │
│        ▼                                                    │
│  ApplicationRealtimeService                                 │
│        │                                                    │
│        ▼                                                    │
│  RealtimeConnection                                         │
└───────────────┬─────────────────────────────────────────────┘
                │
                │ SignalR / WebSocket
                │ authenticated connection
                ▼
┌─────────────────────────────────────────────────────────────┐
│                    Realtime Backend                         │
│                                                             │
│  ApplicationHub                                             │
│        │                                                    │
│        ├── Authentication / Authorization                   │
│        ├── User / Group routing                             │
│        │                                                    │
│        ▼                                                    │
│  Application / Business Services                           │
│        │                                                    │
│        ├── Conversation / Agent domain                      │
│        ├── Persistence                                      │
│        └── External model / message processing              │
└───────────────┬─────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────┐
│             Distributed Realtime Infrastructure            │
│                                                             │
│  Redis backplane hoặc managed SignalR service               │
└─────────────────────────────────────────────────────────────┘
```

Gateway hoặc reverse proxy có thể đứng phía trước realtime service:

```text
Browser
   │
   ▼
API Gateway / HAProxy
   │
   ▼
Realtime Service
   │
   ├── Hub
   ├── Application services
   └── Realtime event publisher
```

Gateway có thể validate token ở lớp ngoài, nhưng realtime service vẫn phải tự enforce authentication và authorization.

---

## 4. Trách nhiệm các thành phần

### 4.1 `RealtimeConnection`

`RealtimeConnection` là lớp transport-level trên frontend.

Trách nhiệm:

- tạo và giữ `HubConnection`;
- cấu hình URL của Hub;
- cung cấp access token thông qua `accessTokenFactory`;
- start/stop connection;
- quản lý automatic reconnect;
- expose trạng thái transport;
- đăng ký/unregister handler mức transport.

`RealtimeConnection` không chứa business logic và không biết chi tiết của conversation, agent hoặc màn hình cụ thể.

---

### 4.2 `ApplicationRealtimeService`

`ApplicationRealtimeService` là application-level realtime coordinator trên frontend.

Trách nhiệm:

- điều phối connection theo authentication lifecycle;
- ánh xạ event SignalR thành RxJS stream/application event;
- expose API realtime cho các feature;
- quản lý subscription theo user/resource;
- restore subscription cần thiết sau reconnect;
- chuyển command từ feature tới realtime transport.

Ví dụ:

```text
Feature
   │
   ▼
ApplicationRealtimeService.sendMessage(...)
   │
   ▼
RealtimeConnection.invoke(...)
```

Feature component không trực tiếp quản lý lifecycle của socket.

---

### 4.3 `AuthenticationService`

`AuthenticationService` chịu trách nhiệm authentication của ứng dụng.

Realtime layer sử dụng các tín hiệu như:

```text
authenticated
tokenChanged
loggedOut
```

Realtime layer không tự implement một authentication flow riêng.

---

### 4.4 Feature Component

Các component như màn chat hoặc màn Agent chỉ:

- subscribe realtime stream;
- gửi command qua `ApplicationRealtimeService`;
- render connection state;
- render event/result;
- unsubscribe khi component bị destroy.

Component không:

- tự tạo `HubConnection`;
- tự gọi connect/disconnect theo lifecycle màn hình;
- tự xử lý access token;
- tự join group mà không thông qua realtime application service.

---

### 4.5 `ApplicationHub`

`ApplicationHub` là realtime transport adapter phía backend.

Hub chịu trách nhiệm:

- nhận SignalR command;
- truy cập authenticated principal;
- xác định `Context.UserIdentifier`;
- validate payload ở mức transport/contract;
- enforce authorization cần thiết;
- gọi application/business service;
- gửi acknowledgement hoặc event tới đúng target.

Hub không nên trở thành nơi chứa toàn bộ business logic.

Luồng chuẩn:

```text
Client command
    ↓
ApplicationHub
    ↓
Authentication / Authorization
    ↓
Application Service
    ↓
Domain / Persistence / External processing
    ↓
Realtime event publisher
    ↓
Client / User / Group
```

---

## 5. Authentication khi kết nối

Authentication phải được thực hiện trong quá trình SignalR handshake.

```text
Frontend lấy JWT
      │
      ▼
RealtimeConnection.withUrl(..., accessTokenFactory)
      │
      ▼
/hubs/application?access_token=<JWT>
      │
      ▼
JWT Bearer middleware
      │
      ├── validate issuer
      ├── validate audience
      ├── validate lifetime
      └── validate signing key
      │
      ▼
[Authorize] ApplicationHub
```

Frontend sử dụng:

```typescript
accessTokenFactory: () => accessToken
```

Với HTTP API thông thường, token tiếp tục được gửi qua header:

```http
Authorization: Bearer <access-token>
```

Việc dùng `access_token` trên query string là đặc thù của browser WebSocket/SignalR trong một số transport scenario.

Hệ thống logging, proxy và telemetry phải redaction query string chứa token.

---

## 6. Authorization và identity

### 6.1 Identity phải lấy từ server context

Mọi realtime command phải lấy user identity từ authenticated context:

```csharp
var userId = Context.UserIdentifier;
```

Không sử dụng `userId` do client gửi làm nguồn xác thực identity.

Tương tự, `tenantId`, role và quyền truy cập resource phải được resolve hoặc validate phía server.

---

### 6.2 Resource authorization

Trước khi thực hiện command liên quan tới resource, server phải kiểm tra user có quyền truy cập resource đó hay không.

Các resource điển hình:

```text
tenant
agent
conversation
session
```

Ví dụ:

```text
SendMessage(conversationId, message)
        │
        ▼
Resolve authenticated user
        │
        ▼
Check tenant membership
        │
        ▼
Check conversation permission
        │
        ▼
Execute application command
```

Không được coi việc client biết `conversationId` là bằng chứng user có quyền truy cập conversation.

---

### 6.3 Authorization khi join group

Connection chỉ được join SignalR group sau khi server xác nhận quyền.

```text
Client requests subscription
        │
        ▼
Authorize resource
        │
        ├── denied  → reject
        │
        └── allowed
              │
              ▼
         Groups.AddToGroupAsync(...)
```

---

## 7. Connection identity và routing

SignalR tạo một `ConnectionId` cho từng connection.

Một user có thể có:

```text
userId
 ├── browser tab 1 → connectionId A
 ├── browser tab 2 → connectionId B
 └── mobile device → connectionId C
```

`ConnectionId`:

- là định danh tạm thời của socket;
- có thể thay đổi sau reconnect;
- không được sử dụng như user identity lâu dài.

Để gửi event tới toàn bộ connection của một user, realtime backend nên sử dụng:

```csharp
Context.UserIdentifier
Clients.User(userId)
```

Để gửi event tới một resource có nhiều subscriber, sử dụng SignalR group sau khi đã authorization.

---

## 8. Group strategy

Group nên đại diện cho phạm vi realtime có ý nghĩa nghiệp vụ.

Ví dụ:

```text
tenant:{tenantId}
agent:{agentId}
conversation:{conversationId}
```

Không join group dựa hoàn toàn vào dữ liệu client gửi.

Luồng chuẩn:

```text
Authenticate connection
      ↓
Client subscribe conversation
      ↓
Authorize conversation
      ↓
Join conversation:{conversationId}
      ↓
Receive events của conversation
```

Khi reconnect làm thay đổi `ConnectionId`, client/application realtime layer phải thực hiện lại các subscription cần thiết nếu group membership không còn được giữ.

---

## 9. Realtime contract

Realtime contract phải được định nghĩa độc lập với implementation UI.

### 9.1 Client command

Ví dụ command gửi message:

```text
SendMessage
```

Payload nên chứa dữ liệu nghiệp vụ cần thiết, ví dụ:

```json
{
  "conversationId": "string",
  "message": "string",
  "clientMessageId": "string"
}
```

Identity không nằm trong payload để server tin tưởng.

`clientMessageId` có thể được sử dụng cho idempotency/correlation ở các flow cần chống gửi lặp.

---

### 9.2 Acknowledgement

Sau khi server chấp nhận command, server có thể trả acknowledgement cho chính caller.

Ví dụ:

```text
event: MessageAccepted
```

```json
{
  "clientMessageId": "string",
  "messageId": "string",
  "occurredAt": "string"
}
```

Acknowledgement không đồng nghĩa với toàn bộ downstream processing đã hoàn tất.

---

### 9.3 Streaming response

Đối với các flow streaming, contract nên tách rõ lifecycle:

```text
MessageChunk
MessageCompleted
MessageFailed
```

Ví dụ:

```text
SendMessage
    ↓
MessageAccepted
    ↓
MessageChunk
    ↓
MessageChunk
    ↓
MessageCompleted
```

Flow lỗi:

```text
SendMessage
    ↓
MessageAccepted
    ↓
MessageFailed
```

Mỗi event phải có schema ổn định và đủ thông tin để client correlate với message/conversation tương ứng.

---

## 10. Connection lifecycle

Frontend phải xem connection như một state machine.

```text
disconnected
    ↓
connecting
    ↓
connected
    ↓
reconnecting
    ├──────────────→ connected
    └──────────────→ disconnected
```

Các state tối thiểu:

```text
connecting
connected
reconnecting
disconnected
```

---

### 10.1 Login

```text
Login thành công
      ↓
AuthenticationService lưu access token
      ↓
ApplicationRealtimeService nhận authenticated event
      ↓
RealtimeConnection start
      ↓
Connect tới /hubs/application
```

---

### 10.2 Token thay đổi

Khi access token thay đổi:

```text
Token mới được lưu
      ↓
Realtime layer refresh authentication state
      ↓
STOP connection cũ nếu cần
      ↓
accessTokenFactory lấy token mới
      ↓
CONNECT lại Hub
      ↓
Restore subscription/group state
```

Realtime layer không được giữ cố định token cũ trong lifetime của ứng dụng.

---

### 10.3 Logout

```text
Logout
   ↓
ApplicationRealtimeService nhận loggedOut
   ↓
Disconnect realtime connection
   ↓
Clear subscription state
   ↓
Clear authentication state
```

---

### 10.4 Mất mạng hoặc backend restart

Client phải sử dụng automatic reconnect.

Một reconnect policy có thể sử dụng các mốc:

```text
0ms
1000ms
3000ms
5000ms
```

Sau reconnect thành công:

1. cập nhật connection state;
2. khôi phục subscription cần thiết;
3. đồng bộ lại dữ liệu nếu client có khả năng đã bỏ lỡ event.

---

## 11. Delivery semantics và reliability

Realtime transport không được mặc định coi là durable message storage.

Source code phải phân biệt:

```text
Realtime delivery
≠
Persistent business state
```

Conversation và message state cần được lưu ở persistent storage nếu nghiệp vụ yêu cầu durability.

Các capability reliability cần được thiết kế tại application layer:

- idempotency;
- timeout;
- retry phù hợp;
- rate limit;
- backpressure;
- correlation;
- xử lý duplicate command/event khi cần.

Khi client reconnect sau khoảng mất kết nối, hệ thống không nên chỉ dựa vào event đã broadcast trước đó để khôi phục state. Client phải có cơ chế load lại persistent state hoặc resume theo contract tương ứng.

---

## 12. Scale-out

Một implementation chỉ lưu connection registry trong memory của một instance không đủ cho production multi-instance.

Khi scale-out:

```text
               ┌── Realtime instance A
Client / Proxy ├── Realtime instance B
               └── Realtime instance C
```

Các instance phải chia sẻ hoặc phân phối realtime message thông qua:

```text
Redis backplane
hoặc
Managed SignalR service
```

Mục tiêu:

- `Clients.User(...)` hoạt động xuyên instance;
- group event được phân phối xuyên instance;
- không phụ thuộc vào connection registry local để xác định toàn bộ connected client.

Local registry có thể dùng cho diagnostics của một instance, nhưng không được coi là global source of truth.

---

## 13. Public widget

Nếu hệ thống cung cấp public chat widget cho website tenant, widget phải có authentication model riêng phù hợp với public client.

Kiến trúc cần hỗ trợ:

```text
Public website
    ↓
Request short-lived session token
    ↓
Connect realtime endpoint
    ↓
Resolve tenant/session
    ↓
Authorize conversation/session
```

Yêu cầu:

- token ngắn hạn;
- tenant isolation;
- không expose credential nội bộ;
- session phải map được tới tenant/resource hợp lệ;
- server vẫn enforce authorization cho mỗi resource.

---

## 14. CORS và WebSocket transport

CORS chỉ giới hạn JavaScript chạy trong browser và không thay thế authentication/authorization.

Realtime endpoint phải cấu hình CORS phù hợp với frontend origin được phép.

Ví dụ development:

```text
http://localhost:4200
```

Proxy/reverse proxy phải hỗ trợ WebSocket upgrade và timeout phù hợp.

Các header transport như:

```text
Upgrade
Connection
Sec-WebSocket-*
```

do browser/SignalR transport xử lý. Application code không nên tự dựng các header này.

---

## 15. Logging và observability

Realtime backend phải ghi structured log cho các lifecycle và command quan trọng.

Các trường nên có:

```text
connectionId
userId
tenantId
traceId
correlationId
eventName
resourceId
duration
outcome
occurredAt
```

Không log:

```text
JWT
access token
secret
connection string
message content nhạy cảm
```

Các nhóm observability cần có:

### Logging

- connection opened/closed;
- reconnect;
- authentication failure;
- authorization denied;
- realtime command accepted/rejected;
- event publish failed.

### Metrics

- số connection active;
- connection rate;
- reconnect rate;
- command rate;
- error rate;
- event delivery latency;
- processing duration.

### Distributed tracing

Realtime flow cần có correlation/trace context để có thể lần theo:

```text
Client command
    ↓
Hub
    ↓
Application service
    ↓
Persistence / external service
    ↓
Realtime response
```

---

## 16. Security requirements

Implementation realtime phải đáp ứng tối thiểu:

- Hub được bảo vệ bằng authentication;
- authorization theo resource;
- tenant isolation;
- không tin identity từ payload;
- không log token;
- query string chứa access token được redaction;
- validate payload;
- reject message rỗng hoặc invalid;
- áp dụng rate limit cho command phù hợp;
- public widget sử dụng short-lived token;
- gateway validation không thay thế authorization tại realtime service.

---

## 17. Source code organization

Một cách tổ chức source code phù hợp:

### Frontend

```text
core/
└── realtime/
    ├── realtime-connection.ts
    ├── realtime-event.model.ts
    └── application-realtime.service.ts
```

Feature:

```text
features/
└── <feature>/
    └── components/
```

Dependency direction:

```text
Feature Component
        ↓
ApplicationRealtimeService
        ↓
RealtimeConnection
        ↓
SignalR
```

Feature không phụ thuộc trực tiếp vào `HubConnection`.

---

### Backend

```text
Api/
├── Hubs/
│   └── ApplicationHub.cs
│
├── Realtime/
│   ├── Publishers/
│   ├── Contracts/
│   └── Authorization/
│
└── Controllers/
```

Application/domain layer được tách khỏi Hub:

```text
ApplicationHub
      ↓
Application Service / Command Handler
      ↓
Domain / Infrastructure
```

Việc publish realtime event từ các flow HTTP, background job hoặc message consumer phải đi qua realtime publisher/service dùng chung thay vì gọi logic nằm trong Hub.

---

## 18. Tiêu chí kiểm thử kiến trúc

Một implementation được coi là tuân theo kiến trúc khi có thể kiểm thử các nhóm sau.

### Connection

- authenticated user kết nối thành công;
- anonymous/invalid token bị từ chối;
- reconnect hoạt động sau mất mạng;
- reconnect hoạt động sau backend restart;
- token mới được sử dụng sau authentication refresh;
- logout đóng connection.

### Authorization

- user không truy cập được conversation không có quyền;
- tenant A không nhận event của tenant B;
- client không thể giả `userId` hoặc `tenantId`;
- join group bị từ chối nếu không có quyền.

### Routing

- event gửi tới caller chỉ tới đúng connection;
- event gửi tới user tới tất cả connection của user;
- event gửi tới group chỉ tới subscriber hợp lệ;
- reconnect có thể restore subscription.

### Messaging

- message hợp lệ được accept;
- payload invalid bị reject;
- duplicate command được xử lý theo idempotency policy;
- streaming có `MessageChunk`, `MessageCompleted`, `MessageFailed`;
- persistent state vẫn khôi phục được sau reconnect.

### Scale-out

- user có connection ở nhiều instance vẫn nhận đúng event;
- group broadcast hoạt động xuyên instance;
- instance restart không làm mất persistent business state.

### Security

- JWT không xuất hiện trong application log;
- access token query string được redaction;
- resource authorization được enforce tại server.

### Observability

- có thể trace một command từ Hub tới downstream processing;
- có metrics về connection, error và latency;
- failure có structured log đủ correlation information.

---

## 19. Checklist triển khai

Trước khi một realtime capability được đưa vào production, cần xác nhận:

- [ ] Realtime contract đã được định nghĩa.
- [ ] Authentication được thực hiện khi handshake.
- [ ] `Context.UserIdentifier` được cấu hình đúng.
- [ ] Resource authorization được enforce phía server.
- [ ] Tenant isolation được kiểm thử.
- [ ] Hub không chứa business logic chính.
- [ ] Feature frontend không trực tiếp quản lý `HubConnection`.
- [ ] Reconnect policy đã được cấu hình.
- [ ] Subscription được restore sau reconnect.
- [ ] Persistent business state không phụ thuộc vào socket connection.
- [ ] Idempotency/rate limit/timeout/backpressure đã được đánh giá.
- [ ] Proxy hỗ trợ WebSocket upgrade.
- [ ] Multi-instance có Redis backplane hoặc managed SignalR.
- [ ] Logging không chứa token/secret.
- [ ] Metrics và distributed tracing đã được cấu hình.
- [ ] Public widget, nếu có, sử dụng short-lived session token và tenant isolation.

---

## 20. Tài liệu liên quan

- [Realtime specification](../../specs/000031-agent-realtime/spec.md)
- [Realtime contract](../../specs/000031-agent-realtime/contracts/realtime-demo.md)
- [Realtime quickstart](../../specs/000031-agent-realtime/quickstart.md)
- [System map](./system-map.md)
