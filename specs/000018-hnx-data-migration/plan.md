# Kế hoạch triển khai: Persist MVP 1 Matching Engine bằng DB

**Branch**: `000018-hnx-data-migration` | **Ngày**: 2026-07-20 | **Đặc tả**: [spec.md](spec.md)

## Tóm tắt

MVP 1 chuyển trạng thái matching engine từ in-memory sang PostgreSQL, giữ nguyên public FE/BE contract và chỉ triển khai bốn bảng lõi: `exchange_instruments`, `exchange_sessions`, `exchange_orders`, `exchange_trades`.

## Phạm vi kỹ thuật

**Trong phạm vi**:
- Liquibase schema/seed cho bốn bảng trong `flex-database/hnx`.
- Application ports và PostgreSQL adapters trong `flex-exchange-service`.
- Transactional matching, cancel order và order-book reconstruction.
- FE/API regression và restart/concurrency tests.

**Ngoài phạm vi**:
- `exchange_order_history`, `exchange_outbox`, account, balance, fee, settlement.
- `exchange_order_book` riêng; order book là dữ liệu dẫn xuất.
- Nhiều market/session/instrument ngoài phạm vi seed MVP 1.

## Thiết kế

- `exchange_instruments`: instrument HNX.
- `exchange_sessions`: phiên `CONTINUOUS` và trạng thái mở/đóng.
- `exchange_orders`: trạng thái hiện tại của order và khối lượng còn lại.
- `exchange_trades`: trade immutable được tạo bởi matching.
- Không dùng generic repository; dùng focused ports/adapters.
- Matching operation cập nhật order và insert trade trong cùng transaction.
- Open order query dùng `instrument_id`, `session_id`, `status`, `side`, `price` và thời gian accepted để dựng price-time priority.
- Dùng Liquibase forward-only; không sửa changeset đã chạy.

## Tương thích API

Không đổi route, status code hoặc payload của các exchange endpoints hiện có. Thay đổi chỉ nằm ở persistence phía sau service.

## Kiểm thử

- Schema, foreign key, unique constraint, seed idempotency.
- No-match, full-match, partial-match, price priority, time priority, cancel.
- Transaction atomicity, concurrent opposite orders và duplicate protection.
- Restart recovery của open orders/trades.
- Backend integration và frontend contract regression.

## Rollout

1. Validate/update-sql Liquibase và seed instrument/session.
2. Deploy BE đọc/ghi DB với smoke test.
3. Kiểm tra matching, cancel và restart recovery.
4. Chỉ khi pass acceptance mới loại bỏ code path in-memory theo task riêng; không xóa trong MVP này nếu chưa có bằng chứng.

## Constitution gate

| Gate | Trạng thái | Ghi chú |
|---|---|---|
| Scope | Pass | Chỉ MVP 1 và bốn bảng |
| Compatibility | Pass | Không đổi public contract |
| Data safety | Pass | Transaction, uniqueness, forward-only migration |
| Test | Pass | Có schema, matching, restart và concurrency tests |
| Security | Pass | Không log secret/connection string |

