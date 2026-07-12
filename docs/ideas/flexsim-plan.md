# FlexSim — Kế hoạch thực hiện theo MVP

Kế hoạch này triển khai ý tưởng trong [flexsim.md](flexsim.md). Vì mỗi phase A–D ước tính 8–10 tuần (quá to cho một MVP), mỗi phase được chia thành các MVP nhỏ 2–5 tuần. Nguyên tắc: **mỗi MVP ship và demo được độc lập**, có tiêu chí hoàn thành đo được, và xác nhận ít nhất một giả định của idea.

Nguồn lực: solo ~15h/tuần. Quy tắc cắt scope: MVP trễ >50% thời lượng dự kiến thì cắt scope, không gia hạn.

## Tổng quan lộ trình

| Giai đoạn | MVP | Nội dung chính | Thời lượng | Demo được |
| --- | --- | --- | --- | --- |
| Nền móng | MVP 0 | Repo, spec khớp lệnh, skeleton | 1–2 tuần | Spec + CI xanh |
| A. Sàn ảo | A1 | Matching engine core | 2–3 tuần | Khớp lệnh qua test harness |
| | A2 | Day cycle + market data realtime | 2–3 tuần | Bảng giá web chạy sống |
| | A3 | Bot thanh khoản + tài khoản demo | 3–4 tuần | Thị trường tự vận hành |
| B. CTCK ảo | B1a | Tenant + tài khoản + ledger | 3–4 tuần | 2 tenant, ledger cân |
| | B1b | Luồng lệnh end-to-end + maker-checker | 3–4 tuần | Đặt lệnh → T+ trọn vòng |
| | B2a | Margin + lệnh điều kiện + force-sell | 3–4 tuần | Force-sell tự động |
| | B2b | Corporate action + đối chiếu EOD + agent đối soát | 3–4 tuần | Agent xử lý lệch đối chiếu |
| C. Giám sát | C1 | Stream pipeline + wash trading | 4–5 tuần | Cảnh báo wash trading |
| | C2 | Thao túng quanh chốt quyền + agent điều tra | 4–5 tuần | Báo cáo điều tra do agent viết |
| D. Research desk | D1 | RAG tiếng Việt (BCTC/tin tức mô phỏng) | 4–5 tuần | Hỏi đáp có trích nguồn |
| | D2 | Đội multi-agent phân tích per tenant | 4–5 tuần | Báo cáo phân tích theo tenant |

Tổng: ~36–46 tuần. Mốc dừng tự nhiên: sau A3 (có "sàn ảo" hoàn chỉnh), sau B2b (có hệ CTCK multi-tenant hoàn chỉnh) — dừng ở đâu cũng có sản phẩm đứng độc lập.

## Decision gates (từ Open Questions của idea)

Không quyết trước; quyết đúng lúc cần, ghi lại quyết định vào tài liệu này:

| Gate | Câu hỏi | Quyết trước MVP | Ghi chú |
| --- | --- | --- | --- |
| G1 | Tech stack: .NET quen thuộc hay stack mới? | MVP 0 | Ảnh hưởng mọi MVP sau |
| G2 | Tên repo + vị trí trong flex-workstation (repo con theo `workstation.json`?) | MVP 0 | |
| G3 | Day cycle: giờ giao dịch thật VN hay chỉ tua nhanh? | A2 | Idea nghiêng về tua nhanh (1 ngày ảo = n phút) |
| G4 | Mô hình multi-tenant: shared schema + RLS, schema-per-tenant, hay DB-per-tenant? | B1a | Quyết bằng spec Speckit của phase B |

## MVP 0 — Nền móng (1–2 tuần)

Mục tiêu: mọi thứ cần có trước dòng code nghiệp vụ đầu tiên.

**In:**

- Quyết G1 (tech stack), G2 (tên repo, vị trí); tạo repo con, khai báo vào `workstation.json`.
- Viết **spec khớp lệnh trước khi code** (giả định #2 của idea): bước giá, biên độ, lô chẵn, ưu tiên giá-thời gian — từ tài liệu công khai của sở giao dịch.
- Skeleton modular monolith + CI (build, test, lint).
- README ghi rõ "simulation only" ngay từ đầu.

**Tiêu chí hoàn thành:** spec khớp lệnh review xong (đối chiếu với tài liệu sở); CI xanh trên commit đầu.

**Xác nhận giả định:** quy tắc khớp lệnh mô phỏng được từ tài liệu công khai.

## Phase A — Sàn ảo (3 MVP, 8–10 tuần)

Sàn kiêm ba vai: sở giao dịch (khớp lệnh, phát market data), lưu ký (giữ số dư gốc), lịch phiên (day cycle điều khiển được). Vai lưu ký chỉ cần "giữ số dư gốc" ở phase A; file đối chiếu EOD lùi sang B2b.

### MVP A1 — Matching engine core (2–3 tuần)

**In:** matching engine khớp lệnh liên tục in-memory cho ~10 mã theo spec MVP 0; nhận/hủy/sửa lệnh qua API nội bộ; event log lệnh + khớp (nền cho event-driven về sau).

**Out:** ATO/ATC (lùi cuối phase B), UI, WebSocket.

**Tiêu chí:** bộ test khớp lệnh phủ toàn bộ quy tắc trong spec (bước giá, biên độ, lô, ưu tiên giá-thời gian) pass; demo khớp lệnh qua test harness/CLI.

### MVP A2 — Day cycle + market data realtime (2–3 tuần)

**In:** day cycle điều khiển được open → continuous → close → clearing, tua nhanh (1 ngày ảo = n phút, quyết G3); phát market data qua WebSocket (fan-out nhiều client); bảng giá web tối giản.

**Tiêu chí:** bảng giá cập nhật realtime với ≥2 client đồng thời; chuyển phiên tự động theo lịch tua nhanh; lệnh bị từ chối đúng khi ngoài phiên.

### MVP A3 — Bot thanh khoản + tài khoản demo (3–4 tuần)

**In:** 3 loại bot code thuần (noise trader, momentum, market-maker) chạy như client của sàn; tài khoản demo: đặt lệnh, xem danh mục; chart quan sát giá.

**Out:** mọi AI dùng LLM (bot là chiến lược code thuần — giữ LLM ngoài hot path).

**Tiêu chí:** thị trường "sống" — giá chuyển động hợp lý, có thanh khoản liên tục trên ~10 mã, kiểm bằng chart quan sát qua nhiều ngày ảo (giả định #3 của idea).

**Kết quả phase A:** đúng MVP Scope trong idea — sản phẩm đứng độc lập đầu tiên.

## Phase B — CTCK ảo multi-tenant (4 MVP, 12–16 tuần)

Mỗi CTCK là một tenant: cùng codebase, cấu hình phí/room/quy tắc duyệt riêng. Trước B1a, chạy Speckit spec cho phase B (thay đổi data + permission — không đi quick flow).

### MVP B1a — Tenant + tài khoản + ledger (3–4 tuần)

**In:** quyết G4 (mô hình multi-tenant); dựng ≥2 tenant mẫu; hồ sơ khách hàng rút gọn (mở/đóng tài khoản); **ledger tiền + ledger chứng khoán double-entry** (số dư CK theo trạng thái: giao dịch được/phong tỏa/chờ về); hệ thống tham số theo tenant (phí, quy tắc).

**Tiêu chí:** mọi bút toán cân (tổng nợ = tổng có) qua property-based test; 2 tenant chạy cùng codebase với tham số khác nhau; dữ liệu tenant này không rò sang tenant kia (test cách ly).

### MVP B1b — Luồng lệnh end-to-end + maker-checker (3–4 tuần)

**In:** luồng xương sống: nhận lệnh → kiểm tra sức mua/số dư → gateway riêng của tenant đẩy sàn (message bất đồng bộ, hàng đợi lỗi + retry) → nhận khớp → cập nhật ledger → thanh toán T+ theo day cycle; maker-checker cho nghiệp vụ nhạy cảm (chuyển tiền, sửa thông tin KH); chuyển tiền với "ngân hàng ảo" một API; notification rút gọn (web/webhook).

**Tiêu chí:** một lệnh đi trọn vòng từ đặt đến tiền/CK về đúng ngày T+ (tua nhanh); lệnh vượt sức mua bị chặn; giao dịch cần duyệt không hiệu lực trước khi checker duyệt; gateway retry được khi sàn tạm ngắt.

### MVP B2a — Margin + lệnh điều kiện + force-sell (3–4 tuần)

Nghiệp vụ "đắt giá" nhất để học, tách riêng một MVP.

**In:** framework lệnh điều kiện (chờ kích hoạt theo sự kiện giá, xử lý event log định kỳ); ký quỹ: tỷ lệ theo mã, room theo mã + room hệ thống, sức mua có vay (gộp cho vay/lãi rút gọn); force-sell tự động qua lệnh điều kiện khi tỷ lệ chạm ngưỡng; tham số margin theo tenant.

**Tiêu chí:** kịch bản giá giảm → tài khoản chạm ngưỡng → force-sell tự kích hoạt và ledger cập nhật đúng; hai tenant có chính sách margin khác nhau cho cùng một mã.

### MVP B2b — Corporate action + đối chiếu EOD + agent đối soát (3–4 tuần)

**In:** thực hiện quyền cơ bản (cổ tức tiền/CK, chốt danh sách); sàn (vai lưu ký) phát file đối chiếu EOD (file tổng + chi tiết); job đối chiếu tenant ↔ sàn mỗi EOD, **cố ý tiêm lỗi lệch ngẫu nhiên**; AI agent "nghiệp vụ viên" đối soát — LLM đầu tiên của dự án, ngoài hot path; batch control cho chuỗi job EOD (kiểm tra "batch đã chạy chưa" trước khi cho giao dịch); ATO/ATC nếu còn thời lượng (mục lùi từ phase A — cắt đầu tiên nếu trễ).

**Tiêu chí:** đối chiếu EOD phát hiện 100% lỗi được tiêm; agent phân loại và đề xuất xử lý lệch, con người duyệt qua maker-checker; đo chi phí LLM/ngày ảo (giả định #4 của idea).

**Kết quả phase B:** hệ CTCK multi-tenant hoàn chỉnh — mốc dừng tự nhiên thứ hai; nguồn sự kiện đủ dày cho phase C.

## Phase C — Giám sát thị trường (2 MVP, 8–10 tuần)

Tiền đề: sự kiện từ phase B (lệnh, khớp, corporate action) đủ dày. Thêm bot "gian lận" có chủ đích để pipeline có tín hiệu thật để bắt.

### MVP C1 — Stream pipeline + wash trading (4–5 tuần)

**In:** pipeline stream processing trên luồng lệnh/khớp; bot mô phỏng wash trading giữa các tài khoản liên quan; rule/anomaly detection phát hiện pattern; dashboard cảnh báo; observability stack (structured log, metrics, trace).

**Tiêu chí:** phát hiện được các phiên wash trading do bot tạo với precision/recall đo được trên nhãn đã biết (bot là ground truth).

### MVP C2 — Thao túng quanh chốt quyền + agent điều tra (4–5 tuần)

**In:** bot mô phỏng thao túng giá quanh ngày chốt quyền (dùng corporate action từ B2b); detection cho pattern này; AI agent "điều tra viên": nhận cảnh báo, tool use truy vấn dữ liệu lệnh/tài khoản, viết báo cáo điều tra.

**Tiêu chí:** từ một cảnh báo, agent tự truy vấn và xuất báo cáo nêu đúng tài khoản/mã/khoảng thời gian liên quan; con người thẩm định mẫu báo cáo.

## Phase D — Research desk (2 MVP, 8–10 tuần)

### MVP D1 — RAG tiếng Việt (4–5 tuần)

**In:** sinh BCTC + tin tức mô phỏng cho ~10 mã (gắn với sự kiện thị trường ảo: corporate action, biến động giá); pipeline RAG tiếng Việt (ingest, chunk, retrieval); hỏi đáp có trích nguồn.

**Tiêu chí:** bộ câu hỏi đánh giá cố định, câu trả lời trích đúng nguồn với tỷ lệ đạt định trước.

### MVP D2 — Đội multi-agent phân tích per tenant (4–5 tuần)

**In:** orchestration đội agent "nhà phân tích" cho từng tenant (phân tích BCTC/tin tức, tổng hợp báo cáo); tích hợp dữ liệu thị trường + RAG từ D1; tùy chọn nếu dư thời gian: eKYC document-AI cho luồng mở tài khoản online.

**Tiêu chí:** mỗi tenant nhận báo cáo phân tích định kỳ theo day cycle; hai tenant với cấu hình khác nhau nhận báo cáo khác nhau.

## Bảng xác nhận giả định (mapping với idea)

| Giả định trong idea | Xác nhận tại | Cách đo |
| --- | --- | --- |
| Duy trì 15h/tuần | Mọi MVP, chốt ở A3 | Trễ >50% → cắt scope, không gia hạn |
| Quy tắc khớp lệnh mô phỏng được từ tài liệu công khai | MVP 0 | Spec viết xong trước khi code A1 |
| Bot code thuần đủ tạo thị trường "sống" | A3 | Chart quan sát qua nhiều ngày ảo |
| Chi phí LLM chấp nhận được | B2b (đo lần đầu), C2, D1 | Chi phí LLM/ngày ảo; LLM ngoài hot path |
| Bản đồ nghiệp vụ rút gọn vẫn "đúng chất" CTCK | Spec từng phase (B, C, D) | Đối chiếu từng luồng với hệ Flex tham chiếu |

## Cách vận hành kế hoạch

- Mỗi phase bắt đầu bằng spec nghiệp vụ theo Speckit workflow (`$speckit-specify`); MVP trong cùng phase dùng chung spec phase, chi tiết hóa bằng plan/tasks.
- Sau mỗi MVP: demo + retro ngắn, cập nhật tài liệu này nếu quyết định tại các gate làm thay đổi lộ trình.
- Thứ tự MVP trong một phase là phụ thuộc cứng (A1→A2→A3, B1a→B1b→B2a→B2b); giữa các phase có thể nghỉ/dừng vì mỗi mốc đều có sản phẩm độc lập.
