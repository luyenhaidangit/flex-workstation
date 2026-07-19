# Research: Persistence foundation MVP 01–08

## R-001 — Boundary persistence
**Decision**: Ba boundary data độc lập: `exchange` (HoSE/HNX), `broker` (CTCK), `vsd` (VSD); `flex-database` sở hữu Liquibase SQL-first changelog/seed.
**Rationale**: Khớp ownership mô phỏng, tránh shared database và tránh VSD đọc trực tiếp dữ liệu CTCK/Sở.
**Alternatives considered**: Một database `exchange` bị loại vì trộn ownership tổ chức.

**Assumption**: Mỗi database `broker` đại diện cho một CTCK; `brokerId` là business identity/configuration, không cần bảng `Broker` trong schema CTCK.

## R-002 — Thứ tự migration
**Decision**: reference/order/trade → account/reservation → ledger → settlement/reconciliation.
**Rationale**: Mọi record bước sau cần tham chiếu nguồn bước trước.
**Alternatives considered**: Tạo toàn bộ schema ledger trước bị loại vì không trace được nguồn.

## R-003 — Database change management
**Decision**: PostgreSQL và Liquibase SQL-first, một master changelog cho mỗi database `exchange`, `broker`, `vsd`.
**Rationale**: Tuân theo `docs/architecture/liquibase-sql-first.md`; giữ SQL reviewable, checksum/audit rõ và không chạy migration từ pod ứng dụng.
**Alternatives considered**: Flyway/MySQL bị loại theo quyết định kiến trúc hiện hành.

## R-004 — Liên kết xuyên tổ chức
**Decision**: Dùng external business IDs, correlation và outbox/inbox; không dùng foreign key hoặc transaction xuyên database.
**Rationale**: Database độc lập phải có autonomy; trace vẫn xây dựng được từ contract.
**Alternatives considered**: Join/shared schema bị loại vì phá ranh giới HoSE/HNX, CTCK và VSD.

## R-005 — Restore
**Decision**: Rehydrate state nghiệp vụ từ lịch sử có sequence và dùng backup/restore staging cho recovery.
**Rationale**: Giữ deterministic lifecycle và không chỉnh sửa lịch sử.
