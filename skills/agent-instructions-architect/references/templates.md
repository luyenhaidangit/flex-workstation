# Templates — Mẫu cho từng loại instruction file

## CLAUDE.md (project root)

```markdown
# <Project name>

<1-2 dòng repo là gì, vai trò trong nhóm>

## Conventions
- <convention 1, cụ thể>
- <convention 2>

## Commands
- Build: `<cmd>`
- Test: `<cmd>`
- Lint: `<cmd>`

## Gotchas
- <thứ dễ sai mà đọc code không tự nói ra>

## Tài liệu cần đọc theo task
- Tổng quan: `README.md`
- <khác>
```

Giữ dưới ~500 tokens. Phần dài → tách.

---

## Memory file

```markdown
---
name: <slug ngắn>
description: <1 dòng cụ thể, future-Claude dùng để judge relevance>
metadata:
  type: <user | feedback | project | reference>
---

<nội dung chính>

**Why:** <lý do — bắt buộc với feedback/project>
**How to apply:** <khi nào áp dụng — bắt buộc với feedback/project>
```

---

## Subagent

```markdown
---
name: <slug>
description: <khi nào main agent nên delegate — pushy, cụ thể context trigger>
tools: <allow-list, hoặc bỏ trống = inherit>
model: <opus | sonnet | haiku tùy task complexity>
---

<system prompt: vai trò, mục tiêu, ràng buộc, output format, ví dụ nếu cần>
```

---

## Skill

```markdown
---
name: <slug>
description: >
  <pushy, kê rõ trigger context, không chung chung.
  Có NOT-trigger. Có DoD.>
---

# <Tên>

<1-2 dòng skill làm gì>

## Khi nào dùng
<triggers cụ thể + NOT-trigger>

## Quy trình
<steps có input contract và DoD>
```

---

## Slash command

```markdown
---
description: <hiển thị trong /help, ngắn>
---

<prompt template, có thể dùng $ARGUMENTS>
```

---

## Output style

```markdown
---
name: <slug>
description: <khi nào dùng>
---

<instructions về tone, format, length, không đụng hành vi>
```

---

## Rules file

```markdown
---
description: <khi nào rule áp dụng, path scope nếu có>
---

<một hành vi ngắn, kèm Why nếu non-obvious>
```
