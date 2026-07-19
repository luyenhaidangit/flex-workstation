# Kế hoạch triển khai: Một CTCK và kiểm tra trước giao dịch

**Branch**: `000015-single-broker-pretrade` | **Ngày**: 2026-07-19 | **Đặc tả**: [spec.md](spec.md)

**Đầu vào**: `specs/000015-single-broker-pretrade/spec.md`

## Tóm tắt

**Yêu cầu chính từ spec**: Đặt `DemoBroker` giữa khách hàng và Exchange; kiểm tra phiên, sức mua/CK khả dụng; phong tỏa tài sản trước khi route; liên kết lệnh khách hàng với `ExchangeOrderId`; cập nhật phong tỏa sau khớp/hủy.

**Hướng tiếp cận kỹ thuật**: Mở rộng `flex-exchange-service` theo Clean Architecture hiện có. `Flex.Exchange.Application` điều phối pre-trade và state demo in-memory; `Flex.Exchange.Domain` tiếp tục xử lý matching; `Flex.Exchange.Api` bổ sung Broker contract.

**Kết quả research**: Một broker, hai account seed deterministic, synchronous route qua `IExchangeService`, `clientOrderId` làm idempotency key, không database/migration/ledger/margin/settlement.

## Phạm vi kỹ thuật

**Trong phạm vi**:

- `flex-exchange-service`: Domain/Application/API/tests cho pre-trade một broker.
- Account demo gồm tiền/CK khả dụng và phần phong tỏa.
- Kiểm tra session, buying power, sellable quantity, reserve, route, release.
- HTTP contract cho đặt lệnh, tra cứu status/link và account summary.
- Audit link `ClientOrderId` ↔ `ExchangeOrderId`, structured logging và `.http` scenarios.

**Ngoài phạm vi kỹ thuật**:

- Database, persistence, migration/backfill hoặc recovery sau restart.
- Double-entry ledger, margin, clearing, settlement T+, custody, reconciliation.
- Multi-tenant/multi-broker, authentication/KYC, production account.
- Thay đổi matching rules, nhiều symbol hoặc loại lệnh nâng cao.

## Bối cảnh kỹ thuật

| Mục | Quyết định |
|---|---|
| Ngôn ngữ/Phiên bản | C# / .NET 9 (`net9.0`) |
| Service/App | `flex-exchange-service`, REST/Swagger/.http |
| Phụ thuộc | ASP.NET Core, `IExchangeService`, `ITradingSessionService`, request correlation, Serilog |
| Lưu trữ | In-memory; reset khi restart |
| Kiểm thử | xUnit, `WebApplicationFactory`, domain unit, API integration/contract, manual |
| Deploy/runtime | `Flex.Exchange.Api` local/dev process hoặc container hiện có |
| Mục tiêu | Kết quả pre-trade trong tối đa 3 giây ở tải demo |
| Ràng buộc | Một broker, hai account demo, một symbol; state mutation nhất quán |

## Kiểm tra constitution

| Gate | Ban đầu | Sau design | Ghi chú |
|---|---|---|---|
| Spec-before-code/traceability | Pass | Pass | US/FR P1 mapping tới module, contract, data, test |
| Workstation boundary | Pass | Pass | Implementation chỉ ở repo con; workstation chứa artifact |
| Clean Architecture/boundary | Pass | Pass | Broker ở Application, Domain không biết account |
| Security/no secret | Pass | Pass | Own-account check; không log secret |
| Testability/quality | Pass | Pass | Unit, integration, contract, manual |
| Simplicity/scope | Pass | Pass | Không thêm database/process |
| Observability/rollback | Pass | Pass | Correlation/audit; rollback code/config |

## Câu hỏi kỹ thuật đã resolve

- **TQ-001**: Account/reservation ở Application in-memory vì MVP và repo hiện có không persistence.
- **TQ-002**: Broker gọi `IExchangeService`, không gọi `MatchingEngine` trực tiếp.
- **TQ-003**: Lock bao quanh validate → reserve → tạo Broker state; chỉ route sau reserve.
- **TQ-004**: `clientOrderId` idempotency key; timeout là `PendingExchangeConfirmation`, không retry mù.
- **TQ-005**: Hai account seed deterministic qua `DemoBroker:Accounts`; không có account-provisioning API.
- **TQ-006**: Thêm `/api/broker/*`; giữ nguyên Exchange endpoints của MVP 1-4.

## Thiết kế tổng quan

**Luồng chính**:

1. `POST /api/broker/orders` nhận account, `clientOrderId`, symbol, side, price, quantity.
2. Application kiểm tra ownership, input và session; tính buying power/sellable quantity.
3. Reject kết thúc trước adapter; lệnh hợp lệ reserve tài sản rồi gọi `IExchangeService`.
4. Lưu mapping client ↔ exchange, reservation và audit; trả status.
5. Fill/cancel cập nhật filled/reserved/available; query trả status/link/history.

**Component/module**:

- `Flex.Exchange.Application/PreTrade`: `DemoBrokerService`, account state, reservation, idempotency.
- `Flex.Exchange.Application/Services/ExchangeService`: adapter tới Exchange flow hiện có.
- `Flex.Exchange.Api/Controllers/BrokerOrdersController.cs`: order/status/cancel boundary.
- `Flex.Exchange.Api/Controllers/DemoAccountsController.cs`: account summary boundary.
- `Flex.Exchange.Domain`: matching/order/session, không phụ thuộc account.
- `tests/Flex.Exchange.Domain.Tests`, `tests/Flex.Exchange.Api.Tests`: unit/integration/contract.

**Lỗi và concurrency**: Reject ngoài phiên/thiếu tài sản không gọi Exchange. Exchange reject release toàn bộ. Timeout giữ pending và không tạo duplicate. Một state lock bảo vệ check/reserve/mapping/release; không giữ lock khi I/O dài.

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Hướng xử lý | Module/Path | Contract/Data | Kiểm thử |
|---|---:|---|---|---|---|
| US-001 / FR-001 | P1 | Account ownership và nhận lệnh | `Application/PreTrade`, `BrokerOrdersController` | POST `/api/broker/orders`, `DemoAccount` | API/permission |
| US-001 / FR-002 | P1 | Kiểm tra `ITradingSessionService` | `DemoBrokerService` | `SessionClosed` | Unit/API |
| US-001 / FR-003 | P1 | Buying power trừ cash reserve | `BuyingPowerPolicy` | `CashBalance` | Unit/API |
| US-001 / FR-004 | P1 | Sellable quantity trừ security reserve | `SellableQuantityPolicy` | `SecurityBalance` | Unit/API |
| US-001 / FR-006 | P1 | Chỉ invoke Exchange sau pre-trade pass | `DemoBrokerService` | Không có Exchange order khi reject | Integration |
| US-002 / FR-005 | P1 | Atomic reserve trước route | `ReservationManager` | `Reservation` | Unit/concurrency |
| US-002 / FR-007 | P1 | Lưu và query client ↔ exchange link | `OrderLinkStore` | GET Broker order | API/contract |
| US-003 / FR-008 | P1 | Map fill về reservation/status | `ExchangeResultMapper` | `Fill`, `BrokerOrder` | Integration |
| US-003 / FR-009 | P1 | Release sau cancel/complete | `ReservationManager` | Account state | Unit/API |
| FR-010 | P2 | Stable reject codes/messages | API models | Broker response/audit | Contract/manual |

## Phân tích tác động

| Khu vực | Tác động | Tương thích/rủi ro | Kiểm tra |
|---|---|---|---|
| Database/Migration | Không đổi, in-memory | Restart mất state, đúng MVP | Smoke seed |
| API/Contract | Thêm `/api/broker/*`; Exchange API giữ nguyên | Consumer mới dùng Broker path | Contract/.http |
| Permission/Security | Own-account check | Không lộ account khác | Permission tests |
| Logging/Audit | Thêm reservation/link/reject fields | Không log secret hoặc balance thừa | Structured log |
| UI/UX | Không sửa frontend | UI tương lai phải dùng Broker | Manual API |
| Integration | Gọi session/exchange hiện có | Timeout/pending, không duplicate | Integration tests |

## API/Contract Detail

**Có thay đổi contract không**: Có, additive.

| Contract | Thay đổi | Compatibility |
|---|---|---|
| `POST /api/broker/orders` | Đặt lệnh qua Broker | Additive |
| `GET /api/broker/orders/{clientOrderId}` | Status, reservation, Exchange link, audit | Additive |
| `DELETE /api/broker/orders/{clientOrderId}` | Hủy và release qua Broker | Additive |
| `GET /api/broker/accounts/{accountId}` | Account available/reserved summary | Additive |
| Existing `/api/orders` | Không đổi, giữ cho MVP 1-4 | Backward compatible |

Payload và reject codes: [contracts/broker-pretrade.md](contracts/broker-pretrade.md).

## Permission Matrix

| Vai trò/scope | Xem account | Đặt lệnh | Hủy lệnh | Xem link |
|---|---:|---:|---:|---:|
| Demo customer / own account | Có | Có | Có | Có |
| Demo operator | Có | Không mặc định | Không mặc định | Có |
| Account khác/unknown | Không | Không | Không | Không |

## Dữ liệu & Migration

**Có thay đổi schema không**: Không. `DemoAccount`, `BrokerOrder`, `Reservation`, `OrderLink`, `BrokerAuditEntry` là Application in-memory state; không migration/backfill. Account seed deterministic sau restart. Invariant và validation nằm trong [data-model.md](data-model.md).

## Quyết định kỹ thuật

| ID | Lựa chọn | Lý do | Phương án loại |
|---|---|---|---|
| DEC-001 | Broker orchestration ở Application | Giữ Domain Exchange thuần | Account check trong `MatchingEngine` trộn boundary |
| DEC-002 | In-memory state | Đúng MVP, không migration | Database ledger vượt scope |
| DEC-003 | Reserve trước route | Bảo đảm pre-trade invariant | Route trước rồi compensate tạo exposure |
| DEC-004 | `clientOrderId` idempotency | Retry không tạo route trùng | Retry không key không an toàn |
| DEC-005 | Hai account seed qua config | Demo/test tái lập | API tạo account vượt scope |
| DEC-006 | `/api/broker/*` additive | Không phá Exchange API cũ | Đổi `/api/orders` gây regression |

## Chiến lược kiểm thử

- **Unit**: buying power, sellable quantity, session/ownership reject, reserve/release, partial/full fill, idempotency, không invoke Exchange khi reject.
- **Integration**: POST Broker → Exchange accepted → status/link; reject không xuất hiện trên book; fill/cancel cập nhật account; timeout không duplicate.
- **Contract**: Broker request/response, reject codes, `ExchangeOrderId`, account summary; regression Exchange contract.
- **Permission/security**: own-account only; không lộ order/balance; không log secret.
- **E2E/manual**: mua vượt tiền, bán vượt CK, lệnh hợp lệ route/khớp, hủy release bằng Swagger/.http.
- **Regression**: toàn bộ domain/API tests MVP 1-4, đặc biệt session, matching, event, realtime.

## Cấu trúc project

```text
specs/000015-single-broker-pretrade/{spec.md,plan.md,research.md,data-model.md,quickstart.md}
specs/000015-single-broker-pretrade/contracts/broker-pretrade.md
flex-exchange-service/src/Flex.Exchange.Application/PreTrade/
flex-exchange-service/src/Flex.Exchange.Api/Controllers/{BrokerOrdersController.cs,DemoAccountsController.cs}
flex-exchange-service/tests/Flex.Exchange.Domain.Tests/
flex-exchange-service/tests/Flex.Exchange.Api.Tests/{BrokerPreTradeApiTests.cs,BrokerPreTradeContractTests.cs,BrokerPreTradeSecurityTests.cs}
```

**Quyết định cấu trúc**: Thêm module `PreTrade` và controller mỏng; không thêm project/layer mới, không sửa frontend/repo khác.

## Rollout & Rollback

**Rollout**: Build/test repo, chạy seed demo và quickstart; expose trong Development. `DemoBroker:Enabled` bật ở Development, `DemoBroker:Accounts` chỉ chứa dữ liệu demo không nhạy cảm.

**Tương thích ngược**: Exchange endpoints và MVP 1-4 tests giữ nguyên.

**Rollback**: Tắt flag hoặc revert code; không có data rollback vì state in-memory.

**Kích hoạt rollback**: Pre-trade fail nhưng vẫn có Exchange order, reservation lệch, duplicate order, link sai hoặc regression MVP 1-4.

## Observability & Debug

**Log**: `correlationId`, `clientOrderId`, `accountId`, `brokerId`, symbol/side/quantity/price, preTradeResult/reason, reservationId, reserved values, `exchangeOrderId`, exchange result, release reason, idempotency outcome.

**Không log**: token, secret, credential và toàn bộ balance nếu không cần.

**Metric**: accept/reject theo reason, route failure, pending timeout, duplicate-idempotency hit, reservation mismatch, Broker latency.

**Trace**: request correlation xuyên API → Broker → Exchange; `clientOrderId` và `exchangeOrderId` là business keys.

**Smoke/debug**: health check, quickstart, reject không có Exchange order, status có link, `available + reserved` đúng. Debug tập trung route boundary, reservation transition, duplicate callback và adapter mapping.

## Theo dõi độ phức tạp

Không có vi phạm constitution. Module `PreTrade` là abstraction cần thiết cho boundary Broker; không thêm repository/database abstraction ngoài scope.

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase đã rõ.
- [x] Câu hỏi kỹ thuật đã resolve trong `research.md`.
- [x] Luồng, component, boundary, lỗi và concurrency đã mô tả.
- [x] Mọi US/FR P1/P2 có mapping path, contract, data và test.
- [x] Database, API, permission, audit, integration đã đánh giá.
- [x] Contract, migration, rollback, config và compatibility đã rõ.
- [x] Test strategy bao phủ unit/integration/contract/security/manual/regression.
- [x] Observability có log, metric, trace và smoke check.
- [x] Source paths là path thật trong `flex-exchange-service`.
- [x] Constitution gate không còn blocker.
