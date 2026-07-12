# FlexSim — Hệ sinh thái thị trường chứng khoán VN mô phỏng

## Problem Statement

Làm thế nào để một kỹ sư học sâu multi-tenancy, event-driven architecture và AI agent qua một hệ thống chứng khoán vận hành thật — mà không cần dữ liệu trả phí, không rủi ro pháp lý, không bỏ dở giữa chừng?

## Recommended Direction

Xây "thị trường ảo" làm nền (phase A), rồi xếp chồng các lớp nghiệp vụ theo từng giai đoạn. Mỗi phase 8-10 tuần, ship và demo được độc lập. Thị trường tự sinh dữ liệu nhờ bot giao dịch, nên toàn hệ thống không phụ thuộc nguồn data bên ngoài.

| Giai đoạn | Sản phẩm đứng độc lập | Học được | Vai AI agent |
| --- | --- | --- | --- |
| A. Sàn ảo | Matching engine + bảng giá realtime + bot tạo thanh khoản | Event-driven, WebSocket fan-out, in-memory engine | Bot nhà đầu tư (chiến lược) |
| B. CTCK ảo | Mỗi CTCK là tenant: tài khoản, ledger, T+, kết nối sàn | Multi-tenancy, event sourcing, saga, consistency | Nghiệp vụ viên (đối soát, xử lý ngoại lệ) |
| C. Giám sát | Phát hiện wash trading, thao túng giá trên luồng lệnh | Stream processing, anomaly detection | Điều tra viên (tool use, viết báo cáo) |
| D. Research desk | Đội agent phân tích BCTC/tin tức cho từng tenant | Multi-agent orchestration, RAG tiếng Việt | Nhà phân tích |

Bối cảnh quyết định: người dùng mục tiêu là "công ty chứng khoán/tổ chức" (mỗi CTCK ảo là một tenant), tiêu chí thành công là học sâu công nghệ + kiến trúc (không cần người dùng thật), thị trường Việt Nam, nguồn lực solo ~15h+/tuần.

## Bản đồ nghiệp vụ tham chiếu (từ hệ thống core Flex thực tế)

Khảo sát một hệ thống core chứng khoán Flex đang vận hành thực tế cho thấy một CTCK thật vận hành các khối nghiệp vụ sau. FlexSim dùng bản đồ này làm "mục lục" để chọn mô phỏng có chủ đích — không phải để tái hiện toàn bộ.

### Khối nghiệp vụ lõi (back-office)

| Mảng | Nội dung thực tế | FlexSim mô phỏng? |
| --- | --- | --- |
| Hồ sơ khách hàng | Mở/đóng tài khoản, phân loại KH, môi giới chăm sóc (care-by) | ✅ Phase B — rút gọn |
| Tiền | Số dư, phong tỏa, chuyển tiền nội bộ/ngân hàng, đối chiếu | ✅ Phase B — ledger tiền là trung tâm |
| Chứng khoán | Số dư CK theo trạng thái (giao dịch được/phong tỏa/chờ về), chuyển khoản CK | ✅ Phase B — ledger chứng khoán song song ledger tiền |
| Xử lý lệnh | Nhận lệnh, kiểm tra sức mua/số dư, đẩy sở, nhận khớp, hủy/sửa | ✅ Phase A+B — luồng xương sống |
| Lệnh điều kiện | Lệnh chờ kích hoạt theo sự kiện giá, xử lý event log định kỳ | ✅ Phase B/C — bài học event-driven đẹp |
| Lệnh thỏa thuận (put-through) | Khớp thỏa thuận giữa hai thành viên | ⬜ Tùy chọn phase B |
| Ký quỹ/Margin | Tỷ lệ ký quỹ, margin room theo mã, room hệ thống, rổ credit line, force-sell tự động | ✅ Phase B nâng cao — nghiệp vụ "đắt giá" nhất để học |
| Cho vay (LN) | Khoản vay margin, lãi, gia hạn | ✅ Gộp vào margin, rút gọn |
| Thực hiện quyền | Cổ tức tiền/CK, quyền mua, chốt danh sách, email đáo hạn quyền | ✅ Phase B/C — nguồn sự kiện corporate action cho cả giám sát lẫn research desk |
| Tiền gửi kỳ hạn | Hợp đồng tiền gửi, tất toán, rút trước hạn | ⬜ Không làm — ít giá trị học mới |
| Trái phiếu riêng lẻ | Luồng đăng ký, chuyển nhượng, đối chiếu lưu ký riêng | ⬜ Không làm — quá ngách |
| Phái sinh (FDS) | Hệ thống riêng, đồng bộ hai chiều với core | ⬜ Không làm ở 4 phase đầu |

### Khối kết nối & tích hợp

| Mảng | Nội dung thực tế | FlexSim mô phỏng? |
| --- | --- | --- |
| Gateway sở giao dịch | Hai gateway riêng cho hai sở, xử lý message bất đồng bộ, hàng đợi lỗi + retry, job giám sát message lỗi | ✅ Phase A+B — sàn ảo đóng vai sở, mỗi tenant có gateway riêng nối vào |
| Trung tâm lưu ký | Sinh yêu cầu, xử lý message, **đối chiếu file cuối ngày** (file tổng + file chi tiết) | ✅ Phase B — sàn ảo kiêm vai lưu ký, phát file đối chiếu EOD cho tenant |
| Gateway ngân hàng | Nhiều gateway cho nhiều ngân hàng, chuyển tiền hai chiều, cảnh báo lỗi nhận tiền | ⬜ Rút gọn thành "ngân hàng ảo" một API |
| eKYC + mở tài khoản online | Định danh điện tử, luồng mở tài khoản tự động | ⬜ Tùy chọn phase D — bài AI vision/document tốt nếu dư thời gian |
| ESB / OpenAPI | API cho kênh online trading, broker, contact center, ebill | ✅ Phase B — API surface của mỗi tenant |
| Thông báo | Email/SMS khi khớp lệnh, sao kê, cảnh báo | ✅ Rút gọn — notification qua web/webhook |

### Khối vận hành (điểm khác biệt của hệ thống "thật")

Đây là phần các dự án học tập luôn bỏ qua, và cũng là phần FlexSim nên làm để xứng chữ "vận hành thực tế":

- **Chu trình ngày giao dịch (day cycle/EOD)**: hệ thống thực có hơn 50 scheduler job — mở phiên, khớp, clearing lệnh cuối phiên, sinh buffer tiền/CK/lệnh, thanh toán T+, chạy batch có kiểm soát trạng thái (batch control), kiểm tra "batch đã chạy chưa" trước khi cho giao dịch. FlexSim mô phỏng day cycle rút gọn: open → continuous → close → clearing → settlement, tua nhanh được (1 ngày ảo = n phút).
- **Giao dịch mã hóa theo tx-code**: mỗi nghiệp vụ là một mã giao dịch đánh số, có package xử lý riêng + phần mở rộng, tra cứu qua bảng tham số. FlexSim học lại tinh thần này bằng command/event catalog có versioning — không cần bắt chước cách đặt tên.
- **Maker-checker (lập — duyệt)**: bảng quy tắc "giao dịch nào cần duyệt", luồng phê duyệt trước khi hiệu lực. FlexSim đưa vào phase B cho nghiệp vụ nhạy cảm (chuyển tiền, sửa thông tin KH) — đây là chỗ AI agent "nghiệp vụ viên" tham gia tự nhiên nhất.
- **Hệ thống tham số hóa**: mã danh mục dùng chung, biến hệ thống, quy tắc nghiệp vụ cấu hình được thay vì hard-code. Với FlexSim, tham số theo **từng tenant** — chính là bài multi-tenancy: cùng codebase, mỗi CTCK cấu hình phí, room margin, quy tắc duyệt khác nhau.
- **Đối chiếu (reconciliation)**: đối chiếu số dư với lưu ký bằng file cuối ngày, đối chiếu tiền với ngân hàng, email cảnh báo lệch. FlexSim: job đối chiếu tenant ↔ sàn ảo mỗi EOD, cố ý tiêm lỗi lệch ngẫu nhiên để AI agent đối soát có việc thật để làm.
- **Giám sát vận hành**: job phân tích log, kiểm tra message/lệnh/email lỗi định kỳ, dashboard monitor. FlexSim: observability stack (structured log, metrics, trace) + agent trực ca đọc cảnh báo.
- **Import/export nghiệp vụ**: nghiệp vụ thực nhập liệu hàng loạt bằng file (room margin, giá, danh sách quyền...). FlexSim rút gọn thành API + một luồng import file để học xử lý batch idempotent.

### Điều chỉnh phase theo bản đồ trên

- **Phase A (Sàn ảo)** bổ sung: sàn kiêm ba vai — sở giao dịch (khớp lệnh, phát market data), lưu ký (giữ số dư gốc, phát file đối chiếu), và lịch phiên (day cycle điều khiển được, tua nhanh). Spec khớp lệnh viết trước, gồm: bước giá, biên độ, lô, ưu tiên giá-thời gian; ATO/ATC lùi sang cuối phase B.
- **Phase B (CTCK ảo — multi-tenant)** bổ sung chi tiết, chia 2 đợt:
  - B1: tài khoản KH, ledger tiền + CK double-entry, luồng đặt lệnh end-to-end (kiểm tra sức mua → gateway → khớp → cập nhật ledger → thanh toán T+), tham số theo tenant, maker-checker.
  - B2: margin (tỷ lệ, room theo mã, sức mua có vay, force-sell qua lệnh điều kiện), thực hiện quyền cơ bản (cổ tức tiền/CK), đối chiếu EOD với sàn + AI agent đối soát.
- **Phase C (Giám sát)** bổ sung: nguồn sự kiện đủ dày từ phase B (lệnh, khớp, corporate action) mới phát hiện được thao túng quanh ngày chốt quyền, wash trading giữa tài khoản liên quan — mô phỏng đúng các pattern giám sát mà thị trường thật quan tâm.
- **Phase D (Research desk)** giữ nguyên; thêm tùy chọn eKYC document-AI nếu dư thời gian.

## Key Assumptions to Validate

- [ ] Duy trì 15h/tuần — đo bằng deadline phase A; trễ >50% thì cắt scope chứ không gia hạn
- [ ] Quy tắc khớp lệnh mô phỏng được từ tài liệu công khai của sở giao dịch — viết spec khớp lệnh trước khi code
- [ ] Bot code thuần đủ tạo thị trường "sống" (giá chuyển động hợp lý) — kiểm bằng chart quan sát
- [ ] Chi phí LLM cho agent ở mức chấp nhận — bot giao dịch là chiến lược code thuần, LLM chỉ dùng ngoài hot path (đối soát, điều tra, phân tích)
- [ ] Bản đồ nghiệp vụ rút gọn vẫn "đúng chất" CTCK — kiểm bằng cách đối chiếu từng luồng với hệ thống Flex tham chiếu khi viết spec từng phase

## MVP Scope (Phase A, 8-10 tuần)

**In:**

- Matching engine khớp lệnh liên tục cho ~10 mã (spec rút gọn: bước giá, biên độ, lô chẵn, ưu tiên giá-thời gian)
- Day cycle điều khiển được: open → continuous → close → clearing, tua nhanh (1 ngày ảo = n phút)
- Market data phát qua WebSocket, bảng giá web
- 3 loại bot: noise trader, momentum, market-maker
- Tài khoản demo: đặt lệnh, xem danh mục

**Out (phase A):** multi-tenant (vào phase B), phiên ATO/ATC, ký quỹ, file đối chiếu EOD, mọi AI dùng LLM.

## Not Doing (and Why)

- **Tiền thật / kết nối sàn thật** — rủi ro pháp lý, ngoài mục tiêu học. Ghi rõ "simulation only" ngay từ README.
- **Mua data realtime VN** — thị trường tự sinh dữ liệu, không cần nguồn ngoài.
- **Tái hiện đủ nghiệp vụ của core thật** — hệ thống tham chiếu là sản phẩm hàng chục năm-người; FlexSim chọn lát cắt có giá trị học cao nhất (bảng "mô phỏng?" ở trên là hợp đồng scope).
- **Tiền gửi kỳ hạn, trái phiếu riêng lẻ, phái sinh** — ngách, ít bài học kiến trúc mới so với chi phí.
- **Microservices + Kubernetes từ ngày 1** — modular monolith trước, tách khi có lý do; chính việc tách là bài học ở phase sau.
- **Mobile app** — web đủ cho mọi mục tiêu học.

## Open Questions

- Tech stack: tận dụng nền .NET quen thuộc hay chọn stack mới hoàn toàn (mục tiêu học nghiêng về cái nào)?
- Mô hình multi-tenant cụ thể cho phase B: shared schema + row-level security, schema-per-tenant, hay database-per-tenant? (Hệ thống thực tế là single-tenant per deployment — FlexSim làm khác có chủ đích.)
- Phase A có cần mô phỏng giờ giao dịch thật của VN hay chỉ cần day cycle tua nhanh?
- Đặt tên repo + vị trí trong flex-workstation (repo con độc lập theo workstation.json?)
