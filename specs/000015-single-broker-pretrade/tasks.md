# Tasks: Một CTCK và kiểm tra trước giao dịch

**Đầu vào**: Design documents từ `specs/000015-single-broker-pretrade/`

**Phạm vi triển khai**: `flex-exchange-service` — C#/.NET 9, in-memory demo, REST API.

**Tests**: Bắt buộc theo plan/constitution; test task phải được viết trước implementation tương ứng.

## Phase 1: Setup

**Mục đích**: Chuẩn bị project, config và baseline để triển khai module Broker mà không ảnh hưởng MVP 1-4.

- [ ] T001 Chạy baseline `dotnet test Flex.Exchange.sln --configuration Release` trong `flex-exchange-service/` và ghi nhận kết quả trước thay đổi.
- [ ] T002 [P] Thêm section `DemoBroker` với `Enabled` và hai account demo deterministic vào `flex-exchange-service/src/Flex.Exchange.Api/appsettings.Development.json`.
- [ ] T003 [P] Thêm nhóm request/response Broker demo vào `flex-exchange-service/src/Flex.Exchange.Api/Flex.Exchange.http` theo contract `specs/000015-single-broker-pretrade/contracts/broker-pretrade.md`.
- [ ] T004 [P] Tạo khung thư mục `flex-exchange-service/src/Flex.Exchange.Application/PreTrade/` và cập nhật project file nếu SDK-style không tự include file mới.

## Phase 2: Foundational

**Mục đích**: Tạo state model, contract và DI dùng chung; phải hoàn tất trước các user story.

- [ ] T005 [P] Tạo `DemoAccountState` với cash/security available-reserved invariants trong `flex-exchange-service/src/Flex.Exchange.Application/PreTrade/DemoAccountState.cs`.
- [ ] T006 [P] Tạo `BrokerOrderState`, status enum và reject reasons theo data model trong `flex-exchange-service/src/Flex.Exchange.Application/PreTrade/BrokerOrderState.cs`.
- [ ] T007 [P] Tạo `Reservation` và transition state trong `flex-exchange-service/src/Flex.Exchange.Application/PreTrade/Reservation.cs`.
- [ ] T008 [P] Tạo `OrderLink` và `BrokerAuditEntry` trong `flex-exchange-service/src/Flex.Exchange.Application/PreTrade/BrokerAuditEntry.cs`.
- [ ] T009 [P] Tạo request/response contracts cho broker order/account/status trong `flex-exchange-service/src/Flex.Exchange.Application/PreTrade/PreTradeContracts.cs`.
- [ ] T010 Tạo `IDemoBrokerService` và đăng ký lifetime/seed `DemoBroker:Accounts` trong `flex-exchange-service/src/Flex.Exchange.Application/PreTrade/IDemoBrokerService.cs` và `flex-exchange-service/src/Flex.Exchange.Application/DependencyInjection.cs` (phụ thuộc T005-T009).
- [ ] T011 Tạo state container có lock, lookup theo `AccountId`/`ClientOrderId` và audit sequence trong `flex-exchange-service/src/Flex.Exchange.Application/PreTrade/DemoBrokerState.cs` (phụ thuộc T005-T008).

## Phase 3: User Story 1 — Từ chối lệnh không đủ tài sản tại Broker (P1) — MVP

**Mục tiêu**: Broker kiểm tra ownership, session, buying power và sellable securities; mọi reject xảy ra trước Exchange và không đổi order book.

**Independent Test**:

1. Seed `demo-account-1`, gửi buy vượt tiền và sell vượt CK qua `POST /api/broker/orders`.
2. Xác nhận response có reject reason cụ thể, không có `exchangeOrderId`/reservation.
3. Đọc Exchange order book và account summary, xác nhận không thay đổi ngoài audit reject.

### Tests for User Story 1

- [ ] T012 [P] [US1] Viết unit tests cho buying power và security availability sau khi trừ reservation trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/BrokerPreTradePolicyTests.cs` (AC-001, AC-002, FR-003, FR-004).
- [ ] T013 [P] [US1] Viết API integration tests cho ownership, invalid account, ngoài session, thiếu tiền và thiếu CK trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/BrokerPreTradeRejectTests.cs` (FR-001-FR-004, SEC-001, SEC-002).
- [ ] T014 [P] [US1] Viết contract assertions cho reject response và reason codes trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Contract/BrokerPreTradeContractTests.cs` (FR-006, FR-010).

### Implementation for User Story 1

- [ ] T015 [P] [US1] Implement `BuyingPowerPolicy` trong `flex-exchange-service/src/Flex.Exchange.Application/PreTrade/BuyingPowerPolicy.cs` để tính `price × quantity` từ cash available sau reserve (FR-003).
- [ ] T016 [P] [US1] Implement `SellableQuantityPolicy` trong `flex-exchange-service/src/Flex.Exchange.Application/PreTrade/SellableQuantityPolicy.cs` để tính CK bán được sau reserve (FR-004).
- [ ] T017 [US1] Implement `DemoBrokerService.ValidatePreTrade` trong `flex-exchange-service/src/Flex.Exchange.Application/PreTrade/DemoBrokerService.cs` cho account ownership, input, session và reject trước adapter (phụ thuộc T010-T011, T015-T016; FR-001-FR-004, FR-006).
- [ ] T018 [US1] Implement `BrokerOrdersController` POST boundary trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/BrokerOrdersController.cs` với `POST /api/broker/orders`, HTTP semantics và correlation id (phụ thuộc T009-T017; FR-001, FR-002, FR-006, FR-010).
- [ ] T019 [US1] Implement read-only account summary trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/DemoAccountsController.cs` với `GET /api/broker/accounts/{accountId}` và không lộ account khác (phụ thuộc T010-T011; SEC-001, SEC-002).
- [ ] T020 [US1] Chạy T012-T014 và sửa implementation để toàn bộ reject path không gọi `IExchangeService.PlaceOrder`, không tạo reservation và không đổi order book (phụ thuộc T017-T019).

## Phase 4: User Story 2 — Route lệnh hợp lệ qua Broker (P1)

**Mục tiêu**: Lệnh hợp lệ được reserve trước, route một lần lên Exchange và truy vết được tới `ExchangeOrderId`.

**Dependencies**: Hoàn tất Phase 2 và US1; US2 dùng validation/state đã tạo ở US1.

**Independent Test**:

1. Với account đủ tài sản và session nhận lệnh, gửi Broker order hợp lệ.
2. Xác nhận reservation tồn tại trước route, Exchange nhận đúng một order và response có `exchangeOrderId`.
3. Query Broker order và kiểm tra audit link; gửi lại cùng `clientOrderId` để xác nhận idempotency.

### Tests for User Story 2

- [ ] T021 [P] [US2] Viết unit tests cho reserve atomic, cash/security reservation và idempotency cùng payload/conflict payload trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/BrokerReservationTests.cs` (AC-003, BR-003, FR-005).
- [ ] T022 [P] [US2] Viết API integration tests cho accepted route, `ClientOrderId` retry và idempotency conflict trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/BrokerOrderRoutingTests.cs` (AC-003, AC-004, FR-005, FR-007).
- [ ] T023 [P] [US2] Bổ sung contract test cho accepted response, `exchangeOrderId`, reservation summary và `GET /api/broker/orders/{clientOrderId}` trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Contract/BrokerPreTradeContractTests.cs` (FR-007, FR-010).

### Implementation for User Story 2

- [ ] T024 [US2] Implement `ReservationManager.Reserve` với state lock, cash/security mutation và audit `Reserved` trong `flex-exchange-service/src/Flex.Exchange.Application/PreTrade/ReservationManager.cs` (phụ thuộc T007, T011, T015-T016; FR-005, BR-003).
- [ ] T025 [US2] Implement `DemoBrokerService.PlaceOrder` để reserve trước rồi gọi `IExchangeService.PlaceOrder` với broker identity, lưu mapping và audit `Routed` (phụ thuộc T017, T024; FR-005, FR-007).
- [ ] T026 [US2] Implement idempotency lookup/conflict handling trong `flex-exchange-service/src/Flex.Exchange.Application/PreTrade/DemoBrokerService.cs` cho cùng `clientOrderId` và khác payload (phụ thuộc T011, T025; BR-001, FR-006).
- [ ] T027 [US2] Implement `GET /api/broker/orders/{clientOrderId}` trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/BrokerOrdersController.cs`, trả status/reservation/link/audit và chặn account ngoài scope (phụ thuộc T009-T011, T025-T026; FR-007, SEC-002).
- [ ] T028 [US2] Chạy T021-T023 và sửa flow để accepted order chỉ route một lần, có link `ClientOrderId` ↔ `ExchangeOrderId`, retry không tạo duplicate (phụ thuộc T024-T027).

## Phase 5: User Story 3 — Cập nhật phong tỏa sau khớp hoặc hủy (P1)

**Mục tiêu**: Fill/cancel từ Exchange cập nhật status và giải phóng đúng phần reservation.

**Dependencies**: Hoàn tất US2 vì US3 cần Broker order, reservation và Exchange link.

**Independent Test**:

1. Tạo order hợp lệ và reservation.
2. Chạy partial/full fill hoặc cancel qua Exchange/Broker.
3. Kiểm tra status, `cash/security available`, reserved values và audit; lặp lại callback không làm release hai lần.

### Tests for User Story 3

- [ ] T029 [P] [US3] Viết unit tests cho partial fill, full fill, Exchange reject và cancel với reservation transition trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/BrokerSettlementStateTests.cs` (AC-005, AC-006, FR-008, FR-009).
- [ ] T030 [P] [US3] Viết API integration tests cho fill/cancel mapping và idempotent duplicate result trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/BrokerOrderLifecycleTests.cs` (FR-008, FR-009, BR-004).
- [ ] T031 [P] [US3] Bổ sung manual `.http` scenarios cho khớp một phần/toàn bộ, hủy và đối chiếu account summary trong `flex-exchange-service/src/Flex.Exchange.Api/Flex.Exchange.http` (AC-005, AC-006, SC-004).

### Implementation for User Story 3

- [ ] T032 [US3] Implement `ReservationManager.ApplyFill` và `ReleaseRemaining` trong `flex-exchange-service/src/Flex.Exchange.Application/PreTrade/ReservationManager.cs`, cập nhật available/reserved và audit (phụ thuộc T024, T029; FR-008, FR-009).
- [ ] T033 [US3] Implement `ExchangeResultMapper` trong `flex-exchange-service/src/Flex.Exchange.Application/PreTrade/ExchangeResultMapper.cs` để map accepted/rejected/fill/cancel theo `ExchangeOrderId` và bỏ qua duplicate event (phụ thuộc T008, T011, T032; FR-008, BR-004).
- [ ] T034 [US3] Implement `DemoBrokerService.CancelOrder` và `DELETE /api/broker/orders/{clientOrderId}` trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/BrokerOrdersController.cs`, release phần còn lại và giữ idempotent cancel (phụ thuộc T027, T032-T033; FR-009, AC-006).
- [ ] T035 [US3] Chạy T029-T031 và sửa lifecycle để partial fill giữ phần chưa hoàn tất, full fill/cancel release đúng một lần (phụ thuộc T032-T034).

## Phase 6: Polish & Cross-Cutting Concerns

**Mục đích**: Hoàn tất logging, security, config, regression và validation end-to-end.

- [ ] T036 [P] Thêm structured logging cho pre-trade, reservation, route, link, release, timeout và idempotency trong `flex-exchange-service/src/Flex.Exchange.Application/PreTrade/DemoBrokerService.cs` (FR-010, NFR-002).
- [ ] T037 [P] Thêm `DemoBroker:Enabled` guard và safe failure response trong `flex-exchange-service/src/Flex.Exchange.Application/DependencyInjection.cs` và `flex-exchange-service/src/Flex.Exchange.Api/Controllers/BrokerOrdersController.cs` (rollout/rollback plan).
- [ ] T038 [P] Viết permission/security regression tests cho own-account và không lộ account/order khác trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/BrokerPreTradeSecurityTests.cs` (SEC-001, SEC-002).
- [ ] T039 [P] Cập nhật Swagger/OpenAPI metadata cho các endpoint `/api/broker/*` trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/BrokerOrdersController.cs` và `DemoAccountsController.cs` (contract discoverability).
- [ ] T040 Chạy toàn bộ regression `dotnet test Flex.Exchange.sln --configuration Release` trong `flex-exchange-service/` và xác nhận MVP 1-4 không bị phá (NFR-003).
- [ ] T041 Chạy toàn bộ quickstart trong `specs/000015-single-broker-pretrade/quickstart.md`, đối chiếu reject/no-Exchange-order, link và `available + reserved` (SC-001-SC-004).
- [ ] T042 Kiểm tra diff cuối cùng chỉ nằm trong scope plan, không có secret/token và không có thay đổi database/migration bằng `rtk git diff --check` và review paths.

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 Setup**: Không có dependency; T002-T004 có thể chạy song song, sau T001 baseline.
- **Phase 2 Foundational**: Phụ thuộc T001; T005-T009 có thể song song, T010-T011 phụ thuộc model/contracts.
- **Phase 3 US1**: Phụ thuộc Phase 2; T012-T014 viết test trước T015-T019; T020 là checkpoint.
- **Phase 4 US2**: Phụ thuộc US1; T021-T023 viết test trước T024-T027; T028 là checkpoint.
- **Phase 5 US3**: Phụ thuộc US2; T029-T031 viết test/manual trước T032-T034; T035 là checkpoint.
- **Phase 6 Polish**: Phụ thuộc US1-US3; T040-T042 là release gate.

### Dependency Graph

```text
T001 → T002/T003/T004 → T005-T011
T005-T011 → T012-T020 (US1)
T020 → T021-T028 (US2)
T028 → T029-T035 (US3)
T035 → T036-T042 (Polish)
```

### Parallel Opportunities

- Setup: T002, T003, T004 sau baseline.
- Foundation: T005-T009 vì mỗi task tạo artifact riêng.
- US1 tests: T012-T014; implementation policies T015-T016.
- US2 tests: T021-T023; T024 chỉ bắt đầu sau model/state foundation.
- US3 tests: T029-T031; T032-T033 cần tuần tự vì cùng reservation lifecycle.
- Polish: T036-T039 có thể song song nếu không cùng chỉnh một section/file; T040-T042 chạy sau tất cả.

## Implementation Strategy

1. Hoàn tất Foundation và deliver **US1** trước: reject không đủ tài sản là MVP tối thiểu có giá trị độc lập.
2. Deliver **US2** tiếp theo để có route hợp lệ và audit link.
3. Deliver **US3** để hoàn thiện lifecycle reservation.
4. Chạy Polish/regression/quickstart trước khi chuyển sang review hoặc implement tiếp theo.

## Validation Commands

- Build: `cd flex-exchange-service; dotnet build Flex.Exchange.sln --configuration Release`
- Tests: `cd flex-exchange-service; dotnet test Flex.Exchange.sln --configuration Release`
- Contract/manual: chạy nhóm Broker trong `src/Flex.Exchange.Api/Flex.Exchange.http` khi service chạy ở `http://localhost:5266`.
- Quickstart: thực hiện các bước trong `specs/000015-single-broker-pretrade/quickstart.md`.
- Data/migration: Không áp dụng; xác nhận không có migration và account state reset sau restart.

## Traceability Matrix

| Source | Covered by tasks |
|---|---|
| US-001 | T012-T020 |
| US-002 | T021-T028 |
| US-003 | T029-T035 |
| FR-001/FR-002 | T013, T017-T020 |
| FR-003/FR-004 | T012, T015-T020 |
| FR-005/FR-006 | T014, T021, T024-T028 |
| FR-007 | T022-T023, T025-T028 |
| FR-008/FR-009 | T029-T035 |
| FR-010 | T014, T018, T036 |
| BR-001/BR-003 | T017, T024-T028 |
| BR-004/BR-005 | T029-T035, T041 |
| SEC-001/SEC-002 | T013, T019, T027, T038 |
| NFR-001/NFR-002 | T036, T041 |
| NFR-003 | T040 |
| SC-001-SC-004 | T020, T028, T035, T041 |

## Chất lượng task

- [x] Mọi task có checkbox, ID tuần tự và file path/command cụ thể.
- [x] Mọi user story có phase, independent test và checkpoint riêng.
- [x] Test task được đặt trước implementation task trong từng story.
- [x] Contract, entity, permission, audit, idempotency, rollback và regression đều có task.
- [x] Không có task database/migration ngoài scope.
- [x] Không còn placeholder generic hoặc task ví dụ từ template.
