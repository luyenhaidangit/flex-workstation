# MVP 22 — FIX protocol gateway

## Mục tiêu

Cho phép client bên ngoài dùng giao thức FIX tiêu chuẩn kết nối vào FlexSim thay vì gọi REST API trực tiếp, mở ra khả năng tích hợp với công cụ giao dịch thật.

## Phạm vi

- FIX gateway nhận FIX 4.2 message và dịch sang Exchange REST/internal API.
- Hỗ trợ message types: Logon (35=A), NewOrderSingle (35=D), OrderCancelRequest (35=F), ExecutionReport (35=8).
- Phát ExecutionReport ngược về client khi có acceptance, rejection, fill hoặc cancel.
- Mô phỏng latency cấu hình được và session management (heartbeat, disconnect).
- Một FIX session tương ứng một BrokerId trong hệ thống.

## Quy tắc

- Gateway không thay đổi business logic — chỉ là adapter protocol; matching engine không biết message đến từ FIX hay REST.
- CompID trong FIX session map 1-1 với BrokerId.
- Message không hợp lệ về cấu trúc FIX trả Business Reject (35=j) trước khi vào domain.

## Kịch bản demo

Kết nối QuickFIX client hoặc script FIX test; gửi NewOrderSingle; nhận ExecutionReport xác nhận; gửi lệnh đối ứng qua REST và xem ExecutionReport fill được phát về FIX client.

## Điều kiện hoàn thành

- Round-trip từ FIX NewOrderSingle đến ExecutionReport hoạt động đúng với các scenario cơ bản.
- Mọi lệnh qua FIX đều xuất hiện trong event log giống lệnh qua REST.
- Chưa hỗ trợ FIX 5.0, multicast market data hay co-location simulation đầy đủ.
