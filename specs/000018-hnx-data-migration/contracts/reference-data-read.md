# MVP 1 Exchange persistence contract

## Public contract

Các exchange endpoints hiện có tiếp tục giữ route, status code và payload shape. FE không cần biết dữ liệu được đọc từ in-memory hay PostgreSQL.

## Persistence behavior

- `exchange_orders` là nguồn trạng thái hiện tại của order.
- `exchange_trades` là nguồn kết quả khớp bất biến.
- Open order query dựng order book theo price-time priority.
- Một matching operation phải atomic giữa order updates và trade insert.
- Restart phải khôi phục open orders từ DB.

## Scope

Contract này chỉ áp dụng cho HNX, `CONTINUOUS`, `LIMIT`, `BUY`/`SELL` trong MVP 1. Không bao gồm order history, outbox, account hoặc settlement.
