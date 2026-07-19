# Persistence contracts MVP 01–08

Existing order/broker APIs giữ semantics hiện có. Internal operations yêu cầu tenant/broker scope và operator authorization; response không lộ dữ liệu scope khác.

| Endpoint | Kết quả |
|---|---|
| `GET /internal/persistence/trace` | Chuỗi order/trade/account/journal/obligation/reconciliation theo source reference. |
| `GET /internal/persistence/health` | Migration readiness, rehydration, backlog, DLQ, projection lag và restore state. |
| `POST /internal/ledger/replay` | Replay source đã cô lập, không tạo effect trùng. |
| `POST /internal/settlement/run` | Cycle T+ idempotent. |
| `POST /internal/reconciliation/run` | Matched/alert bất biến, không auto-fix. |
