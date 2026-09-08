@AGENTS.md

## Claude Code Rules

- **Cấu hình**:
  - Dùng chung repo: `.claude/settings.json`
  - Thiết lập máy/cá nhân: `.claude/settings.local.json` (tuyệt đối không commit file này).
- **Quản lý Skills**:
  - Thư mục `.claude/skills/` chỉ là junction trỏ tới `.agents/skills/`.
  - **Quy tắc bắt buộc**: Khi tạo hoặc chỉnh sửa skill, chỉ thao tác trực tiếp trên source gốc tại `.agents/skills/`.
  - Kiểm tra tính hợp lệ qua hook: `.claude/hooks/skill-format-guard.js`.
