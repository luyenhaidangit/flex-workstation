# MVP 05 — Một CTCK và kiểm tra trước giao dịch

## Mục tiêu

Đặt đúng ranh giới: nhà đầu tư chỉ giao dịch qua CTCK; CTCK kiểm tra trước khi route lệnh lên Exchange.

## Actor và dữ liệu

- Một `DemoBroker`, hai khách hàng và tài khoản giao dịch demo.
- Mỗi tài khoản có tiền khả dụng, CK khả dụng và phần đang phong tỏa.
- Broker giữ liên kết giữa lệnh khách hàng và `ExchangeOrderId`.

## Luồng mua/bán

1. Khách đặt lệnh tại Broker.
2. Broker kiểm tra tài khoản, phiên, tiền mua dự kiến hoặc CK bán khả dụng.
3. Broker phong tỏa tiền/CK dự kiến và gửi lệnh đến Exchange.
4. Broker nhận kết quả khớp/hủy; giải phóng phần phong tỏa phù hợp.

## Kịch bản demo

- Mua vượt sức mua và bán vượt CK bị từ chối tại Broker, không xuất hiện trên sổ lệnh Exchange.
- Lệnh hợp lệ được route và nhận kết quả khớp.

## Điều kiện hoàn thành

- Có audit link từ lệnh khách hàng tới lệnh Exchange.
- Số dư ở đây là trạng thái đơn giản; chưa có ledger double-entry, margin hay settlement T+.
