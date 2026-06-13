# flex-workstation

`flex-workstation` là workspace điều phối: quản lý các project cá nhân, tài liệu triển khai, danh sách task, kiến trúc hệ thống, và skill có thể tái sử dụng khi làm việc với Claude Code.

## Mục đích

- Tập trung tài liệu định hướng cho các project trong cùng workspace.
- Theo dõi task triển khai theo từng giai đoạn.
- Ghi lại kiến trúc, quy ước kỹ thuật, cách tổ chức thư mục và trách nhiệm của từng project.
- Lưu skill dùng chung để tái sử dụng giữa nhiều project.
- Giảm việc giải thích lại bối cảnh khi tiếp tục làm việc trong các phiên sau.

## Cấu trúc thư mục

```text
flex-workstation/
|-- .vscode/
|   +-- tasks.json
|-- config/
|   +-- workspace-skills.json
|-- docs/
|   |-- architecture.md
|   |-- onboarding.md
|   |-- projects.md
|   +-- tasks.md
|-- scripts/
|   +-- bootstrap.ps1
|   +-- sync-workspace-skills.ps1
|-- skills/
|   +-- README.md
|-- templates/
|   +-- project-root/
|       +-- .claude/
|-- .gitattributes
|-- SETUP_WORKSPACE.cmd
|-- OPEN_WORKSPACE.cmd
|-- OPEN_CLAUDE.cmd
|-- SYNC_WORKSPACE_SKILLS.cmd
|-- CLAUDE.md
+-- README.md
```

## Tài liệu chính

- [CLAUDE.md](CLAUDE.md): quy ước cho Claude Code khi làm việc trong workstation.
- [config/workspace-skills.json](config/workspace-skills.json): khai báo skill local dùng chung cho workspace Claude.
- [docs/onboarding.md](docs/onboarding.md): bootstrap máy mới, cấu trúc local, mở workspace VS Code.
- [docs/architecture.md](docs/architecture.md): kiến trúc tổng quan, vai trò từng project, quy ước tích hợp.
- [docs/projects.md](docs/projects.md): danh sách Git project được theo dõi chung.
- [docs/tasks.md](docs/tasks.md): danh sách task, trạng thái, độ ưu tiên.
- [skills/README.md](skills/README.md): skill org-share dùng chung trong workspace.

## Khởi tạo nhanh

Trên Windows: double-click `SETUP_WORKSPACE.cmd` để chạy bootstrap, sau đó double-click `OPEN_WORKSPACE.cmd` để mở VS Code tại `C:\Workspace\Project`.

Khi cần mở Claude Code tại workspace, double-click `OPEN_CLAUDE.cmd`. File này chạy Claude với quyền bỏ qua prompt permission, chỉ dùng trong workspace tin cậy.

Khi chỉ cần cập nhật skill dùng chung, double-click `SYNC_WORKSPACE_SKILLS.cmd`.

Chi tiết bootstrap, manual install, troubleshooting: xem [docs/onboarding.md](docs/onboarding.md).

## Skill dùng chung

Skill dùng chung cho workspace được khai báo trong `config/workspace-skills.json` và được sync vào:

```text
C:\Workspace\Project\.claude\skills
```

Bootstrap sẽ tự chạy sync. Nếu muốn sync thủ công:

```powershell
.\scripts\sync-workspace-skills.ps1
```

Hoặc double-click:

```text
SYNC_WORKSPACE_SKILLS.cmd
```
