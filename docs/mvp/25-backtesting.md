# MVP 25 — Back-testing framework

## Mục tiêu

Cho phép replay lại dữ liệu thị trường lịch sử để đánh giá hiệu quả chiến lược giao dịch mà không ảnh hưởng đến thị trường thật đang chạy.

## Phạm vi

- Lưu event stream đầy đủ của Exchange (order, trade, cancellation) với timestamp.
- Back-test runner: chạy lại event stream theo thứ tự thời gian trong môi trường sandbox riêng biệt.
- Chiến lược đơn giản: interface nhận market event, ra quyết định đặt/hủy lệnh, nhận kết quả.
- Tính PnL, số lệnh khớp, win rate, max drawdown và Sharpe ratio rút gọn cho mỗi lần chạy.
- So sánh kết quả nhiều chiến lược trên cùng tập dữ liệu.

## Quy tắc

- Back-test không gửi lệnh vào Exchange đang chạy; chạy hoàn toàn isolated.
- Replay đảm bảo thứ tự sự kiện đúng như lịch sử; không look-ahead bias.
- Slippage model đơn giản: fill theo giá tốt nhất có trong event stream tại thời điểm đó.

## Kịch bản demo

Thu thập dữ liệu 30 ngày ảo; chạy chiến lược moving-average crossover đơn giản; xem PnL curve và các metrics; so sánh với chiến lược random và buy-and-hold.

## Điều kiện hoàn thành

- Cùng dữ liệu + cùng chiến lược luôn cho kết quả giống nhau (deterministic).
- PnL tính đúng sau khi trừ phí giao dịch mô phỏng.
- Chưa có walk-forward optimization, genetic algorithm hay live paper trading.
