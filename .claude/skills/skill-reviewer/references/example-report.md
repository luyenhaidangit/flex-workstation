# Ví dụ end-to-end — Skill Review

Minh họa một review hoàn chỉnh: từ input đến output.

---

## Input

```
/skill-reviewer run-tests
```

Skill `run-tests` có SKILL.md 45 dòng, frontmatter YAML không parse được do `description` chứa dấu `:`, không có references/, không có ví dụ good/bad, không khai báo trong workspace-skills.json.

---

## Output mẫu

---

## Skill Review: run-tests
**Score: 46/100**

| Trục | Điểm | Tối đa |
|---|---|---|
| Description/Trigger | 9 | 25 |
| Cấu trúc body | 12 | 15 |
| Completeness & Operational clarity | 13 | 25 |
| Chất lượng instructions | 9 | 25 |
| Workspace conventions | 3 | 10 |

### Issues (theo mức độ ưu tiên)
1. `SKILL.md:1-4` — frontmatter YAML không parse được do dấu `:` trong description → đổi sang `description: >` và indent nội dung description ở các dòng tiếp theo
2. `SKILL.md:3` — description thiếu NOT-trigger, không phân biệt với skill `run-lint` → thêm "Không dùng khi chỉ cần chạy linter (dùng `run-lint` thay thế)"
3. `SKILL.md:3` — definition of done không có → thêm "Task hoàn thành khi output test runner đã được in trong chat"
4. `SKILL.md:12-18` — thiếu ví dụ good/bad cho cách gọi lệnh → thêm 1 cặp minh họa đúng vs sai
5. `SKILL.md` (toàn file) — không có safety rule → thêm "Không chạy test có side effect (write to DB, send email) trừ khi user xác nhận"
6. `workspace-skills.json` — skill chưa được khai báo → thêm entry và chạy `SYNC_WORKSPACE_SKILLS.cmd`

### Không có vấn đề tại
- Cấu trúc body viết imperative, dưới 500 dòng
- Input contract có phân biệt required/optional

### Tóm tắt
Skill chưa nên dùng production vì frontmatter YAML có nguy cơ làm skill không load. Khuyến nghị dùng `skill-creator` để iterate nhanh hơn — sửa YAML trước, rồi bổ sung definition of done và khai báo workspace-skills.json.
