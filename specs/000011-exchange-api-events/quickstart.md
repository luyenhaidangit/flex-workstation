# Quickstart validation — Exchange API và nhật ký sự kiện

## Phạm vi

Xác nhận luồng từ đặt lệnh đến tra cứu order status, order book, trade tape và event history. Chạy trong `flex-exchange-service`; không cần database hay service bên ngoài.

## Chuẩn bị

```powershell
cd C:\Workspace\Project\flex-workstation\flex-exchange-service
dotnet restore Flex.Exchange.sln
dotnet build Flex.Exchange.sln --configuration Release
```

## Chạy service

```powershell
dotnet run --project src/Flex.Exchange.Api/Flex.Exchange.Api.csproj --launch-profile http
```

Swagger được bật ở Development theo URL HTTP trong `launchSettings.json`.

## Luồng smoke test

1. Gửi lệnh bán `BrokerA`, 100 FXS @20.000 và ghi `OrderId`/`CorrelationId`.
2. Gửi lệnh mua `BrokerB`, 100 FXS @20.000.
3. Xác nhận response có `OrderAccepted` và `TradeExecuted`.
4. Tra cứu từng `OrderId`, xác nhận trạng thái cuối và broker đúng.
5. Tra cứu order book, xác nhận hai phía rỗng sau khớp toàn phần.
6. Tra cứu trade tape, xác nhận giá passive order, khối lượng và thứ tự.
7. Tra cứu event history của mỗi order, xác nhận `EventId`, `EventSequence`, `OccurredAt`, `BrokerId`, `CorrelationId`.
8. Gửi lệnh sai tick/quantity hoặc thiếu `BrokerId`, xác nhận rejection không đổi order book.
9. Khởi động lại service, chạy lại cùng chuỗi và so sánh projection nghiệp vụ/event sequence.

Chi tiết route/payload nằm trong [contracts](contracts/).

## Automated validation

```powershell
dotnet test Flex.Exchange.sln --configuration Release
```

Bộ test phải bao phủ domain invariants, API integration, JSON contract, correlation/event ordering, order lookup, trade tape, rejection side effect và health endpoint.

## Rollback smoke check

Nếu release mới làm lệch contract hoặc matching, dừng traffic demo, quay về build trước đó, chạy lại smoke flow và so sánh baseline MVP 01. Không có migration cần rollback.
