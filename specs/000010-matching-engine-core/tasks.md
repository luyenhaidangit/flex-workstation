# Tasks: Lõi khớp lệnh và order book (FlexSim MVP 01)

**Đầu vào**: Artifact thiết kế trong `specs/000010-matching-engine-core/`  
**Repo triển khai**: `flex-exchange-service/`  
**Kiểm chứng**: Không tạo test tự động theo ngoại lệ EX-001 đã phê duyệt; dùng `Flex.Exchange.http` và Swagger theo `quickstart.md`.

## Phase 1: Setup

**Mục đích**: Tạo solution .NET 9 và các file nền theo cấu trúc đã chốt.

- [ ] T001 Tạo solution ba project và project references trong `flex-exchange-service/Flex.Exchange.sln`
- [ ] T002 [P] Tạo project domain thuần BCL `net9.0` trong `flex-exchange-service/src/Flex.Domain/Flex.Domain.csproj`
- [ ] T003 [P] Tạo project hạ tầng với package Serilog và Swashbuckle cần thiết trong `flex-exchange-service/src/Flex.Infrastructures/Flex.Infrastructures.csproj`
- [ ] T004 Tạo project Web API tham chiếu `Flex.Domain` và `Flex.Infrastructures` trong `flex-exchange-service/src/Flex.Exchange/Flex.Exchange.csproj`
- [ ] T005 [P] Tạo file nền, ignore .NET và context agent trong `flex-exchange-service/{README.md,CLAUDE.md,.gitignore,.gitattributes,.env.example}`
- [ ] T006 Tạo cấu hình chạy cục bộ HTTP/HTTPS, chỉ phục vụ demo local, trong `flex-exchange-service/src/Flex.Exchange/Properties/launchSettings.json`

---

## Phase 2: Foundational

**Mục đích**: Hoàn thành model, hợp đồng in-process, hạ tầng và host chung chặn mọi user story.

**Checkpoint**: Solution build được; domain không tham chiếu runtime package; Web API có DI, logging, lỗi chuẩn hóa và Swagger Development.

- [ ] T007 [P] Tạo enum `OrderSide`, `OrderStatus` và `RejectReason` theo data model trong `flex-exchange-service/src/Flex.Domain/Enums/{OrderSide.cs,OrderStatus.cs,RejectReason.cs}`
- [ ] T008 [P] Tạo command `PlaceOrder` và `CancelOrder` mang `BrokerId` trong `flex-exchange-service/src/Flex.Domain/Commands/{PlaceOrder.cs,CancelOrder.cs}`
- [ ] T009 [P] Tạo entity cấu hình và lệnh với giá/khối lượng `long`, `SequenceNumber` và chuyển trạng thái trong `flex-exchange-service/src/Flex.Domain/Entities/{InstrumentConfig.cs,Order.cs}`
- [ ] T010 [P] Tạo entity `Trade`, `OrderBookSnapshot` và các giá-level snapshot trong `flex-exchange-service/src/Flex.Domain/Entities/{Trade.cs,OrderBookSnapshot.cs}`
- [ ] T011 [P] Tạo base event và bốn event contract có `EventSequence`/`BrokerId` trong `flex-exchange-service/src/Flex.Domain/Events/{ExchangeEvent.cs,OrderAccepted.cs,OrderRejected.cs,TradeExecuted.cs,OrderCancelled.cs}`
- [ ] T012 Tạo result type cho place/cancel command theo contract trong `flex-exchange-service/src/Flex.Domain/Matching/{PlaceOrderResult.cs,CancelOrderResult.cs}`
- [ ] T013 Tạo cấu trúc order book hai phía với API thêm/gỡ/duyệt theo giá và FIFO xác định trong `flex-exchange-service/src/Flex.Domain/Entities/OrderBook.cs`
- [ ] T014 [P] Tạo API response wrapper chuẩn trong `flex-exchange-service/src/Flex.Infrastructures/Responses/ApiResponse.cs`
- [ ] T015 [P] Tạo global exception handler và `ValidationException` trong `flex-exchange-service/src/Flex.Infrastructures/Exceptions/{GlobalExceptionHandler.cs,ValidationException.cs}`
- [ ] T016 [P] Tạo cấu hình Serilog, correlation ID và request/response logging middleware trong `flex-exchange-service/src/Flex.Infrastructures/{Logging/SeriLogger.cs,Observability/CorrelationIdMiddleware.cs,Observability/GlobalLoggingMiddleware.cs,Observability/LogFields.cs}`
- [ ] T017 [P] Tạo cấu hình Swagger và JSON dùng chung trong `flex-exchange-service/src/Flex.Infrastructures/{OpenApi/SwaggerConfiguration.cs,Json/JsonOptions.cs,AssemblyReference.cs}`
- [ ] T018 Tạo `ExchangeOptions`, bind `Exchange:Instrument` và chuyển sang `InstrumentConfig` trong `flex-exchange-service/src/Flex.Exchange/Models/ExchangeOptions.cs`
- [ ] T019 Tạo cấu hình FXS (20.000, tick 100, trần 21.400, sàn 18.600, lô 100) và Serilog trong `flex-exchange-service/src/Flex.Exchange/{appsettings.json,appsettings.Development.json}`
- [ ] T020 Tạo bootstrap host, đăng ký middleware/Swagger và DI options theo pattern service Flex trong `flex-exchange-service/src/Flex.Exchange/{Program.cs,Extensions/HostExtensions.cs,Extensions/ServiceExtensions.cs,Extensions/ApplicationExtensions.cs}`

---

## Phase 3: User Story 1 — Khớp toàn phần hai lệnh đối ứng (Priority: P1) MVP

**Goal**: Nhận hai limit order đối ứng, phát event theo contract và trả snapshot rỗng sau khi khớp hết.

**Independent Test**:

1. Qua Swagger hoặc `Flex.Exchange.http`, gửi bán 100 FXS @20.000 rồi mua 100 FXS @20.000.
2. Xác nhận response thứ hai có đúng một `TradeExecuted` 100 @20.000, và `GET /api/orderbook` trả hai phía rỗng.
3. Xác nhận `GET /api/events` có event sequence tăng dần, gồm hai `OrderAccepted` và một `TradeExecuted`.

- [ ] T021 [US1] Implement `MatchingEngine.PlaceOrder`, cấp ID/sequence, phát `OrderAccepted` và khớp toàn phần tại giá lệnh chờ trong `flex-exchange-service/src/Flex.Domain/Matching/MatchingEngine.cs` (phụ thuộc T007–T013)
- [ ] T022 [US1] Bổ sung snapshot read-only rỗng/đầy đủ cùng event log append-only trong `flex-exchange-service/src/Flex.Domain/Matching/MatchingEngine.cs` (phụ thuộc T021)
- [ ] T023 [P] [US1] Tạo DTO request/response đặt lệnh map đúng contract trong `flex-exchange-service/src/Flex.Exchange/Models/{PlaceOrderRequest.cs,PlaceOrderResponse.cs}`
- [ ] T024 [US1] Tạo `IExchangeService` và `ExchangeService` singleton bọc engine, serialize place/read bằng lock và ghi log nghiệp vụ trong `flex-exchange-service/src/Flex.Exchange/Services/{Interfaces/IExchangeService.cs,ExchangeService.cs}` (phụ thuộc T018, T021, T022)
- [ ] T025 [US1] Implement `POST /api/orders` với business reject HTTP 200 qua response wrapper trong `flex-exchange-service/src/Flex.Exchange/Controllers/OrdersController.cs` (phụ thuộc T023, T024)
- [ ] T026 [US1] Implement `GET /api/orderbook` và `GET /api/events` theo REST contract trong `flex-exchange-service/src/Flex.Exchange/Controllers/{OrderBookController.cs,EventsController.cs}` (phụ thuộc T024)
- [ ] T027 [US1] Thêm kịch bản không khớp, khớp toàn phần và truy vấn snapshot/event vào `flex-exchange-service/src/Flex.Exchange/Flex.Exchange.http` (phụ thuộc T025, T026)

**Definition of Done**: AC-001/AC-002 đạt bằng `.http`; controller không chứa quy tắc khớp; event log và snapshot khớp contract.

---

## Phase 4: User Story 2 — Khớp một phần và phần còn lại nằm trong sổ (Priority: P1)

**Goal**: Khớp đến hết khả năng, giữ phần dư theo trạng thái và tổng hợp snapshot đúng.

**Independent Test**:

1. Từ service mới khởi động, gửi bán 100 FXS @20.000 rồi mua 200 FXS @20.000.
2. Xác nhận một giao dịch 100 @20.000, lệnh mua `PartiallyFilled` còn 100 và snapshot chỉ còn bid 20.000/100.

- [ ] T028 [US2] Mở rộng vòng lặp matching để giảm `RemainingQuantity`, cập nhật `PartiallyFilled`/`Filled` và đưa phần dư hợp lệ vào sổ trong `flex-exchange-service/src/Flex.Domain/Matching/MatchingEngine.cs` (phụ thuộc T021)
- [ ] T029 [US2] Hoàn thiện tổng hợp price level và danh sách lệnh FIFO trong snapshot trong `flex-exchange-service/src/Flex.Domain/Entities/OrderBook.cs` (phụ thuộc T013, T028)
- [ ] T030 [US2] Thêm kịch bản khớp một phần và kiểm tra `GET /api/orderbook` vào `flex-exchange-service/src/Flex.Exchange/Flex.Exchange.http` (phụ thuộc T028, T029)

**Definition of Done**: AC-003/AC-004 đạt; order đã filled rời sổ, phần dư dương duy nhất nằm sổ.

---

## Phase 5: User Story 3 — Ưu tiên giá và ưu tiên thời gian (Priority: P1)

**Goal**: Luôn khớp best price trước và FIFO trong cùng price level, không dùng timestamp/hash order cho priority.

**Independent Test**:

1. Dựng ask 19.900 và 20.000, rồi mua 20.000; xác nhận trade dùng ask 19.900.
2. Dựng hai ask 20.000 tuần tự, rồi mua 100; xác nhận `SellOrderId` của lệnh đến trước xuất hiện trong trade.

- [ ] T031 [US3] Sắp xếp bid giảm/ask tăng và FIFO bằng `SequenceNumber`, bảo đảm không dùng `ReceivedAt` trong priority tại `flex-exchange-service/src/Flex.Domain/Entities/OrderBook.cs` (phụ thuộc T029)
- [ ] T032 [US3] Bảo đảm `MatchingEngine` luôn chọn lệnh đối ứng tốt nhất, giá trade từ passive order và `ExecutedSequence` xác định trong `flex-exchange-service/src/Flex.Domain/Matching/MatchingEngine.cs` (phụ thuộc T028, T031)
- [ ] T033 [US3] Thêm kịch bản ưu tiên giá, FIFO và khớp xuyên nhiều mức vào `flex-exchange-service/src/Flex.Exchange/Flex.Exchange.http` (phụ thuộc T032)

**Definition of Done**: AC-005/AC-006 đạt; thứ tự event/trade tái lập với cùng chuỗi input.

---

## Phase 6: User Story 4 — Hủy lệnh đang chờ (Priority: P1)

**Goal**: Hủy phần còn dư, phát `OrderCancelled`, và từ chối cancel lệnh không còn trong sổ mà không đổi trạng thái.

**Independent Test**:

1. Đặt lệnh chờ, gọi `DELETE /api/orders/{orderId}?brokerId=DemoBroker`, rồi đặt đối ứng; xác nhận không có trade và lệnh đã biến mất khỏi snapshot.
2. Cancel lại hoặc cancel ID đã filled; xác nhận HTTP 200 business reject `OrderNotFound`, event list rỗng, book không đổi.
3. Cancel với `brokerId` rỗng; xác nhận HTTP 200 business reject `MissingBrokerId`, event list rỗng, book không đổi.

- [ ] T034 [US4] Implement `MatchingEngine.CancelOrder` để từ chối `BrokerId` rỗng bằng `MissingBrokerId`, hoặc gỡ lệnh còn dư/cập nhật `Cancelled`/phát `OrderCancelled`, hoặc trả `OrderNotFound` trong `flex-exchange-service/src/Flex.Domain/Matching/MatchingEngine.cs` (phụ thuộc T028)
- [ ] T035 [P] [US4] Tạo `CancelOrderResponse` theo contract trong `flex-exchange-service/src/Flex.Exchange/Models/CancelOrderResponse.cs`
- [ ] T036 [US4] Mở rộng `IExchangeService`/`ExchangeService` với cancel được serialize bằng cùng lock và log kết quả trong `flex-exchange-service/src/Flex.Exchange/Services/{Interfaces/IExchangeService.cs,ExchangeService.cs}` (phụ thuộc T034)
- [ ] T037 [US4] Implement `DELETE /api/orders/{orderId}` nhận `brokerId` query string và trả business reject HTTP 200 trong `flex-exchange-service/src/Flex.Exchange/Controllers/OrdersController.cs` (phụ thuộc T035, T036)
- [ ] T038 [US4] Thêm kịch bản hủy thành công, hủy lặp, hủy sau filled và `brokerId` rỗng vào `flex-exchange-service/src/Flex.Exchange/Flex.Exchange.http` (phụ thuộc T037)

**Definition of Done**: AC-007/AC-008 đạt; lệnh cancelled/filled không thể khớp lại.

---

## Phase 7: User Story 5 — Từ chối lệnh không hợp lệ (Priority: P2)

**Goal**: Chặn mọi lệnh sai trước khi engine cấp `OrderId`, mutate sổ hoặc tạo trade.

**Independent Test**:

1. Gửi lần lượt lệnh sai symbol, broker rỗng, giá/khối lượng không dương, sai tick, ngoài band và sai lot.
2. Mỗi response trả `accepted: false`, đúng `RejectReason`, chỉ có `OrderRejected` và `GET /api/orderbook` không thay đổi.

- [ ] T039 [US5] Implement `OrderValidator` kiểm tra BrokerId, symbol, price, tick, band, quantity và lot theo `InstrumentConfig` trong `flex-exchange-service/src/Flex.Domain/Matching/OrderValidator.cs` (phụ thuộc T007–T009)
- [ ] T040 [US5] Gọi validator trước cấp order sequence/mutate sổ, phát `OrderRejected` không có `OrderId` và trả reason trong `flex-exchange-service/src/Flex.Domain/Matching/MatchingEngine.cs` (phụ thuộc T039)
- [ ] T041 [US5] Thêm kịch bản validate từng `RejectReason` và xác nhận snapshot bất biến vào `flex-exchange-service/src/Flex.Exchange/Flex.Exchange.http` (phụ thuộc T040)

**Definition of Done**: AC-009 đạt; mọi lệnh reject không có side effect ngoài `OrderRejected` append vào event log.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Mục đích**: Hoàn tất tính xác định, an toàn demo local, observability và tài liệu vận hành.

- [ ] T042 Kiểm tra và loại mọi dependency ASP.NET/package runtime khỏi domain project trong `flex-exchange-service/src/Flex.Domain/Flex.Domain.csproj`
- [ ] T043 Kiểm tra `ExchangeService` serialize toàn bộ place/cancel/snapshot/event read bằng một lock, không để trạng thái nửa command, trong `flex-exchange-service/src/Flex.Exchange/Services/ExchangeService.cs`
- [ ] T044 Kiểm tra engine không dùng clock/random/hash iteration cho ID, event sequence hoặc priority trong `flex-exchange-service/src/Flex.Domain/Matching/{MatchingEngine.cs,OrderValidator.cs}`
- [ ] T045 Kiểm tra launch profile chỉ dùng cho local demo và không thêm auth/secret vào config trong `flex-exchange-service/src/Flex.Exchange/{Properties/launchSettings.json,appsettings.json,appsettings.Development.json}`
- [ ] T046 Cập nhật README với restore/build/run, Swagger và quy trình demo `.http` trong `flex-exchange-service/README.md`
- [ ] T047 Hoàn thiện tám nhóm kịch bản manual và hướng dẫn so sánh determinism sau restart trong `flex-exchange-service/src/Flex.Exchange/Flex.Exchange.http`
- [ ] T048 Chạy `dotnet restore Flex.Exchange.sln`, `dotnet build Flex.Exchange.sln` và toàn bộ kịch bản trong `specs/000010-matching-engine-core/quickstart.md`; ghi nhận thời gian chạy demo theo NFR-002 và review commands, bốn events, snapshot trong `specs/000010-matching-engine-core/contracts/exchange-core.md` đối chiếu implementation/Swagger cho MVP 02

---

## Traceability Matrix

| Source | Covered by tasks |
|---|---|
| US-001 / AC-001 / AC-002 | T021–T027 |
| US-002 / AC-003 / AC-004 | T028–T030 |
| US-003 / AC-005 / AC-006 | T031–T033 |
| US-004 / AC-007 / AC-008 | T034–T038 |
| US-005 / AC-009 / FR-001 | T039–T041 |
| FR-002, FR-003, FR-005 | T021, T031, T032, T033 |
| FR-004 | T028–T030 |
| FR-006 / SEC-001 (CancelOrder) | T034, T036–T038 |
| FR-007, FR-008 | T011, T021–T022, T026, T029 |
| FR-009 / NFR-001 | T024, T031–T032, T043–T044, T047 |
| FR-010 | T002, T004, T042 |
| FR-011 | T023–T027, T035–T038 |
| SEC-001, SEC-002 | T008, T011, T039, T045 |
| NFR-003 | T009, T018–T019, T039 |
| NFR-002 / SC-001…SC-004 | T027, T030, T033, T038, T041, T047–T048 |

## Dependencies & Execution Order

- Phase 1 → Phase 2 → US-001 là đường MVP tối thiểu.
- US-002 phụ thuộc US-001; US-003 phụ thuộc cơ chế sổ/partial fill của US-002; US-004 phụ thuộc lệnh đang chờ của US-002; US-005 có thể làm sau Foundation nhưng được xếp P2 theo spec.
- Polish chỉ bắt đầu sau khi toàn bộ story hoàn thành.

## Parallel Opportunities

- Trong Setup: T002, T003 và T005 sau khi thống nhất solution name.
- Trong Foundational: T007–T011 và T014–T017 có thể chia theo file; T018–T020 cần làm tuần tự theo config/host.
- Trong US-001: T023 có thể làm song song với T021–T022; trong US-004: T035 có thể làm song song T034.

## Implementation Strategy

1. Hoàn tất Setup và Foundational, build solution rỗng có host/Swagger.
2. Hoàn tất US-001 rồi chạy kịch bản full match để xác nhận MVP end-to-end.
3. Bổ sung lần lượt partial fill, priority, cancellation và validation; sau mỗi phase chạy independent test của phase đó.
4. Kết thúc bằng tám nhóm `.http`, restart determinism và build theo `quickstart.md`.

## Validation Commands

```powershell
cd flex-exchange-service
dotnet restore Flex.Exchange.sln
dotnet build Flex.Exchange.sln
dotnet run --project src/Flex.Exchange/Flex.Exchange.csproj
```

Mở `src/Flex.Exchange/Flex.Exchange.http`, đặt `@baseUrl` theo URL Kestrel, chạy tám nhóm kịch bản. Không áp dụng lệnh chạy test tự động (EX-001).
