# Research: Persist MVP 1 Matching Engine bằng DB

## Phạm vi khảo sát

- `flex-exchange-service`: matching rules, order book và các state hiện đang in-memory.
- `flex-database/hnx`: Liquibase migrations hiện có cho `exchange_instruments`, `exchange_orders`, `exchange_order_history`, `exchange_trades`, `exchange_outbox`.
- `flex-microfrontend`: exchange API consumers cần giữ contract.

## Quyết định

### TQ-001 — Bảng nào thuộc MVP 1?

Chỉ dùng `exchange_instruments`, `exchange_sessions`, `exchange_orders`, `exchange_trades`. Không tạo `exchange_order_history`, `exchange_outbox` hoặc bảng `exchange_order_book` riêng.

### TQ-002 — Order book lưu thế nào?

Không lưu snapshot riêng. Dựng order book từ các order chưa `FILLED`/`CANCELLED` với `remaining_quantity > 0`, sắp xếp price-time ở query/service.

### TQ-003 — Transaction boundary?

Một matching operation phải cập nhật buy order, sell order và insert trade trong cùng database transaction.

### TQ-004 — Persistence boundary?

Application định nghĩa focused ports; Infrastructure dùng Npgsql. Không thêm generic repository hoặc database-specific type vào Application.

### TQ-005 — Migration safety?

Liquibase forward-only, changeset mới không sửa changeset đã chạy. Seed instrument/session idempotent. Không dùng destructive rollback.

## Kết luận

MVP 1 là một vertical slice DB-backed cho matching engine. Các nghiệp vụ order history, event delivery, account/balance và settlement sẽ được tách thành feature sau.

