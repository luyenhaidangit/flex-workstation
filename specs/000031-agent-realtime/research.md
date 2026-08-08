# Research: Demo realtime cho Agent Service

## Phạm vi nghiên cứu

Nghiên cứu read-only trên codebase hiện tại để resolve các câu hỏi kỹ thuật trong plan; không thêm database, không thay đổi source product trong phase này.

## TQ-001 — Chọn giao thức realtime

**Decision**: Dùng ASP.NET Core SignalR ở backend và `@microsoft/signalr` ở Angular.

**Rationale**:
- `flex-microfrontend/package.json` đã có `@microsoft/signalr`.
- `src/app/exchange/exchange-realtime.service.ts` đã chứng minh pattern `HubConnectionBuilder`, automatic reconnect, event subscription và RxJS state phù hợp codebase.
- `Flex.Agent.Api` là ASP.NET Core .NET 9 nên SignalR là transport native, không cần tự xây protocol WebSocket.

**Alternatives considered**:
- WebSocket thủ công: loại vì phải tự xử lý protocol, reconnect và dispatch event.
- Polling: loại vì không kiểm chứng đúng yêu cầu BE chủ động đẩy event.

## TQ-002 — Boundary của hub và endpoint

**Decision**: Đặt hub và endpoint trong `Flex.Agent.Api`; hub ở `Hubs/AgentRealtimeHub.cs`, endpoint ở `Controllers/RealtimeDemoController.cs`.

**Rationale**:
- `Flex.Agent.Api` hiện là composition root, đăng ký controller/auth và map HTTP endpoints.
- Demo chỉ là transport/integration slice, không có business policy hoặc persistence để justify project mới.
- Endpoint HTTP dùng `IHubContext<AgentRealtimeHub>` nên developer có thể gọi bằng Postman/curl, đồng thời FE dùng cùng contract event.

**Alternatives considered**:
- Đặt demo trong `Flex.Agent.Infrastructures`: loại vì infrastructure không nên sở hữu HTTP/hub boundary.
- Tạo service/project realtime riêng: loại vì tăng deployment/coordination cho một demo không có failure boundary độc lập.

## TQ-003 — Dữ liệu và migration

**Decision**: Không có database/schema/migration.

**Rationale**:
- Spec chỉ yêu cầu nhận message, log và broadcast trong phiên chạy.
- Việc lưu lịch sử hội thoại nằm ngoài scope; event DTO và log đủ cho smoke test.
- Constitution VI vì vậy được đánh dấu `Không áp dụng` trong plan.

**Alternatives considered**:
- Lưu message vào PostgreSQL của Agent Service: loại vì tạo schema ngoài scope và làm demo khó rollback.

## Cấu hình và tương thích

**Decision**: Thêm URL Agent API/hub vào environment Angular; dùng origin local đã cấu hình trong backend khi cần CORS.

**Rationale**:
- `environment.ts` hiện có các base URL service và `environment.prod.ts` có giá trị production riêng.
- Không hardcode URL trong component/service.
- Không đưa secret hoặc connection string vào artifact; các giá trị nhạy cảm hiện có trong file local không thuộc phạm vi feature.

## Kết luận

Các câu hỏi chặn task generation đã được resolve. Thiết kế có thể chuyển sang `$speckit-tasks`.
