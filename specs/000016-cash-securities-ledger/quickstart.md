# Quickstart kiểm chứng MVP 7

## Prerequisites

- .NET 9 SDK.
- Repo `flex-exchange-service` build được.
- Chạy API ở `http://localhost:5266` với `Ledger:Enabled=true` và seed Alpha/Beta.

## 1. Build và test

```powershell
cd flex-exchange-service
dotnet test Flex.Exchange.sln --configuration Release
```

Kỳ vọng: toàn bộ test hiện có và test Ledger pass.

## 2. Seed và kiểm tra opening balance

Gọi `GET /api/broker/ledger/accounts/{accountId}?tenantId=alpha`. Kỳ vọng balance có `available` theo opening journal, các bucket khác bằng 0 và `asOfJournalSequence` tăng.

## 3. Reserve và fill Alpha/Beta

Tạo lệnh mua Alpha và bán Beta qua endpoint Broker hiện có trong `Flex.Exchange.http`, để Exchange tạo `TradeExecuted`. Sau đó gọi balance cho hai account.

Kỳ vọng:

- Mỗi phía có journal `Fill` cân bằng.
- Tài sản vừa khớp chưa trở thành `available`; bucket phải thu/phải trả phản ánh transition.
- Phí xuất hiện trong journal của bên phát sinh giao dịch.

## 4. Trace

Gọi `GET /api/broker/ledger/trace/{sourceReference}?tenantId=alpha`. Đối chiếu `journalId`, event nguồn, debit/credit và balance delta với order/trade.

## 5. Retry và permission

- Gửi lại cùng `TradeExecuted.EventId`; entry count và balance không đổi.
- Gọi trace/account bằng `tenantId=beta` cho source Alpha; kỳ vọng `403/404` và không có dữ liệu ngoài scope.

## 6. Cân bằng và rollback smoke

- Kiểm tra mọi journal có tổng debit bằng tổng credit.
- Tắt `Ledger:Enabled`, restart và xác nhận Broker/Exchange endpoint cũ vẫn hoạt động; ledger reset đúng giới hạn in-memory.
