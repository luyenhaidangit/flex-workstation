# FlexSim — Roadmap 27 MVP

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
| B — CTCK | 08 | [Database, pipeline, clearing, settlement, đối chiếu](08-database-pipeline-clearing-settlement-reconciliation.md) |
| B — CTCK | 09 | [Kiểm soát CTCK nâng cao](09-broker-controls-margin.md) |
| C — Giám sát | 10 | [Giám sát và điều tra](10-market-surveillance.md) |
| D — Research | 11 | [Kho tri thức theo tenant](11-tenant-research-knowledge.md) |
| D — Research | 12 | [Nhóm agent và báo cáo](12-research-agent-reporting.md) |
| E — Cơ chế thị trường | 13 | [Đấu giá mở/đóng phiên ATO/ATC](13-auction-ato-atc.md) |
| E — Cơ chế thị trường | 14 | [Đa mã chứng khoán và chỉ số](14-multi-symbol-index.md) |
| E — Cơ chế thị trường | 15 | [Biên độ giá và tạm dừng giao dịch](15-price-limits-circuit-breaker.md) |
| F — Loại lệnh | 16 | [Market order và lệnh điều kiện](16-market-order-conditional.md) |
| F — Loại lệnh | 17 | [Lệnh iceberg và thời lực](17-iceberg-time-in-force.md) |
| G — Tổ chức & nước ngoài | 18 | [Quỹ đầu tư mô phỏng](18-investment-fund.md) |
| G — Tổ chức & nước ngoài | 19 | [Nhà đầu tư nước ngoài và room ngoại](19-foreign-investor-room.md) |
| H — Hậu giao dịch | 20 | [Corporate actions đầy đủ](20-corporate-actions.md) |
| H — Hậu giao dịch | 21 | [Hệ thống lưu ký](21-custodian.md) |
| I — Kết nối | 22 | [FIX protocol gateway](22-fix-protocol-gateway.md) |
| I — Kết nối | 23 | [Market data feed phân tầng](23-market-data-feed.md) |
| J — Risk & Analytics | 24 | [Risk engine thời gian thực](24-risk-engine.md) |
| J — Risk & Analytics | 25 | [Back-testing framework](25-backtesting.md) |
| K — AI nâng cao | 26 | [Anomaly detection bằng ML](26-ml-anomaly-detection.md) |
| K — AI nâng cao | 27 | [Natural language market query](27-nl-market-query.md) |

Quy ước: Exchange mô phỏng vai trò Sở giao dịch và khớp lệnh; Broker/CTCK quản lý khách hàng, kiểm soát trước giao dịch rồi gửi lệnh lên Exchange; Clearing–Settlement mô phỏng phần hậu giao dịch của VSDC, xử lý nghĩa vụ sau khớp; Custodian mô phỏng VSD giữ tài sản độc lập; Tenant là một CTCK ảo. Không dùng tiền thật, kết nối sàn thật hoặc dữ liệu trả phí.

## Dependency giữa các stage

```
Stage A (01-04): Nền tảng — phải hoàn thành trước tất cả
Stage B (05-09): Cần Stage A hoàn thành
Stage C (10): Cần Stage B (dữ liệu giao dịch dày đủ)
Stage D (11-12): Cần Stage C (event stream làm bằng chứng)
Stage E (13-15): Độc lập với B-D, cần Stage A; nên làm sau Stage D để có đủ dữ liệu demo
Stage F (16-17): Cần Stage E (đa mã, biên độ áp dụng cho loại lệnh mới)
Stage G (18-19): Cần Stage B (broker infra) và Stage E (đa mã)
Stage H (20-21): Cần Stage G (danh mục) và Stage B (ledger)
Stage I (22-23): Cần Stage E trở lên; độc lập với G-H
Stage J (24-25): Cần dữ liệu lịch sử từ Stage E+ và Stage B (danh mục)
Stage K (26-27): Cần Stage C (surveillance data) và Stage D (research KB)
```
