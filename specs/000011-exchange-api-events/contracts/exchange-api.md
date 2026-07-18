# Exchange API contract — MVP 02

Base path: `/api`

## Common rules

- JSON dùng camelCase.
- `BrokerId` bắt buộc ở mọi command đặt/hủy.
- Client có thể gửi `X-Correlation-Id`; nếu không gửi, service trả correlation id deterministic trong response/event metadata.
- Business rejection giữ HTTP success semantics hiện tại; malformed payload do boundary validation xử lý.
- Unexpected failure trả Problem Details an toàn và correlation id.

## Commands

### `POST /api/orders`

Request:

```json
{
  "brokerId": "BrokerA",
  "symbol": "FXS",
  "side": "Buy",
  "price": 20000,
  "quantity": 100
}
```

Response `200` giữ `accepted`, `orderId`, `reason` và `events`; event mới có metadata `eventId`, `eventSequence`, `occurredAt`, `correlationId`, `brokerId`, `type` và payload theo type.

Rejection giữ `accepted: false`, `orderId: null`, reason cụ thể và `OrderRejected`; không mutate order book/trade tape.

### `DELETE /api/orders/{orderId}?brokerId=BrokerA`

Response `200` chứa `cancelled`, `reason` và events. Hủy thành công emit `OrderCancelled`; hủy lặp lại/không hợp lệ không tạo trade.

## Queries

### `GET /api/orders/{orderId}?brokerId=BrokerA`

Trả `OrderStatusView`; order không tồn tại hoặc broker mismatch trả business not-found an toàn, không lộ order của broker khác.

### `GET /api/orders/{orderId}/events?brokerId=BrokerA`

Trả events của order, sort theo `eventSequence`.

### `GET /api/orderbook`

Giữ `OrderBookSnapshot` hiện tại và chỉ trả pending/partially filled levels.

### `GET /api/trades`

Trả trade tape sort theo `executedSequence`.

### `GET /api/events`

Giữ global event history route; metadata mới là additive. Filter chỉ được thêm nếu không đổi semantics response không filter.

## Event types

`OrderAccepted`, `OrderRejected`, `TradeExecuted`, `OrderCancelled`.

Mỗi event có `eventId`, `eventSequence`, `occurredAt`, `correlationId`, `brokerId`, `type`; `orderId` có khi event gắn với order cụ thể.
