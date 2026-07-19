# Persistence contracts MVP 01–08

`exchange` công bố order/trade references; `broker` và `vsd` chỉ nhận external IDs/correlation qua contract, không đọc hoặc join database của tổ chức khác. Internal operations yêu cầu scope phù hợp và không lộ dữ liệu scope khác.

Database `broker` đại diện cho một CTCK; `brokerId` trong contract là identity/configuration của CTCK, không phải foreign key tới bảng dùng chung.

| Endpoint | Kết quả |
|---|---|
| `GET /internal/persistence/trace` | Tổng hợp chuỗi order/trade/account/journal/obligation/reconciliation theo external reference và correlation. |
| `GET /internal/persistence/health` | Readiness riêng của `exchange`, `broker`, `vsd`; backlog, DLQ, projection lag và restore state. |
| `POST /internal/ledger/replay` | Replay source đã cô lập, không tạo effect trùng. |
| `POST /internal/settlement/run` | Cycle T+ idempotent. |
| `POST /internal/reconciliation/run` | Matched/alert bất biến, không auto-fix. |
