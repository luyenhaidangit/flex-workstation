---
name: "mmo-research"
description: "Research online money-making methods by scanning Reddit, forums, and web sources, then analyze and synthesize the business models found."
argument-hint: "Keyword or niche to research (e.g. 'cheap chatgpt', 'resell accounts', 'ai tools arbitrage')"
user-invocable: true
disable-model-invocation: false
---

## User Input

```text
$ARGUMENTS
```

---

## Mục tiêu

Nghiên cứu các phương pháp kiếm tiền online (MMO) liên quan đến từ khóa/niche người dùng cung cấp. Nếu không có input, dùng niche mặc định: **"cheap ai tools resell"**.

Quy trình gồm 3 phase tuần tự: **Discover → Read → Analyze**. Thực hiện từng bước, không bỏ qua.

**Nguyên tắc recency-first**: Ưu tiên nội dung mới nhất (1–4 tuần gần đây) hơn bài nhiều upvote nhưng cũ. Bài cũ = method có thể đã bị patch, bão hòa, hoặc platform đã thay đổi chính sách. Bài mới = tín hiệu method đang còn sống.

---

## Phase 1 — Discover: Tìm nguồn

### 1.1 Reddit Search

Với mỗi từ khóa dưới đây, dùng `WebSearch` để tìm kiếm trên Reddit. Luôn thêm bộ lọc thời gian vào query:

```
site:reddit.com "<keyword>" after:2025-06-01
site:reddit.com "<keyword>" "still working" OR "just started" after:2025-01-01
site:reddit.com "<keyword>" selling resell arbitrage after:2025-01-01
```

Ưu tiên các subreddit MMO phổ biến:
- r/beermoney — micro-tasks, passive income
- r/entrepreneur — business models
- r/Flipping — mua rẻ bán đắt
- r/slavelabour — freelance giá thấp
- r/WorkOnline — remote work & side hustles
- r/ChatGPT, r/AItools — nếu keyword liên quan AI
- r/digitalmarketing — bán dịch vụ digital
- r/dropship, r/ecommerce — nếu liên quan thương mại

Khi fetch URL Reddit, ưu tiên dùng `?sort=new` thay vì `?sort=top` để lấy thread mới nhất trong subreddit. Ví dụ: `reddit.com/r/beermoney/new/`

Lấy **5–10 link bài viết**, ưu tiên theo thứ tự: **(1) mới nhất** trong 30 ngày → **(2) mới nhất** trong 90 ngày → **(3) upvote cao nhất** nếu không có gì mới. Ghi rõ ngày đăng của từng bài.

### 1.2 Web Search mở rộng

Tìm thêm ngoài Reddit, luôn kèm bộ lọc thời gian:
```
"<keyword>" make money 2025 after:2025-01-01
"<keyword>" resell method "still working" after:2025-01-01
"<keyword>" arbitrage guide after:2025-04-01
```

Tìm thêm trên:
- YouTube (tìm title video, ưu tiên video upload trong 3 tháng gần nhất)
- BlackHatWorld — dùng filter "Sort by: Date" trong kết quả tìm kiếm
- Warrior Forum
- Medium / Substack

Ghi lại danh sách nguồn tìm được: **URL + tiêu đề + platform + ngày đăng**.

### 1.3 Diễn đàn Việt Nam

Tìm thêm trên các diễn đàn MMO Việt Nam, ưu tiên nội dung mới:
```
site:mmo4me.com "<keyword>" after:2025-01-01
site:voz.vn "<keyword>" kiếm tiền after:2025-01-01
site:mmovn.com "<keyword>" after:2025-01-01
```

Ưu tiên:
- **MMO4ME** (mmo4me.com) — tổng hợp method, giao dịch account/tool
- **VOZ MMO** (voz.vn/f/make-money-online.93) — kinh nghiệm thực tế cộng đồng
- **VietAff** (vietaff.com) — affiliate marketing Việt Nam
- **MMOVN** (mmovn.com) — affiliate, crypto, airdrop

Khi truy cập forum, nếu có tùy chọn sort, chọn **"Mới nhất" / "Latest" / "Sort by Date"** thay vì "Hot" hay "Top".

Chú ý các loại thread theo độ ưu tiên:
1. **Journey thread mới** (ai đó vừa bắt đầu trong 2–4 tuần) → method đang sống
2. **Bán/mua thread gần đây** → tín hiệu cầu hiện tại
3. **"Còn hoạt động không?" / "Is this still working?"** → community tự verify
4. **Hiring thread** → ai đó đang scale → method profitable
5. **Method leaked / proof thread** — đọc nhưng verify ngày đăng

### 1.4 Marketplace Research

Đọc tín hiệu cung/cầu từ marketplace:
```
site:fiverr.com "<keyword>" best selling
site:gumroad.com "<keyword>"
"<keyword>" appsumo deal
"<keyword>" product hunt
```

- **Fiverr trending gigs**: gig nhiều đơn → dịch vụ đang được mua nhiều
- **Gumroad/Lemon Squeezy bestsellers**: digital product nào đang bán chạy
- **AppSumo active deals**: SaaS nào đang tìm khách để validate
- **Product Hunt**: sản phẩm mới nào đang hot → niche nào đang tăng trưởng

### 1.5 Freshness Validation — Lọc trước khi đọc sâu

Trước khi bước vào Phase 2, chạy nhanh validation query cho từng method/source tìm được:

```
"<method name>" "still working" 2025
"<method name>" "not working" OR "patched" OR "banned" 2025
"<method name>" site:reddit.com after:2025-03-01
```

Phân loại kết quả:

| Tín hiệu | Đánh giá |
|----------|----------|
| Có người hỏi "còn hoạt động không?" trong tháng này và nhận reply tích cực | ✅ Đang sống |
| Có journey thread mới (< 4 tuần) với update | ✅ Đang sống |
| Nhiều comment "đã die", "bị patch", "không còn" | ❌ Đã chết |
| Không có mention nào sau 6 tháng | ⚠️ Không rõ — ghi chú khi đọc |
| Có thread mua/bán active với reply gần đây | ✅ Đang sống |

Chỉ đưa vào Phase 2 các source đánh giá ✅ hoặc ⚠️. Bỏ qua ❌.

---

## Phase 2 — Read: Đọc và trích xuất

Với **3–5 bài viết quan trọng nhất** từ Phase 1, dùng `WebFetch` để đọc nội dung đầy đủ.

Với mỗi bài, trích xuất:

| Trường | Nội dung cần tìm |
|--------|-----------------|
| **Phương pháp** | Họ đang làm gì cụ thể? |
| **Chuỗi giá trị** | INPUT → XỬ LÝ → OUTPUT → Người mua cuối kiếm gì từ output đó? |
| **Nguồn cung** | Lấy sản phẩm/dịch vụ từ đâu? (API, resell, crack, family plan, bulk buy...) |
| **Kênh bán** | Bán ở đâu? (Telegram, Discord, Shopee, fiverr, tự lập web...) |
| **Giá & margin** | Giá mua bao nhiêu? Bán bao nhiêu? Margin ước tính? |
| **Rủi ro** | Ai cũng nêu rủi ro gì? (bị ban, scam, pháp lý...) |
| **Đầu tư ban đầu** | Cần bao nhiêu vốn/thời gian để bắt đầu? |
| **Bằng chứng thu nhập** | Có proof không? (screenshot, số liệu, income report?) |

---

## Phase 2.5 — Reverse Engineering: Phân tích ngược sản phẩm thành công

Với **1–2 seller/product nổi bật nhất** tìm được từ Phase 1 & 2, thực hiện phân tích ngược từ bên ngoài để hiểu cơ chế vận hành mà không cần mua hay tham gia.

### Nguồn để Reverse Engineer

| Nguồn | Thông tin khai thác |
|-------|---------------------|
| **Landing page / Pricing page** | Pricing model, target audience, USP, tier structure |
| **BuiltWith / Wappalyzer** | Tech stack → ước tính chi phí infra/dev |
| **SimilarWeb** | Traffic volume, traffic source (SEO/paid/social) |
| **Job listings** (Indeed, LinkedIn) | Scale thực sự, công nghệ đang dùng, đội ngũ |
| **G2 / Trustpilot / AppSumo reviews** | Pain point khách hàng, gap chưa được giải quyết |
| **Wayback Machine** | Lịch sử pricing, feature, pivot — thấy được cả thất bại |
| **Affiliate program page** | Commission rate → ước tính margin gốc |
| **Social media (Twitter/X, TikTok)** | Growth strategy, viral angle, community size |

### Template Reverse Engineering

```
## [Tên seller/product]

**Quan sát từ bên ngoài:**
- Pricing: [tier, giá, model]
- Traffic ước tính: [nguồn, volume]
- Tech stack: [nếu tìm được]
- Review pattern: [điểm mạnh/yếu theo khách hàng]

**Tái dựng chuỗi giá trị:**
INPUT:  [nguyên liệu họ cần, chi phí ước tính]
PROCESS: [họ làm gì để tạo ra giá trị]
OUTPUT: [sản phẩm/dịch vụ cuối]
MARGIN ước tính: [dựa trên giá bán và chi phí đoán được]

**Gap phát hiện được:**
- [Segment nào chưa được phục vụ?]
- [Pain point nào khách hàng hay complain?]
- [Giá có thể thấp hơn / chất lượng có thể cao hơn ở điểm nào?]

**Angle khai thác:**
- [Cách vào thị trường khác biệt]
- [Có thể white-label / wrap lại không?]
```

---

## Phase 3 — Analyze: Phân tích & tổng hợp

### 3.1 Bản đồ phương pháp

Nhóm các phương pháp tìm được thành các cluster:

```
[Tên cluster]
  └── Phương pháp A: mô tả ngắn
  └── Phương pháp B: mô tả ngắn
```

Ví dụ cluster:
- **Arbitrage giá** — mua bulk/API rẻ, bán lẻ đắt hơn
- **Family plan splitting** — chia sẻ tài khoản premium nhiều người
- **Resell account** — tạo/mua tài khoản, bán lại
- **Affiliate** — tiếp thị liên kết nhận hoa hồng
- **Service wrapping** — bọc API thành tool/service riêng

### 3.2 Bảng đánh giá

| Phương pháp | Freshness | Vốn ban đầu | Time to First $ | Thời gian ROI | Rủi ro | Scalable? | Kỹ năng cần |
|-------------|-----------|-------------|-----------------|---------------|--------|-----------|-------------|
| ... | ... | ... | ... | ... | ... | ... | ... |

Rating rủi ro: 🟢 Thấp / 🟡 Trung bình / 🔴 Cao

**Freshness**: Bằng chứng gần nhất method còn sống — ghi dạng `"còn active, seen YYYY-MM"` hoặc `"last seen YYYY-MM, chưa rõ"`.  
**Time to First $**: Số ngày ước tính từ khi bắt đầu đến khi có doanh thu đầu tiên (dù nhỏ).

### 3.3 Deep-dive phương pháp nổi bật nhất

Chọn **1–2 phương pháp** khả thi nhất, phân tích chi tiết:

```
## [Tên phương pháp]

**Cách hoạt động:**
[Giải thích cơ chế, step-by-step nếu có]

**Nguồn cung:**
[Lấy từ đâu, liên kết nào, giá thế nào]

**Kênh phân phối:**
[Bán qua đâu, cách tiếp cận khách]

**Chi phí & lợi nhuận ước tính:**
- Vốn: $X
- Thu nhập ước tính: $Y/tháng
- Break-even: Z tháng

**Rủi ro cần lưu ý:**
- [Rủi ro 1]
- [Rủi ro 2]

**Bước đầu tiên để thử:**
1. [Bước 1]
2. [Bước 2]
3. [Bước 3]

**Kiểm thử với vốn tối thiểu:**
- Có thể test với $0–$20 không? Nếu có, cách nào?
- Mất bao lâu để có kết quả đầu tiên (dù nhỏ)?
- Dấu hiệu nào cho thấy đáng scale tiếp?
```

### 3.4 Gợi ý mở rộng

Sau khi phân tích, đề xuất thêm **3–5 niche/keyword liên quan** đáng nghiên cứu tiếp theo dựa trên pattern đã thấy.

---

## Output Format

Sau khi hoàn thành tất cả các phase, lưu toàn bộ kết quả vào file:

```
C:\Workspace\Project\flex-workstation\docs\ideas\mmo-YYYY-MM-DD.md
```

Nếu trong ngày đã có file cùng tên, append thêm vào cuối file (không ghi đè).

Nội dung file theo thứ tự:

```markdown
# MMO Research — YYYY-MM-DD
**Keyword/Niche**: <keyword đã nghiên cứu>

## 1. Tóm tắt nguồn
<đã tìm & đọc bao nhiêu nguồn, từ đâu>

## 2. Bản đồ phương pháp
<Phase 3.1>

## 3. Bảng đánh giá
<Phase 3.2 — bao gồm Time to First $>

## 4. Reverse Engineering
<Phase 2.5 — phân tích sản phẩm thành công nhất>

## 5. Deep-dive
<Phase 3.3 — bao gồm kiểm thử vốn tối thiểu>

## 6. Gợi ý tiếp theo
<Phase 3.4>
```

Viết bằng **tiếng Việt**, dùng tiếng Anh cho tên kỹ thuật/platform. Không bịa số liệu — nếu không tìm được data thực, ghi rõ "chưa có dữ liệu xác nhận".

---

## Lưu ý khi thực thi

- Nếu `WebFetch` bị block (paywall, login required), ghi chú và dùng WebSearch snippet thay thế.
- Không đưa ra phán xét đạo đức về phương pháp tìm được — chỉ mô tả khách quan và nêu rủi ro thực tế.
- Ưu tiên phương pháp có bằng chứng cộng đồng (nhiều người làm được) hơn phương pháp lý thuyết.
- Nếu tìm thấy thread có nhiều người share income proof, đọc kỹ hơn.
