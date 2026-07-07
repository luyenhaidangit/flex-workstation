# Research: Speckit hỗ trợ Codex

**Date**: 2026-07-07
**Feature**: `specs/000001-speckit-codex-support`

---

## Q1: Codex CLI có cơ chế skill riêng không?

**Decision**: Có — Codex CLI scans `.agents/skills/` với định dạng `SKILL.md`.

**Rationale**: Theo OpenAI Codex documentation, Codex scans `.agents/skills/` từ thư mục hiện tại lên đến repository root. Định dạng `SKILL.md` (frontmatter `name:`, `description:` + nội dung) giống hệt với Claude Code. Đây là **cross-agent standard** — thiết kế để nhiều agent dùng chung.

**Alternatives considered**:
- `.codex/skills/` — tồn tại nhưng là Codex-specific; không cross-agent
- `AGENTS.md` inline — chỉ là context tĩnh, không phải skill có thể invoke theo tên

**Sources**: developers.openai.com/codex/skills, agentskills.io

---

## Q2: Claude Code đọc skills từ đâu, có hỗ trợ custom path không?

**Decision**: Claude Code chỉ scan `.claude/skills/` (project) và `~/.claude/skills/` (user). Không có cấu hình custom path.

**Rationale**: Feature request cho custom skills path đang mở (github.com/anthropics/claude-code/issues/22902, #33957) nhưng chưa được implement. Claude Code hiện tại phụ thuộc cứng vào `.claude/skills/`.

**Alternatives considered**:
- Symlink (`ln -s`) — không reliable trên Windows Git Bash
- Copy qua bootstrap — tạo duplication, dễ lệch version
- Chờ Claude Code hỗ trợ custom path — không có timeline rõ ràng

---

## Q3: Giải pháp bridge hai vị trí scan?

**Decision**: Windows Directory Junctions (`mklink /J`) — `.claude/skills/<name>` → `.agents/skills/<name>`.

**Rationale**:
- Directory Junctions trên Windows không yêu cầu admin rights (khác với Symbolic Links)
- Transparent với cả hai agent — mỗi agent đọc từ path của mình nhưng thực sự cùng một file
- Bootstrap (`Sync-SkillJunctions` trong `bootstrap.ps1`) tự tạo/refresh junctions — không cần setup thủ công

**Alternatives considered**:
- mklink /D (symbolic link to dir) — yêu cầu admin hoặc Developer Mode
- robocopy trong bootstrap — copy ≠ junction; thay đổi skill không tự động sync
- Hardlink từng file — hoạt động cho file, không cho thư mục

---

## Tóm tắt quyết định kiến trúc

| Quyết định | Lựa chọn | Lý do |
|------------|----------|-------|
| Skill source of truth | `.agents/skills/` | Cross-agent standard, Codex-native |
| Claude Code access | Directory Junction | Không cần admin, transparent, tự động qua bootstrap |
| Maintenance | `Sync-SkillJunctions` trong bootstrap | Idempotent, chạy tự động với SYNC_WORKSPACE.cmd |
| Git tracking | `.agents/skills/` tracked; `.claude/skills/` gitignored | Junctions là machine-local |
