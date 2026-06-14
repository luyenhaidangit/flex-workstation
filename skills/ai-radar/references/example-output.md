# Ví dụ output — AI Radar

## Output tốt (Good)

```
## AI Radar — 2026-06-13
**Chủ đề:** agent-design

### Đáng chú ý
1. **smolagents** (GitHub Trending) — thư viện agent nhỏ gọn của HuggingFace, chạy tool-call qua code thay vì JSON schema → loại bỏ tầng parse, giảm lỗi khi tool trả structured data phức tạp
2. **"Evaluating Agentic Systems" (Anthropic blog)** — framework 4 chiều đánh giá agent: task completion, tool precision, safety boundary, cost per run → có rubric sẵn, áp dụng được ngay vào dự án agent hiện tại

### Có thể thử ngay
- Clone smolagents và chạy example notebook để so sánh với cách gọi tool hiện tại
- Lấy rubric từ bài Anthropic, đánh giá 1 agent đang build theo 4 chiều

### Không lấy được
- papers.cool — login-wall
```

**Tại sao tốt:** item cụ thể, có tên + nguồn + lý do đáng chú ý + hành động ngay; "Không lấy được" trung thực thay vì bỏ qua.

---

## Output xấu (Bad)

```
## AI Radar — hôm nay
**Chủ đề:** tổng quát

### Đáng chú ý
1. Có nhiều bài viết thú vị về AI agent gần đây
2. LLM đang phát triển rất nhanh, nhiều model mới ra mắt
3. https://example.com/ai-trends-2026 — tổng hợp xu hướng AI

### Có thể thử ngay
- Đọc thêm về AI
- Cập nhật kiến thức thường xuyên
```

**Tại sao xấu:**
- Item 1-2: mơ hồ, không có nguồn, không rõ mới ở chỗ nào — nhồi nội dung nhạt
- Item 3: link bịa (chưa fetch được) — vi phạm rule "Không bịa"
- "Có thể thử ngay": hành động không cụ thể, không áp dụng được ngay
- Thiếu section "Không lấy được" dù không fetch được nguồn nào
