# MVP 23 — Market data feed phân tầng

## Mục tiêu

Phát market data theo các tầng dịch vụ khác nhau, mô phỏng mô hình kinh doanh data của sở giao dịch thật.

## Phạm vi

- Level 1 (L1): giá mua/bán tốt nhất và khối lượng, giá giao dịch gần nhất — công khai, không cần đăng ký.
- Level 2 (L2): năm bước giá cả hai chiều — cần subscription.
- Level 3 (L3): full order book depth, trade tape realtime — cần subscription cao hơn.
- Client đăng ký một hoặc nhiều kênh per symbol; nhận push qua WebSocket.
- Throttling per tier: L1 500ms, L2 200ms, L3 realtime.

## Quy tắc

- Client không có subscription L2 chỉ nhận L1 ngay cả khi request L2 endpoint.
- Snapshot đầy đủ gửi khi client kết nối; sau đó chỉ gửi delta.
- Ngắt kết nối và reconnect phải tự phục hồi từ snapshot mới.

## Kịch bản demo

Ba client kết nối với ba tier khác nhau; quan sát client L1 chỉ nhận top-of-book trong khi L3 thấy từng thay đổi trong sổ lệnh; throttle L1 rõ ràng so với L3 realtime.

## Điều kiện hoàn thành

- Client L2 không nhận được data của L3 và ngược lại.
- Snapshot + delta đảm bảo client luôn consistent sau reconnect.
- Chưa có multicast UDP, historical tick data hay market data licensing contract thật.
