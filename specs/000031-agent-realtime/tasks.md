# Tasks: Demo realtime cho Agent Service

**Đặc tả**: [spec.md](./spec.md)  
**Plan**: [plan.md](./plan.md)  
**Contract**: [contracts/realtime-demo.md](./contracts/realtime-demo.md)

## Phase 1: Setup

**Mục đích**: Chuẩn bị dependency, config và test surface cho hai repo.

- [X] T001 [P] Bổ sung package `Microsoft.AspNetCore.Mvc.Testing` phiên bản tương thích .NET 9 vào `flex-agent-service/tests/Flex.Agent.Tests/Flex.Agent.Tests.csproj` để hỗ trợ test host/integration cho hub và endpoint.
- [X] T002 [P] Bổ sung `agentApiBaseUrl` và `agentRealtimeHubPath` vào `flex-microfrontend/src/environments/environment.ts` và `environment.prod.ts`, giữ giá trị production không hardcode secret.
- [X] T003 [P] Tạo thư mục `flex-agent-service/src/Flex.Agent.Api/Hubs` và `flex-agent-service/tests/Flex.Agent.Tests/Realtime` theo cấu trúc plan; không tạo project hoặc migration mới.
- [X] T004 [P] Tạo khung service `flex-microfrontend/src/app/core/services/agent-realtime.service.ts` và chuẩn bị test double cho Agent create preview.

## Phase 2: Foundational (Blocking Prerequisites)

**Mục đích**: Đăng ký transport, auth/CORS và contract types trước mọi user story.

- [X] T005 Cập nhật `flex-agent-service/src/Flex.Agent.Api/Extensions/ServiceExtensions.cs` để đăng ký `AddSignalR()` và CORS policy chỉ cho origin Angular local đã cấu hình; không mở anonymous policy.
- [X] T006 Cập nhật `flex-agent-service/src/Flex.Agent.Api/Extensions/ApplicationExtensions.cs` để gọi CORS đúng thứ tự middleware, giữ `UseAuthentication`/`UseAuthorization`, map controllers và map `/hubs/application` tới `ApplicationHub`.
- [X] T007 [P] Tạo DTO `DemoChatMessage` và `DemoNotification` trong `flex-agent-service/src/Flex.Agent.Api/DTOs/RealtimeDemoDtos.cs` theo contract, gồm trim/non-empty rule và timestamp do server gán.
- [X] T008 [P] Tạo model TypeScript cho `DemoChatMessage`, `DemoNotification` và `RealtimeConnectionState` trong `flex-microfrontend/src/app/core/services/agent-realtime.service.ts`, khớp field/name trong `specs/000031-agent-realtime/contracts/realtime-demo.md`.
- [X] T009 [P] Tạo contract test skeleton trong `flex-agent-service/tests/Flex.Agent.Tests/Realtime/AgentRealtimeContractTests.cs` để khóa hub path, method/event name và response shape của endpoint trước implementation.

**Checkpoint**: Backend map được hub/HTTP pipeline và frontend có contract/config; các user story có thể triển khai theo dependency bên dưới.

## Phase 3: User Story 1 — Gửi tin nhắn và quan sát BE nhận được (P1) — MVP

**Goal**: FE gửi message không rỗng qua SignalR, BE nhận, log và trả ack để FE xác nhận.

**Independent Test**:

1. Chạy Agent Service và frontend, mở `/agents/create`, xác nhận trạng thái `Connected` trong panel preview bên phải.
2. Gửi `realtime-smoke-20260808` từ ô chat.
3. Xác nhận message xuất hiện ở chat qua event `messageReceived` và log backend có event nhận cùng thời điểm/connection.
4. Gửi input chỉ có khoảng trắng và xác nhận FE không gọi hub, hub gọi trực tiếp cũng trả lỗi hợp lệ.

### Tests for User Story 1

- [X] T010 [US1] Viết unit/contract test trong `flex-agent-service/tests/Flex.Agent.Tests/Realtime/AgentRealtimeContractTests.cs` kiểm tra `SendMessage` trim input, từ chối chuỗi rỗng và phát `messageReceived` với `type`, `message`, `occurredAt`.
- [X] T011 [US1] Viết test Angular trong `flex-microfrontend/src/app/core/services/agent-realtime.service.spec.ts` kiểm tra service subscribe `messageReceived`, phát message stream và cập nhật state khi kết nối/reconnect/close.
- [X] T012 [US1] Mở rộng test của Agent create preview để kiểm tra submit message hợp lệ gọi service, message rỗng không gửi, và trạng thái disconnected hiển thị lỗi thử lại.

### Implementation for User Story 1

- [X] T013 [US1] Implement `ApplicationHub.SendMessage` trong `flex-agent-service/src/Flex.Agent.Api/Hubs/ApplicationHub.cs`: yêu cầu `[Authorize]`, trim/validate, gán UTC timestamp, ghi structured log không chứa token/secret và gọi `Clients.Caller.SendAsync("messageReceived", ...)`.
- [X] T014 [US1] Implement `AgentRealtimeService.connect`, `disconnect`, `sendMessage` và các observable state/event trong `flex-microfrontend/src/app/core/services/agent-realtime.service.ts` bằng `HubConnectionBuilder`, URL từ environment và automatic reconnect theo pattern `exchange-realtime.service.ts`.
- [X] T015 [US1] Cập nhật `onSendMessage`, lifecycle init/destroy và hàm xử lý event trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.ts` để kết nối một lần, trim message, gọi `sendMessage`, hiển thị ack và không tạo connection trùng.
- [X] T016 [US1] Cập nhật `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.html` để hiển thị trạng thái `Connecting/Connected/Reconnecting/Disconnected`, disable submit khi chưa connected và giữ layout preview hiện có.
- [ ] T017 [US1] Thực hiện manual validation cho AC-001/AC-002/AC-003 bằng marker message và log backend theo bước Independent Test; ghi nhận kết quả/lỗi cấu hình trong `specs/000031-agent-realtime/quickstart.md` nếu cần.

**Definition of Done**:

- `SendMessage` nhận message hợp lệ, trả ack và log đúng; message rỗng bị chặn ở cả FE và BE.
- FE có trạng thái kết nối/lỗi và không tạo nhiều connection.
- Test Angular/backend liên quan pass và Independent Test US1 hoàn tất.

## Phase 4: User Story 2 — Nhận thông báo chủ động từ BE (P1)

**Goal**: Developer gọi endpoint test, backend broadcast `demoNotification` tới FE đang kết nối; FE hiển thị `alert`, còn không có client thì trả `connectedClients: 0`.

**Dependency**: Phụ thuộc T014–T016 vì service và chat component đã sở hữu lifecycle/subscription realtime; backend endpoint có thể viết song song với phần frontend nếu không sửa cùng file.

**Independent Test**:

1. Để `/agents/create` kết nối và ghi nhận `Connected` trong panel preview.
2. Gọi `POST /api/v1/realtime-demo/notify` với message test và authorization hiện có.
3. Xác nhận response `200`, `connectedClients > 0` và browser hiển thị `alert` đúng nội dung.
4. Disconnect FE, gọi lại endpoint và xác nhận `connectedClients: 0`, không có exception.

### Tests for User Story 2

- [X] T018 [P] [US2] Viết integration/contract test trong `flex-agent-service/tests/Flex.Agent.Tests/Realtime/RealtimeDemoControllerTests.cs` kiểm tra endpoint yêu cầu authorization, trả `200` với client count và trả `0` khi không có client.
- [X] T019 [P] [US2] Mở rộng `flex-microfrontend/src/app/core/services/agent-realtime.service.spec.ts` để kiểm tra event `demoNotification` truyền đúng payload qua observable và không xử lý event type không xác định.
- [X] T020 [US2] Mở rộng test của Agent create preview để spy `window.alert`, xác nhận alert đúng message và không alert khi payload thiếu message.

### Implementation for User Story 2

- [X] T021 [US2] Implement broadcaster contract trong `flex-agent-service/src/Flex.Agent.Api/Hubs/AgentRealtimeHub.cs` để phát `demoNotification` qua `IHubContext`/hub client và trả được số client đã gửi.
- [X] T022 [US2] Tạo `RealtimeDemoController` trong `flex-agent-service/src/Flex.Agent.Api/Controllers/RealtimeDemoController.cs` với `POST /api/v1/realtime-demo/notify`, `[Authorize]`, default message an toàn khi request rỗng, gọi broadcaster và trả `connectedClients` theo contract.
- [X] T023 [US2] Hoàn thiện subscription `demoNotification` và `notification$` trong `flex-microfrontend/src/app/core/services/agent-realtime.service.ts`, chạy trong Angular zone để UI cập nhật.
- [X] T024 [US2] Cập nhật `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.ts` để subscribe notification trong lifecycle, gọi `window.alert` đúng message, unsubscribe/stop connection khi destroy và giữ behavior reconnect của US1.
- [X] T025 [US2] Cập nhật `flex-agent-service/src/Flex.Agent.Api/Controllers/RealtimeDemoController.cs` và `AgentRealtimeHub.cs` với structured log `RealtimeDemoNotificationSent`, `connectedClients`, `occurredAt`; không log token/secret hoặc connection string.
- [ ] T026 [US2] Thực hiện manual validation AC-004/AC-005/AC-006 bằng Postman/curl theo `specs/000031-agent-realtime/quickstart.md`, gồm trường hợp FE connected và không có client.

**Definition of Done**:

- Endpoint authorized broadcast đúng event/payload và trả count chính xác ở hai trạng thái có/không có client.
- FE alert đúng nội dung, không crash khi payload lỗi hoặc mất kết nối.
- Test contract/integration/Angular và Independent Test US2 hoàn tất.

## Phase 5: Polish & Cross-Cutting Concerns

- [X] T027 [P] Chạy `dotnet build flex-agent-service/Flex.Agent.sln` và `dotnet test flex-agent-service/tests/Flex.Agent.Tests/Flex.Agent.Tests.csproj`, xử lý lỗi do feature và không hạ nullable/analyzer.
- [X] T028 [P] Chạy `npm test -- --watch=false --browsers=ChromeHeadless` và `npm run build` trong `flex-microfrontend`, xử lý lỗi TypeScript/template do feature.
- [X] T029 [P] Rà soát authorization/CORS và thêm test anonymous không được gọi hub/endpoint trong `flex-agent-service/tests/Flex.Agent.Tests/Realtime/RealtimeDemoPermissionTests.cs`.
- [X] T030 [P] Rà soát các log mới trong `flex-agent-service/src/Flex.Agent.Api/Hubs/AgentRealtimeHub.cs` và `RealtimeDemoController.cs`, xác nhận không có JWT, secret, API key, password hoặc connection string.
- [X] T031 Cập nhật `specs/000031-agent-realtime/quickstart.md` với URL local thực tế, auth prerequisite, command build/test đã xác minh và troubleshooting cho sai origin/CORS/hub path.
- [ ] T032 Chạy toàn bộ quickstart hai chiều trên browser local, lưu bằng chứng smoke test cho connected, reconnect, message log, alert và `connectedClients: 0`; chỉ đánh dấu feature hoàn tất khi US1/US2 đều pass.

## Dependencies & Execution Order

### Phase Dependencies

- Phase 1 không phụ thuộc phase khác.
- Phase 2 phụ thuộc Phase 1 và chặn mọi user story.
- Phase 3 (US1) phụ thuộc Phase 2; đây là MVP đầu tiên.
- Phase 4 (US2) phụ thuộc service/lifecycle chat từ T014–T016 của US1; phần backend T018/T021/T022 có thể chuẩn bị song song nhưng phải tích hợp sau foundation.
- Phase 5 phụ thuộc US1 và US2.

### User Story Dependencies

- **US1 (P1)**: độc lập sau Phase 2.
- **US2 (P1)**: phụ thuộc US1 vì dùng chung `AgentRealtimeService` và `ChatComponent` lifecycle; không chạy song song phần sửa cùng file.

### Parallel Opportunities

- T001–T004 có thể chạy song song vì khác repo/file.
- T007–T009 có thể chạy song song sau T005/T006 nếu không cần compile ngay.
- T010–T012 có thể viết song song vì khác test file/surface.
- T018–T020 có thể viết song song; T021/T022 có thể triển khai song song với T019/T020 nhưng không với task sửa cùng file.
- T027–T030 có thể chạy song song sau implementation; T031/T032 chạy sau khi build/test có kết quả.

## Traceability Matrix

| Source | Covered by tasks |
|---|---|
| US-001 | T010–T017 |
| AC-001 | T010, T013–T015, T017 |
| AC-002 | T010, T013, T017, T030 |
| AC-003 | T012, T014–T016 |
| US-002 | T018–T026 |
| AC-004 | T018, T021–T023, T026 |
| AC-005 | T019/T020, T023/T024, T026 |
| AC-006 | T018, T022, T026 |
| FR-001/BR-001 | T010, T012, T013, T015 |
| FR-002/FR-003 | T010, T013, T017 |
| FR-004 | T018, T021, T022 |
| FR-005 | T019, T020, T023, T024 |
| FR-006/NFR-001 | T011, T016, T019, T026 |
| SEC-001 | T005, T013, T022, T029 |
| SEC-002 | T013, T025, T030 |
| Rollback/observability | T025, T030–T032 |

## Validation Commands

- Backend build: `dotnet build flex-agent-service/Flex.Agent.sln`
- Backend tests: `dotnet test flex-agent-service/tests/Flex.Agent.Tests/Flex.Agent.Tests.csproj`
- Frontend tests: `npm test -- --watch=false --browsers=ChromeHeadless` tại `flex-microfrontend`
- Frontend build: `npm run build` tại `flex-microfrontend`
- API/SignalR smoke check: các bước trong [quickstart.md](./quickstart.md)
- Migration check: Không áp dụng; xác nhận không có file migration/schema mới.

## Implementation Strategy

### MVP First

1. Hoàn tất Phase 1–2.
2. Implement US1 và chạy Independent Test T017.
3. Dừng kiểm tra: phải thấy message FE → BE/log trước khi làm US2.
4. Implement US2 và chạy T026.

### Incremental Delivery

1. Foundation sẵn sàng.
2. US1 cung cấp message receive/log/ack.
3. US2 bổ sung backend trigger/FE alert.
4. Polish xác nhận build, test, permission, log và quickstart.

## Checklist chất lượng trước khi implement

- [x] Không còn task ví dụ hoặc placeholder trong output.
- [x] Không còn mã task mẫu, phase user story không tồn tại hoặc path generic.
- [x] Toàn bộ task được đánh số tuần tự từ T001 đến T032.
- [x] Mỗi task có path cụ thể hoặc command cụ thể.
- [x] Task sửa file có sẵn nêu rõ class/method/section hoặc endpoint.
- [x] Task phụ thuộc story/task khác đã được ghi rõ.
- [x] Mỗi user story có Independent Test và Definition of Done.
- [x] Contract, permission, observability, rollback/config và test risk đều có task.
- [x] Task `[P]` không sửa cùng file với task `[P]` khác trong cùng nhóm.
- [x] Không có database/migration task vì plan xác định Không áp dụng.
