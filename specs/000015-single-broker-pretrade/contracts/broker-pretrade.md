# Contract Broker pre-trade

Base path: `/api/broker`. JSON camelCase. Business rejection trả HTTP `200` với `accepted: false` theo convention Exchange; malformed request `400`, unknown resource `404`, unexpected failure là Problem Details có `correlationId`.

## POST `/api/broker/orders`

Request:

```json
{
  "clientOrderId": "client-order-001",
  "accountId": "demo-account-1",
  "symbol": "FXS",
  "side": "Buy",
  "price": 20000,
  "quantity": 100
}
```

Accepted response có `accepted: true`, `clientOrderId`, `accountId`, `status`, `exchangeOrderId`, `reservation`, `reason: null`, `correlationId`.

Rejected response có `accepted: false`, `status: Rejected`, `exchangeOrderId: null`, `reservation: null`, `reason` và `correlationId`.

Reject reasons tối thiểu: `InvalidAccount`, `InvalidOrder`, `SessionClosed`, `InsufficientBuyingPower`, `InsufficientSecurities`, `DuplicateClientOrderId`, `IdempotencyConflict`, `ExchangeRejected`, `PendingExchangeConfirmation`.

## GET `/api/broker/orders/{clientOrderId}`

Trả account, order fields, status, `exchangeOrderId` nếu có, reservation summary, reject reason và audit entries. Không trả resource của account khác.

## DELETE `/api/broker/orders/{clientOrderId}`

Hủy phần còn lại qua Broker. Thành công trả `Cancelled` và reservation còn lại bằng zero; hủy lặp lại không release lần hai.

## GET `/api/broker/accounts/{accountId}`

Trả `accountId`, `customerId`, `symbol`, `cashAvailable`, `cashReserved`, `securityAvailable`, `securityReserved`.

## Compatibility

`/api/orders` và market-data endpoints không đổi. Investor flow MVP 5 phải dùng `/api/broker/*`; direct Exchange order không được coi là Broker order.
