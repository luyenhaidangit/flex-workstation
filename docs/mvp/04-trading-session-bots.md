# MVP 04 — Phiên giao dịch, realtime và bot

## Mục tiêu

Làm thị trường ảo có thanh khoản và vòng đời phiên rõ ràng.

## Phạm vi

- Day cycle `open → continuous → close`, cấu hình được thời lượng ngày ảo.
- WebSocket phát thay đổi order book, trade và trạng thái phiên.
- Một market-maker bot gửi giá mua/bán hai chiều qua `DemoBroker`.

## Quy tắc

- Chỉ nhận lệnh mới trong `continuous`; có thể cho phép hủy lệnh khi đóng phiên theo rule đã chốt.
- Bot không gọi matching engine trực tiếp; bot là nhà đầu tư mô phỏng đi qua broker/gateway.
- `close` chỉ đóng giao dịch, chưa tạo clearing hoặc settlement.

## Kịch bản demo

Khởi động ngày ảo, mở bảng điện ở hai trình duyệt, quan sát giá realtime, đặt lệnh khớp với bot và đóng phiên để thấy lệnh mới bị từ chối.

## Điều kiện hoàn thành

- Kết thúc MVP có demo độc lập của Phase A.
- ATO/ATC, nhiều loại bot, CTCK tenant, ledger và T+ đều để sau.
