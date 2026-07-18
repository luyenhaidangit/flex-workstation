# Kế hoạch triển khai: Exchange API và nhật ký sự kiện (FlexSim MVP 02)

**Branch**: `000011-exchange-api-events` | **Ngày**: 2026-07-18 | **Đặc tả**: [spec.md](spec.md)

**Đầu vào**: Đặc tả tính năng từ `specs/000011-exchange-api-events/spec.md`

---

## Tóm tắt

**Yêu cầu chính từ spec**: Đưa matching engine của MVP 01 thành dịch vụ có thể gọi, quan sát và replay ở mức cơ bản: Gateway tra cứu trạng thái lệnh theo `OrderId` (FR-007), xem trade tape (FR-009), xem lịch sử sự kiện theo lệnh với correlationId (FR-010); hủy lệnh kiểm tra quyền sở hữu BrokerId (FR-006); tính xác định MVP 01 được giữ nguyên (FR-011, BR-002).

**Hướng tiếp cận kỹ thuật dự kiến**: Mở rộng `flex-exchange-service` trong cùng repo: bổ sung ba endpoint mới (`GET /api/orders/{orderId}`, `GET /api/trades`, `GET /api/orders/{orderId}/events`), thêm order index vào `MatchingEngine` cho O(1) lookup, kiểm tra BrokerId ownership trong `CancelOrder`, làm giàu event (correlationId, timestamp, EventSequence làm EventId) ở lớp Application.

**Kết quả sau research**: Đã resolve tất cả câu hỏi kỹ thuật (xem phần TQ bên dưới). Matching rules MVP 01 giữ nguyên hoàn toàn; mọi thay đổi là additive — không break contract MVP 01.

---

## Phạm vi kỹ thuật

**Trong phạm vi**:
- Repo `flex-exchange-service`: thêm endpoint `GET /api/orders/{orderId}`, `GET /api/trades`, `GET /api/orders/{orderId}/events`
- `MatchingEngine`: thêm `_orderIndex` (`Dictionary<long, Order>`) để tra cứu mọi lệnh đã chấp nhận; mở rộng `CancelOrder` kiểm tra BrokerId ownership → `RejectReason.BrokerMismatch`
- Application layer (`ExchangeService`): thêm enriched event store với `CorrelationId` (từ `X-Correlation-Id` header) và `RecordedAt` (wall-clock tại thời điểm lệnh được xử lý); `MatchingEngine.EventLog` trở thành internal
- Cập nhật `Flex.Exchange.http` với 3 nhóm kịch bản mới (nhóm 9-11); bổ sung acceptance test cho MVP 02 behavior

**Ngoài phạm vi kỹ thuật**:
- Không thay đổi quy tắc khớp, ưu tiên giá-thời gian, tính xác định của engine (BR-002, MVP-004)
- Không database nghiệp vụ, không lưu trữ bền vững (in-memory như MVP 01)
- Không WebSocket/SSE, không push sự kiện realtime (MVP 03)
- Không xác thực, không phân quyền, không đa broker, không đa tenant (MVP 06)
- Không kiểm tra số dư, margin, settlement (MVP 05+)
- Không UI, bảng điện (MVP 03)
- Không sửa repo nào ngoài `flex-exchange-service` và artifact Speckit của feature này

---

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: C# / .NET 9 (`net9.0`) — đồng bộ MVP 01.

**Service/App liên quan**: `flex-exchange-service` (repo hiện có từ MVP 01). Pattern không đổi: `Flex.Exchange.Api → Flex.Exchange.Application → Flex.Exchange.Domain ← Flex.Exchange.Infrastructure`.

**Phụ thuộc chính**: Như MVP 01 — ASP.NET Core, Serilog.AspNetCore, Swashbuckle.AspNetCore. Thêm `IHttpContextAccessor` (có sẵn trong ASP.NET Core) để đọc `X-Correlation-Id` tại ExchangeService.

**Lưu trữ**: Không áp dụng — in-memory; mất khi restart (không đổi từ MVP 01).

**Kiểm thử**: Domain tests, API integration tests (`WebApplicationFactory`), kịch bản `Flex.Exchange.http` — thêm 3 nhóm cho MVP 02.

**Nền tảng chạy**: Kestrel self-host cục bộ, như MVP 01.

**Đơn vị deploy**: Không áp dụng — chưa deploy; chạy cục bộ demo.

**Loại project**: Không đổi — web-service (API host) + domain library + infrastructure + application library.

**Mục tiêu hiệu năng**: Gateway hoàn tất gửi lệnh + tra cứu trạng thái + trade tape + sự kiện trong ≤ 5 giây, không tính khởi động Kestrel (NFR-001).

**Ràng buộc**: Tính xác định của matching kết quả (order book, trades, EventSequence) PHẢI giữ nguyên. CorrelationId và RecordedAt là metadata presentation — không được dùng làm khóa xác định thứ tự khớp.

**Quy mô/Phạm vi**: 1 mã, 1 broker giả lập, hàng trăm lệnh mỗi kịch bản — quy mô demo.

---

## Kiểm tra constitution

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| Scope Gate | Pass | Pass | Phạm vi khớp MVP-001..005 (spec); không thêm kênh/auth/DB ngoài spec |
| Traceability Gate | Pass | Pass | Bảng traceability map FR-001..FR-011 sang module/path/test |
| Test Gate | Pass | Pass | Domain/API tests + kịch bản `.http` nhóm 9-11 cho SC-001..SC-004 |
| Security Gate | Pass | Pass | API chỉ demo cục bộ (SEC-003); BrokerId ownership kiểm tra tại engine |
| Compatibility Gate | Pass | Pass | Contract MVP 01 không bị phá vỡ (mở rộng additive, DEC-001) |
| Observability Gate | Pass | Pass | CorrelationId + RecordedAt + EventSequence đủ để trace và replay một lệnh |
| Complexity Gate | Pass | Pass | Mở rộng additive trong cùng repo; không thêm datastore/service/process |
| Release Gate | Không áp dụng | Không áp dụng | Demo cục bộ như MVP 01 |

---

## Câu hỏi kỹ thuật cần research

- **TQ-001**: Lưu trữ order state cho lookup ở đâu khi MVP 01 đã loại Filled/Cancelled khỏi `OrderBook` (T051)? → Resolve: thêm `_orderIndex: Dictionary<long, Order>` vào `MatchingEngine` — theo dõi mọi lệnh được chấp nhận (DEC-002).
- **TQ-002**: Trade tape lấy từ đâu? → Resolve: project từ enriched event store (lọc `TradeExecuted`). Không cần cấu trúc riêng (DEC-003).
- **TQ-003**: CorrelationId và RecordedAt tích hợp vào Domain hay Application? → Resolve: Application layer giữ Domain thuần; `ExchangeService` làm giàu events trước khi lưu vào enriched store (DEC-004).
- **TQ-004**: EventId — dùng GUID hay EventSequence? → Resolve: EventSequence đã là định danh duy nhất và xác định; không thêm GUID tránh vi phạm tính xác định (DEC-005).
- **TQ-005**: Tính xác định với metadata mới? → Resolve: assertion determinism chỉ so sánh trường nghiệp vụ (EventSequence, BrokerId, OrderId, Price...); CorrelationId và RecordedAt ngoài phạm vi so sánh (DEC-006).
- **TQ-006**: BrokerId ownership cho CancelOrder — Domain hay Application? → Resolve: Domain — đây là quy tắc nghiệp vụ (lệnh của broker nào chỉ broker đó hủy được), không phải auth/HTTP concern (DEC-007).

---

## Thiết kế tổng quan

**Luồng chính**:
1. Gateway gửi `POST /api/orders` hoặc `DELETE /api/orders/{orderId}` với `X-Correlation-Id` header tùy chọn; nếu thiếu, middleware tự sinh.
2. `OrdersController` chuyển request sang `ExchangeService`; `ExchangeService` đọc `X-Correlation-Id` từ `IHttpContextAccessor`.
3. `ExchangeService` tạo command (`PlaceOrder`/`CancelOrder`) → gọi `MatchingEngine` (serialize bằng lock như MVP 01) → nhận domain events.
4. `ExchangeService` làm giàu mỗi domain event thành `EnrichedEvent { DomainEvent, CorrelationId, RecordedAt }` → append vào `_enrichedEventLog` (in-memory, append-only).
5. Controller trả response: kết quả chấp nhận/từ chối + danh sách events đã làm giàu.
6. `GET /api/orders/{orderId}` → `ExchangeService.GetOrder(orderId)` → tra `MatchingEngine._orderIndex` → trả `OrderResponse`.
7. `GET /api/trades` → `ExchangeService.GetTradeTape()` → lọc `_enrichedEventLog` lấy `TradeExecuted` → trả danh sách giao dịch.
8. `GET /api/orders/{orderId}/events` → `ExchangeService.GetOrderEvents(orderId)` → lọc `_enrichedEventLog` theo OrderId → trả sự kiện liên quan.

**Component/module tham gia**:
- `src/Flex.Exchange.Domain`:
  - `Entities/Order.cs` — không đổi logic; `_orderIndex` lưu trực tiếp tham chiếu `Order` object
  - `Matching/MatchingEngine.cs` — thêm `_orderIndex`; thêm `GetOrder(orderId)` API; mở rộng `CancelOrder` validate BrokerId ownership; domain events không đổi cấu trúc
  - `Enums/RejectReason.cs` — thêm `BrokerMismatch`
- `src/Flex.Exchange.Application`:
  - Thêm `EnrichedEvent` record (wraps `ExchangeEvent` + `CorrelationId` + `RecordedAt`)
  - `IExchangeService` + `ExchangeService` — thêm `_enrichedEventLog`; thêm `GetOrder`, `GetTradeTape`, `GetOrderEvents`; inject `IHttpContextAccessor`; đọc correlation ID từ header
- `src/Flex.Exchange.Api`:
  - `Controllers/OrdersController.cs` — thêm `GET /api/orders/{orderId}`, `GET /api/orders/{orderId}/events`
  - Thêm `Controllers/TradesController.cs` — `GET /api/trades`
  - `Models/` — thêm `OrderResponse`, `OrderEventResponse`, `TradeResponse`

**Điểm mở rộng/thay đổi chính**:
- `_enrichedEventLog` (Application layer) thay thế việc đọc trực tiếp `MatchingEngine.EventLog` trong `GET /api/events`; `MatchingEngine.EventLog` trở thành internal audit.
- `_orderIndex` (Domain) làm seam cho MVP 06 khi có đa broker: mọi lookup đã đi qua một điểm.

**Luồng thay thế/lỗi chính**:
- `GET /api/orders/{orderId}` với OrderId không tồn tại → HTTP 404 (không phải business reject 200, vì đây là tra cứu tài nguyên).
- `DELETE` với BrokerId khác chủ lệnh → HTTP 200 business reject `BrokerMismatch`, không đổi order book (AC-005).
- `GET /api/orders/{orderId}/events` với OrderId không tồn tại → HTTP 404.
- Yêu cầu lỗi MVP 01 (thiếu BrokerId, lệnh sai quy tắc, hủy lệnh không tồn tại) → giống MVP 01; event từ chối vẫn được append vào `_enrichedEventLog`.

**Thay đổi boundary giữa service/module**:
- `ExchangeService` nay inject `IHttpContextAccessor` — cần đăng ký `AddHttpContextAccessor()` trong DI.
- `MatchingEngine.EventLog` (public property) trở thành implementation detail; `ExchangeService` không expose trực tiếp mà dùng `_enrichedEventLog`.

**Idempotency/Concurrency**:
- Như MVP 01: lock trong `ExchangeService` serialize mọi thao tác ghi và đọc `_orderIndex`/`_enrichedEventLog`.
- `GetOrder`, `GetTradeTape`, `GetOrderEvents` đọc dưới lock để nhất quán.

---

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|------------|----------------------|---------------------|--------------|-------------|----------|
| US-001 / FR-001 | P1 | Đủ rõ | PlaceOrder — tái dùng nguyên vẹn từ MVP 01 | `MatchingEngine.PlaceOrder`, `OrdersController` | `POST /api/orders` | `Order`, events | kịch bản `.http` nhóm 1-2 (reuse) |
| US-001 / FR-002 | P1 | Đủ rõ | Response chấp nhận trả `OrderId` + trạng thái; từ chối trả lý do — shape MVP 01 đã đủ | `ExchangeService`, `OrdersController` | `POST /api/orders` response | `PlaceOrderResponse` | AC-001, AC-002 |
| US-001 / FR-003 | P1 | Đủ rõ | Trades trong kết quả đặt lệnh — qua `PlaceOrderResponse.Events` (TradeExecuted); bổ sung `TradeIds` summary | `ExchangeService.PlaceOrder`, `PlaceOrderResponse` | `POST /api/orders` response | `EnrichedEvent` | AC-003 |
| US-001 / FR-004 | P1 | Đủ rõ | Lệnh bị từ chối không đổi order book — bảo đảm từ MVP 01 (engine invariant) | `MatchingEngine.OrderValidator` | Không áp dụng | order book | AC-002 |
| US-002 / FR-005 | P1 | Đủ rõ | Hủy lệnh — tái dùng logic từ MVP 01 | `MatchingEngine.CancelOrder`, `OrdersController` | `DELETE /api/orders/{orderId}` | `Order` (`Cancelled`) | AC-004 |
| US-002 / FR-006 | P1 | Đủ rõ | BrokerId ownership: `_orderIndex[orderId].BrokerId ≠ command.BrokerId` → business reject `BrokerMismatch`; order book không đổi | `MatchingEngine.CancelOrder`, `RejectReason.BrokerMismatch` | `DELETE` response `reason: BrokerMismatch` | `RejectReason` enum | AC-005 |
| US-002 / FR-007 | P1 | Đủ rõ | Order lookup: `MatchingEngine.GetOrder(orderId)` từ `_orderIndex` → trả OrderResponse | `MatchingEngine._orderIndex`, `ExchangeService.GetOrder`, `OrdersController` | `GET /api/orders/{orderId}` | `Order` entity | AC-006 |
| US-003 / FR-008 | P1 | Đủ rõ | Snapshot order book — tái dùng từ MVP 01 (`GET /api/orderbook`) | `OrderBookController` | `GET /api/orderbook` | `OrderBookSnapshot` | AC-007 |
| US-003 / FR-009 | P1 | Đủ rõ | Trade tape: lọc `_enrichedEventLog` lấy `TradeExecuted` events, project thành `TradeResponse` | `ExchangeService.GetTradeTape`, `TradesController` | `GET /api/trades` | `EnrichedEvent` (TradeExecuted) | AC-008 |
| US-003 / FR-010 | P1 | Đủ rõ | Event history by order: lọc `_enrichedEventLog` theo OrderId; mỗi event có `EventSequence`, `RecordedAt`, `BrokerId`, `CorrelationId` | `ExchangeService.GetOrderEvents`, `OrdersController` | `GET /api/orders/{orderId}/events` | `EnrichedEvent` | AC-009 |
| FR-011 | P1 | Đủ rõ | Determinism: matching outcome (EventSequence, trades, order book) xác định; CorrelationId/RecordedAt ngoài phạm vi determinism assertion (DEC-006) | `MatchingEngine` — không đổi | Guarantee trong contract | Business fields only | SC-004 |

---

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---------|------------------|--------------------------|---------------|
| Database/Migration | Không áp dụng — in-memory | Không áp dụng | Không áp dụng |
| API/Contract | 3 endpoint mới; `DELETE` thêm reject reason `BrokerMismatch`; event response thêm `correlationId`/`recordedAt` — additive | Consumer MVP 01 không expect field mới — backward compatible (field thêm không phá JSON consumer cũ) | Chạy lại 8 kịch bản `.http` MVP 01 sau khi bổ sung MVP 02 |
| Permission/Security | Không áp dụng — API demo cục bộ (SEC-003) | Rủi ro nếu deploy công khai — bị cấm | Kiểm tra launch profile không expose ngoài localhost |
| Logging/Audit | `_enrichedEventLog` là audit nghiệp vụ đầy đủ (correlationId, timestamp, EventSequence) | Thiếu truy vết nếu correlation không truyền → middleware tự sinh (acceptable) | Soi `GET /api/orders/{orderId}/events` sau mỗi lệnh trong `.http` |
| UI/UX | Không áp dụng — Swagger và `.http` là bề mặt demo | Không áp dụng | Mở Swagger, chạy kịch bản |
| Job/Worker/Integration | Không áp dụng | Không áp dụng | Không áp dụng |

---

## API/Contract Detail

**Có thay đổi contract không**: Có — mở rộng additive (3 endpoint mới, 1 reject reason mới, 2 field metadata mới). Contract MVP 01 không bị phá vỡ.

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|----------|------|----------|---------------------|------------------------|
| `GET /api/orders/{orderId}` | REST API | Mới | Không áp dụng | `.http`/Swagger demo; MVP 06 đa broker |
| `GET /api/trades` | REST API | Mới | Không áp dụng | `.http`/Swagger demo; MVP 03 bảng điện (tương lai) |
| `GET /api/orders/{orderId}/events` | REST API | Mới | Không áp dụng | `.http`/Swagger demo |
| `DELETE /api/orders/{orderId}` | REST API | Mở rộng: thêm `BrokerMismatch` | Backward compatible (field mới trong enum) | `.http`/Swagger demo |
| Event response (trong `PlaceOrder`/`Cancel` response và `GET /api/events`) | Response schema | Thêm `correlationId` (string?), `recordedAt` (DateTimeOffset?) | Backward compatible (field mới trong JSON) | Consumer `.http`/Swagger |

### Payload endpoint mới

**`GET /api/orders/{orderId}`** — HTTP 200 hoặc 404:
```json
{
  "orderId": 1,
  "brokerId": "DemoBroker",
  "symbol": "FXS",
  "side": "Buy",
  "price": 20000,
  "originalQuantity": 200,
  "remainingQuantity": 100,
  "status": "PartiallyFilled",
  "tradeIds": [1]
}
```

**`GET /api/trades`** — HTTP 200:
```json
[
  {
    "tradeId": 1,
    "symbol": "FXS",
    "buyOrderId": 2,
    "sellOrderId": 1,
    "price": 20000,
    "quantity": 100,
    "executedSequence": 1,
    "correlationId": "abc-123",
    "recordedAt": "2026-07-18T10:00:00Z"
  }
]
```

**`GET /api/orders/{orderId}/events`** — HTTP 200 hoặc 404: danh sách enriched events của lệnh (OrderAccepted, TradeExecuted liên quan, OrderCancelled nếu hủy).

---

## Permission Matrix

Không áp dụng — một `DemoBroker`, API demo cục bộ không xác thực. BrokerId trong cancel là nhận dạng nghiệp vụ, không phải cơ chế auth (như MVP 01, SEC-001).

---

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Không áp dụng — in-memory, không schema.

**Migration/Backfill/Tương thích/Rủi ro/Cách xác minh**: Không áp dụng.

---

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| DEC-001 | Contract MVP 01 (4 endpoint, event shape) giữ nguyên; MVP 02 là extension additive | FR-011 + BR-002: không được phá contract MVP 01; consumer `.http` hiện hành phải pass không sửa | Thay thế endpoint MVP 01 | Rủi ro regression; vi phạm BR-002 |
| DEC-002 | Thêm `_orderIndex: Dictionary<long, Order>` vào `MatchingEngine` | O(1) lookup; engine tự quản order lifecycle; sạch hơn scan EventLog O(n) | (a) Scan EventLog; (b) Lưu ở Application | (a) O(n) tạo pattern xấu khi scale; (b) domain logic rò rỉ ra Application |
| DEC-003 | Trade tape = project từ `_enrichedEventLog` (lọc `TradeExecuted`) | Không nhân đôi storage; `TradeExecuted` đã có đủ thông tin đối chiếu | `List<Trade> TradeTape` riêng trong engine | Trùng lặp data; engine biết quá nhiều về presentation |
| DEC-004 | CorrelationId và RecordedAt ở Application layer (`EnrichedEvent`); Domain events không thay đổi | Giữ Domain thuần (không phụ thuộc HTTP/request context); dễ test Domain độc lập | Truyền correlationId vào Domain event | Coupling HTTP concept vào Domain; làm phức tạp unit test engine |
| DEC-005 | EventId = `EventSequence` (long) — không thêm GUID | EventSequence đã là định danh duy nhất và xác định; GUID ngẫu nhiên vi phạm FR-011 | GUID riêng | Phá tính xác định; complexity không cần thiết |
| DEC-006 | Determinism test assert chỉ business fields (EventSequence, OrderId, Price, Quantity, BrokerId, Symbol); không assert CorrelationId và RecordedAt | CorrelationId phụ thuộc HTTP header; RecordedAt là wall-clock — cả hai không ảnh hưởng tính đúng của matching | Assert toàn bộ event object | Test sẽ fail khi replay với timestamp/correlationId khác dù matching hoàn toàn đúng |
| DEC-007 | BrokerId ownership check trong `MatchingEngine.CancelOrder` (Domain) | Quy tắc nghiệp vụ: lệnh của broker nào chỉ broker đó hủy được; không phải auth HTTP; cần test ở Domain level | Application/Controller | Engine có thể bị gọi trực tiếp với lệnh không hợp lệ; vi phạm domain invariant |
| DEC-008 | `GET /api/events` đọc từ `_enrichedEventLog` (Application) thay vì `MatchingEngine.EventLog` | Enriched events có đầy đủ correlationId/timestamp; nhất quán với `GET /api/orders/{orderId}/events` | Giữ đọc `MatchingEngine.EventLog` | Trả events thiếu correlationId/timestamp, vi phạm FR-010 |

---

## Chiến lược kiểm thử

**Unit test** (`Flex.Exchange.Domain.Tests`):
- `MatchingEngine._orderIndex` có đầy đủ orders đã chấp nhận sau mỗi command.
- `CancelOrder` trả `BrokerMismatch` khi BrokerId không khớp; order book không đổi.
- `GetOrder(orderId)` trả đúng trạng thái order sau fill/cancel.

**Integration test** (`Flex.Exchange.Api.Tests` — `WebApplicationFactory`):
- Đặt hai lệnh đối ứng → `GET /api/orders/{orderId}` trả đúng trạng thái; `GET /api/trades` trả đúng trade; `GET /api/orders/{orderId}/events` trả đúng sự kiện với correlationId.
- `DELETE` với BrokerId khác chủ lệnh → reject `BrokerMismatch`, order book không đổi.
- `GET /api/orders/{orderId}` với OrderId không tồn tại → 404.
- Chạy lại cùng kịch bản hai lần → business fields giống nhau 100% (CorrelationId/RecordedAt ngoài phạm vi so sánh — DEC-006, SC-004).
- Tám nhóm kịch bản MVP 01 vẫn pass sau thay đổi (regression).

**Contract test**: Response shape của 3 endpoint mới khớp API/Contract Detail. `GET /api/events` vẫn trả kết quả đúng sau khi đổi source sang `_enrichedEventLog`.

**Permission/security test**: Không áp dụng.

**E2E/manual test** — 3 nhóm kịch bản mới trong `Flex.Exchange.http` (bổ sung vào 8 nhóm MVP 01):
- **Nhóm 9**: Tra cứu lệnh — đặt hai lệnh đối ứng, lấy `OrderId`, tra cứu trạng thái lệnh (AC-006).
- **Nhóm 10**: Trade tape và sự kiện — xem `GET /api/trades` + `GET /api/orders/{orderId}/events`; đối chiếu correlationId xuyên event và request (AC-008, AC-009).
- **Nhóm 11**: BrokerId mismatch — hủy lệnh của broker A bằng broker B; xác nhận reject + book bất biến (AC-005).

**Regression test**: Toàn bộ 8 nhóm kịch bản MVP 01 phải pass không sửa sau khi bổ sung MVP 02.

---

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/000011-exchange-api-events/
├── plan.md              # File này
├── checklists/
│   └── requirements.md
└── tasks.md             # Output /speckit-tasks — bước tiếp theo
```

### Source code (`flex-exchange-service/`)

```text
flex-exchange-service/
├── src/
│   ├── Flex.Exchange.Domain/
│   │   ├── Entities/Order.cs              # Không đổi matching logic
│   │   ├── Enums/RejectReason.cs          # + BrokerMismatch
│   │   └── Matching/MatchingEngine.cs     # + _orderIndex: Dictionary<long,Order>
│   │                                      # + GetOrder(orderId): Order?
│   │                                      # CancelOrder: + BrokerMismatch check
│   ├── Flex.Exchange.Application/
│   │   ├── EnrichedEvent.cs               # record: DomainEvent + CorrelationId + RecordedAt
│   │   ├── Interfaces/IExchangeService.cs # + GetOrder, GetTradeTape, GetOrderEvents
│   │   └── ExchangeService.cs             # + _enrichedEventLog; + IHttpContextAccessor
│   │                                      # + 3 new methods; GET /api/events từ _enrichedEventLog
│   └── Flex.Exchange.Api/
│       ├── Controllers/OrdersController.cs  # + GET /api/orders/{orderId}
│       │                                    # + GET /api/orders/{orderId}/events
│       ├── Controllers/TradesController.cs  # Mới: GET /api/trades
│       └── Models/
│           ├── OrderResponse.cs             # Mới
│           ├── OrderEventResponse.cs        # Mới
│           └── TradeResponse.cs             # Mới
└── tests/
    ├── Flex.Exchange.Domain.Tests/          # + test _orderIndex, BrokerMismatch, GetOrder
    └── Flex.Exchange.Api.Tests/             # + acceptance tests MVP 02 (nhóm 9-11)
```

**Quyết định cấu trúc**: Mở rộng trong cùng project layout MVP 01; không thêm project/layer mới; `EnrichedEvent` đặt trong `Flex.Exchange.Application` (tầng đúng cho presentation enrichment).

---

## Rollout & Rollback

**Kế hoạch rollout**: Không áp dụng — không deploy; hoàn thành = merge vào `main` của `flex-exchange-service` với kịch bản nhóm 9-11 đạt và 8 nhóm MVP 01 vẫn pass.

**Tương thích ngược**: Contract MVP 01 không bị phá (DEC-001); consumer `.http` hiện hành không cần sửa.

**Feature flag/config**: Không cần — extension additive, hành vi cũ không đổi.

**Rollback code/config**: Revert commit/PR — không có state ngoài code.

**Rollback dữ liệu/migration**: Không áp dụng.

**Điều kiện kích hoạt rollback**: Không áp dụng — demo cục bộ.

---

## Observability & Debug

**Log cần có**:
- `ExchangeService`: log command nhận được (type, BrokerId, OrderId khi cancel, CorrelationId) + kết quả.
- Enriched event append: log EventSequence, CorrelationId, event type.

**Dữ liệu không được log**: Không áp dụng — toàn bộ giả lập, không credential/PII.

**Metric cần theo dõi**: Không áp dụng ở MVP 02 (không deploy).

**Trace/Correlation**: `CorrelationId` gắn vào mọi enriched event và response; dùng `GET /api/orders/{orderId}/events` để replay đầy đủ diễn biến một lệnh với context request gốc.

**Cách kiểm tra sau release**: Build → run → 8 nhóm `.http` MVP 01 pass → 3 nhóm MVP 02 pass → SC-004 (chạy lại cùng chuỗi lệnh, so sánh business fields).

**Tình huống debug chính**:
- `GET /api/orders/{orderId}` trả 404 bất ngờ → lệnh bị `OrderRejected` (rejected orders không vào `_orderIndex`).
- `BrokerMismatch` không mong đợi → kiểm tra BrokerId trong cancel request vs BrokerId khi đặt lệnh.
- CorrelationId thiếu trong event → kiểm tra `X-Correlation-Id` header có được middleware sinh và `IHttpContextAccessor` đọc đúng.
- Kết quả matching khác MVP 01 sau thay đổi → scan `_enrichedEventLog` kiểm tra engine không bị sửa.

---

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật chặn thiết kế/task generation đã được resolve (TQ-001..TQ-006).
- [x] Thiết kế tổng quan đã mô tả luồng chính, component/module tham gia, điểm thay đổi và boundary.
- [x] Các tình huống idempotency/concurrency/retry đã được đánh giá (lock như MVP 01, không thay đổi).
- [x] Mỗi FR P1 có mapping sang module/path, API/contract, data/entity và kiểm thử.
- [x] Tác động tới database, API contract, permission, logging/audit và integration đã được đánh giá hoặc ghi `Không áp dụng`.
- [x] Các contract/API thay đổi đã có consumer bị ảnh hưởng và cách kiểm tra compatibility.
- [x] Dữ liệu/migration/backfill: Không áp dụng (in-memory như MVP 01).
- [x] Quyết định kỹ thuật chính (DEC-001..DEC-008) đã có lý do chọn và phương án bị loại.
- [x] Chiến lược kiểm thử bao phủ Domain, API integration và `.http` nhóm 9-11 + regression 8 nhóm MVP 01.
- [x] Rollout/rollback: Không áp dụng (demo cục bộ).
- [x] Observability: CorrelationId + RecordedAt + EventSequence đủ để trace và replay.
- [x] Cấu trúc source code là path thật trong repo `flex-exchange-service`.
- [x] Constitution gate không còn blocker.
