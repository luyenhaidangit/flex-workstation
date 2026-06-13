# Rubric chấm điểm — Skill Reviewer

Chi tiết tiêu chí cho từng trục. Đọc file này trước khi chấm.

---

## Trục 1 — Description/Trigger (tối đa 25đ)

Description là cơ chế trigger chính — Claude quyết định có invoke skill không dựa vào đây.

### Tiêu chí

| Tiêu chí | Điểm |
|---|---|
| Viết third-person ("Dùng khi...", "Use when...") — không phải first/second person | 5 |
| Có ít nhất 3 trigger phrase cụ thể (vd: "khi user nói 'review skill X'") | 5 |
| "Pushy" — liệt kê nhiều ngữ cảnh trigger, không chỉ 1 use case | 5 |
| Có ngưỡng NOT-trigger hoặc phân biệt với skill liền kề (tránh overtrigger) | 5 |
| Không mơ hồ — đọc xong biết ngay skill làm gì | 5 |

### Dấu hiệu vấn đề
- Description chỉ mô tả tính năng, không có trigger context
- Dùng "I will" hoặc "You should" thay vì third-person
- Overlap lớn với skill khác mà không phân biệt
- Quá ngắn (< 30 words) hoặc quá chung chung

---

## Trục 2 — Cấu trúc body (tối đa 20đ)

| Tiêu chí | Điểm |
|---|---|
| Dưới 500 dòng (skill-creator standard) | 5 |
| Viết imperative/verb-first — không second-person ("Đọc file...", không "Bạn nên đọc...") | 5 |
| Progressive disclosure: chi tiết dài ở `references/`, code ở `scripts/`, template ở `assets/` | 5 |
| References được gọi tên rõ trong body kèm hướng dẫn khi nào đọc | 5 |

### Dấu hiệu vấn đề
- Body > 500 dòng mà không có references/ để offload
- Có bảng, ví dụ dài, rubric chi tiết nhét thẳng vào body
- Nhắc đến file references/ nhưng không nói khi nào cần đọc
- Dùng "bạn", "bạn nên", "hãy" thay vì imperative

---

## Trục 3 — Completeness (tối đa 20đ)

| Tiêu chí | Điểm |
|---|---|
| Các file/thư mục được nhắc đến trong body thực sự tồn tại | 7 |
| Ví dụ trong body hoàn chỉnh, có thể chạy/dùng được (không phải pseudo-code) | 6 |
| Cold-read test: Claude mới không có context conversation có thể follow và ra đúng output không | 7 |

### Cách kiểm tra cold-read
Tự hỏi: "Nếu tôi chưa biết gì về skill này, chỉ đọc SKILL.md, tôi có biết:
- Khi nào dừng lại hỏi user vs tự làm?
- Output trông như thế nào?
- Khi nào task được coi là xong?"

Nếu cần đọc thêm code hay conversation history mới hiểu → trừ điểm.

### Dấu hiệu vấn đề
- Nhắc đến `references/foo.md` nhưng file không tồn tại
- Output format không được mô tả đủ rõ
- Phụ thuộc ngầm vào context conversation không được document

---

## Trục 4 — Chất lượng instructions (tối đa 20đ)

| Tiêu chí | Điểm |
|---|---|
| Giải thích **tại sao** (Why) cho các quyết định không hiển nhiên | 7 |
| Không có MUST/ALWAYS/NEVER vô lý — nếu có thì đi kèm lý do rõ | 5 |
| Không overfit vào ví dụ hẹp — instructions mang tính nguyên lý, dùng được rộng | 5 |
| Không mâu thuẫn nội tại giữa các section | 3 |

### Dấu hiệu vấn đề
- "ALWAYS use X format" mà không giải thích tại sao
- Instructions chỉ hoạt động cho 1-2 use case hẹp trong description
- Hai section nói ngược nhau (vd: section A bảo "hỏi user", section B bảo "tự quyết")
- Giải thích WHAT nhưng không giải thích WHY

---

## Trục 5 — Workspace conventions (tối đa 15đ)

Tiêu chí đặc thù của workspace này (flex-workstation).

| Tiêu chí | Điểm |
|---|---|
| Ghi chú, mô tả, tiêu đề viết tiếng Việt có dấu | 5 |
| Tên file, command, package, framework, thuật ngữ kỹ thuật giữ nguyên tiếng Anh | 5 |
| Skill được khai báo trong `flex-workstation/config/workspace-skills.json` | 5 |

### Dấu hiệu vấn đề
- Tiếng Việt không dấu trong body/description
- Dịch thuật ngữ kỹ thuật sang tiếng Việt (vd: "kỹ năng" thay vì "skill")
- Chưa có entry trong `workspace-skills.json`

---

## Thang điểm tổng

| Điểm | Nhận xét | Hành động khuyến nghị |
|---|---|---|
| ≥ 80 | Tốt, sẵn sàng dùng | Polish 1-2 điểm nhỏ nếu muốn |
| 60–79 | Dùng được, có điểm yếu rõ | User tự sửa theo issues list |
| < 60 | Cần cải thiện đáng kể | Dùng `skill-creator` để iterate |
