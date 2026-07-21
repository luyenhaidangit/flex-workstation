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

---

## Phase 1 — Discover: Tìm nguồn

### 1.1 Reddit Search

Với mỗi từ khóa dưới đây, dùng `WebSearch` để tìm kiếm trên Reddit:

```
site:reddit.com "<keyword>"
site:reddit.com "<keyword>" how to make money
site:reddit.com "<keyword>" selling resell arbitrage
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

Lấy **5–10 link bài viết** có nhiều comment nhất, ưu tiên post có upvote cao.

### 1.2 Web Search mở rộng

Tìm thêm ngoài Reddit:
```
"<keyword>" make money online 2024 OR 2025
"<keyword>" resell method tutorial
"<keyword>" arbitrage how it works
```

Tìm thêm trên:
- YouTube (tìm title video, không cần xem)
- BlackHatWorld forum
- Warrior Forum
- Medium / Substack

Ghi lại danh sách nguồn tìm được (URL + tiêu đề + platform).

---

## Phase 2 — Read: Đọc và trích xuất

Với **3–5 bài viết quan trọng nhất** từ Phase 1, dùng `WebFetch` để đọc nội dung đầy đủ.

Với mỗi bài, trích xuất:

| Trường | Nội dung cần tìm |
|--------|-----------------|
| **Phương pháp** | Họ đang làm gì cụ thể? |
| **Nguồn cung** | Lấy sản phẩm/dịch vụ từ đâu? (API, resell, crack, family plan, bulk buy...) |
| **Kênh bán** | Bán ở đâu? (Telegram, Discord, Shopee, fiverr, tự lập web...) |
| **Giá & margin** | Giá mua bao nhiêu? Bán bao nhiêu? Margin ước tính? |
| **Rủi ro** | Ai cũng nêu rủi ro gì? (bị ban, scam, pháp lý...) |
| **Đầu tư ban đầu** | Cần bao nhiêu vốn/thời gian để bắt đầu? |
| **Bằng chứng thu nhập** | Có proof không? (screenshot, số liệu, income report?) |

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

| Phương pháp | Vốn ban đầu | Thời gian ROI | Rủi ro | Scalable? | Khả thi 2025? |
|-------------|-------------|---------------|--------|-----------|---------------|
| ... | ... | ... | ... | ... | ... |

Rating rủi ro: 🟢 Thấp / 🟡 Trung bình / 🔴 Cao

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
```

### 3.4 Gợi ý mở rộng

Sau khi phân tích, đề xuất thêm **3–5 niche/keyword liên quan** đáng nghiên cứu tiếp theo dựa trên pattern đã thấy.

---

## Output Format

Trình bày kết quả theo thứ tự:

1. **Tóm tắt nguồn** — đã tìm & đọc bao nhiêu nguồn, từ đâu
2. **Bản đồ phương pháp** (Phase 3.1)
3. **Bảng đánh giá** (Phase 3.2)
4. **Deep-dive** (Phase 3.3)
5. **Gợi ý tiếp theo** (Phase 3.4)

Viết bằng **tiếng Việt**, dùng tiếng Anh cho tên kỹ thuật/platform. Không bịa số liệu — nếu không tìm được data thực, ghi rõ "chưa có dữ liệu xác nhận".

---

## Lưu ý khi thực thi

- Nếu `WebFetch` bị block (paywall, login required), ghi chú và dùng WebSearch snippet thay thế.
- Không đưa ra phán xét đạo đức về phương pháp tìm được — chỉ mô tả khách quan và nêu rủi ro thực tế.
- Ưu tiên phương pháp có bằng chứng cộng đồng (nhiều người làm được) hơn phương pháp lý thuyết.
- Nếu tìm thấy thread có nhiều người share income proof, đọc kỹ hơn.
