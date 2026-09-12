@AGENTS.md

## Claude Code Rules

- **Cấu hình**:
  - Dùng chung repo: `.claude/settings.json`
  - Thiết lập máy/cá nhân: `.claude/settings.local.json` (đã gitignore, không commit).
- **Quản lý Skills**:
  - Thư mục `.claude/skills/` chỉ là junction trỏ tới `.agents/skills/`.
  - **Quy tắc bắt buộc**: Khi tạo hoặc chỉnh sửa skill, chỉ thao tác trực tiếp trên source gốc tại `.agents/skills/`.
