# Quickstart kiểm chứng MVP 04

## Chạy và build

```powershell
dotnet build flex-exchange-service/Flex.Exchange.sln --no-restore
dotnet test flex-exchange-service/Flex.Exchange.sln --no-build --no-restore
```

Cấu hình `open=10s`, `continuous=60s`, bật bot; chạy Exchange và frontend `/exchange`.

## Smoke flow

1. Gọi `POST /api/trading-session/start`; `GET /api/trading-session` phải lần lượt cho thấy `open`, `continuous`, `close`; start lần hai khi đang chạy trả `409`.
2. Mở `/exchange` ở hai tab; cả hai nhận snapshot qua `/hubs/market` và cập nhật bid/ask/trade trong tối đa 3 giây không reload.
3. Đặt lệnh đối ứng với bot; kiểm tra `TRADE_EXECUTED`, giá gần nhất và order book ở cả hai tab.
4. Chờ `close`; bot hủy lệnh trước, Exchange backstop hủy phần còn lại; lệnh mới bị reject và book không đổi.
5. Start ngày mới; book/trade tape trống, bot về reference price. Tắt/mở kết nối để kiểm tra reconnect và snapshot lại.

## Tiêu chí đạt

AC-001–AC-009 có test hoặc bằng chứng manual; không có hai session đồng thời và không có order tồn tại qua close. Ghi rõ mọi legacy test failure ngoài scope.
