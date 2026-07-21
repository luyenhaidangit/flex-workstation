# MMO Research Skill — Review & Cải Tiến

**Ngày**: 2026-07-21  
**Skill được review**: `.agents/skills/mmo-research/SKILL.md`  
**Tài liệu liên quan**: `docs/ideas/mmo.md`

---

## 1. Đánh giá hiện trạng

### Điểm mạnh

| # | Điểm mạnh | Lý do |
|---|-----------|-------|
| 1 | Cấu trúc 3-phase tuần tự rõ ràng | Discover → Read → Analyze không bị nhảy bước |
| 2 | Bảng trích xuất Phase 2 đầy đủ | 7 trường bao phủ đủ góc nhìn thực tế |
| 3 | Phân tích deep-dive có template | Có cost/revenue/break-even rõ ràng |
| 4 | Gợi ý mở rộng Phase 3.4 | Tạo vòng lặp nghiên cứu liên tục |

### Điểm yếu / Thiếu sót

| # | Vấn đề | Tác động |
|---|--------|----------|
| 1 | **Thiếu nguồn diễn đàn Việt Nam** | Bỏ qua thị trường gần nhất, dễ tiếp cận nhất |
| 2 | **Thiếu Reverse Engineering** | Không phân tích sản phẩm đang thành công từ bên ngoài |
| 3 | **Thiếu phân tích chuỗi giá trị** | Chưa có mô hình INPUT→PROCESS→OUTPUT để bóc tách method |
| 4 | **Thiếu marketplace research** | Fiverr, Gumroad, AppSumo là nguồn signal thị trường quan trọng |
| 5 | **Thiếu chỉ số "Time to First $"** | Bảng đánh giá Phase 3.2 chưa đo được tốc độ sinh lời |
| 6 | **Thiếu bước validation** | Không có cách test nhanh trước khi bỏ vốn thật |
| 7 | **Thiếu trend check** | Chưa dùng Google Trends / keyword volume để xác nhận niche còn sống |

---

## 2. Phương pháp mới được thêm vào

### 2.1 Reverse Engineering (phương pháp chính được bổ sung)

**Reverse Engineering** trong MMO là kỹ thuật phân tích ngược một sản phẩm/service đang chạy tốt, bằng cách quan sát từ bên ngoài (không cần mua hay tham gia), để tái dựng lại:
- Cơ cấu chi phí ẩn
- Kênh thu hút khách hàng
- Margin thực sự
- Điểm yếu có thể khai thác

**Các nguồn khai thác để Reverse Engineer:**

| Nguồn | Thông tin lấy được |
|-------|-------------------|
| Landing page / pricing page | Pricing model, target audience, USP |
| BuiltWith / Wappalyzer | Tech stack → ước tính chi phí infra |
| SimilarWeb / Semrush | Traffic volume, traffic source |
| Job listings (Indeed/LinkedIn) | Scale thực sự, tech đang dùng |
| G2 / Trustpilot / AppSumo reviews | Pain point khách hàng, gap chưa được giải quyết |
| Wayback Machine | Lịch sử pricing, feature, pivot |
| Social media (Twitter/X, TikTok) | Growth strategy, viral angle |
| Affiliate program page | Commission rate → margin estimate |

**Quy trình:**
1. Tìm seller/product thành công trong niche (nhiều review, nhiều mention trên forum)
2. Thu thập dữ liệu từ các nguồn trên
3. Dựng bảng phân tích: Input / Process / Output / Margin ước tính
4. Xác định: Gap thị trường, góc tiếp cận khác biệt, segment chưa được phục vụ

### 2.2 Marketplace Research

Quan sát các marketplace để đọc tín hiệu cung/cầu:
- **Fiverr/Upwork trending**: Gig nhiều đơn → dịch vụ đang có cầu cao
- **Gumroad/Lemon Squeezy bestsellers**: Digital product nào bán chạy
- **AppSumo active deals**: SaaS đang cần khách để validate
- **Product Hunt "Made"**: Sản phẩm mới nào đang được upvote

### 2.3 Vietnamese Forum Coverage

Các diễn đàn Việt Nam bổ sung vào Phase 1:
- **MMO4ME** (mmo4me.com) — tổng hợp MMO, giao dịch tools
- **VOZ MMO** (voz.vn/f/make-money-online.93) — chia sẻ kinh nghiệm thực tế
- **VietAff** (vietaff.com) — affiliate marketing VN
- **MMOVN** (mmovn.com) — affiliate, crypto, airdrop

### 2.4 Value Chain Deconstruction

Công thức phân tích chuỗi giá trị mỗi method:

```
INPUT → XỬ LÝ → OUTPUT → NGƯỜI MUA CUỐI → LỢI NHUẬN CỦA HỌ
  ↓        ↓        ↓            ↓                 ↓
Cần gì?  Làm gì?  Được gì?   Ai mua?        Họ kiếm từ đâu?
```

Hiểu "người mua cuối kiếm gì" mới biết được ceiling thực sự của method.

---

## 3. Cải tiến bổ sung

### Bảng đánh giá Phase 3.2 — Thêm cột

Thêm 2 cột vào bảng hiện có:
- **Time to First $**: Ước tính số ngày/tuần từ khi bắt đầu đến khi có doanh thu đầu tiên
- **Cần kỹ năng gì**: Rào cản skill thực tế

### Validation Test trong Phase 3.3

Thêm mục **"Bước kiểm thử 0 vốn/vốn tối thiểu"** vào template deep-dive:
- Có thể test method với $0–$20 không?
- Mất bao lâu để có kết quả đầu tiên (dù nhỏ)?
- Dấu hiệu nào cho thấy nên tiếp tục scale?

---

## 4. Những gì không nên thêm

| Đề xuất từ chối | Lý do |
|-----------------|-------|
| Tự động crawl toàn bộ forum | Ngoài scope skill; dễ bị block; output noise nhiều |
| Rating đạo đức cho từng method | Skill đã có nguyên tắc "chỉ mô tả, không phán xét" — không cần thêm |
| Template báo cáo PDF | Skill output là text, không phải document |

---

## 5. Mapping vào SKILL.md

| Thay đổi | Vị trí trong skill |
|----------|-------------------|
| Thêm Vietnamese forums | Phase 1.1 — danh sách subreddit mở rộng → thành Phase 1.3 riêng |
| Thêm Marketplace research | Phase 1.2 — Web Search mở rộng |
| Thêm Value Chain template | Phase 2 — thêm trường "Chuỗi giá trị" |
| Thêm Reverse Engineering | Phase mới: Phase 2.5 (sau Read, trước Analyze) |
| Cập nhật bảng đánh giá | Phase 3.2 — thêm 2 cột |
| Thêm Validation Test | Phase 3.3 — thêm mục trong template |
