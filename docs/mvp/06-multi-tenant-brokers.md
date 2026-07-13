# MVP 06 — Nhiều CTCK tenant

## Mục tiêu

Chứng minh nhiều CTCK dùng chung Exchange nhưng dữ liệu vận hành của họ bị cô lập.

## Phạm vi

- Hai tenant: Alpha và Beta; mỗi tenant có khách hàng, tài khoản, lệnh và cấu hình phí riêng.
- Mọi dữ liệu thuộc Broker có `TenantId`; tenant được xác định từ đăng nhập hoặc API key demo.
- Exchange chỉ nhận `BrokerId` và có thể khớp lệnh giữa Alpha với Beta.

## Quy tắc cô lập

- Alpha không truy vấn, sửa hoặc nhận thông báo về khách hàng/số dư/báo cáo nội bộ của Beta.
- Exchange chỉ phát kết quả lệnh về đúng broker đã gửi lệnh.
- Market data công khai không mang dữ liệu định danh khách hàng.

## Kịch bản demo

Khách Alpha mua khớp với Beta bán. Cả hai thấy giao dịch của mình; truy vấn bằng phiên Alpha tới dữ liệu Beta bị từ chối.

## Điều kiện hoàn thành

- Có test cô lập tenant ở API và truy vấn dữ liệu.
- Dùng shared schema + `TenantId`; chưa tách database theo tenant.
