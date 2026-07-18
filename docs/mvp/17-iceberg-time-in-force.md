# MVP 17 — Lệnh iceberg và thời lực lệnh

## Mục tiêu

Mô phỏng các chiến lược ẩn khối lượng và kiểm soát thời hạn sống của lệnh để phản ánh hành vi tổ chức thực tế.

## Phạm vi

- Iceberg order: chỉ hiển thị một phần (peak) trên public order book; sau mỗi lần khớp hết peak, phần ẩn (hidden) tự nạp thêm một peak mới vào cuối hàng đợi.
- Time-in-force GTC (Good Till Cancel): lệnh tồn tại qua nhiều phiên cho đến khi bị khớp hết hoặc bị huỷ chủ động.
- Time-in-force GTD (Good Till Date): tự động huỷ vào cuối ngày chỉ định nếu chưa khớp hết.
- Session-only (mặc định hiện tại): huỷ cuối phiên.

## Quy tắc

- Peak mới của iceberg lấy thứ tự sau cùng trong hàng đợi giá đó, không giữ ưu tiên thời gian ban đầu.
- GTC/GTD lệnh được lưu persistent qua restart; session-only lệnh không cần lưu.
- Phần hidden của iceberg không xuất hiện trong bất kỳ API public nào.

## Kịch bản demo

Đặt iceberg 1.000 CK, peak 100; quan sát order book chỉ thấy 100; sau khi một phía khớp hết peak, tự động xuất hiện 100 tiếp theo; xác nhận hidden volume không lộ trong snapshot.

## Điều kiện hoàn thành

- Hidden volume không bao giờ xuất hiện qua GET /api/orderbook.
- GTC lệnh tồn tại đúng qua phiên mới sau restart.
- Chưa có reserve iceberg (peak và hidden khác nhau per trade), chưa có lệnh theo giá trị tiền (value order).
