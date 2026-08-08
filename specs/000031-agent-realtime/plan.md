# Kế hoạch triển khai: Demo realtime cho Agent Service

**Branch**: `000031-agent-realtime` | **Ngày**: 2026-08-08 | **Đặc tả**: [spec.md](./spec.md)

**Đầu vào**: Đặc tả tính năng từ `specs/000031-agent-realtime/spec.md`

## Tóm tắt

**Yêu cầu chính từ spec**: Kết nối màn hình `ChatComponent` với `flex-agent-service` qua realtime; BE nhận và log tin nhắn FE gửi; một endpoint test của BE phát thông báo đến FE để FE hiển thị `alert`.

**Hướng tiếp cận kỹ thuật dự kiến**: Dùng ASP.NET Core SignalR native ở Agent Service với một hub demo có method nhận tin nhắn và event thông báo. Dùng `@microsoft/signalr` đã có trong Angular để tạo `ApplicationRealtimeService`; `AgentCreateWizardComponent` quản lý kết nối, trạng thái và gửi tin nhắn. Endpoint HTTP được bảo vệ bằng authorization hiện có và gọi broadcaster của hub.

**Kết quả sau research**: Đã xác nhận frontend đã có dependency và pattern SignalR trong `exchange-realtime.service.ts`; backend hiện chưa đăng ký SignalR/hub; Agent API đang dùng controller, JWT authorization và Serilog; demo không cần database.

## Phạm vi kỹ thuật

**Trong phạm vi**:
- `flex-agent-service`: đăng ký SignalR, thêm hub realtime demo, DTO sự kiện, endpoint test phát thông báo, log tin nhắn nhận được và CORS/endpoint mapping tối thiểu cho local.
- `flex-microfrontend`: thêm service realtime cho Agent, cấu hình base URL local, nối khung chat preview của `AgentCreateWizardComponent` với hub, hiển thị trạng thái kết nối/lỗi và `alert` khi nhận thông báo.
- Feature artifacts: contract, quickstart và test cho hai chiều giao tiếp.

**Ngoài phạm vi kỹ thuật**:
- Database, migration, lịch sử hội thoại, AI completion, streaming, room/broadcast production, retry durable và thay đổi authentication platform.
- Đổi layout Skote ngoài các trạng thái realtime tối thiểu cần hiển thị.

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: Backend .NET 9/C#; frontend Angular 16/TypeScript 5.1.6; RxJS 7.8.1.

**Service/App liên quan**: `flex-agent-service/src/Flex.Agent.Api`; `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard`.

**Convention skill áp dụng**: `flex-agent-service` → `flex-dotnet-engineering`; `flex-microfrontend` → `flex-frontend-engineering`.

**Phụ thuộc chính**: ASP.NET Core SignalR server APIs; frontend package `@microsoft/signalr` đã có; JWT/authentication và Serilog hiện có.

**Lưu trữ**: Không áp dụng; dữ liệu demo chỉ tồn tại trong event và log của process.

**Kiểm thử**: xUnit cho backend; Jasmine/Karma cho Angular; integration/manual smoke test cho SignalR + HTTP endpoint.

**Nền tảng chạy**: ASP.NET Core web service và Angular development server trên local browser.

**Đơn vị deploy**: `Flex.Agent.Api` và Angular app `flex-microfrontend`.

**Loại project**: Web API và admin web.

**Mục tiêu hiệu năng**: FE nhận thông báo test trong tối đa 2 giây ở local; không đặt throughput production cho demo.

**Ràng buộc**: Không ghi token/secret vào log; không làm thay đổi luồng chat mock ngoài màn hình thử nghiệm.

**Quy mô/Phạm vi**: Một phiên FE local, một service local, không lưu trữ và không broadcast durable.

## Kiểm tra constitution

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|-----------------------|---------|
| Scope Gate | Pass | Pass | Bám đúng demo hai chiều, phần production nằm ngoài phạm vi. |
| Traceability Gate | Pass | Pass | P1/P2 map tới hub, endpoint, Angular service/component và test. |
| Test Gate | Pass | Pass | Có unit, contract, integration và manual smoke test phù hợp. |
| Security Gate | Pass | Pass | Tận dụng auth hiện có; endpoint test không mở anonymous và cấm log secret. |
| Compatibility Gate | Pass | Pass | Chỉ thêm route/hub demo, không đổi API hiện hữu; config có giá trị local riêng. |
| Observability Gate | Pass | Pass | Log event nhận tin nhắn, trạng thái phát và lỗi; có quickstart kiểm tra. |
| Complexity Gate | Pass | Pass | Dùng pattern SignalR có sẵn, không thêm abstraction đa mục đích. |
| Release Gate | Không áp dụng | Không áp dụng | MVP local/demo, không có migration hay rollout production. |

## Câu hỏi kỹ thuật cần research

- **TQ-001**: Có thể dùng SignalR native và pattern đã có thay vì thêm thư viện/giao thức mới không? → Đã resolve trong `research.md`.
- **TQ-002**: Hub/endpoint nên đặt ở boundary nào để không ảnh hưởng API Agent hiện có? → Đã resolve trong `research.md`.
- **TQ-003**: Có thay đổi database hoặc migration không? → Đã resolve: không áp dụng.

## Thiết kế tổng quan

**Luồng chính**:
1. `AgentCreateWizardComponent` yêu cầu `ApplicationRealtimeService` mở kết nối tới `/hubs/application` và hiển thị trạng thái `connecting/connected/reconnecting/disconnected`.
2. Khi người dùng gửi nội dung không rỗng, service gọi method hub `SendMessage`; hub chuẩn hóa/validate nội dung, ghi structured log và trả event `messageReceived` để FE xác nhận.
3. Khi gọi `POST /api/v1/realtime-demo/notify`, controller gọi broadcaster phát event `demoNotification` tới các client đang kết nối; FE nhận event trong Angular zone và gọi `window.alert(message)`.
4. Nếu không có client, endpoint trả kết quả có `connectedClients: 0`; nếu mất kết nối, FE hiển thị lỗi và SignalR automatic reconnect được dùng ở mức client.

**Component/module tham gia**:
- `Flex.Agent.Api/Hubs/ApplicationHub.cs`: nhận message và phát event demo.
- `Flex.Agent.Api/Controllers/RealtimeDemoController.cs`: endpoint kích hoạt thông báo.
- `Flex.Agent.Api/Extensions/ServiceExtensions.cs`, `ApplicationExtensions.cs`: đăng ký SignalR, authorization/CORS cần thiết và map hub/controller.
- `flex-microfrontend/src/app/core/services/application-realtime.service.ts`: một service quản lý connection lifecycle và RxJS streams.
- `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.ts/html`: gửi message, render state, nhận event và alert.
- `flex-microfrontend/src/environments/environment*.ts`: cấu hình `agentApiBaseUrl`/hub URL theo môi trường.

**Điểm mở rộng/thay đổi chính**:
- Public realtime contract trong `contracts/realtime-demo.md`.
- Chỉ một singleton client service cho lifecycle SignalR; component không tự tạo nhiều connection.
- Event payload có `type`, `message`, `occurredAt`; không có entity/database id.

**Luồng thay thế/lỗi chính**:
- Message rỗng: FE chặn; hub vẫn validate và trả lỗi nếu client gọi trực tiếp.
- Chưa kết nối: FE không gửi và hiển thị trạng thái; endpoint không có client trả số lượng 0.
- Hub start thất bại: service phát `disconnected`, không làm vỡ component.
- Endpoint unauthorized/forbidden: giữ status hiện có; không broadcast.

**Thay đổi boundary giữa service/module**:
- Thêm boundary realtime Agent giữa browser và Agent API; không thay đổi các controller Agent hiện có.

**Idempotency/Concurrency**:
- Mỗi lần `SendMessage` là một event độc lập, không retry server-side và không lưu state.
- Endpoint chỉ broadcast một lần cho mỗi HTTP request; concurrent calls có thể phát nhiều alert vì đây là hành vi demo được chấp nhận.

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|------------|----------------------|---------------------|--------------|-------------|----------|
| US-001 / FR-001 | P1 | Đủ rõ | FE trim/chặn message rỗng và gọi hub method | `agent-create-wizard.component.ts`, `core/services/application-realtime.service.ts` | `SendMessage` | Không áp dụng | Angular unit + manual |
| US-001 / FR-002 | P1 | Đủ rõ | Hub nhận message trong connection hiện tại và phát ack | `Flex.Agent.Api/Hubs/AgentRealtimeHub.cs` | `SendMessage`, `messageReceived` | `DemoChatMessage` in-memory | xUnit/integration |
| US-001 / FR-003 | P1 | Đủ rõ | Structured log tại boundary hub, không log credential | `AgentRealtimeHub.cs` | Không áp dụng | Không áp dụng | Log assertion/manual |
| US-002 / FR-004 | P1 | Đủ rõ | Controller gọi hub context broadcast event, trả client count | `Controllers/RealtimeDemoController.cs` | `POST /api/v1/realtime-demo/notify` | Không áp dụng | Controller/integration |
| US-002 / FR-005 | P1 | Đủ rõ | Service subscribe `demoNotification`, component gọi `alert` | `agent-realtime.service.ts`, `chat.component.ts` | `demoNotification` | `DemoNotification` | Angular unit/manual |
| FR-006 | P2 | Đủ rõ | RxJS `connectionState$` và error stream hiển thị ở chat | `chat.component.html` | Không áp dụng | Không áp dụng | Angular component |

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---------|------------------|--------------------------|---------------|
| Database/Migration | Không thay đổi schema/data | Không áp dụng | Xác nhận không có migration/file DB mới |
| API/Contract | Thêm hub và endpoint demo, không đổi endpoint Agent hiện hữu | Client mới phải dùng đúng event/payload; endpoint demo chỉ dành cho local/demo | Contract test + quickstart |
| Permission/Security | Hub và endpoint dùng authorization hiện có; CORS chỉ cho origin cấu hình local | Cấu hình sai có thể mở endpoint ngoài ý muốn | Test unauthorized + kiểm tra CORS |
| Logging/Audit | Thêm structured log `RealtimeDemoMessageReceived` và `RealtimeDemoNotificationSent` | Log quá nhiều hoặc lộ nội dung nhạy cảm | Unit/inspection + manual log |
| UI/UX | Chat mock có thêm connection state, gửi realtime và alert | `alert` chỉ phù hợp demo; giữ layout hiện tại | Angular test + browser smoke |
| Job/Worker/Integration | Thêm kết nối browser ↔ SignalR; không có job/worker | Mất kết nối trong local | Integration/reconnect manual |

## API/Contract Detail

**Có thay đổi contract không**: Có — thêm realtime hub contract và endpoint demo. Chi tiết đầy đủ tại [contracts/realtime-demo.md](./contracts/realtime-demo.md).

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|----------|------|----------|---------------------|------------------------|
| `/hubs/application` | SignalR Hub `ApplicationHub` | Thêm `SendMessage`, `messageReceived`, `demoNotification` | Có, contract mới độc lập | `ApplicationRealtimeService` |
| `POST /api/v1/realtime-demo/notify` | HTTP API | Thêm endpoint demo | Có, không đổi route cũ | Developer/quickstart |

## Permission Matrix

| Vai trò/Scope | Xem | Tạo | Sửa | Xóa | Duyệt/Xử lý | Ghi chú |
|---------------|-----|-----|-----|-----|-------------|---------|
| Người dùng đã xác thực trong môi trường demo | Có | Không áp dụng | Không áp dụng | Không áp dụng | Có — gọi thao tác test | Bị giới hạn bởi auth hiện có. |
| Anonymous | Không | Không áp dụng | Không áp dụng | Không áp dụng | Không | Không được mở hub/endpoint. |

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Không áp dụng — chỉ event realtime và structured log trong process.

**Database đích**: Không áp dụng.

**Repo chứa migration**: Không áp dụng.

**Migration**:
- Không áp dụng.

**Backfill/Cleanup**:
- Không áp dụng.

**Tương thích dữ liệu cũ**:
- Không áp dụng.

**Rủi ro dữ liệu**:
- Không tạo dữ liệu bền vững; vẫn cấm secret/token trong log.

**Cách xác minh**:
- Kiểm tra diff không có migration/schema; chạy smoke test hai chiều.

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| DEC-001 | ASP.NET Core SignalR | Native với .NET 9 và frontend đã có `@microsoft/signalr`/pattern tương tự | WebSocket thủ công | Tăng code protocol/lifecycle, không cần cho demo |
| DEC-002 | Một `ApplicationRealtimeService` singleton + RxJS streams | Tách lifecycle khỏi component và khớp pattern `ExchangeRealtimeService` hiện có | Tạo `HubConnection` trong `AgentCreateWizardComponent` | Khó test, dễ tạo nhiều connection và trộn UI với transport |
| DEC-003 | HTTP endpoint gọi `IHubContext` để phát test | Dễ gọi bằng Postman/curl và kiểm chứng BE → FE | Endpoint giả lập ở FE | Không chứng minh được BE phát event |
| DEC-004 | Không persistence | Đúng phạm vi demo, giảm migration/rủi ro dữ liệu | Lưu message vào database | Ngoài phạm vi và không cần để xác nhận realtime |

## Chiến lược kiểm thử

**Unit test**:
- Backend: validate message rỗng/trim và payload/logging boundary nếu tách helper nhỏ; controller trả `connectedClients` đúng.
- Angular: service xử lý state/event; component chặn rỗng, gửi message và gọi `alert` khi nhận notification.

**Integration test**:
- Khởi chạy API test host và client SignalR để xác nhận `SendMessage` nhận được; gọi endpoint notify và xác nhận client nhận event.

**Contract test**:
- Kiểm tra tên hub method/event, field payload, status/response của endpoint theo [contract](./contracts/realtime-demo.md).

**Permission/security test**:
- Anonymous không connect/gọi endpoint; request hợp lệ dùng auth hiện có; log không chứa token/secret.

**E2E/manual test**:
- Quickstart: mở FE chat, xác nhận connected, gửi marker message, kiểm tra log, gọi endpoint và xác nhận browser alert.

**Regression test**:
- `Agent API` test suite; Angular Agent create preview test; các route/chat mock hiện có vẫn render.

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/000031-agent-realtime/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/realtime-demo.md
└── tasks.md                 # tạo bởi /speckit-tasks
```

### Source code

```text
flex-agent-service/
├── src/Flex.Agent.Api/
│   ├── Hubs/ApplicationHub.cs
│   ├── Controllers/RealtimeDemoController.cs
│   ├── DTOs/RealtimeDemoDtos.cs
│   ├── Extensions/ServiceExtensions.cs
│   └── Extensions/ApplicationExtensions.cs
└── tests/Flex.Agent.Tests/
    └── Realtime/AgentRealtimeTests.cs

flex-microfrontend/
├── src/app/core/services/application-realtime.service.ts
├── src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.ts
├── src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.html
├── src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.spec.ts
└── src/environments/environment*.ts
```

**Quyết định cấu trúc**: Giữ feature backend trong `Flex.Agent.Api` vì đây là demo transport/API; không tạo project Domain/Infrastructure mới. Đặt Angular service ở `core/services` để tái sử dụng và giữ component chat tập trung vào UI.

## Rollout & Rollback

**Kế hoạch rollout**: Chỉ chạy local/demo; khởi động API rồi frontend theo [quickstart.md](./quickstart.md).

**Tương thích ngược**: Route/controller hiện hữu không đổi; client không dùng hub mới không bị ảnh hưởng.

**Feature flag/config**: Dùng config URL local và có thể tắt phần realtime bằng cấu hình hoặc không khởi tạo service; không cần flag production.

**Thực thi migration/backfill khi rollout**:
- Không áp dụng.

**Rollback code/config**:
- Revert các file hub/controller/service/agent-create-preview/config của feature; không cần rollback dữ liệu.

**Rollback dữ liệu/migration**:
- Không áp dụng.

**Điều kiện kích hoạt rollback**:
- Build/test hiện hữu hỏng hoặc route chat không render; tắt/revert demo trước khi xử lý tiếp.

## Observability & Debug

**Log cần có**:
- `RealtimeDemoMessageReceived`: `eventName`, `connectionId`, `messageLength`, `occurredAt`.
- `RealtimeDemoNotificationSent`: `eventName`, `connectedClients`, `occurredAt`.
- Error: `eventName`, `connectionId`/request id nếu có, `result`; không log secret.

**Dữ liệu không được log**:
- JWT, refresh token, API key, password, connection string và dữ liệu nhạy cảm. Nội dung demo chỉ log khi đã xác nhận là dữ liệu giả lập; nếu cần an toàn hơn log length/preview có giới hạn.

**Metric cần theo dõi**:
- Không cần metric production; quickstart kiểm tra số client kết nối và số event nhận.

**Trace/Correlation**:
- Giữ `connectionId` cho event hub và request id của endpoint trong log nếu framework cung cấp; không tự tạo tracing infrastructure cho demo.

**Cách kiểm tra sau release**:
- Kiểm tra trạng thái `Connected`, gửi marker message, xem log, gọi endpoint và xác nhận alert trong browser.

**Tình huống debug chính**:
- Sai URL/origin/CORS, authorization bị từ chối, hub không map, mất connection, payload/event name lệch contract.

## Theo dõi độ phức tạp

Không có vi phạm constitution cần biện minh. SignalR service singleton, hub và endpoint là các boundary trực tiếp cần thiết cho demo; không thêm repository/mediator/abstraction dùng một lần.

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật chặn thiết kế/task generation đã được resolve trong research hoặc ghi rủi ro rõ ràng.
- [x] Thiết kế tổng quan đã mô tả luồng chính, component/module tham gia, điểm thay đổi và boundary nếu có.
- [x] Các tình huống idempotency/concurrency/retry đã được đánh giá hoặc ghi `Không áp dụng`.
- [x] Mỗi `US`/`FR` P1/P2 hoặc FR ảnh hưởng code/data/API/permission có mapping sang module/path, API/contract, data/entity và kiểm thử.
- [x] Tác động tới database, API contract, permission, logging/audit và integration đã được đánh giá hoặc ghi `Không áp dụng`.
- [x] Các contract/API/event thay đổi đã có consumer bị ảnh hưởng và cách kiểm tra compatibility.
- [x] Dữ liệu/migration/backfill/compatibility đã rõ hoặc ghi `Không áp dụng`.
- [x] Database đích và repo chứa migration đã được xác định, đối chiếu `docs/architecture/system-map.md`, hoặc ghi `Không áp dụng` (Constitution VI).
- [x] Quyết định kỹ thuật chính đã có lý do chọn và phương án bị loại.
- [x] Chiến lược kiểm thử đã bao phủ unit, integration, contract, permission/security, E2E/manual và regression khi liên quan.
- [x] Rollout, rollback code/config, rollback dữ liệu/migration, feature flag/config và backward compatibility đã rõ hoặc ghi `Không áp dụng`.
- [x] Observability/debug plan có log field, dữ liệu không được log, metric/trace và cách kiểm tra sau release.
- [x] Không còn cây thư mục mẫu/generic; toàn bộ path trong cấu trúc source code là path thật trong repository.
- [x] Constitution gate không còn blocker trước khi chuyển sang `/speckit-tasks`.
