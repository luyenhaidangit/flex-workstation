# Contract: Skill Directory Structure

**Feature**: `specs/000001-speckit-codex-support`
**Type**: Filesystem interface contract (shared between Claude Code và Codex CLI)

---

## Mô tả

Đây là contract định nghĩa cấu trúc thư mục skills mà **cả hai agent phải tuân thủ**. Thay đổi cấu trúc này có thể làm agents không tìm thấy skills.

---

## Source of Truth: `.agents/skills/`

```
.agents/
└── skills/
    └── <skill-name>/
        └── SKILL.md          ← bắt buộc
```

### SKILL.md — required frontmatter

```yaml
---
name: "<skill-name>"          # phải khớp với tên thư mục
description: "<mô tả ngắn>"  # dùng để agent tự chọn skill
---

<nội dung instruction>
```

### Constraints

- `name` phải là kebab-case, unique trong registry
- `description` phải đủ rõ để agent chọn đúng khi implicit invocation
- Không có subdirectory lồng nhau trong `<skill-name>/`

---

## Consumer: Claude Code — `.claude/skills/`

```
.claude/
└── skills/
    └── <skill-name>/         ← Windows Directory Junction → .agents/skills/<skill-name>/
        └── SKILL.md          ← đọc qua junction, không phải bản sao
```

### Junction lifecycle

| Event | Action |
|-------|--------|
| bootstrap.ps1 chạy lần đầu | Tạo junction cho mọi skill trong `.agents/skills/` |
| Skill mới thêm vào `.agents/skills/` | Chạy lại bootstrap → junction được tạo tự động |
| Skill bị xóa khỏi `.agents/skills/` | Junction trở thành dangling — xóa thủ công hoặc cleanup script |
| Clone repo mới | bootstrap.ps1 tạo lại toàn bộ junctions |

---

## Consumer: Codex CLI — `.agents/skills/`

Codex đọc trực tiếp từ `.agents/skills/` — không cần junction hay config bổ sung.

### Invocation

- **Explicit**: Mention skill name trong prompt hoặc dùng `$` để chọn từ menu
- **Implicit**: Codex tự chọn khi task description khớp với `description:` trong SKILL.md

---

## Breaking Changes

Các thay đổi sau đây là **breaking** và yêu cầu cập nhật đồng thời ở nhiều nơi:

| Thay đổi | Impact |
|----------|--------|
| Đổi tên thư mục skill | Junction cũ trở thành dangling; cần tạo junction mới |
| Đổi `name:` trong SKILL.md mà không đổi thư mục | Behavior undefined cho implicit invocation |
| Xóa `.agents/skills/` | Mất toàn bộ skills cho cả hai agent |
| Đổi `SKILL.md` thành tên khác | Cả hai agent không nhận ra skill |
