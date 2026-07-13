# MVP 01 — Quy tắc khớp lệnh và order book

## Mục tiêu

Tạo lõi Exchange có kết quả khớp xác định được: cùng tập lệnh đầu vào luôn cho cùng order book và danh sách giao dịch đầu ra.

## Actor và phạm vi

- Người gửi lệnh là `DemoBroker`; chưa có người dùng hay CTCK thật.
- Chỉ một mã cổ phiếu giả lập, một phiên `continuous` và limit order mua/bán.
- Lệnh gồm mã, chiều mua/bán, giá, khối lượng, thời điểm và `BrokerId`.

## Quy tắc nghiệp vụ

- Giá và khối lượng phải hợp lệ theo bước giá, biên độ và lô chẵn cấu hình.
- Bên mua ưu tiên giá cao hơn; bên bán ưu tiên giá thấp hơn.
- Cùng giá, lệnh đến trước được ưu tiên trước.
- Lệnh có thể khớp một phần; phần còn lại nằm trong order book cho tới khi hủy hoặc hết phiên.
- Giá khớp là giá của lệnh đang chờ trong sổ lệnh.

## Kịch bản demo

1. Đặt bán 100 FXS giá 20.000, rồi mua 100 FXS giá 20.000.
2. Quan sát một `TradeExecuted`, hai lệnh hoàn tất và order book rỗng.
3. Lặp lại với mua 200 để thấy một lệnh khớp hết, một lệnh khớp một phần.

## Điều kiện hoàn thành

- Có test cho không khớp, khớp toàn phần, khớp một phần, ưu tiên giá, ưu tiên thời gian và hủy lệnh.
- Không có API, database, UI, WebSocket, bot hay kiểm tra số dư.

## Đầu ra cho MVP 02

`PlaceOrder`, `CancelOrder`, `OrderAccepted`, `OrderRejected`, `TradeExecuted`, `OrderCancelled` và snapshot order book.
