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

## Key Assumptions to Validate

- [ ] Duy trì 15h/tuần — đo bằng deadline phase A; trễ >50% thì cắt scope chứ không gia hạn
- [ ] Quy tắc khớp lệnh HOSE mô phỏng được từ tài liệu công khai — viết spec khớp lệnh trước khi code, đối chiếu tài liệu HOSE
- [ ] Bot code thuần đủ tạo thị trường "sống" (giá chuyển động hợp lý) — kiểm bằng chart quan sát
- [ ] Chi phí LLM cho agent ở mức chấp nhận — bot giao dịch là chiến lược code thuần, LLM chỉ dùng ngoài hot path (điều tra, phân tích, quyết định cấp cao)

## MVP Scope (Phase A, 8-10 tuần)

**In:**

- Matching engine khớp lệnh liên tục cho ~10 mã (spec HOSE rút gọn: bước giá, biên độ, lô chẵn)
- Market data phát qua WebSocket, bảng giá web
- 3 loại bot: noise trader, momentum, market-maker
- Tài khoản demo: đặt lệnh, xem danh mục

**Out (phase A):** multi-tenant (vào phase B), phiên ATO/ATC, ký quỹ, mọi AI dùng LLM.

## Not Doing (and Why)

- **Tiền thật / kết nối sàn thật** — rủi ro pháp lý, ngoài mục tiêu học. Ghi rõ "simulation only" ngay từ README.
- **Mua data realtime VN** — thị trường tự sinh dữ liệu, không cần nguồn ngoài.
- **Microservices + Kubernetes từ ngày 1** — modular monolith trước, tách khi có lý do; chính việc tách là bài học ở phase sau.
- **Mobile app** — web đủ cho mọi mục tiêu học.

## Open Questions

- Tech stack: tận dụng nền .NET quen thuộc hay chọn stack mới hoàn toàn (mục tiêu học nghiêng về cái nào)?
- Phase A có cần mô phỏng phiên/giờ giao dịch VN hay chạy 24/7?
- Đặt tên repo + vị trí trong flex-workstation (repo con độc lập theo workstation.json?)
