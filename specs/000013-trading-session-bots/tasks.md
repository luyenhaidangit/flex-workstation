# Tasks: Phiên giao dịch, realtime và market-maker bot

**Đầu vào**: `spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/market-realtime.md`, `quickstart.md`

## Phase 1: Setup

**Mục đích**: Chuẩn bị dependency, configuration và cấu trúc file cho Exchange API và Angular client.

- [ ] T001 Thêm package `@microsoft/signalr` và script kiểm tra realtime trong `flex-microfrontend/package.json` (FR-004, FR-005)
- [ ] T002 [P] Tạo thư mục feature `TradingSession`, `MarketData`, `Hubs` và `HostedServices` trong `flex-exchange-service/src/Flex.Exchange.{Domain,Application,Api}` theo `plan.md`
- [ ] T003 [P] Thêm section cấu hình `TradingSession` và `Bot` với duration, symbol, reference price, spread, quantity và cycle interval trong `flex-exchange-service/src/Flex.Exchange.Api/appsettings.json`

## Phase 2: Foundational

**Mục đích**: Hoàn tất contract, state model và DI foundation dùng chung trước các user story.

- [ ] T004 [P] Viết unit test cho invariant `None → Open → Continuous → Close → None` trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/TradingSessionStateTests.cs` (BR-001, FR-001)
- [ ] T005 [P] Viết contract test kiểm tra các message `MARKET_SNAPSHOT`, `SESSION_STATE_CHANGED`, `ORDER_BOOK_CHANGED`, `TRADE_EXECUTED` trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/MarketRealtimeContractTests.cs` (FR-003–FR-005, FR-011)
- [ ] T006 Tạo `TradingSessionState`, transition result và close invariant trong `flex-exchange-service/src/Flex.Exchange.Domain/TradingSession/TradingSessionState.cs` (phụ thuộc T004)
- [ ] T007 Tạo application DTO `TradingSessionView`, `MarketEvent` và snapshot contract trong `flex-exchange-service/src/Flex.Exchange.Application/MarketData/MarketContracts.cs` (phụ thuộc T005)
- [ ] T008 Tạo `TradingSessionOptions` và `MarketMakerOptions` có validation duration/price/spread/quantity trong `flex-exchange-service/src/Flex.Exchange.Application/TradingSession/TradingSessionOptions.cs` (phụ thuộc T003)
- [ ] T009 Đăng ký options, session service, event publisher và SignalR trong `flex-exchange-service/src/Flex.Exchange.Api/Extensions/ServiceExtensions.cs` (phụ thuộc T006, T007, T008)

## Phase 3: User Story 1 — Khởi động và quan sát vòng đời phiên (P1, MVP)

**Mục tiêu**: Operator khởi động một ngày ảo; session chuyển đúng `open → continuous → close` và không tạo session thứ hai.

**Kiểm thử độc lập**:

1. Gọi `POST /api/trading-session/start` với config duration ngắn.
2. Gọi `GET /api/trading-session` và quan sát đủ ba state theo đúng thứ tự.
3. Gọi start lần hai khi state là `open` hoặc `continuous`, nhận `409`.

### Tests for User Story 1

- [ ] T010 [P] [US1] Viết integration test cho start/status, duplicate start và transition timing trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/TradingSessionApiTests.cs` (AC-001, FR-001, FR-009)
- [ ] T011 [P] [US1] Viết unit test cho duration transition và cancellation của worker trong `flex-exchange-service/tests/Flex.Exchange.Application.Tests/TradingSessionWorkerTests.cs` (AC-001)

### Implementation for User Story 1

- [ ] T012 [US1] Implement `TradingSessionService` với atomic start/status/transition trong `flex-exchange-service/src/Flex.Exchange.Application/TradingSession/TradingSessionService.cs` (phụ thuộc T006, T008, T010)
- [ ] T013 [US1] Thêm interface `ITradingSessionService` và mapping view trong `flex-exchange-service/src/Flex.Exchange.Application/TradingSession/ITradingSessionService.cs` (phụ thuộc T007, T012)
- [ ] T014 [US1] Implement `TradingSessionWorker` xử lý `open → continuous → close` theo host cancellation trong `flex-exchange-service/src/Flex.Exchange.Api/HostedServices/TradingSessionWorker.cs` (phụ thuộc T012, T011)
- [ ] T015 [US1] Thêm `TradingSessionController` cho `POST /api/trading-session/start` và `GET /api/trading-session` trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/TradingSessionController.cs` (phụ thuộc T013, T010)

## Phase 4: User Story 2 — Quan sát market realtime qua WebSocket (P1)

**Mục tiêu**: Hai tab `/exchange` nhận snapshot khi connect và incremental market events trong tối đa 3 giây, không reload.

**Kiểm thử độc lập**:

1. Mở hai tab `/exchange` và kết nối `/hubs/market`.
2. Xác nhận mỗi tab nhận `MARKET_SNAPSHOT` ngay khi kết nối.
3. Tạo order/trade hoặc để bot tạo quote; cả hai tab cập nhật board.

### Tests for User Story 2

- [ ] T016 [P] [US2] Viết integration test mở hai SignalR client, xác nhận snapshot và broadcast event sequence trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/MarketHubIntegrationTests.cs` (AC-002, AC-004, AC-005, FR-011)
- [ ] T017 [P] [US2] Viết Angular unit test cho reconnect, bỏ qua sequence cũ và cập nhật snapshot trong `flex-microfrontend/src/app/exchange/exchange-realtime.service.spec.ts` (FR-005, FR-011)

### Implementation for User Story 2

- [ ] T018 [US2] Implement `IMarketEventPublisher` và broadcast snapshot/incremental event qua `IHubContext<MarketHub>` trong `flex-exchange-service/src/Flex.Exchange.Api/Hubs/MarketEventPublisher.cs` (phụ thuộc T007, T016)
- [ ] T019 [US2] Implement read-only `MarketHub` gửi snapshot nguyên tử khi `OnConnectedAsync` trong `flex-exchange-service/src/Flex.Exchange.Api/Hubs/MarketHub.cs` (phụ thuộc T012, T018)
- [ ] T020 [US2] Map `/hubs/market`, cấu hình WebSocket transport và CORS trong `flex-exchange-service/src/Flex.Exchange.Api/Extensions/ApplicationExtensions.cs` (phụ thuộc T009, T019)
- [ ] T021 [US2] Implement Angular `ExchangeRealtimeService` dùng `HubConnection`, WebSocket transport, reconnect và `marketEvent` reducer trong `flex-microfrontend/src/app/exchange/exchange-realtime.service.ts` (phụ thuộc T001, T017)
- [ ] T022 [US2] Thay polling bằng realtime state, hiển thị session state và disconnected/reconnecting trong `flex-microfrontend/src/app/exchange/market-board.component.ts` và `flex-microfrontend/src/app/exchange/market-board.component.html` (phụ thuộc T021)

## Phase 5: User Story 3 — Market-maker bot và khớp lệnh (P1)

**Mục tiêu**: Bot duy trì bid/ask qua `DemoBroker`; người dùng đặt lệnh đối ứng và thấy trade realtime.

**Kiểm thử độc lập**:

1. Trong `continuous`, quan sát bid/ask của bot trên order book.
2. Đặt lệnh đối ứng tại giá bot.
3. Xác nhận `TradeExecuted`, trade tape và order book cập nhật.

### Tests for User Story 3

- [ ] T023 [P] [US3] Viết unit test cho fixed reference price, spread ticks, quantity và cycle trong `flex-exchange-service/tests/Flex.Exchange.Application.Tests/MarketMakerBotTests.cs` (BR-003, BR-006, FR-006)
- [ ] T024 [P] [US3] Viết integration test bot đặt lệnh qua BrokerId `DemoBroker` và khớp với user order trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/MarketMakerFlowTests.cs` (AC-006, AC-007, FR-007, FR-010)

### Implementation for User Story 3

- [ ] T025 [US3] Implement `IMarketMakerBot` tạo bid/ask command theo fixed reference price trong `flex-exchange-service/src/Flex.Exchange.Application/TradingSession/MarketMakerBot.cs` (phụ thuộc T008, T023)
- [ ] T026 [US3] Tích hợp bot cycle vào `TradingSessionWorker` và chỉ chạy khi state `continuous` trong `flex-exchange-service/src/Flex.Exchange.Api/HostedServices/TradingSessionWorker.cs` (phụ thuộc T014, T025)
- [ ] T027 [US3] Publish order book/trade event sau mutation trong `flex-exchange-service/src/Flex.Exchange.Application/Services/ExchangeService.cs` (phụ thuộc T018, T024)

## Phase 6: User Story 4 — Từ chối lệnh khi phiên đóng (P1)

**Mục tiêu**: `open` và `close` không nhận lệnh mới; close hủy bot trước rồi backstop-cancel toàn bộ lệnh còn lại.

**Kiểm thử độc lập**:

1. Gửi lệnh trong `open`, nhận reject reason phiên chưa giao dịch.
2. Chờ `close`, gửi lệnh mới, nhận reject reason phiên đã đóng.
3. Kiểm tra không còn remaining order và start ngày mới reset book/trades.

### Tests for User Story 4

- [ ] T028 [P] [US4] Viết unit/integration test reject order ngoài `continuous` và giữ nguyên order book trong `flex-exchange-service/tests/Flex.Exchange.Application.Tests/SessionOrderGateTests.cs` (AC-003, AC-008, AC-009, FR-002)
- [ ] T029 [P] [US4] Viết integration test graceful bot cancel, Exchange backstop cancel và restart session trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/SessionCloseCleanupTests.cs` (BR-005, FR-008, FR-009)

### Implementation for User Story 4

- [ ] T030 [US4] Thêm session-state gate vào `PlaceOrder` trong `flex-exchange-service/src/Flex.Exchange.Application/Services/ExchangeService.cs` và mapping reject reason phiên (phụ thuộc T012, T028)
- [ ] T031 [US4] Implement graceful bot cancel và backstop cancel remaining orders khi transition `close` trong `flex-exchange-service/src/Flex.Exchange.Application/TradingSession/TradingSessionService.cs` (phụ thuộc T025, T029)
- [ ] T032 [US4] Reset matching engine/order book/trade tape khi tạo session mới sau `close` trong `flex-exchange-service/src/Flex.Exchange.Application/Services/ExchangeService.cs` (phụ thuộc T031)

## Final Phase: Polish & Cross-Cutting Concerns

- [ ] T033 [P] Thêm structured logging cho session transition, bot cycle, broadcast, connection và correlation trong `flex-exchange-service/src/Flex.Exchange.Api/Observability` và `flex-exchange-service/src/Flex.Exchange.Application/TradingSession` (SEC-001, observability)
- [ ] T034 [P] Kiểm tra hub không có method đặt lệnh và không phát token/secret trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/MarketHubSecurityTests.cs` (BR-007, SEC-002, SEC-003)
- [ ] T035 Chạy backend build/test theo `specs/000013-trading-session-bots/quickstart.md` bằng `dotnet build flex-exchange-service/Flex.Exchange.sln --no-restore` và `dotnet test flex-exchange-service/Flex.Exchange.sln --no-build --no-restore`
- [ ] T036 Chạy frontend `npm test -- --watch=false`, `npx tsc --noEmit -p tsconfig.app.json` và `npx ng build --progress=false` trong `flex-microfrontend` (AC-004, AC-005)
- [ ] T037 Thực hiện manual smoke hai tab `/exchange`, reconnect, bot match, close reject và cập nhật bằng chứng vào `specs/000013-trading-session-bots/quickstart.md` (AC-001–AC-009)

## Dependencies & Execution Order

### Phase Dependencies

- Phase 1 không phụ thuộc phase khác.
- Phase 2 phụ thuộc Phase 1 và chặn mọi user story.
- US1 phụ thuộc Phase 2.
- US2 phụ thuộc T012/T013 của US1 để lấy session snapshot; T016/T017 có thể chuẩn bị trước implementation.
- US3 phụ thuộc T014 của US1 và publisher foundation; bot không được chạy trước `continuous`.
- US4 phụ thuộc US1 và US3 để đóng/cancel bot đúng luồng.
- Polish phụ thuộc các story implementation.

### Dependency Graph

```text
Setup → Foundation → US1 → US2
                    └──→ US3 → US4 → Polish
```

### Parallel Opportunities

- T002, T003 chạy song song.
- T004, T005 chạy song song; T010 và T011 chạy song song.
- T016 và T017 chạy song song.
- T023 và T024 chạy song song.
- T028 và T029 chạy song song.
- T033 và T034 có thể chạy song song sau khi các story hoàn tất.

## Implementation Strategy

1. Hoàn tất Foundation và US1 để có lifecycle chạy được — đây là MVP tối thiểu.
2. Thêm US2 để board nhận snapshot/realtime.
3. Thêm US3 để bot tạo thanh khoản và match.
4. Thêm US4 để bảo đảm reject/close cleanup.
5. Chạy polish, regression và manual smoke trước khi converge.

## Validation Commands

- Backend build: `dotnet build flex-exchange-service/Flex.Exchange.sln --no-restore`
- Backend tests: `dotnet test flex-exchange-service/Flex.Exchange.sln --no-build --no-restore`
- Frontend tests: `npm test -- --watch=false` trong `flex-microfrontend`
- Frontend type-check: `npx tsc --noEmit -p tsconfig.app.json` trong `flex-microfrontend`
- Frontend build: `npx ng build --progress=false` trong `flex-microfrontend`
- Manual smoke: các bước trong `specs/000013-trading-session-bots/quickstart.md`

## Traceability Matrix

| Source | Covered by tasks |
|---|---|
| US-001 / FR-001, FR-009 | T004, T010–T015 |
| US-002 / FR-003–FR-005, FR-011 | T005, T016–T022 |
| US-003 / FR-006, FR-007, FR-010 | T023–T027 |
| US-004 / FR-002, FR-008 | T028–T032 |
| BR-001 | T004, T006, T010, T011 |
| BR-003, BR-006 | T023, T025, T026 |
| BR-005 | T029, T031, T037 |
| BR-007 / SEC-002, SEC-003 | T020, T034 |
| AC-001–AC-009 | T010, T016, T024, T028, T029, T037 |

## Checklist chất lượng

- [x] Mỗi user story có phase và independent test criteria.
- [x] Mỗi task có checkbox, ID tuần tự, path/command cụ thể.
- [x] Task test được đặt trước implementation tương ứng.
- [x] Contract, data model, security, observability, rollback và manual smoke đã có task.
- [x] Không có placeholder hoặc task mơ hồ.
