# Data model: Exchange API và nhật ký sự kiện

MVP 02 không thêm database hay migration. Các thực thể tồn tại trong process và được expose qua immutable application contracts.

## Order

Đại diện một lệnh do `BrokerId` gửi.

| Thuộc tính | Ý nghĩa | Quy tắc |
|---|---|---|
| `OrderId` | Định danh lệnh | Tăng dần, duy nhất trong một lần chạy |
| `BrokerId` | Broker gửi lệnh | Bắt buộc; dùng để truy vết và kiểm tra hủy |
| `Symbol` | Mã giao dịch | Khớp instrument được cấu hình |
| `Side` | Buy/Sell | Bắt buộc |
| `Price`, `Quantity` | Giá và khối lượng ban đầu | Tuân tick, band và lot MVP 01 |
| `RemainingQuantity` | Khối lượng còn chờ | Không âm; bằng 0 khi filled/cancelled |
| `SequenceNumber` | Thứ tự vào sổ | Dùng cho price-time priority |
| `Status` | Vòng đời lệnh | Pending/PartiallyFilled/Filled/Cancelled/Rejected |

## Trade

Một lần khớp giữa buy order và sell order: `TradeId`, `Symbol`, hai order id, `Price`, `Quantity` và `ExecutedSequence`.

## ExchangeEvent

Immutable audit/read record cho command hoặc matching result.

| Thuộc tính | Ý nghĩa | Quy tắc |
|---|---|---|
| `EventId` | Định danh ổn định | Sinh từ event sequence, không random |
| `EventSequence` | Thứ tự toàn cục | Tăng dần, không lặp |
| `OccurredAt` | Logical event time | Tính deterministic từ sequence |
| `CorrelationId` | Liên kết request | Giữ request value hoặc fallback deterministic |
| `BrokerId` | Broker nguồn | Bắt buộc |
| `OrderId` | Lệnh liên quan | Có khi áp dụng |
| `Type` | Event type | OrderAccepted/OrderRejected/TradeExecuted/OrderCancelled |
| Payload | Giá, quantity, reason, references | Phụ thuộc type |

## Read models

- `OrderStatusView`: thông tin lệnh và trạng thái cuối.
- `TradeTapeEntry`: trade theo `TradeId`/`ExecutedSequence`.
- `OrderEventHistory`: events filter theo `OrderId`.
- `OrderBookSnapshot`: chỉ lệnh còn chờ, tại `AsOfEventSequence`.

## Bất biến

- Một Order có nhiều ExchangeEvent và có thể tham gia nhiều Trade.
- Một Trade tham chiếu đúng một buy order và một sell order.
- Event/order/trade sequence và logical timestamp không đổi sau append.
- Query trả bản copy immutable, không trả reference mutable của Domain.
