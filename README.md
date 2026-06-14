# flex-workstation

`flex-workstation` là workspace điều phối: quản lý các project cá nhân, tài liệu triển khai, danh sách task, kiến trúc hệ thống, và skill có thể tái sử dụng khi làm việc với Claude Code hoặc Codex.

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
|   +-- workspace-assistants.json
|-- docs/
|   |-- architecture.md
|   |-- onboarding.md
|   |-- projects.md
|   +-- tasks.md
|-- scripts/
|   +-- bootstrap.ps1
|   +-- check-skill-path.ps1
|   +-- sync-workspace-skills.ps1
|-- skills/
|   +-- README.md
|-- templates/
|   +-- project-root/
|       |-- AGENTS.md
|       |-- CLAUDE.md
|       |-- .agents/
|       +-- .claude/
|-- .gitattributes
|-- OPEN_WORKSPACE.cmd
|-- OPEN_CLAUDE.cmd
|-- SYNC_WORKSPACE.cmd
|-- CLAUDE.md
+-- README.md
```

## Tài liệu chính

- [CLAUDE.md](CLAUDE.md): quy ước cho Claude Code khi làm việc trong workstation.
- [config/workspace-assistants.json](config/workspace-assistants.json): cấu hình assistant target cho Claude/Codex và skill local dùng chung.
- [docs/onboarding.md](docs/onboarding.md): bootstrap máy mới, cấu trúc local, mở workspace VS Code.
- [docs/architecture.md](docs/architecture.md): kiến trúc tổng quan, vai trò từng project, quy ước tích hợp.
- [docs/projects.md](docs/projects.md): danh sách Git project được theo dõi chung.
- [docs/tasks.md](docs/tasks.md): danh sách task, trạng thái, độ ưu tiên.
- [skills/README.md](skills/README.md): skill org-share dùng chung trong workspace.

## Hook bảo vệ skill runtime

Claude settings dùng hook `PreToolUse` gọi `scripts/check-skill-path.ps1` để chặn sửa trực tiếp vào `C:\Workspace\Project\.claude\skills` và `C:\Workspace\Project\.agents\skills`. Skill source phải được sửa trong `flex-workstation/.claude/skills` hoặc path đã khai báo trong `config/workspace-assistants.json`, rồi sync lại.

## Khởi tạo nhanh

Trên Windows: double-click `SYNC_WORKSPACE.cmd` để chạy bootstrap/sync workspace, sau đó double-click `OPEN_WORKSPACE.cmd` để mở VS Code tại `C:\Workspace\Project`.

Khi cần mở Claude Code tại workspace, double-click `OPEN_CLAUDE.cmd`. File này chạy Claude với quyền bỏ qua prompt permission, chỉ dùng trong workspace tin cậy.

Khi cần cập nhật cấu hình workspace hoặc skill dùng chung, double-click `SYNC_WORKSPACE.cmd`.

Chi tiết bootstrap, manual install, troubleshooting: xem [docs/onboarding.md](docs/onboarding.md).

Khi mở Claude tại `C:\Workspace\Project`, root `CLAUDE.md` được bootstrap từ `templates/project-root/CLAUDE.md`. Khi mở Codex tại cùng workspace, root `AGENTS.md` được bootstrap từ `templates/project-root/AGENTS.md`. Hai file này cùng giúp assistant hiểu `flex-workstation` là source-of-truth cho cấu hình và skill source.

## Skill dùng chung

Skill dùng chung cho workspace được khai báo trong `config/workspace-assistants.json` và được sync vào runtime của Claude và Codex:

```text
C:\Workspace\Project\.claude\skills
C:\Workspace\Project\.agents\skills
```

Bootstrap sẽ tự chạy sync. Nếu muốn sync thủ công:

```powershell
.\scripts\sync-workspace-skills.ps1
```

Hoặc double-click:

```text
SYNC_WORKSPACE.cmd
```

Nếu Claude đang mở sẵn, chạy `/reload-skills` trong Claude sau khi sync. Nếu Codex đang mở sẵn mà skill mới chưa xuất hiện, mở session mới.
