# Research: Persistence foundation MVP 01–08

## R-001 — Boundary persistence
**Decision**: `flex-exchange-service` sở hữu persistence state Exchange/Broker; `flex-database` sở hữu Liquibase SQL-first changelog và seed local/test.
**Rationale**: Khớp ownership MVP 01–08, không tạo service mới.
**Alternatives considered**: Ledger database độc lập bị loại vì mất source order/trade.

## R-002 — Thứ tự migration
**Decision**: reference/order/trade → account/reservation → ledger → settlement/reconciliation.
**Rationale**: Mọi record bước sau cần tham chiếu nguồn bước trước.
**Alternatives considered**: Tạo toàn bộ schema ledger trước bị loại vì không trace được nguồn.

## R-003 — Database change management
**Decision**: PostgreSQL và Liquibase SQL-first, một master changelog cho database `exchange`, release changelog include SQL formatted changesets theo thứ tự tường minh.
**Rationale**: Tuân theo `docs/architecture/liquibase-sql-first.md`; giữ SQL reviewable, checksum/audit rõ và không chạy migration từ pod ứng dụng.
**Alternatives considered**: Flyway/MySQL bị loại theo quyết định kiến trúc hiện hành.

## R-004 — Restore
**Decision**: Rehydrate state nghiệp vụ từ lịch sử có sequence và dùng backup/restore staging cho recovery.
**Rationale**: Giữ deterministic lifecycle và không chỉnh sửa lịch sử.
