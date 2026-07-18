# Mô hình dữ liệu

## TradingSession

`SessionId: Guid`, `Symbol: string` (FXS), `State: Open|Continuous|Close`, `StartedAt`, `ContinuousStartedAt?`, `ClosedAt?`, `OpenDuration`, `ContinuousDuration`. Transition duy nhất: `None → Open → Continuous → Close → None`; chỉ một session active.

## MarketMakerOptions

`ReferencePrice`, `SpreadTicks`, `Quantity`, `CycleInterval`, `BrokerId`, `Symbol`; validate > 0 và configurable, không hardcode.

## MarketEvent

`Type`, `EventSequence`, `OccurredAt`, `SessionId`, `Symbol`, `Payload`, `CorrelationId?`. Type gồm `MARKET_SNAPSHOT`, `SESSION_STATE_CHANGED`, `ORDER_BOOK_CHANGED`, `TRADE_EXECUTED`. Event chỉ broadcast, không persistence.

## Invariants

Chỉ `continuous` nhận lệnh mới; close phải graceful-cancel bot rồi backstop-cancel mọi remaining order; session mới reset order book/trade tape.
