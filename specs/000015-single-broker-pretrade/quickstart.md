# Quickstart validation: Một CTCK và kiểm tra trước giao dịch

## Prerequisites

- .NET SDK `9.0.308` hoặc tương thích.
- Repo `flex-exchange-service` tại `../../flex-exchange-service`.
- Port `5266` không bị chiếm.

## Build và test

```powershell
cd flex-exchange-service
dotnet restore Flex.Exchange.sln
dotnet build Flex.Exchange.sln --configuration Release
dotnet test Flex.Exchange.sln --configuration Release
```

## Chạy service

```powershell
dotnet run --project src/Flex.Exchange.Api/Flex.Exchange.Api.csproj --launch-profile http
```

Service mặc định chạy tại `http://localhost:5266`.

## Kịch bản kiểm tra

1. Mở Swagger hoặc `src/Flex.Exchange.Api/Flex.Exchange.http`.
2. Gọi `GET /api/broker/accounts/demo-account-1`; xác nhận số dư available/reserved ban đầu.
3. Gửi buy vượt tiền; xác nhận `accepted: false`, reason `InsufficientBuyingPower`, `exchangeOrderId: null`.
4. Gửi sell vượt CK; xác nhận reason `InsufficientSecurities` và Exchange book không đổi.
5. Gửi lệnh hợp lệ với `clientOrderId` mới; xác nhận reservation, `exchangeOrderId` và status link.
6. Gửi lại cùng payload/id; xác nhận không tạo Exchange order thứ hai.
7. Tạo full/partial fill; xác nhận account và reservation giảm đúng phần đã xử lý.
8. Hủy phần còn lại; xác nhận `Cancelled`, reservation zero và available balance được hoàn trả.
9. Query Broker order; xác nhận audit sequence có pre-trade, reserve, route, fill/cancel và correlation id.

## Expected outcomes

- Reject pre-trade không tạo Exchange order hoặc thay đổi Exchange order book.
- Lệnh hợp lệ có liên kết `ClientOrderId` ↔ `ExchangeOrderId`.
- `available + reserved` nhất quán qua reserve/fill/cancel.
- Retry idempotent không tạo duplicate order/reservation.
- Test MVP 1-4 vẫn pass.

Contract: [contracts/broker-pretrade.md](contracts/broker-pretrade.md). Entity/invariant: [data-model.md](data-model.md).
