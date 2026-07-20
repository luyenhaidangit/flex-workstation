# Data model: MVP 1 Matching Engine

## Entities

### `exchange_instruments`

| Thuộc tính | Ý nghĩa | Ràng buộc |
|---|---|---|
| `instrument_id` | Identity ổn định | Primary key |
| `symbol` | Mã giao dịch | Unique, not null |
| `market` | Thị trường | `HNX` trong MVP 1 |
| `status` | Trạng thái | `active` hoặc giá trị BE hỗ trợ |
| `created_at` | Thời điểm tạo | Timestamp |

### `exchange_sessions`

| Thuộc tính | Ý nghĩa | Ràng buộc |
|---|---|---|
| `session_id` | Identity phiên | Primary key |
| `market` | Thị trường | `HNX` |
| `session_date` | Ngày giao dịch | Not null |
| `session_type` | Loại phiên | `CONTINUOUS` |
| `status` | Trạng thái | `open`/`closed` |
| `opened_at`, `closed_at` | Thời gian phiên | Timestamp |

### `exchange_orders`

Lưu trạng thái hiện tại của order. Order book được dựng từ order còn khối lượng.

| Thuộc tính | Ý nghĩa | Ràng buộc |
|---|---|---|
| `order_id` | Identity order | Primary key |
| `session_id`, `instrument_id` | Phiên và instrument | Foreign key |
| `broker_id`, `client_order_id` | Chủ thể và identity phía client | Unique theo scope |
| `side` | Mua/bán | `BUY`/`SELL` |
| `order_type` | Loại order | `LIMIT` |
| `price` | Giá đặt | Positive |
| `quantity` | Khối lượng ban đầu | Positive |
| `filled_quantity` | Đã khớp | `0..quantity` |
| `remaining_quantity` | Còn lại | `0..quantity` |
| `status` | Trạng thái | `open`/`partially_filled`/`filled`/`cancelled`/`rejected` |
| `accepted_at`, `updated_at` | Thời gian xử lý | Timestamp |
| `correlation_id` | Định danh truy vết yêu cầu | UUID hoặc `NULL` |

### `exchange_trades`

Trade là immutable; mỗi lần khớp tạo một record.

| Thuộc tính | Ý nghĩa | Ràng buộc |
|---|---|---|
| `trade_id` | Identity trade | Primary key |
| `session_id`, `instrument_id` | Phiên và instrument | Foreign key |
| `buy_order_id`, `sell_order_id` | Hai order đối ứng | Foreign key, khác nhau |
| `price`, `quantity` | Giá/khối lượng khớp | Positive |
| `trade_sequence` | Thứ tự trong session | Unique |
| `executed_at` | Thời điểm khớp | Timestamp |
| `correlation_id` | Định danh truy vết yêu cầu | UUID hoặc `NULL` |

## Relationships

```text
exchange_instruments ──┬── exchange_orders ── exchange_trades
                       └── exchange_trades
exchange_sessions ─────── exchange_orders / exchange_trades
```

## Invariants

- Không có hai instrument cùng symbol trong market.
- `remaining_quantity = quantity - filled_quantity`.
- Không có order âm khối lượng.
- Trade chỉ được ghi khi cả hai order cùng instrument/session.
- Cập nhật hai order và insert trade phải atomic.
- Không tạo duplicate trade khi retry hoặc xử lý đồng thời.
- Nếu client gửi `X-Correlation-Id`, giá trị phải là UUID hợp lệ; nếu không gửi, BE tự sinh UUID.
