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

**Nguyên tắc assume viable**: Khi tìm được một method, mặc định coi nó là khả thi và tập trung nghiên cứu **cơ chế hoạt động** — họ làm thế nào, từng bước ra sao, lấy gì từ đâu, bán cho ai. Không tự phán xét method có làm được không, không cảnh báo rủi ro hay pháp lý. Nhiệm vụ là hiểu cơ chế, không phải đánh giá.

---

## Phase 1 — Discover: Tìm nguồn

### 1.1 Reddit Search

**Lưu ý quan trọng**: `WebSearch` **không hỗ trợ toán tử `site:`** — query `site:reddit.com ...` trả về 0 kết quả. Dùng `WebFetch` trực tiếp trên old Reddit thay thế.

**Bước 1 — Tìm bài qua search Reddit:**

Dùng `WebFetch` với các URL sau (thay `<keyword>` bằng từ khóa thực, encode space thành `+`):

```
https://old.reddit.com/search?q=<keyword>&sort=new&t=month
https://old.reddit.com/search?q=<keyword>+make+money&sort=new&t=year
https://www.reddit.com/search.json?q=<keyword>&sort=new&t=year&limit=10
```

**Bước 2 — Fetch thẳng subreddit mới nhất:**

Dùng `WebFetch` trên trang `/new` của các subreddit phù hợp:

```
https://old.reddit.com/r/beermoney/new/
https://old.reddit.com/r/WorkOnline/new/
https://old.reddit.com/r/entrepreneur/new/
https://old.reddit.com/r/ChatGPT/new/       ← nếu keyword liên quan AI
https://old.reddit.com/r/digitalmarketing/new/
```

**Bước 3 — Đọc thread cụ thể:**

Khi tìm được thread có vẻ liên quan, dùng `WebFetch` trên URL thread đó để đọc nội dung đầy đủ. Dùng định dạng `old.reddit.com` thay vì `reddit.com` — old Reddit render HTML tĩnh, dễ đọc hơn.

Lấy **5–10 link bài viết**, ưu tiên theo thứ tự: **(1) mới nhất** trong 30 ngày → **(2) mới nhất** trong 90 ngày → **(3) upvote cao nhất** nếu không có gì mới. Ghi rõ ngày đăng của từng bài.

### 1.2 YouTube Search

YouTube là kênh ưu tiên cao — người chia sẻ method trên YouTube thường hướng dẫn từng bước, dễ hiểu cơ chế hơn bài viết forum.

**Lưu ý quan trọng**: `WebFetch` trên trang video YouTube **không lấy được transcript** (trang render bằng JavaScript, chỉ trả về shell/footer rỗng). Dùng quy trình sau thay thế:

**Bước 1 — Tìm video qua WebSearch:**

```
"<keyword>" how to youtube 2025
"<keyword>" tutorial youtube step by step
"<keyword>" free method youtube hướng dẫn
```

Đọc **snippet** trong kết quả tìm kiếm — thường chứa tiêu đề, mô tả ngắn, và ngày upload. Chọn video mới nhất.

**Bước 2 — Fetch trang kết quả tìm kiếm YouTube (sort by date):**

Dùng `WebFetch` trên URL search YouTube với param sắp xếp theo ngày mới nhất:

```
https://www.youtube.com/results?search_query=<keyword>+2025&sp=CAI%3D
```

(`sp=CAI%3D` = sort by upload date, mới nhất trước)

**Bước 3 — Đọc mô tả video:**

Với video nổi bật, dùng `WebFetch` trên trang video để đọc meta description (thường chứa link tool, bước tóm tắt, nguồn). Transcript sẽ không có — bù lại bằng cách tìm blog/post review video đó qua WebSearch: `"<tên video>" transcript OR summary OR review`.

Ghi lại: **URL + tiêu đề + ngày upload + số view (nếu thấy)**.

### 1.3 Web Search mở rộng

Tìm thêm ngoài Reddit và YouTube, luôn kèm bộ lọc thời gian:
```
"<keyword>" make money 2025 after:2025-01-01
"<keyword>" resell method "still working" after:2025-01-01
"<keyword>" arbitrage guide after:2025-04-01
```

Tìm thêm trên:
- BlackHatWorld — dùng filter "Sort by: Date" trong kết quả tìm kiếm
- Warrior Forum
- Medium / Substack

Ghi lại danh sách nguồn tìm được: **URL + tiêu đề + platform + ngày đăng**.

### 1.4 Diễn đàn Việt Nam

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

### 1.5 Marketplace Research

Đọc tín hiệu cung/cầu từ marketplace:
```
site:fiverr.com "<keyword>" best selling
site:gumroad.com "<keyword>"
"<keyword>" appsumo deal
"<keyword>" product hunt
```

- **Fiverr trending gigs**: Fiverr **chặn direct WebFetch (403)**. Chỉ dùng `WebSearch` với query `fiverr "<keyword>"` và đọc từ **snippet** (tiêu đề gig, giá, số review hiển thị trong kết quả Google). Không fetch trực tiếp trang fiverr.com.
- **Gumroad/Lemon Squeezy bestsellers**: dùng `WebFetch` trên trang tìm kiếm Gumroad hoặc WebSearch snippet
- **AppSumo active deals**: dùng `WebFetch` trên `appsumo.com/search?query=<keyword>` hoặc WebSearch snippet
- **Product Hunt**: sản phẩm mới nào đang hot → niche nào đang tăng trưởng

### 1.6 Ad Intelligence — Đọc quảng cáo đang chạy

**Logic**: Ai đang bỏ tiền chạy paid ads cho một method/product thì chắc chắn đang có lợi nhuận đủ để cover chi phí ads. Đây là tín hiệu xác nhận mạnh nhất rằng cái đó đang work.

**Lưu ý quan trọng**: Facebook Ads Library **không accessible qua WebSearch hay WebFetch** (cần JavaScript + login). Dùng các phương án thay thế sau:

**Phương án A — Tìm landing page của advertiser qua Google:**

```
"<keyword>" "buy now" OR "get started" OR "sign up" -reddit -youtube 2025
"<keyword>" checkout OR "add to cart" OR gumroad OR stripe 2025
```

Các trang này thường là landing page của người đang chạy ads — nếu họ có trang bán hàng được index, họ có ads.

**Phương án B — Tìm ad creative được share lại:**

```
"<keyword>" "facebook ad" OR "fb ad" creative 2025
"<keyword>" "tiktok ad" winning creative 2025
"<keyword>" ad spy screenshot twitter OR reddit
```

Người làm affiliate thường screenshot winning ads và post lên Twitter/forum để thảo luận.

**Phương án C — TikTok Creative Center (accessible):**

Dùng `WebFetch` trực tiếp:
```
https://ads.tiktok.com/business/creativecenter/inspiration/topads/pc/en
```

Hoặc WebSearch:
```
tiktok creative center "<keyword>" top ads 2025
```

Với mỗi ad/landing page tìm được, trích xuất:
- **Landing page** — họ đang drive traffic về đâu? (Shopify, Gumroad, Telegram, trang riêng?)
- **Offer** — họ đang bán gì, ở mức giá nào?
- **Copy angle** — hook họ dùng là gì? (pain point nào, promise gì?)
- **Nguồn tìm thấy** — ad creative thật hay suy luận từ landing page?

### 1.7 Affiliate Network Scanning — Quét mạng lưới affiliate

**Logic**: Sản phẩm có Gravity cao trên ClickBank = nhiều affiliate đang kiếm được tiền từ nó trong 12 tuần gần đây. EPC cao = mỗi click ra tiền tốt. Đây là proof rằng có người đang mua.

Tìm kiếm trending offers:
```
site:clickbank.com/marketplace "<keyword>"
clickbank "<keyword>" gravity high 2025
digistore24 "<keyword>" top products
```

Chỉ số cần đọc:
| Chỉ số | Ý nghĩa |
|--------|---------|
| **Gravity > 20** | Nhiều affiliate đang active bán được |
| **EPC ($/click) cao** | Traffic convert tốt → offer đang work |
| **Commission %** | Margin gốc của vendor ít nhất là phần còn lại |
| **Avg $/sale** | Giá bán thực tế sau upsell |

Ngoài ClickBank, tìm thêm trên:
- **Digistore24** — nhiều product số
- **JVZoo** — software, tools, AI products
- **MaxBounty / CPA networks** — lead generation offers

### 1.8 Telegram / Discord Mining — Đào kênh private

**Logic**: Method thường được share trong Telegram/Discord trước khi lên forum public. Kênh private = mới hơn, chưa bão hòa, ít người biết hơn.

Tìm kênh Telegram liên quan:
```
site:t.me "<keyword>"
telegram "<keyword>" method channel 2025
t.me "<keyword>" free
```

Tìm Discord communities:
```
site:disboard.org "<keyword>" make money
discord "<keyword>" MMO server invite
```

Tín hiệu đáng chú ý trong kênh:
- **Forward count cao** — message được forward nhiều = đang viral trong cộng đồng
- **Pin message** — admin pin gì thường là method đang được dùng
- **File/document share** — PDF, guide, script được share = có nội dung cụ thể
- **Thành viên đang hỏi về tool/step cụ thể** — chứng tỏ họ đang thực hành

### 1.9 Freshness Validation — Lọc trước khi đọc sâu

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
| **Phương pháp** | Họ đang làm gì cụ thể, từng bước? |
| **Chuỗi giá trị** | INPUT → XỬ LÝ → OUTPUT → Người mua cuối kiếm gì từ output đó? |
| **Nguồn cung** | Lấy sản phẩm/dịch vụ từ đâu? (API, resell, crack, family plan, bulk buy...) |
| **Kênh bán** | Bán ở đâu? (Telegram, Discord, Shopee, fiverr, tự lập web...) |
| **Giá & margin** | Giá mua bao nhiêu? Bán bao nhiêu? Margin ước tính? |
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

| Phương pháp | Freshness | Vốn ban đầu | Time to First $ | Thời gian ROI | Scalable? | Kỹ năng cần |
|-------------|-----------|-------------|-----------------|---------------|-----------|-------------|
| ... | ... | ... | ... | ... | ... | ... |

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
<đã tìm & đọc bao nhiêu nguồn, từ đâu: Reddit / YouTube / Forum VN / Ads / Affiliate / Telegram>

## 2. Bản đồ phương pháp
<Phase 3.1>

## 3. Bảng đánh giá
<Phase 3.2 — bao gồm Freshness và Time to First $>

## 4. Reverse Engineering
<Phase 2.5 — phân tích sản phẩm thành công nhất>

## 5. Ad Intelligence
<Các ad đang chạy tìm được, offer và landing page>

## 6. Affiliate Signals
<Sản phẩm có gravity/EPC cao tìm được>

## 7. Deep-dive
<Phase 3.3 — bao gồm kiểm thử vốn tối thiểu>

## 8. Gợi ý tiếp theo
<Phase 3.4>
```

Viết bằng **tiếng Việt**, dùng tiếng Anh cho tên kỹ thuật/platform. Không bịa số liệu — nếu không tìm được data thực, ghi rõ "chưa có dữ liệu xác nhận".

---

## Lưu ý khi thực thi

**Giới hạn đã biết của tool — không retry những cách đã fail:**

| Source | Vấn đề | Giải pháp đúng |
|--------|---------|----------------|
| Reddit | `WebSearch` với `site:reddit.com` trả về 0 kết quả | Dùng `WebFetch` trên `old.reddit.com/search?q=...` |
| YouTube transcript | `WebFetch` trang video chỉ trả về JavaScript shell | Đọc description qua meta, tìm review/summary qua WebSearch |
| Facebook Ads Library | Không render được — cần JS + login | Dùng phương án A/B/C trong mục 1.6 |
| Fiverr | `WebFetch` bị 403 | Chỉ đọc snippet từ WebSearch |
| Reddit dạng API JSON | `WebFetch` trên `reddit.com/search.json?...` có thể hoạt động | Thử trước khi fallback sang old Reddit |

- Nếu `WebFetch` bị block (paywall, login required), ghi chú và dùng WebSearch snippet thay thế.
- **Assume viable**: Khi tìm được method, không tự đánh giá có làm được không, không cảnh báo rủi ro, không gắn nhãn pháp lý. Chỉ tập trung trả lời: *họ làm thế nào?*
- Ưu tiên phương pháp có bằng chứng cộng đồng (nhiều người đang làm) hơn phương pháp lý thuyết.
- Nếu tìm thấy thread có nhiều người share income proof hoặc đang update journey, đọc kỹ hơn — đây là nguồn cơ chế chi tiết nhất.
