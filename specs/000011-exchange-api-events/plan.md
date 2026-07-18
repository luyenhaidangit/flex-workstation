# Kế hoạch triển khai: Exchange API và nhật ký sự kiện

**Branch**: `000011-exchange-api-events` | **Ngày**: 2026-07-18 | **Đặc tả**: [spec.md](spec.md)

**Đầu vào**: Đặc tả tính năng từ `specs/000011-exchange-api-events/spec.md`

## Tóm tắt

**Yêu cầu chính từ spec**: Mở rộng matching engine MVP 01 thành contract dịch vụ có thể đặt/hủy lệnh, tra cứu trạng thái theo `OrderId`, order book, trade tape và lịch sử event theo order; bổ sung event metadata (`EventId`, logical `OccurredAt`, `CorrelationId`) mà không làm thay đổi quy tắc matching hoặc route hiện có.

**Hướng tiếp cận kỹ thuật dự kiến**: Giữ `Domain → Application → Api`, mở rộng engine bằng immutable state/read methods, đặt mapping và HTTP contract ở Application/Api, serialize command/read bằng lock hiện có, không thêm database. Các event sequence và logical timestamp là canonical deterministic values; request correlation được truyền từ boundary khi có.

**Kết quả sau research**: Đã chốt in-memory read models, additive HTTP compatibility, deterministic event metadata, không custom correlation middleware, không idempotency cho retry `PlaceOrder` trong MVP.

## Phạm vi kỹ thuật

**Trong phạm vi**:

- `flex-exchange-service/src/Flex.Exchange.Domain`: event metadata, trạng thái/lookup order, trade collection và event correlation.
- `flex-exchange-service/src/Flex.Exchange.Application`: immutable contracts, command/query methods và mapping Domain → contract.
- `flex-exchange-service/src/Flex.Exchange.Api`: endpoints tra cứu order/trades/events, request correlation và Problem Details contract.
- `flex-exchange-service/tests`: domain unit, API integration, JSON contract và deterministic replay tests.
- `specs/000011-exchange-api-events/contracts`, quickstart và manual smoke flow.

**Ngoài phạm vi kỹ thuật**:

- Database/event store, migration, backfill hoặc durable recovery.
- UI, WebSocket/realtime push, nhiều broker/tenant, authentication/authorization và pre-trade balance checks.
- Idempotency/deduplication đầy đủ cho retry đặt lệnh sau timeout.

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: C# trên .NET 9, nullable và implicit usings bật.

**Service/App liên quan**: `flex-exchange-service`, solution `Flex.Exchange.sln`.

**Phụ thuộc chính**: ASP.NET Core Web API, xUnit, `WebApplicationFactory`, Serilog, existing `MatchingEngine` và contracts.

**Lưu trữ**: In-memory process state; không có database.

**Kiểm thử**: xUnit domain unit/API integration, serialization/contract assertions và `.http` manual smoke.

**Nền tảng chạy**: ASP.NET Core service local/demo; có thể chạy sau reverse proxy nhưng MVP chưa public.

**Đơn vị deploy**: `src/Flex.Exchange.Api/Flex.Exchange.Api.csproj` cùng Domain/Application/Infrastructure.

**Loại project**: Clean Architecture web service.

**Mục tiêu hiệu năng**: Luồng demo đặt hai lệnh và truy vấn kết quả hoàn tất trong ≤ 5 giây, không tính startup.

**Ràng buộc**: Không làm thay đổi price-time priority, event order, cancellation semantics hay response fields MVP 01.

**Quy mô/Phạm vi**: Một process, một instrument FXS, một `DemoBroker`/các broker demo, dữ liệu bounded theo phiên chạy.

## Kiểm tra constitution

*GATE: Đạt trước Phase 0 và giữ nguyên sau Phase 1 design.*

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|-----------------------|---------|
| Spec trước code / source of truth | Pass | Pass | Spec 000011 có trước plan/tasks/code; plan không mở rộng nghiệp vụ |
| Dependency direction / boundary | Pass | Pass | Domain không phụ thuộc HTTP; Api là composition root |
| Thay đổi phẫu thuật và đơn giản | Pass | Pass | Tận dụng engine/service/route hiện có, không thêm database hoặc project |
| API/contract compatibility | Pass | Pass | Field/route hiện có giữ nguyên; additions có contract và regression test |
| Security và dữ liệu nhạy cảm | Pass có điều kiện | Pass có điều kiện | API chưa auth chỉ local/demo; trước public deployment phải có security MVP sau |
| Test/observability/release gate | Pass | Pass | Có unit/integration/contract/manual, correlation, health và rollback smoke |

## Câu hỏi kỹ thuật cần research

- **TQ-001**: Làm thế nào vừa cung cấp event time/correlation vừa giữ replay deterministic?
- **TQ-002**: Read model/status/trade lookup nên đặt ở boundary nào để không làm lộ mutable Domain state?
- **TQ-003**: Bổ sung query contract thế nào để không phá các route và response MVP 01?

Các câu hỏi trên đã được resolve trong [research.md](research.md).

## Thiết kế tổng quan

**Luồng chính**:

1. Api nhận command, bind/validate payload và lấy `X-Correlation-Id` hoặc deterministic fallback.
2. Application đưa command cùng correlation vào `ExchangeService`; service lock engine và gọi Domain validator/matching/cancel.
3. Domain append event/order/trade state với sequence, event metadata và logical timestamp deterministic.
4. Application map kết quả thành immutable response/read model; Api trả response additive, Problem Details khi lỗi bất ngờ.
5. Query endpoint lock cùng gate, lấy bản copy status/trades/events/snapshot và filter theo `OrderId`/`BrokerId` trước khi trả.

**Component/module tham gia**:

- `Flex.Exchange.Domain/Matching/MatchingEngine.cs`: command processing, state transition, event/trade/order lookup.
- `Flex.Exchange.Domain/Events/*`: event metadata và type-specific payload.
- `Flex.Exchange.Application/Contracts/ExchangeContracts.cs`: public application read/command contracts.
- `Flex.Exchange.Application/Services/ExchangeService.cs`: serialization, mapping, logging, correlation propagation.
- `Flex.Exchange.Api/Controllers/*`: HTTP binding, status/response mapping và query endpoints.
- `Flex.Exchange.Api/RequestContext/*` hoặc request boundary helper: correlation extraction; không tạo custom correlation middleware.
- `tests/Flex.Exchange.Domain.Tests` và `tests/Flex.Exchange.Api.Tests`: regression/contract proof.

**Điểm mở rộng/thay đổi chính**:

- Bổ sung event metadata và correlation vào Domain/Application contracts.
- Bổ sung `GetOrder`, `GetOrderEvents`, `GetTrades` qua Application service.
- Bổ sung `GET /api/orders/{orderId}`, `GET /api/orders/{orderId}/events`, `GET /api/trades`; giữ route cũ.
- Bổ sung tests và cập nhật `.http`/Swagger contract.

**Luồng thay thế/lỗi chính**:

- Thiếu/sai `BrokerId`, invalid order hoặc broker mismatch trả business rejection, không mutate state.
- Unexpected exception đi qua `GlobalExceptionHandler`, trả Problem Details có correlation an toàn.
- Timeout sau khi command có thể đã xử lý không tự động replay; Gateway phải query correlation/order trước khi retry.

**Thay đổi boundary giữa service/module**: Không có service-to-service integration. HTTP Api contract mới là boundary public của Exchange; Domain/Application không tham chiếu ASP.NET Core.

**Idempotency/Concurrency**: Mọi command và state read tiếp tục dùng một lock tại `ExchangeService`; retry `PlaceOrder` là command mới, không deduplicate. Cancel lặp lại không có side effect.

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|------------|----------------------|---------------------|--------------|-------------|----------|
| US-001 / FR-001–FR-004 | P1 | Đủ rõ | Giữ command flow hiện tại, truyền correlation và mở rộng result metadata; rejection không mutate | `Domain/Matching`, `Application/Services`, `Api/Controllers/OrdersController` | `POST /api/orders` additive | `Order`, `ExchangeEvent` | Domain + API integration |
| US-002 / FR-005–FR-007 | P1 | Đủ rõ | Engine lưu/lookup order history; Application map status; Api thêm status query và giữ cancel contract | `Domain/Matching/MatchingEngine`, `Application/Contracts`, `Api/Controllers/OrdersController` | `DELETE /api/orders/{id}`, `GET /api/orders/{id}` | `OrderStatusView` | Domain state + API contract |
| US-003 / FR-008 | P1 | Đủ rõ | Dùng snapshot copy hiện có, filter order còn active | `Domain/Entities/OrderBook`, `Application/Services` | `GET /api/orderbook` | `OrderBookSnapshot` | API regression |
| US-003 / FR-009 | P1 | Đủ rõ | Giữ trade append order và expose read-only tape | `Domain/Matching`, `Application/Services` | `GET /api/trades` | `TradeTapeEntry` | Domain/API integration |
| US-003 / FR-010 | P1 | Đủ rõ | Event metadata deterministic, filter per order và global history additive | `Domain/Events`, `Application/Contracts`, `Api/Controllers/EventsController` | `GET /api/events`, `GET /api/orders/{id}/events` | `ExchangeEvent` | JSON contract/correlation |
| US-003 / FR-011 | P1 | Đủ rõ | Sequence/logical timestamp/fallback correlation deterministic; giữ lock | `Domain/Matching`, `Application/Services` | Event contract | In-memory sequence state | Replay regression |
| BR-001–BR-005 / SEC-001–SEC-003 | P1 | Đủ rõ | Validate broker, filter access, không log secret; local-only security boundary | `OrderValidator`, Api boundary, logging | Command/event metadata | `BrokerId`, correlation | Negative/security smoke |
| NFR-001–NFR-003 | P1 | Đủ rõ | Bounded in-memory flow, Problem Details, structured correlation logs | Api/Application/tests | Error/health contract | Không thêm persistence | Timed integration + log smoke |

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---------|------------------|--------------------------|---------------|
| Database/Migration | Không áp dụng; chỉ in-memory | Không có dữ liệu cần migrate; mất state khi restart là constraint | Xác nhận không thêm package/schema; restart smoke |
| API/Contract | Additive event fields và 3 query endpoints; route cũ giữ nguyên | Client deserialize strict có thể bị ảnh hưởng bởi field mới; contract test và tài liệu hóa | API integration + JSON snapshots |
| Permission/Security | Chưa có auth; broker filter cho lookup/cancel theo `BrokerId` | Không được public deploy trước auth; test broker mismatch không lộ data | Negative API tests + launch config review |
| Logging/Audit | Event history và structured logs có correlation/event/order ids | Không log token/secret; logical time cần giải thích rõ | Log assertion/redaction review |
| UI/UX | Không áp dụng; chỉ Gateway/Swagger/.http | Không có UI consumer trong MVP | Manual API smoke |
| Job/Worker/Integration | Không áp dụng; không có async worker/broker | Timeout retry không idempotent | Contract ghi rõ, test repeated cancel |

## API/Contract Detail

**Có thay đổi contract không**: Có, additive.

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|----------|------|----------|---------------------|------------------------|
| `POST /api/orders` | API | Giữ wrapper/fields cũ; events có metadata mới | Có | Gateway demo, `.http`, API tests |
| `DELETE /api/orders/{orderId}` | API | Giữ cancel response; correlation/events bổ sung | Có | Gateway demo |
| `GET /api/orders/{orderId}` | API | Mới: order status lookup | Có | Gateway/operator mới |
| `GET /api/orders/{orderId}/events` | API | Mới: per-order event history | Có | Gateway/operator mới |
| `GET /api/orderbook` | API | Giữ snapshot; chỉ bổ sung metadata nếu cần | Có | Existing tests/clients |
| `GET /api/trades` | API | Mới: ordered trade tape | Có | Gateway/operator mới |
| `GET /api/events` | API | Giữ route; event metadata additive | Có | Existing tests/clients |
| `ExchangeEvent` | In-process/public JSON | EventId/time/correlation/broker/type fields bắt buộc | Additive | Api/Application/tests |

## Permission Matrix

| Vai trò/Scope | Xem | Tạo | Sửa | Xóa | Duyệt/Xử lý | Ghi chú |
|---------------|-----|-----|-----|-----|-------------|---------|
| `DemoBroker` + matching `BrokerId` | Order của mình, global demo snapshot/tape theo local policy | Đặt lệnh | Không áp dụng | Hủy order còn chờ của mình | Không áp dụng | Chưa có authentication |
| Broker khác `BrokerId` | Không xem chi tiết order của broker khác | Đặt command riêng | Không áp dụng | Không được hủy | Không áp dụng | Trả not-found an toàn |
| Operator local demo | Xem diagnostics/demo data | Không áp dụng | Không áp dụng | Không áp dụng | Không áp dụng | Chỉ local, auth thuộc MVP sau |

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Không áp dụng — không có database.

**Migration**: Không áp dụng.

**Backfill/Cleanup**: Không áp dụng.

**Tương thích dữ liệu cũ**: Event/order state chỉ tồn tại trong process; state cũ không được restore sau restart.

**Rủi ro dữ liệu**: Event metadata mới phải được tạo cho mọi event; thiếu metadata làm hỏng contract/replay.

**Cách xác minh**: Domain tests assert mọi event type có metadata; API tests assert JSON fields và deterministic projection.

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| DEC-001 | Mở rộng engine và application read models, không thêm DB | Đúng scope, giữ deterministic và đơn giản | Repository/DB/event store | Ngoài MVP, tăng vận hành |
| DEC-002 | EventId/logical time deterministic theo sequence | Vừa đáp ứng metadata vừa replay được | Guid + UTC now | Làm stream không deterministic |
| DEC-003 | Correlation lấy request value, fallback deterministic; Activity chỉ diagnostics | Không custom middleware, vẫn truy vết request | Random trace id làm event key | Không tái lập |
| DEC-004 | Additive contract, giữ route/wrapper MVP 01 | Bảo vệ consumer hiện tại | Version/breaking rewrite | Không cần cho MVP |
| DEC-005 | Một lock tại `ExchangeService` cho command/read | Bảo toàn ordering với in-memory singleton | Concurrent mutation/async queue | Tăng race và scope |
| DEC-006 | Query status/tape/history bằng immutable DTO | Không lộ mutable domain state | Trả trực tiếp entity | Coupling và risk mutation |

## Chiến lược kiểm thử

**Unit test**:

- Event metadata/event sequence/logical timestamp cho accepted, rejected, trade, cancelled.
- Order status transitions, broker match, order lookup, trade tape ordering và event filtering.
- Deterministic replay projection và rejection không side effect.

**Integration test**:

- `WebApplicationFactory` cho place/cancel/status/orderbook/trades/events, Problem Details và health.
- Correlation header propagation/fallback, malformed payload và broker mismatch.

**Contract test**:

- JSON property names, additive response fields, event type payload và backward assertions cho existing routes.
- OpenAPI/Swagger endpoint presence cho query routes.

**Permission/security test**:

- Broker A không hủy/tra cứu chi tiết order của Broker B.
- Không có token/secret trong event/log/problem response; xác nhận API chỉ local theo deployment config.

**E2E/manual test**:

- Hai lệnh đối ứng, partial/rejection/cancel, query order/trades/history theo [quickstart.md](quickstart.md) và `.http`.

**Regression test**:

- Chạy toàn bộ tests MVP 01 hiện có và deterministic scenario sau restart; so sánh snapshot/trade/event sequence.

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/000011-exchange-api-events/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/exchange-api.md
└── checklists/requirements.md
```

### Source code (repository root)

```text
flex-exchange-service/
├── src/
│   ├── Flex.Exchange.Domain/
│   │   ├── Entities/{Order,Trade,OrderBook,OrderBookSnapshot}.cs
│   │   ├── Events/{ExchangeEvent,OrderAccepted,OrderRejected,TradeExecuted,OrderCancelled}.cs
│   │   └── Matching/MatchingEngine.cs
│   ├── Flex.Exchange.Application/
│   │   ├── Contracts/ExchangeContracts.cs
│   │   └── Services/{IExchangeService,ExchangeService}.cs
│   └── Flex.Exchange.Api/
│       ├── Controllers/{OrdersController,OrderBookController,EventsController,TradesController}.cs
│       ├── RequestContext/
│       ├── ExceptionHandling/GlobalExceptionHandler.cs
│       └── Flex.Exchange.http
└── tests/
    ├── Flex.Exchange.Domain.Tests/MatchingEngineTests.cs
    └── Flex.Exchange.Api.Tests/{MvpAcceptanceTests,OrdersApiTests}.cs
```

**Quyết định cấu trúc**: Giữ solution 4 production projects và 2 test projects hiện tại; chỉ mở rộng module sở hữu contract, không tạo project mới.

## Rollout & Rollback

**Kế hoạch rollout**:

1. Build/test solution và contract smoke trong CI/local.
2. Chạy local demo với API chưa public; so sánh output với MVP 01 baseline.
3. Deploy cùng service binary/config hiện tại sau khi health và smoke pass.

**Tương thích ngược**: Giữ các route, HTTP status và response fields MVP 01; consumer cũ bỏ qua field mới.

**Feature flag/config**: Không áp dụng; query routes và metadata luôn bật trong MVP.

**Thực thi migration/backfill khi rollout**: Không áp dụng.

**Rollback code/config**: Quay về binary MVP 01 nếu contract/query hoặc matching regression; không cần đổi data.

**Rollback dữ liệu/migration**: Không áp dụng; in-memory state bị bỏ khi process restart.

**Điều kiện kích hoạt rollback**: Existing MVP 01 tests fail, event sequence không deterministic, contract smoke fail, hoặc lỗi 5xx/query tăng trong demo.

## Observability & Debug

**Log cần có**:

- `traceId`, `correlationId`, `eventId`, `eventSequence`, `orderId`, `tradeId`, `brokerId`, `operation`, `result`, `reason`, duration.

**Dữ liệu không được log**:

- Token, authorization header, secret, connection string và raw sensitive payload.

**Metric cần theo dõi**:

- Command count/success/rejection, query count, 5xx/429, latency, event count và active order count trong demo.

**Trace/Correlation**:

- Nhận `X-Correlation-Id` tại request boundary; truyền vào application/domain event; enrich Serilog bằng W3C `Activity` trace/span. Fallback canonical correlation deterministic.

**Cách kiểm tra sau release**:

- `/health`, smoke two-order flow, query status/trade/history, kiểm tra event metadata và log correlation.

**Tình huống debug chính**:

- Broker mismatch, missing correlation, rejection side effect, wrong passive price, event ordering, partial fill và replay mismatch.

## Theo dõi độ phức tạp

Không có vi phạm constitution cần biện minh. Kế hoạch không thêm project, database, mediator, repository hay custom middleware dùng một lần.

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật đã được resolve trong [research.md](research.md).
- [x] Thiết kế tổng quan đã mô tả luồng, component, điểm thay đổi và boundary.
- [x] Idempotency/concurrency/retry đã được đánh giá.
- [x] Mỗi US/FR P1 và security/NFR liên quan có mapping path, contract, data và test.
- [x] Tác động database, API, permission, logging/audit và integration đã được đánh giá.
- [x] Contract thay đổi có consumer và compatibility check.
- [x] Data/migration/backfill/compatibility đã rõ.
- [x] Quyết định kỹ thuật có lý do và phương án bị loại.
- [x] Chiến lược test bao phủ unit, integration, contract, security, manual và regression.
- [x] Rollout, rollback, config và backward compatibility đã rõ.
- [x] Observability/debug có log field, redaction, metric, trace và smoke check.
- [x] Cây source code dùng path thật trong repository.
- [x] Constitution gate không còn blocker.
