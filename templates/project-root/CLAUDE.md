# CLAUDE.md

Workspace root: `C:\Workspace\Project`.

`flex-workstation` là source-of-truth cho tài liệu, bootstrap, template, skill source và cấu hình workspace.

Không tạo source file trực tiếp tại workspace root, trừ runtime generated config trong `.claude`.

Khi người dùng yêu cầu tạo hoặc sửa skill dùng chung:

- Tạo source tại `flex-workstation/.claude/skills/<skill-name>/SKILL.md` hoặc thư mục source đã khai báo.
- Khai báo skill trong `flex-workstation/config/workspace-skills.json`.
- Chạy `flex-workstation/SYNC_WORKSPACE_SKILLS.cmd`.
- Nếu Claude đang mở, chạy `/reload-skills` hoặc mở session mới.

Runtime skills được Claude load từ:

```text
C:\Workspace\Project\.claude\skills
```

Tài liệu chi tiết nằm trong:

```text
C:\Workspace\Project\flex-workstation\README.md
```
