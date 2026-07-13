# MVP 02 — Exchange API và nhật ký sự kiện

## Mục tiêu

Đưa matching engine thành dịch vụ có thể gọi, quan sát và replay ở mức cơ bản.

## Phạm vi

- API đặt lệnh, hủy lệnh, xem trạng thái lệnh, order book và trade tape.
- Ghi event theo thứ tự cho mỗi lệnh và mỗi giao dịch.
- Mọi request có `BrokerId`; Exchange chưa xác thực tài khoản khách hàng.

## Luồng chính

1. Gateway gửi `PlaceOrder`.
2. Exchange kiểm tra quy tắc giao dịch của MVP 01.
3. Exchange sinh sự kiện chấp nhận/từ chối, rồi có thể sinh sự kiện khớp.
4. Gateway truy vấn được trạng thái và lịch sử theo `OrderId`.

## Kịch bản demo

Gửi hai lệnh đối ứng qua API; lấy `OrderId`; xem event stream chứa chấp nhận, khớp và trạng thái cuối của lệnh.

## Điều kiện hoàn thành

- Request lỗi không làm thay đổi order book.
- Event có `EventId`, thời điểm, `OrderId`, `BrokerId` và correlation id.
- Chưa có database nghiệp vụ đầy đủ, UI, phân quyền hay kiểm tra tiền/CK.
