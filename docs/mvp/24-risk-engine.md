# MVP 24 — Risk engine thời gian thực

## Mục tiêu

Tính toán và phát cảnh báo rủi ro danh mục theo thời gian thực, phục vụ kiểm soát rủi ro tại CTCK và giám sát toàn thị trường.

## Phạm vi

- VaR (Value at Risk) đơn giản hoá theo phương pháp lịch sử: dùng chuỗi giá đóng cửa của các mã để ước lượng mức thua lỗ tối đa với độ tin cậy 95% trong một ngày.
- Tính VaR theo danh mục cho từng tài khoản; alert khi VaR vượt ngưỡng cấu hình.
- Stress test scenario: admin tiêm một cú giảm giá mô phỏng (ví dụ −15% tất cả mã) và xem margin call lan rộng.
- Concentration risk: cảnh báo khi một mã chiếm hơn X% giá trị danh mục.
- Dashboard tổng hợp rủi ro toàn thị trường cho vai trò giám sát.

## Quy tắc

- VaR là chỉ số ước lượng, không phải đảm bảo; kết quả đính chuỗi dữ liệu nguồn để audit.
- Stress test chỉ tính toán; không tự kích hoạt margin call hay force-sell.
- Dữ liệu lịch sử tối thiểu 30 ngày ảo mới tính VaR có ý nghĩa.

## Kịch bản demo

Chạy 30 ngày ảo với dữ liệu giao dịch; xem VaR của từng danh mục; tiêm scenario giảm 15%; quan sát danh sách tài khoản vượt ngưỡng và magnitude từng tài khoản.

## Điều kiện hoàn thành

- VaR tính đúng từ chuỗi giá lịch sử thực tế trong hệ thống.
- Stress test không làm thay đổi trạng thái thị trường thật.
- Chưa có Monte Carlo, Expected Shortfall (CVaR), cross-asset correlation nâng cao hay model risk.
