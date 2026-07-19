# Data model: Persistence foundation MVP 01–08

| Domain | Entity | Quan hệ/invariant |
|---|---|---|
| Reference | Instrument, TradingSession | Được order/trade tham chiếu. |
| Exchange | Order, OrderHistory, Trade | Trade tham chiếu đúng hai order và broker; history có sequence. |
| Broker | Broker, Customer, TradingAccount, Reservation | Reservation tham chiếu account và order/trade, idempotent theo source. |
| Ledger | Journal, Entry, Balance, Inbox, Outbox, Audit | Journal/audit append-only; entry cân bằng; balance là projection. |
| Post-trade | SettlementObligation, EodStatement, ReconciliationResult, Alert | Obligation tham chiếu trade/account/journal; alert không sửa source. |

Mọi entity operational có tenant/broker scope, source reference, correlation khi có và timestamp UTC. Tiền/quantity dùng decimal chính xác. Migration chỉ thêm schema; không backfill dữ liệu ngoài.
