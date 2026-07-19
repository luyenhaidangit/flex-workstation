# Research: Persistence foundation MVP 01–08

## R-001 — Boundary persistence
**Decision**: `flex-exchange-service` sở hữu persistence state Exchange/Broker; `flex-database` chỉ sở hữu migration/seed.
**Rationale**: Khớp ownership MVP 01–08, không tạo service mới.
**Alternatives considered**: Ledger database độc lập bị loại vì mất source order/trade.

## R-002 — Thứ tự migration
**Decision**: reference/order/trade → account/reservation → ledger → settlement/reconciliation.
**Rationale**: Mọi record bước sau cần tham chiếu nguồn bước trước.
**Alternatives considered**: Tạo toàn bộ schema ledger trước bị loại vì không trace được nguồn.

## R-003 — Restore
**Decision**: Rehydrate state nghiệp vụ từ lịch sử có sequence và dùng backup/restore staging cho recovery.
**Rationale**: Giữ deterministic lifecycle và không chỉnh sửa lịch sử.
