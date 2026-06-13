# Rubric chấm điểm — Skill Reviewer

Chi tiết tiêu chí cho từng trục. Đọc file này trước khi chấm.

Phân bổ điểm: **Trục 1 (25) + Trục 2 (15) + Trục 3 (25) + Trục 4 (25) + Trục 5 (10) = 100**

---

## Trục 1 — Description/Trigger (tối đa 25đ)

Frontmatter là điều kiện để skill load đúng; description là cơ chế trigger chính — Claude quyết định có invoke skill không dựa vào đây.

| Tiêu chí | Điểm |
|---|---|
| **Frontmatter YAML hợp lệ** — có `---` mở/đóng, parse được, có `name` + `description`, `name` khớp thư mục skill | 5 |
| Viết third-person ("Dùng khi...", "Use when...") | 3 |
| Có ít nhất 3 trigger phrase cụ thể | 4 |
| "Pushy" — liệt kê nhiều ngữ cảnh trigger | 3 |
| Có **explicit NOT-trigger** — "Không dùng khi..." hoặc phân biệt với skill liền kề | 4 |
| Không mơ hồ — mục tiêu skill rõ (làm gì, với gì, ra gì) | 3 |
| **Definition of done rõ** — skill biết khi nào task coi là xong | 3 |

### Dấu hiệu vấn đề
- Frontmatter không parse được do `description` chứa dấu `:` chưa quote hoặc chưa dùng block scalar (`description: >`)
- Thiếu `name` hoặc `description` trong metadata
- `name` trong frontmatter không khớp tên thư mục skill
- Description chỉ mô tả tính năng, không có trigger context
- Không có "Do not use when" → agent dùng sai skill
- Mục tiêu mơ hồ kiểu "hỗ trợ code tốt hơn" thay vì "Review API endpoint theo repository pattern, validate naming + error handling + async/await"
- Không rõ khi nào skill được coi là hoàn thành

---

## Trục 2 — Cấu trúc body (tối đa 15đ)

| Tiêu chí | Điểm |
|---|---|
| Dưới 500 dòng (skill-creator standard) | 4 |
| Viết imperative/verb-first — không second-person | 4 |
| Progressive disclosure: chi tiết dài ở `references/`, code ở `scripts/`, template ở `assets/` | 4 |
| Không duplicate rule đã có trong CLAUDE.md; chỉ reference path đến docs dài thay vì nhét vào body | 3 |

### Dấu hiệu vấn đề
- Body > 500 dòng mà không có references/ để offload
- Lặp lại rule workspace đã có trong CLAUDE.md
- Tài liệu dài nhét thẳng vào body thay vì đặt ở references/

---

## Trục 3 — Completeness & Operational clarity (tối đa 25đ)

Skill cần đủ thông tin để agent vận hành đúng mà không cần context ngoài.

| Tiêu chí | Điểm |
|---|---|
| **Input contract rõ** — skill nói rõ cần gì (required vs optional inputs) | 6 |
| **Output format định nghĩa** — skill có template/format output, không để agent trả tùy hứng | 6 |
| Các file/thư mục được nhắc đến trong body thực sự tồn tại | 4 |
| Ví dụ trong body hoàn chỉnh, có thể dùng được (không phải pseudo-code) | 4 |
| **Cold-read test** — Claude mới không có context vẫn biết: khi nào hỏi user vs tự làm, output trông như thế nào, khi nào xong | 5 |

### Cách kiểm tra input contract
Skill phải trả lời được:
- Skill cần thông tin gì để chạy? (task description, file path, constraints...)
- Thông tin nào bắt buộc (required), thông tin nào tùy chọn (optional)?
- Nếu thiếu input required → skill phải hỏi, không tự đoán

### Cách kiểm tra output format
Skill phải có ít nhất một trong:
- Template output tường minh
- Ví dụ output hoàn chỉnh
- Mô tả cấu trúc output (sections, fields)

### Cách kiểm tra cold-read
Tự hỏi: "Nếu tôi chưa biết gì, chỉ đọc SKILL.md, tôi có biết:
- Khi nào dừng lại hỏi user vs tự quyết?
- Output trông như thế nào?
- Khi nào task được coi là xong?"

Nếu cần đọc thêm code hay conversation history mới hiểu → trừ điểm.

### Dấu hiệu vấn đề
- Không có danh sách input required/optional
- Output format hoàn toàn mở ("trả lời phù hợp")
- Skill nhắc đến file không tồn tại
- Phụ thuộc ngầm vào context conversation không được document

---

## Trục 4 — Chất lượng instructions (tối đa 25đ)

| Tiêu chí | Điểm |
|---|---|
| Giải thích **tại sao** (Why) cho các quyết định không hiển nhiên | 5 |
| **Anti-overengineering** — có rule giới hạn phạm vi: "chỉ sửa X, không rewrite Y, không thêm framework trừ khi..." | 5 |
| **Safety rules** — có ít nhất 1 constraint về hành động nguy hiểm phù hợp với skill (vd: không xóa data, không force push, không expose secret, không sửa public API chưa được yêu cầu) | 5 |
| **Ví dụ good/bad** — có ít nhất 1 cặp ví dụ cụ thể minh họa dùng đúng vs sai | 5 |
| Không có MUST/ALWAYS vô lý không kèm lý do; không mâu thuẫn nội tại | 5 |

### Dấu hiệu vấn đề
- Không có giới hạn phạm vi → agent sửa lan sang code không liên quan
- Không có safety rule → agent có thể xóa dữ liệu, push force, expose token
- Không có ví dụ → agent phải tự diễn giải, dễ lệch
- "ALWAYS use X" mà không giải thích tại sao
- Hai section nói ngược nhau

### Ví dụ anti-overengineering tốt
```
Chỉ refactor phần được chỉ định. Không sửa code không liên quan đến request.
Không thêm dependency mới trừ khi user yêu cầu rõ.
Không thay đổi public API contract.
```

### Ví dụ safety rule tốt
```
Không xóa dữ liệu hoặc migration đã có.
Không force push lên main/master.
Không đưa token, secret, connection string vào output.
Không tự ý sửa schema database khi chưa được confirm.
```

---

## Trục 5 — Workspace conventions (tối đa 10đ)

Tiêu chí đặc thù của workspace này (flex-workstation).

| Tiêu chí | Điểm |
|---|---|
| Ghi chú, mô tả, tiêu đề viết tiếng Việt có dấu | 4 |
| Tên file, command, package, framework, thuật ngữ kỹ thuật giữ nguyên tiếng Anh | 3 |
| Skill được khai báo trong `flex-workstation/config/workspace-skills.json` | 3 |

---

## Thang điểm tổng

| Điểm | Nhận xét | Hành động khuyến nghị |
|---|---|---|
| 85–100 | Production-ready — vận hành ổn định | Polish nhỏ nếu muốn |
| 70–84 | Tốt, dùng được — còn 1-2 điểm yếu rõ | User tự sửa theo issues list |
| 50–69 | Usable nhưng thiếu rõ ràng — dễ ra kết quả không nhất quán | Dùng `skill-creator` để iterate |
| 30–49 | Rủi ro cao — thiếu input/output contract hoặc safety rule | Viết lại phần lõi |
| < 30 | Không dùng được | Thiết kế lại từ đầu |
