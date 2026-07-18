# MVP 14 — Đa mã chứng khoán và chỉ số

## Mục tiêu

Mở rộng Exchange từ một mã FXS thành nhiều mã giao dịch song song, và tính chỉ số thị trường tổng hợp theo vốn hoá.

## Phạm vi

- Exchange quản lý nhiều order book độc lập, mỗi mã có tham số riêng: lot size, giá tham chiếu, biên độ, số lượng cổ phiếu niêm yết.
- Chỉ số FXI tính theo phương pháp vốn hoá có điều chỉnh free-float đơn giản; cập nhật sau mỗi giao dịch.
- Bot market-maker chạy song song cho nhiều mã độc lập nhau.
- API order book và trade tape phân biệt theo symbol.

## Quy tắc

- Mỗi order book độc lập; khớp lệnh của mã A không ảnh hưởng mã B.
- Chỉ số FXI được snapshot theo chu kỳ và lưu intraday history.
- Thêm/bỏ mã chỉ cần cấu hình không cần deploy lại.

## Kịch bản demo

Khởi động session với ba mã FXS, FXA, FXB; giao dịch song song; quan sát chỉ số FXI biến động khi mã có vốn hoá lớn thay đổi giá; xem order book riêng từng mã.

## Điều kiện hoàn thành

- FXI được tính đúng và cập nhật liên tục sau mỗi trade.
- Không có shared state giữa các order book; test xác nhận isolation.
- Chưa có niêm yết mới (IPO), huỷ niêm yết hay tách/gộp mã.
