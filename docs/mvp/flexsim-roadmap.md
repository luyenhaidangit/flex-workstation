# FlexSim — Roadmap 12 MVP

Mỗi MVP là một lát cắt nghiệp vụ có thể demo độc lập. Chỉ chuyển sang MVP kế tiếp khi luồng chính chạy từ đầu đến cuối, có test cho quy tắc mới và không kéo scope của MVP sau vào trước.

| Giai đoạn | MVP | Tài liệu |
| --- | --- | --- |
| A — Sàn ảo | 01 | [Quy tắc khớp lệnh](01-matching-rules.md) |
| A — Sàn ảo | 02 | [Exchange API và sự kiện](02-exchange-api-events.md) |
| A — Sàn ảo | 03 | [Bảng điện demo](03-market-board.md) |
| A — Sàn ảo | 04 | [Phiên giao dịch và bot](04-trading-session-bots.md) |
| B — CTCK | 05 | [CTCK đơn và kiểm tra trước lệnh](05-single-broker-pretrade.md) |
| B — CTCK | 06 | [CTCK đa tenant](06-multi-tenant-brokers.md) |
| B — CTCK | 07 | [Ledger tiền và chứng khoán](07-cash-securities-ledger.md) |
| B — CTCK | 08 | [Clearing, settlement, đối chiếu](08-clearing-settlement-reconciliation.md) |
| B — CTCK | 09 | [Kiểm soát CTCK nâng cao](09-broker-controls-margin.md) |
| C — Giám sát | 10 | [Giám sát và điều tra](10-market-surveillance.md) |
| D — Research | 11 | [Kho tri thức theo tenant](11-tenant-research-knowledge.md) |
| D — Research | 12 | [Nhóm agent và báo cáo](12-research-agent-reporting.md) |

Quy ước: Exchange khớp lệnh; Broker/CTCK quản lý khách hàng và kiểm soát trước giao dịch; Clearing–Settlement xử lý nghĩa vụ sau khớp; tenant là một CTCK ảo. Không dùng tiền thật, kết nối sàn thật hoặc dữ liệu trả phí.
