# MVP 15 — Biên độ giá và tạm dừng giao dịch

## Mục tiêu

Áp dụng quy tắc giới hạn giá và cơ chế tự động tạm dừng để mô phỏng cơ chế bảo vệ thị trường khi giá biến động bất thường.

## Phạm vi

- Giá trần/sàn tính từ giá tham chiếu theo biên độ cấu hình per-symbol (ví dụ ±7%).
- Lệnh vượt biên bị reject tại matching engine với lý do PriceOutOfRange.
- Circuit breaker theo symbol: Exchange tự tạm dừng mã nếu giá dịch chuyển quá ngưỡng trong khoảng thời gian ngắn.
- Admin có thể halt/resume một mã thủ công.
- Ngày đầu niêm yết mã mới áp dụng biên ±20%.

## Quy tắc

- Biên độ tính từ giá tham chiếu ngày; cập nhật lại sau ATC.
- Trong thời gian halt, lệnh mới bị từ chối; lệnh đang chờ trong sổ vẫn giữ nguyên.
- Circuit breaker reset sau khoảng thời gian cooling-off cấu hình được.

## Kịch bản demo

Đặt lệnh vượt giá trần; quan sát reject ngay. Tiêm biến động giá lớn để circuit breaker tự kích hoạt; xác nhận lệnh mới bị từ chối trong thời gian halt; resume và giao dịch trở lại bình thường.

## Điều kiện hoàn thành

- Lệnh vượt biên không bao giờ vào sổ lệnh.
- Circuit breaker log rõ nguyên nhân và thời gian kích hoạt.
- Chưa có biên độ intraday động hoặc VIX-style volatility pause.
