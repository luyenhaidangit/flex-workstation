# Data Model: Speckit hỗ trợ Codex

**Feature**: `specs/000001-speckit-codex-support`

Tính năng này không có data model theo nghĩa truyền thống (không có database, không có state runtime). Thay vào đó, đây là **configuration model** — mô tả cấu trúc file/thư mục và quan hệ giữa chúng.

---

## Entities

### Skill

Đơn vị tái sử dụng chứa instructions cho agent.

| Thuộc tính | Loại | Mô tả |
|------------|------|-------|
| `name` | string | Định danh skill, phải unique trong scope |
| `description` | string | Mô tả ngắn để agent chọn skill phù hợp |
| `content` | markdown | Nội dung instruction đầy đủ |
| `directory` | path | Thư mục chứa `SKILL.md` |

**Quan hệ**: một Skill có đúng một `SKILL.md`. Skill source nằm tại `.agents/skills/<name>/SKILL.md`.

---

### SkillJunction

Liên kết machine-local từ `.claude/skills/<name>/` đến `.agents/skills/<name>/`.

| Thuộc tính | Loại | Mô tả |
|------------|------|-------|
| `source` | path | `.claude/skills/<name>/` (directory junction) |
| `target` | path | `.agents/skills/<name>/` (actual directory) |
| `type` | enum | `junction` (Windows NTFS Directory Junction) |

**Invariant**: Mỗi Skill trong `.agents/skills/` PHẢI có junction tương ứng trong `.claude/skills/` sau khi bootstrap chạy.

---

### SkillRegistry

Thư mục scan được agent tìm kiếm skills.

| Registry | Agent | Path | Ghi chú |
|----------|-------|------|---------|
| Project (source) | Codex | `.agents/skills/` | Source of truth, tracked by git |
| Project (junction) | Claude Code | `.claude/skills/` | Machine-local, gitignored |
| User | Codex | `~/.codex/skills/` | Ngoài phạm vi tính năng này |
| User | Claude Code | `~/.claude/skills/` | Ngoài phạm vi tính năng này |

---

## State Transitions

```
bootstrap.ps1 chạy
    │
    ├── .agents/skills/<name>/ tồn tại, .claude/skills/<name>/ chưa có
    │       └── tạo junction → READY
    │
    ├── .claude/skills/<name>/ là junction hợp lệ
    │       └── bỏ qua → READY
    │
    └── .claude/skills/<name>/ là thư mục thật (legacy)
            └── xóa thư mục thật → tạo junction → READY
```

---

## Validation Rules

- `SKILL.md` phải có frontmatter với `name:` và `description:`
- Tên thư mục skill PHẢI khớp với `name:` trong frontmatter
- Số lượng junctions trong `.claude/skills/` PHẢI bằng số skills trong `.agents/skills/` sau bootstrap
