# MVP 03 — Bảng điện demo

## Mục tiêu

Cho người xem quan sát thị trường và tự tạo giao dịch mà không đọc log kỹ thuật.

## Phạm vi

- Một trang web cho một mã FXS.
- Hiển thị giá gần nhất, năm mức mua/bán tốt nhất, khối lượng chờ và trade tape.
- Form đặt/hủy lệnh cho hai tài khoản demo; dữ liệu có thể cập nhật bằng polling.

## Luồng người dùng

1. Chọn tài khoản demo, chiều lệnh, giá và khối lượng.
2. Gửi lệnh; màn hình hiện trạng thái chấp nhận hoặc từ chối.
3. Khi có lệnh đối ứng, price, trade tape và order book đổi theo kết quả Exchange.

## Điều kiện hoàn thành

- Người không đọc log vẫn chỉ ra được lệnh nào đang chờ và giao dịch nào vừa khớp.
- Refresh trang không làm mất dữ liệu từ API.
- Chưa có đăng nhập, portfolio, biểu đồ hoặc responsive/mobile hoàn chỉnh.
