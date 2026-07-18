# MVP 16 — Market order và lệnh điều kiện

## Mục tiêu

Bổ sung các loại lệnh cơ bản ngoài limit order để mô phỏng đầy đủ hành vi giao dịch thực tế.

## Phạm vi

- Market order: khớp ngay ở giá tốt nhất hiện có trên sổ; nếu sổ trống một phần, phần còn lại bị huỷ (IOC mặc định) hoặc giữ lại tuỳ cấu hình.
- Stop order: được kích hoạt khi giá thị trường chạm ngưỡng stop, sau đó hoạt động như market hoặc limit order.
- Fill-or-Kill (FOK): toàn bộ hoặc không có gì; nếu không khớp đủ trong một lần, huỷ toàn bộ.
- Immediate-or-Cancel (IOC): khớp phần có thể, phần còn lại huỷ ngay.

## Quy tắc

- Market order ưu tiên khớp trước limit order ở cùng phía trong ATO/ATC.
- Stop order không hiển thị trên public order book cho đến khi được kích hoạt.
- FOK và IOC không để lại lệnh chờ trên sổ sau khi xử lý.

## Kịch bản demo

Đặt market order khi sổ mua có đủ khối lượng và quan sát khớp nhiều mức giá; đặt stop order rồi tiêm giá chạm ngưỡng để xem activation; gửi FOK không đủ khối lượng và xác nhận huỷ toàn bộ.

## Điều kiện hoàn thành

- Market order không còn lệnh chờ sau khi xử lý xong sổ.
- Stop order chỉ xuất hiện trong event stream sau khi được kích hoạt.
- Chưa có trailing stop, lệnh theo điều kiện phức tạp hay one-cancels-other (OCO).
