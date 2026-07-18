# Tasks: Exchange API và nhật ký sự kiện (FlexSim MVP 02)

**Đầu vào**: Artifact thiết kế trong `specs/000011-exchange-api-events/`
**Repo triển khai**: `flex-exchange-service/`
**Nền tảng**: MVP 01 (000010) đã hoàn thành — matching rules, 4 endpoint, domain/API tests, 8 nhóm kịch bản `.http` đã hoạt động đúng.
**Kiểm chứng**: Kịch bản `Flex.Exchange.http` nhóm 9-11 (mới) + 8 nhóm cũ vẫn pass (regression).
**Repository**: `flex-exchange-service/`
**Strategy**: hoàn thành nền tảng, sau đó triển khai từng user story P1 theo dependency; giữ tương thích MVP 01.

## Phase 1: Setup

**Mục đích**: xác nhận baseline và chuẩn bị cấu trúc test/contract cho thay đổi additive.

- [X] T001 Xác nhận baseline từ thư mục `flex-exchange-service/` bằng `dotnet test Flex.Exchange.sln --configuration Release` trước khi thay đổi source
- [X] T002 [P] Cập nhật fixture HTTP cho luồng MVP 02 trong `flex-exchange-service/src/Flex.Exchange.Api/Flex.Exchange.http`, gồm place/cancel/status/orderbook/trades/events và `X-Correlation-Id`
- [X] T003 [P] Bổ sung kiểm tra presence của các route MVP 02 vào `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Contract/ExchangeApiContractTests.cs`

## Phase 2: Foundational (Blocking Prerequisites)

**Mục đích**: xây dựng model/contract chung và bảo toàn ordering trước khi triển khai các story.

**Checkpoint**: T001–T009 phải hoàn tất trước mọi user-story task.

- [X] T004 [P] Mở rộng immutable event contract trong `flex-exchange-service/src/Flex.Exchange.Domain/Events/ExchangeEvent.cs` với `EventId`, `EventSequence`, logical `OccurredAt`, `BrokerId`, `CorrelationId`, `OrderId` và type payload theo `data-model.md`
- [X] T005 [P] Bổ sung metadata và payload bất biến cho `OrderAccepted`, `OrderRejected`, `TradeExecuted`, `OrderCancelled` trong `flex-exchange-service/src/Flex.Exchange.Domain/Events/`
- [X] T006 [P] Bổ sung immutable application DTOs `OrderStatusView`, `TradeTapeEntry`, `OrderEventHistory`, `OrderBookSnapshot` và event response fields trong `flex-exchange-service/src/Flex.Exchange.Application/Contracts/ExchangeContracts.cs`
- [X] T007 Cập nhật `flex-exchange-service/src/Flex.Exchange.Domain/Entities/Order.cs` và `OrderBook.cs` để lưu trạng thái cuối, broker ownership, remaining quantity và bản sao read-only cần cho lookup (phụ thuộc T004)
- [X] T008 Cập nhật `flex-exchange-service/src/Flex.Exchange.Domain/Matching/MatchingEngine.cs` để giữ event/order/trade sequence tăng dần, tạo logical timestamp deterministic và không expose mutable state (phụ thuộc T004, T005, T007)
- [X] T009 Cập nhật `flex-exchange-service/src/Flex.Exchange.Application/Services/IExchangeService.cs` và `ExchangeService.cs` để truyền correlation, serialize command/query bằng lock hiện có và map Domain → immutable DTO (phụ thuộc T006, T008)

## Phase 3: User Story 1 — Gửi lệnh và nhận kết quả nghiệp vụ (P1) MVP

**Goal**: Gateway đặt lệnh hợp lệ/không hợp lệ, nhận `OrderId` hoặc lý do, và thấy các trade sinh ra mà không phá quy tắc matching MVP 01.

**Independent Test**:

1. Gửi hai lệnh đối ứng qua `POST /api/orders` với `BrokerId` và correlation khác nhau.
2. Xác nhận response accepted có `OrderId`, trạng thái và trade; request sai có rejection reason.
3. Xác nhận rejection không làm đổi order book/trade tape và event có correlation metadata.

### Tests for User Story 1

- [X] T010 [P] [US1] Viết unit test cho accepted/rejected order, thiếu `BrokerId`, invalid order và rejection không side effect trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/MatchingEngineTests.cs`
- [X] T011 [P] [US1] Viết integration test cho `POST /api/orders` accepted/rejected, response `OrderId`/status/trades và `X-Correlation-Id` trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/OrdersApiTests.cs`
- [X] T012 [P] [US1] Viết JSON contract assertions cho response order/event và backward fields MVP 01 trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Contract/ExchangeApiContractTests.cs`

### Implementation for User Story 1

- [X] T013 [US1] Cập nhật validation và command result cho `BrokerId`, invalid order và rejection reason trong `flex-exchange-service/src/Flex.Exchange.Domain/Matching/MatchingEngine.cs` (phụ thuộc T010)
- [X] T014 [US1] Cập nhật mapping `PlaceOrder` và event/trade result trong `flex-exchange-service/src/Flex.Exchange.Application/Services/ExchangeService.cs` (phụ thuộc T009, T013)
- [X] T015 [US1] Cập nhật `POST /api/orders` binding, correlation extraction và status mapping trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/OrdersController.cs` theo `contracts/exchange-api.md` (phụ thuộc T014)
- [X] T016 [US1] Bổ sung structured logging cho place-order với `operation`, `result`, `reason`, `brokerId`, `orderId`, `eventSequence`, `correlationId` trong `flex-exchange-service/src/Flex.Exchange.Application/Services/ExchangeService.cs` (phụ thuộc T014)

**Definition of Done**:

- Unit, integration và contract tests của US1 pass.
- Accepted/rejected command không làm sai matching/order book.
- Event có đầy đủ metadata và log không chứa token/secret.

## Phase 4: User Story 2 — Hủy và tra cứu trạng thái lệnh (P1)

**Goal**: Gateway hủy đúng order của broker, bị từ chối an toàn khi không hợp lệ, và tra cứu được trạng thái theo `OrderId`.

**Independent Test**:

1. Đặt một lệnh còn chờ, hủy bằng đúng `OrderId` và `BrokerId`.
2. Tra cứu order xác nhận trạng thái `Cancelled` và order không còn trong snapshot.
3. Lặp lại cancel hoặc dùng broker khác xác nhận rejection, không có trade/state mutation.

### Tests for User Story 2

- [X] T017 [P] [US2] Viết unit test cho order lookup, cancel transition, cancel lặp lại, order completed/not-found và broker mismatch trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/MatchingEngineTests.cs`
- [X] T018 [P] [US2] Viết integration/contract test cho `DELETE /api/orders/{orderId}` và `GET /api/orders/{orderId}` gồm not-found/broker mismatch trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/OrdersApiTests.cs`

### Implementation for User Story 2

- [X] T019 [US2] Implement order status lookup, broker ownership check và cancel result bất biến trong `flex-exchange-service/src/Flex.Exchange.Domain/Matching/MatchingEngine.cs` (phụ thuộc T007, T017)
- [X] T020 [US2] Mở rộng `GetOrder` và contract trong `flex-exchange-service/src/Flex.Exchange.Application/Services/IExchangeService.cs`, đồng thời cập nhật `CancelOrder` mapping, reason và events trong `flex-exchange-service/src/Flex.Exchange.Application/Services/ExchangeService.cs` (phụ thuộc T009, T019)
- [X] T021 [US2] Cập nhật `DELETE /api/orders/{orderId}` và thêm `GET /api/orders/{orderId}` trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/OrdersController.cs` theo contract, trả not-found an toàn cho broker mismatch (phụ thuộc T020)
- [X] T022 [US2] Bổ sung structured cancel/status logging và correlation propagation trong `flex-exchange-service/src/Flex.Exchange.Application/Services/ExchangeService.cs` (phụ thuộc T021)

**Definition of Done**:

- Cancel đúng broker chuyển trạng thái và loại order khỏi order book.
- Cancel sai/lặp lại không đổi state và không tạo trade.
- Status query không lộ chi tiết order của broker khác.

## Phase 5: User Story 3 — Đối chiếu order book, trade tape và sự kiện (P1)

**Goal**: Operator/Gateway đọc được snapshot, trade tape và event history có thứ tự, metadata và khả năng replay deterministic.

**Independent Test**:

1. Gửi hai lệnh đối ứng và một lệnh chờ.
2. Gọi `GET /api/orderbook`, `GET /api/trades`, `GET /api/events` và `GET /api/orders/{id}/events`.
3. Xác nhận thứ tự sequence tăng dần, metadata đầy đủ, trade tham chiếu hai order và chạy lại cùng kịch bản cho projection giống nhau.

### Tests for User Story 3

- [X] T023 [P] [US3] Viết unit test cho trade tape ordering, snapshot chỉ chứa pending/partial order và event filtering theo order trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/MatchingEngineTests.cs`
- [X] T024 [P] [US3] Viết integration test cho orderbook/trades/global events/order events và correlation fallback trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/MvpAcceptanceTests.cs`
- [X] T025 [P] [US3] Viết deterministic replay regression test so sánh order state, orderbook, trade tape và event sequence qua hai lần chạy trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/DeterministicReplayTests.cs`
- [X] T026 [P] [US3] Viết security/negative test bảo đảm broker mismatch không lộ order detail và log/problem response không chứa token/secret trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/SecurityContractTests.cs`

### Implementation for User Story 3

- [X] T027 [US3] Bổ sung read methods cho trades, global events, per-order events và immutable orderbook snapshot trong `flex-exchange-service/src/Flex.Exchange.Domain/Matching/MatchingEngine.cs` (phụ thuộc T008, T023)
- [X] T028 [US3] Bổ sung `GetTrades`, `GetEvents`, `GetOrderEvents` và mapping read models trong `flex-exchange-service/src/Flex.Exchange.Application/Services/ExchangeService.cs` (phụ thuộc T006, T027)
- [X] T029 [P] [US3] Cập nhật `OrderBookController` để giữ `GET /api/orderbook` và trả snapshot immutable trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/OrderBookController.cs` (phụ thuộc T028)
- [X] T030 [P] [US3] Cập nhật `TradesController` để implement `GET /api/trades` theo ordered trade tape contract trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/TradesController.cs` (phụ thuộc T028)
- [X] T031 [P] [US3] Cập nhật `EventsController` để giữ `GET /api/events`, thêm `GET /api/orders/{orderId}/events` và trả event metadata additive trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/EventsController.cs` (phụ thuộc T028)
- [X] T032 [US3] Cập nhật request boundary/correlation fallback dùng `RequestContext` và `Activity.Current` trong `flex-exchange-service/src/Flex.Exchange.Api/RequestContext/`, không thêm custom correlation middleware (phụ thuộc T028, T031)

**Definition of Done**:

- Các query route trong contract tồn tại và trả DTO read-only đúng schema.
- Event/trade/order sequence và logical timestamp deterministic.
- Replay test, security test và integration test pass.

## Phase 6: Polish & Cross-Cutting Concerns

**Mục đích**: hoàn tất error contract, observability, quickstart và release gate.

- [X] T033 Cập nhật `flex-exchange-service/src/Flex.Exchange.Api/ExceptionHandling/GlobalExceptionHandler.cs` để mọi lỗi bất ngờ trả Problem Details an toàn kèm correlation id và không leak exception detail (phụ thuộc T032)
- [X] T034 [P] Rà soát `flex-exchange-service/src/Flex.Exchange.Application/Services/ExchangeService.cs` và `flex-exchange-service/src/Flex.Exchange.Api/RequestContext/` để log đủ event/order/trade/correlation fields nhưng không log token, authorization header, secret hoặc raw sensitive payload
- [X] T035 [P] Cập nhật `specs/000011-exchange-api-events/quickstart.md` và `flex-exchange-service/src/Flex.Exchange.Api/Flex.Exchange.http` với smoke flow, expected responses, restart replay check và rollback binary MVP 01
- [ ] T036 Chạy `dotnet format Flex.Exchange.sln --verify-no-changes`, `dotnet build Flex.Exchange.sln --configuration Release` và `dotnet test Flex.Exchange.sln --configuration Release`; sửa regression nếu có trong các source/test path liên quan
- [ ] T037 Chạy manual smoke theo `specs/000011-exchange-api-events/quickstart.md`, kiểm tra `/health`, latency luồng hai lệnh ≤ 5 giây, event metadata/correlation, xác nhận launch profile chỉ bind local/demo và không expose API ra public interface, đồng thời xác nhận không có database/migration mới
- [ ] T038 Cập nhật `specs/000011-exchange-api-events/plan.md` hoặc ghi chú release nếu phát hiện sai khác contract/rollout/rollback sau validation (phụ thuộc T036, T037)

**Validation note**: `dotnet build` và `dotnet test` đạt 33/33. `dotnet format --verify-no-changes` hiện vẫn báo lỗi whitespace/import/line-ending tồn tại từ baseline solution; chưa tự động format hàng loạt file không thuộc thay đổi MVP. Manual smoke cần chạy từ môi trường có thể giữ service process và gọi HTTP trực tiếp.

## Dependencies & Execution Order

### Phase dependencies

- Phase 1 không phụ thuộc phase khác.
- Phase 2 phụ thuộc Phase 1 và chặn toàn bộ user story.
- US1, US2, US3 đều phụ thuộc Phase 2; triển khai tuần tự theo thứ tự ưu tiên được khuyến nghị vì cùng mở rộng `MatchingEngine`, `ExchangeService` và controller tổng hợp.
- Phase 6 phụ thuộc các story đã chọn trong scope; T036–T038 là release gate.

### User story dependencies

- **US1 (P1)**: bắt đầu sau T009; là MVP tối thiểu.
- **US2 (P1)**: bắt đầu sau T009; nên tích hợp sau US1 vì dùng kết quả/order state của place flow.
- **US3 (P1)**: bắt đầu sau T009; nên tích hợp sau US1/US2 để query được accepted, cancelled và trade state đầy đủ.

### Parallel opportunities

- Sau T001, T002 và T003 có thể thực hiện song song.
- T004–T006 có thể thực hiện song song; T007–T009 phải theo dependency đã ghi.
- Trong mỗi story, các test khác file có thể chạy song song trước implementation.
- T029–T031 khác controller nên có thể thực hiện song song sau T028; không coi là song song với task sửa `ExchangeService`.
- T034 và T035 khác file có thể thực hiện song song sau implementation.

## Implementation Strategy

### MVP first

1. Hoàn tất Phase 1–2.
2. Hoàn tất US1 và chạy T010–T012 cùng independent test.
3. Dừng tại checkpoint để demo place/reject/two-order flow.

### Incremental delivery

1. Thêm US2 để hoàn thiện vòng đời order và broker ownership.
2. Thêm US3 để hoàn thiện snapshot, tape, event history và replay.
3. Chạy Phase 6 trước rollout local/demo.

## Validation Commands

- Restore: `dotnet restore flex-exchange-service/Flex.Exchange.sln`
- Build: `dotnet build flex-exchange-service/Flex.Exchange.sln --configuration Release`
- Tests: `dotnet test flex-exchange-service/Flex.Exchange.sln --configuration Release`
- Format: `dotnet format flex-exchange-service/Flex.Exchange.sln --verify-no-changes`
- Manual smoke: chạy service bằng `dotnet run --project src/Flex.Exchange.Api/Flex.Exchange.Api.csproj --launch-profile https` từ `flex-exchange-service/`, sau đó thực hiện `quickstart.md`/`.http`.
- Database/migration: Không áp dụng.

## Traceability Matrix

| Source | Covered by tasks |
|---|---|
| US-001 | T010–T016 |
| FR-001, FR-002 | T010–T015 |
| FR-003, FR-004 | T010–T014 |
| US-002 | T017–T022 |
| FR-005, FR-006, FR-007 | T017–T021 |
| US-003 | T023–T032 |
| FR-008 | T023, T027, T029 |
| FR-009 | T023–T025, T028, T030 |
| FR-010 | T004–T006, T023–T025, T028, T031 |
| FR-011 / NFR-002 | T008, T025, T036–T037 |
| BR-001–BR-005 | T010, T013, T017, T019, T027 |
| SEC-001–SEC-003 | T016, T018, T026, T032–T034, T037 |
| NFR-001 | T011, T024, T036–T037 |
| NFR-003 | T033–T034, T026 |
| SC-001 | T011, T024, T037 |
| SC-002 | T010, T013, T024 |
| SC-003 | T024, T031, T037 |
| SC-004 | T025, T037 |
| API contracts | T003, T012, T018, T024, T029–T031 |
| Rollout/rollback | T035–T038 |

## Suggested MVP scope

MVP triển khai tối thiểu là **Phase 1 + Phase 2 + User Story 1**. User Story 2 và 3 là các increment P1 tiếp theo để hoàn thiện vòng đời order và khả năng đối chiếu/replay.

## Quality checklist

- [x] Mọi task có checkbox, ID tuần tự, story label đúng phase và file path/command cụ thể.
- [x] Mỗi user story có independent test và Definition of Done.
- [x] Test task được sinh vì spec/plan yêu cầu unit, integration, contract, security và regression test.
- [x] Không còn placeholder trong task description; mọi task dùng tên domain/path thật.
- [x] Mỗi endpoint trong `contracts/exchange-api.md` có task implementation/contract test.
- [x] Không có database/migration; không tạo task migration ngoài scope.
- [x] Correlation, observability, error safety, rollout và rollback đều có task.
- [x] Task `[P]` chỉ dùng cho file khác nhau và không phụ thuộc task chưa hoàn tất.
