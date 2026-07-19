# Mô hình dữ liệu: Một CTCK và kiểm tra trước giao dịch

Các entity đều là Application in-memory state; không có schema, migration hoặc persistence contract.

## DemoAccount

`AccountId`, `CustomerId`, `CashAvailable`, `CashReserved`, `SecurityAvailable`, `SecurityReserved`, `Symbol`.

Invariant: giá trị không âm; account chỉ giao dịch symbol được cấp; available/reserved nhất quán sau mỗi transition.

## BrokerOrder

`ClientOrderId`, `AccountId`, `CustomerId`, `BrokerId`, `Symbol`, `Side`, `Price`, `OriginalQuantity`, `FilledQuantity`, `RemainingQuantity`, `Status`, `RejectReason`, `CreatedAt`, `UpdatedAt`.

Status: `PendingPreTrade`, `Rejected`, `PendingExchangeConfirmation`, `Accepted`, `PartiallyFilled`, `Filled`, `Cancelled`.

Invariant: filled + remaining = original; rejected-before-route không có Exchange link; một client id không map hai Exchange order.

## Reservation

`ReservationId`, `ClientOrderId`, `AccountId`, `Side`, `ReservedCash`, `ReservedQuantity`, `ConsumedCash`, `ConsumedQuantity`, `ReleasedCash`, `ReleasedQuantity`, `Status`.

Transition: `Active → PartiallyReleased → Released` hoặc `Active → Released`.

## OrderLink

`ClientOrderId`, `ExchangeOrderId`, `AccountId`, `BrokerId`, `CorrelationId`, `LinkedAt`, `ExchangeStatus`.

Chỉ tạo sau khi Exchange accepted.

## BrokerAuditEntry

`Sequence`, `ClientOrderId`, `ExchangeOrderId?`, `AccountId`, `Type`, `Reason?`, `OccurredAt`, `CorrelationId`.

Type: `PreTradeChecked`, `Rejected`, `Reserved`, `Routed`, `FillApplied`, `Cancelled`, `ReservationReleased`, `PendingExchangeConfirmation`.

## Validation/invariant

- Buy: `price × quantity <= CashAvailable` sau khi trừ cash reserved.
- Sell: `quantity <= SecurityAvailable` sau khi trừ security reserved.
- Session phải nhận lệnh trước khi reserve.
- `clientOrderId` bắt buộc và unique trong account/session.
- Account/customer ownership phải được xác minh trước khi đọc/mutate.
- Fill/cancel duplicate không được release lần hai.
