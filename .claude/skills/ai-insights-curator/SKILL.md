---
name: ai-insights-curator
description: Thu thập, chắt lọc và lưu trữ tri thức AI hữu ích từ một nguồn bất kỳ (GitHub repo, bài viết/blog, video YouTube/Facebook, hoặc text dán trực tiếp) thành một note markdown tiếng Việt trong kho ai-knowledge/. Dùng skill này BẤT CỨ KHI NÀO người dùng đưa một link hoặc nội dung về AI/coding agent/LLM/prompting/tooling và muốn "tóm tắt", "chắt lọc", "lưu lại", "tổng hợp", "ghi chú", "lưu vào kho", "có gì hay", hoặc muốn theo dõi/đề xuất nguồn AI để cải thiện công việc — kể cả khi họ chỉ dán link mà chưa nói rõ "tạo note". Cũng dùng khi người dùng muốn xem lại kho tri thức, tạo digest tổng hợp định kỳ, hoặc xin gợi ý nguồn AI đáng follow.
---

# AI Insights Curator

Biến các nguồn AI rời rạc (repo, bài viết, video, đoạn text) thành tri thức **áp dụng được vào công việc**, lưu tích lũy trong một kho markdown cá nhân. Mục tiêu không phải tóm tắt cho có, mà là trả lời được: *cái này giúp cải thiện cách mình làm việc như thế nào?*

## Nguyên tắc ngôn ngữ

Viết note bằng **tiếng Việt có dấu**. Giữ nguyên tiếng Anh cho tên riêng, tên repo, command, package, API, framework và thuật ngữ kỹ thuật (vd: `agent`, `prompt`, `quality gate`, `RAG`, `subagent`). Không dịch máy móc thuật ngữ sang tiếng Việt nếu bản tiếng Anh phổ biến hơn.

## Vị trí kho tri thức

- Kho: `ai-knowledge/` ở gốc repo `flex-workstation` (tức `C:\Workspace\Project\flex-workstation\ai-knowledge\`).
- Mỗi nguồn = một file `ai-knowledge/notes/<slug>.md`.
- Index tra cứu: `ai-knowledge/INDEX.md` (cập nhật mỗi lần thêm note).
- Bản tổng hợp định kỳ: `ai-knowledge/digests/<YYYY-MM-DD>.md` (khi người dùng yêu cầu digest).

Nếu thư mục chưa tồn tại thì tạo. Đừng xóa hay ghi đè note cũ trừ khi người dùng yêu cầu rõ.

## Quy trình xử lý một nguồn

Khi người dùng đưa một nguồn, đi qua 4 bước:

### 1. Thu thập (Collect)

Nhận diện loại nguồn rồi lấy nội dung — xem mục "Xử lý theo loại nguồn" bên dưới. Nếu fetch thất bại (paywall, login, FB video không có transcript), nói rõ giới hạn và đề nghị người dùng dán nội dung/transcript thủ công thay vì bịa.

### 2. Chắt lọc (Distill)

Đọc kỹ và rút ra phần *có giá trị*, bỏ phần marketing/lặp. Trả lời 4 câu hỏi cốt lõi:
- **Đây là gì?** — 1-2 câu mô tả trung thực.
- **Tại sao đáng chú ý?** — điều gì mới/khác/hữu ích so với cách làm hiện tại.
- **Điểm cốt lõi** — 3-5 ý chính, mỗi ý là một insight cụ thể (không phải mô tả chung chung).
- **Cách áp dụng vào công việc** — ít nhất 1-2 hành động cụ thể người dùng có thể thử. Đây là phần quan trọng nhất; nếu không nghĩ ra cách áp dụng thì nói thẳng là "chưa rõ áp dụng trực tiếp, giá trị chủ yếu là tham khảo".

### 3. Phân loại (Tag)

Gắn 1-4 tag từ bộ tag chuẩn để sau này tra cứu theo chủ đề. Bộ tag gợi ý (mở rộng khi cần, nhưng tái dùng tag cũ trước):
`coding-agent`, `prompting`, `tooling`, `RAG`, `agent-design`, `workflow`, `eval`, `mcp`, `claude-code`, `llm-fundamentals`, `productivity`, `security`.

### 4. Lưu (Save)

- Viết note theo template ở `assets/note-template.md`.
- Đặt tên file: slug kebab-case từ tiêu đề, vd `addyosmani-agent-skills.md`.
- Thêm một dòng vào `ai-knowledge/INDEX.md`.
- Báo lại cho người dùng: đường dẫn note + tóm tắt 1 dòng "cách áp dụng" nổi bật nhất.

## Template note

Đọc và theo đúng `assets/note-template.md`. Điền đầy đủ frontmatter (source, type, date, tags) để sau này lọc/sort được.

## Cập nhật INDEX.md

`INDEX.md` là bảng tra nhanh. Mỗi note một dòng, dạng:

```
- [Tiêu đề](notes/<slug>.md) — `tag1` `tag2` — Áp dụng: <một câu> (thêm YYYY-MM-DD)
```

Thêm dòng mới vào đầu danh sách (mới nhất lên trên). Không lặp lại nội dung note trong INDEX.

## Xử lý theo loại nguồn

**GitHub repo (URL):**
- Fetch README và mô tả repo. Nếu cần, xem cấu trúc thư mục cấp 1 và các file quan trọng (vd `SKILL.md`, `docs/`) để hiểu repo *làm gì* và *dùng thế nào*.
- Ghi rõ: repo giải quyết vấn đề gì, cách cài/dùng cơ bản, và phần nào đáng "mượn ý" cho công việc của người dùng.

**Bài viết / blog (URL):**
- Fetch nội dung trang. Bỏ qua phần điều hướng/quảng cáo. Tập trung luận điểm chính và ví dụ cụ thể.

**Video (YouTube / Facebook / link):**
- Ưu tiên transcript/mô tả nếu lấy được. Facebook video thường KHÔNG có transcript công khai — khi đó nói rõ và xin người dùng dán nội dung hoặc tự tóm tắt từ phần mô tả/caption mà họ cung cấp.
- Đừng bịa nội dung video không truy cập được.

**Text dán trực tiếp:**
- Xử lý ngay như nội dung gốc. Nếu người dùng dán kèm link, ghi link vào `source`.

## Đề xuất nguồn AI hữu ích

Khi người dùng hỏi "follow nguồn nào", "có repo/kênh nào hay", hoặc sau khi lưu vài note cùng chủ đề, gợi ý nguồn liên quan từ `references/sources.md`. Ưu tiên nguồn khớp với tag mà người dùng hay lưu. Khuyến khích người dùng thử 1-2 nguồn rồi mới mở rộng, thay vì ôm hết.

## Digest tổng hợp (tùy chọn)

Khi người dùng muốn "tổng hợp tuần này / gần đây": đọc các note trong `ai-knowledge/notes/` theo ngày, gom thành một file `ai-knowledge/digests/<YYYY-MM-DD>.md` gồm:
- 3-5 insight nổi bật nhất gần đây.
- "Nên thử ngay" — 2-3 hành động cụ thể.
- Chủ đề đang nổi (theo tag xuất hiện nhiều).

## Lưu ý chất lượng

- Trung thực: nếu nguồn nông/marketing, nói thẳng giá trị thấp thay vì thổi phồng.
- Cụ thể hơn chung chung: "dùng quality gate yêu cầu bằng chứng trước khi đánh dấu task xong" tốt hơn "cải thiện chất lượng code".
- Không nhồi nhét: 3-5 điểm cốt lõi là đủ; thà ít mà sắc.
