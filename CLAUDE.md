@AGENTS.md

## Claude Code

- Cấu hình dùng chung ở `.claude/settings.json`; thiết lập theo máy/người dùng ở `.claude/settings.local.json` và không được commit.
- `.claude/skills/` là junction do bootstrap tạo tới `.agents/skills/`; chỉ sửa skill nguồn đã được Git theo dõi.
- Hook kiểm tra format skill nằm tại `.claude/hooks/skill-format-guard.js`.
