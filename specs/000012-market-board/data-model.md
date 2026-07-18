# Mô hình dữ liệu — Bảng điện thị trường demo

## Nguyên tắc

Các model dưới đây là read model và command model của UI. Chúng không thay thế entity/domain model của `flex-exchange-service` và không được lưu thành nguồn dữ liệu nghiệp vụ thứ hai.

## Thực thể và quan hệ

### `MarketBoardViewModel`

Trạng thái hiển thị tổng hợp cho một mã.

| Thuộc tính | Ý nghĩa | Nguồn |
|---|---|---|
| `symbol` | Mã đang quan sát, luôn là `FXS` trong MVP | `OrderBookSnapshot.symbol` |
| `asOfEventSequence` | Mốc dữ liệu gần nhất của snapshot | `OrderBookSnapshot.asOfEventSequence` |
| `bids` | Tối đa 5 mức mua, sắp xếp giá giảm dần | `OrderBookSnapshot.bids` |
| `asks` | Tối đa 5 mức bán, sắp xếp giá tăng dần | `OrderBookSnapshot.asks` |
| `latestPrice` | Giá của trade mới nhất, nếu có | phần tử đầu của trade tape |
| `trades` | Trade tape sắp xếp mới nhất trước | `GET /api/trades` |
| `lastUpdatedAt` | Thời điểm browser nhận lần refresh thành công | client-only |
| `loading`/`stale` | Trạng thái hiển thị khi đang tải hoặc dùng dữ liệu cũ | client-only |

`totalQuantity` của từng `PriceLevel` được hiển thị trực tiếp; tổng khối lượng chờ là tổng các mức đang được hiển thị, không tự suy diễn thêm ngoài snapshot.

### `OrderBookLevelViewModel`

| Thuộc tính | Ý nghĩa |
|---|---|
| `price` | Giá tại mức |
| `totalQuantity` | Tổng khối lượng còn chờ tại mức |
| `orders` | Các order level nếu cần hiển thị chi tiết |

UI chỉ cần năm mức đầu; không sửa thứ tự do server trả về.

### `TradeTapeEntry`

| Thuộc tính | Ý nghĩa |
|---|---|
| `tradeId` | Định danh giao dịch |
| `symbol` | Mã giao dịch |
| `buyOrderId`/`sellOrderId` | Hai order đã khớp |
| `price`/`quantity` | Giá và khối lượng khớp |
| `executedSequence` | Thứ tự thực thi |

### `DemoBrokerOption`

Danh sách cố định gồm hai broker demo, mỗi option có `id` và `label`. `id` là giá trị gửi tới Exchange; người dùng chỉ chọn, không nhập tự do.

### `PlaceOrderFormModel`

| Thuộc tính | Quy tắc |
|---|---|
| `brokerId` | Bắt buộc, phải thuộc hai `DemoBrokerOption` |
| `symbol` | Read-only `FXS` |
| `side` | `Buy` hoặc `Sell` |
| `price` | Số nguyên dương, kiểm tra client ở mức định dạng; Exchange kiểm tra rule nghiệp vụ |
| `quantity` | Số nguyên dương, kiểm tra client ở mức định dạng; Exchange kiểm tra lot size |
| `submitting` | Khóa submit trong lúc request đang chờ |

### `DemoOrderViewModel`

Đại diện order cuối cùng do thao tác hiện tại tạo ra, gồm `orderId`, `brokerId`, `symbol`, `side`, `price`, `quantity`, `remainingQuantity`, `status` và `reason` nếu bị từ chối. Dữ liệu được đọc lại từ Exchange, không lấy trạng thái thành công chỉ từ response của form.

## State transitions

```text
idle -> submitting -> accepted -> pending -> cancelled
                         |          |
                         |          +-> partially-filled -> filled
                         +-> rejected
```

- `submitting`: vô hiệu hóa nút gửi để tránh thao tác lặp.
- `accepted`: lưu `orderId`, sau đó lấy status nếu cần.
- `rejected`: giữ form để người dùng sửa; hiển thị reason an toàn.
- `pending`: cho phép hủy đúng order/broker.
- `cancelled` hoặc `filled`: không cho hủy lại; refresh bảng điện.
- `stale`: chỉ là trạng thái dữ liệu UI khi polling lỗi, không phải trạng thái nghiệp vụ của Exchange.

## Validation và bất biến

- Chỉ gửi `symbol = FXS` và broker nằm trong danh sách demo.
- Không submit khi thiếu side, price hoặc quantity, hoặc khi đang submit.
- Client validation chỉ cải thiện UX; mọi rule giá, tick, lot, price band và ownership vẫn do Exchange xác nhận.
- Không lưu token, `Authorization`, secret hoặc raw Problem Details vào model hiển thị.
