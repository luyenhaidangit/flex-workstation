# Ledger API contract

Các endpoint mới là additive; Broker/Exchange contract hiện tại không đổi.

## GET `/api/broker/ledger/accounts/{accountId}`

Query bắt buộc: `tenantId`; tùy chọn `assetCode`.

Response `200`:

```json
{
  "tenantId": "alpha",
  "accountId": "alpha-account-1",
  "balances": [
    { "assetType": "Cash", "assetCode": "VND", "available": 9800000, "reserved": 200000, "receivable": 0, "payable": 0 }
  ],
  "asOfJournalSequence": 12
}
```

`403` hoặc `404`: tenant/account không thuộc scope; response không tiết lộ existence ngoài scope.

## GET `/api/broker/ledger/trace/{sourceReference}`

Query bắt buộc: `tenantId`.

Response `200` gồm `journalId`, `tenantId`, `sourceReference`, `eventType`, `occurredAt`, `entries[]`, và `balanceDelta`.

`404`: source chưa tồn tại trong tenant; `403`: caller không có quyền tenant.

## POST `/api/broker/ledger/adjustments`

Chỉ operator demo được gọi; tạo journal `Adjustment` liên kết `reversalOfJournalId`, `reason`, `tenantId`, `accountId` và các entry cân bằng. Không cho sửa hoặc xóa journal gốc.

`409`: source reference hoặc reversal conflict; `422`: journal mất cân bằng/entry không hợp lệ.

## Internal ledger transition

`TradeExecuted` được map thành transition có `TenantId`, `SourceReference = EventId`, `EventType = Fill`, buy/sell account và fee metadata. Event lặp phải trả kết quả idempotent.

## Compatibility

`BrokerAccountSummary` và các endpoint `/api/broker/orders/*`, `/api/orders/*` giữ nguyên. Ledger endpoint không thay thế breaking trong MVP này.
