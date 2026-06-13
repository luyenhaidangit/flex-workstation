---
name: ai-radar
description: >
  Dùng khi người dùng muốn biết "có gì mới về AI không", "AI hôm nay có gì hay",
  "tìm repo/bài về [chủ đề]", "cập nhật AI/LLM/agent/tooling", "đề xuất gì không" —
  skill tự chủ động fetch các nguồn uy tín (GitHub Trending, HN, blog kỹ thuật) và
  trả briefing trực tiếp trong chat. KHÔNG cần người dùng cung cấp link hay nội dung.
  KHÔNG dùng khi user đã cung cấp link hoặc nội dung sẵn để tóm tắt
  (dùng ai-insights-curator thay thế).
---

# AI Radar

Tự tìm và tổng hợp nội dung AI mới/hữu ích từ các nguồn uy tín, trả kết quả trực tiếp trong chat. Không cần người dùng cung cấp link.

## Args tùy chọn

- **Chủ đề:** `agent-design`, `claude-code`, `RAG`, `prompting`, `mcp`, `tooling`, `llm-fundamentals`
- **Timeframe:** `hôm nay`, `tuần này`
- Không có arg → quét tổng quát tất cả chủ đề

## Quy trình

### 1. Xác định phạm vi

- Đọc `references/sources.md` để lấy danh sách nguồn và mapping tag → nhóm nguồn.
- Nếu có arg chủ đề → ưu tiên nguồn trong nhóm khớp tag.
- Nếu không có arg → quét toàn bộ nhóm nguồn.
- Chỉ sử dụng nguồn trong danh sách này. Không tự thêm source ngoài `references/sources.md` trừ khi user yêu cầu rõ.

### 2. Fetch và lọc

Với mỗi nguồn liên quan:
- Fetch trang/feed.
- Lọc lấy nội dung mới hoặc nổi bật, bỏ: nội dung cũ, quảng cáo, bài không liên quan AI/LLM/tooling.
- Nếu fetch thất bại (timeout, login-wall) → bỏ qua, ghi chú "không lấy được", không bịa nội dung.

### 3. Chắt lọc

Với mỗi item đáng chú ý, đánh giá 3 chiều:
- **Đây là gì?** — 1 câu mô tả trung thực.
- **Tại sao đáng chú ý?** — điều gì mới, khác, hoặc hữu ích so với hiện tại.
- **Áp dụng được không?** — có thể thử ngay vào workflow/code không; nếu không thì nói thẳng "tham khảo thôi".

### 4. Trả kết quả

Format briefing trực tiếp trong chat:

```
## AI Radar — [ngày hôm nay]
**Chủ đề:** [tổng quát / chủ đề cụ thể]

### Đáng chú ý
1. **[Tên]** ([nguồn]) — [1 câu mô tả] → [tại sao đáng chú ý]
2. ...

### Có thể thử ngay
- [Hành động cụ thể 1]
- [Hành động cụ thể 2]

### Không lấy được (nếu có)
- [tên nguồn] — [lý do]
```

Tối đa **5 item** mỗi lần. Thà ít mà sắc hơn nhiều mà nhạt.

Xem ví dụ output đầy đủ (good/bad) tại `references/example-output.md`.

## Nguyên tắc chất lượng

- **Trung thực:** nếu không tìm thấy gì đáng chú ý → nói thẳng, không nhồi nội dung nhạt. Vì bài nhạt làm mất trust nhanh hơn không có bài.
- **Không bịa:** không tự tạo ra link hay nội dung chưa fetch được. Vì link bịa dẫn user vào 404 hoặc sai nguồn — mất trust tức thì.
- **Ưu tiên có hành động:** repo có code, bài có ví dụ cụ thể > bài lý thuyết chung chung. Vì user muốn áp dụng được ngay, không phải đọc lý thuyết.
- **Không lưu file** trừ khi người dùng yêu cầu rõ. Vì skill là read-and-report, không phải persist.

Task hoàn thành khi briefing đã trả trong chat và user chưa yêu cầu thêm.
