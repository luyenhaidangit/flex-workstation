# Contract: Exchange Core (in-process) — FlexSim MVP 01

**Ngày**: 2026-07-14
**Loại**: In-process API (C#), không phải HTTP/event bus. Đây là hợp đồng mà MVP 02 sẽ bọc API/WebSocket lên trên (SC-004); danh sách thành phần khớp mục "Đầu ra cho MVP 02" trong `docs/mvp/01-matching-rules.md`: `PlaceOrder`, `CancelOrder`, `OrderAccepted`, `OrderRejected`, `TradeExecuted`, `OrderCancelled`, snapshot order book.

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

Engine **không** tự publish sự kiện ra ngoài (DEC-005); caller (demo console, test, và sau này MVP 02) nhận sự kiện từ giá trị trả về hoặc `EventLog`.

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
| Console demo (`src/Flex.Exchange`) | Toàn bộ API | MVP 01 |
| Unit tests (`tests/Flex.Exchange.UnitTests`) | Toàn bộ API + guarantees | MVP 01 |
| Exchange API host (MVP 02) | Bọc HTTP/WebSocket lên commands/events/snapshot | Tương lai — không được yêu cầu sửa engine |
