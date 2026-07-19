# Data model: Persistence foundation MVP 01–08

| Domain | Entity | Quan hệ/invariant |
|---|---|---|
| `exchange` — HoSE/HNX | Instrument, TradingSession, Order, OrderHistory, Trade, Outbox | Trade tham chiếu hai order; phát `TradeExecuted` bằng external IDs. |
| `broker` — CTCK | Customer, TradingAccount, Reservation, Inbox, Outbox | Database đại diện một CTCK; reservation dùng external order/trade reference và idempotent theo source. |
| `vsd` — VSD | Journal, Entry, Balance, SettlementObligation, EodStatement, ReconciliationResult, Alert, Inbox, Audit | VSD lưu external trade/account reference; journal/audit append-only. |

Mọi entity có scope phù hợp, source reference, correlation và timestamp UTC. Tiền/quantity dùng decimal chính xác. Foreign key chỉ tồn tại trong cùng database; liên kết xuyên tổ chức dùng external IDs và contract. `Audit` của VSD ghi các thao tác replay, settlement, reconciliation và alert.
