# Contract: Exchange Core (in-process) — FlexSim MVP 01

**Ngày**: 2026-07-14
**Loại**: REST API cục bộ và contract in-process (C#). REST API phục vụ demo MVP 01; engine không tự publish event bus/WebSocket. Danh sách thành phần khớp mục "Đầu ra cho MVP 02" trong `docs/mvp/01-matching-rules.md`.

**Breaking change**: Không áp dụng — contract tạo mới, chưa có consumer bên ngoài solution.

---

## Bề mặt API của engine

```csharp
namespace Flex.Domain.Matching;

public sealed class MatchingEngine
{
    public MatchingEngine(InstrumentConfig config);

    // Xử lý tuần tự, đồng bộ. Mỗi lời gọi xử lý trọn vẹn một command (BR-005)
    // và trả về danh sách sự kiện sinh ra theo đúng thứ tự (EventSequence tăng dần).
    public PlaceOrderResult PlaceOrder(PlaceOrder command);
    public CancelOrderResult CancelOrder(CancelOrder command);

    // Read-only, có thể gọi bất kỳ lúc nào giữa hai command (FR-008).
    public OrderBookSnapshot GetSnapshot();

    // Toàn bộ sự kiện từ đầu phiên chạy, append-only (audit/trace — spec §10).
    public IReadOnlyList<ExchangeEvent> EventLog { get; }
}
```

Engine **không** tự publish sự kiện ra ngoài (DEC-005); `ExchangeService` trả chúng trong REST response và lưu event log để truy vấn. MVP 02 có thể thêm publisher mà không sửa engine.

## REST API

Base path: `/api`. API chỉ chạy local để demo (SEC-002); mọi business reject trả HTTP `200` kèm mã lý do, request sai cấu trúc trả `400`.

| Endpoint | Request | Kết quả |
|----------|---------|---------|
| `POST /api/orders` | `brokerId`, `symbol`, `side`, `price`, `quantity` | `accepted`, `orderId`, `reason`, `events` |
| `DELETE /api/orders/{orderId}` | `brokerId` (query string) | `cancelled`, `reason`, `events` |
| `GET /api/orderbook` | Không có | `OrderBookSnapshot` |
| `GET /api/events` | Không có | Dòng `ExchangeEvent` theo `eventSequence` tăng dần |

Mọi response dùng response wrapper chuẩn của service; payload nghiệp vụ giữ nguyên các field ở phần contract in-process bên dưới.

## Commands

### PlaceOrder

| Trường | Kiểu | Bắt buộc | Ghi chú |
|--------|------|----------|---------|
| `BrokerId` | `string` | Có | Rỗng → reject `MissingBrokerId` |
| `Symbol` | `string` | Có | Khác config → reject `UnknownSymbol` |
| `Side` | `OrderSide` (`Buy`/`Sell`) | Có | |
| `Price` | `long` | Có | VND nguyên; xem RejectReason |
| `Quantity` | `long` | Có | Bội số lô chẵn |

**Kết quả** `PlaceOrderResult`:
- `Accepted` (`bool`); `OrderId` (`long?`, có khi accepted); `Reason` (`RejectReason?`, có khi rejected);
- `Events` (`IReadOnlyList<ExchangeEvent>`): `[OrderRejected]` hoặc `[OrderAccepted, TradeExecuted*]` — accepted luôn đứng trước các trade sinh ra từ chính lệnh đó.

### CancelOrder

| Trường | Kiểu | Bắt buộc | Ghi chú |
|--------|------|----------|---------|
| `BrokerId` | `string` | Có | |
| `OrderId` | `long` | Có | |

**Kết quả** `CancelOrderResult`:
- `Cancelled` (`bool`); `Reason` (`RejectReason?` — `OrderNotFound` khi lệnh không tồn tại/đã khớp hết/đã hủy — AC-008);
- `Events`: `[OrderCancelled]` khi thành công, `[]` khi bị từ chối (từ chối hủy không phát event, chỉ trả reason — order book không đổi).

## Events

Trường chung (base `ExchangeEvent`): `EventSequence` (`long`, tuần tự toàn cục, tăng nghiêm ngặt), `BrokerId` (`string`).

| Event | Payload | Phát khi |
|-------|---------|----------|
| `OrderAccepted` | `OrderId`, `Symbol`, `Side`, `Price`, `Quantity`, `SequenceNumber` | Lệnh qua validate, trước mọi trade của nó |
| `OrderRejected` | `Symbol`, `Side`, `Price`, `Quantity`, `Reason` | Lệnh vi phạm FR-001 (không có `OrderId`) |
| `TradeExecuted` | `TradeId`, `Symbol`, `BuyOrderId`, `SellOrderId`, `Price` (giá lệnh chờ — FR-005), `Quantity`, `ExecutedSequence` | Mỗi lần khớp, theo đúng thứ tự ưu tiên |
| `OrderCancelled` | `OrderId`, `CancelledQuantity` | Hủy thành công lệnh còn dư trong sổ |

## Snapshot

`OrderBookSnapshot`: `Symbol`, `AsOfEventSequence`, `Bids`/`Asks` — danh sách mức giá đúng thứ tự ưu tiên (mua giảm dần, bán tăng dần), mỗi mức có `Price`, `TotalQuantity`, danh sách `(OrderId, RemainingQuantity, SequenceNumber)` FIFO. Chi tiết trường: [data-model.md §7](../data-model.md).

## Bảo đảm hành vi (contract guarantees)

1. **Determinism** (FR-009): cùng chuỗi command (nội dung + thứ tự) → cùng chuỗi `ExchangeEvent` (từng trường một) và cùng snapshot cuối, trên mọi lần chạy và mọi máy.
2. **Thứ tự sự kiện**: `EventSequence` tăng nghiêm ngặt, không lỗ hổng, phản ánh đúng thứ tự nghiệp vụ xảy ra.
3. **Nguyên tử theo command** (BR-005): sau khi một lời gọi trả về, order book ở trạng thái nhất quán; không có trade "nửa chừng".
4. **Giá khớp** = giá lệnh chờ (BR-003); ưu tiên giá rồi thời gian (BR-002).
5. **Lệnh đã hủy/hoàn tất không bao giờ khớp lại** (BR-004).

## Consumer

| Consumer | Dùng gì | Thời điểm |
|----------|---------|-----------|
| `Flex.Exchange.http` / Swagger | REST endpoints | MVP 01 |
| `ExchangeService` | Toàn bộ API in-process | MVP 01 |
| MVP 02 publisher | Commands/events/snapshot, thêm WebSocket hoặc event publisher | Tương lai — không được yêu cầu sửa engine |
