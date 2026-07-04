# flex-workstation

`flex-workstation` là workspace điều phối: quản lý tài liệu, bootstrap, template và skill source dùng chung cho các project Flex.

## Mục đích

- Tập trung tài liệu định hướng cho các project trong cùng workspace.
- Quản lý template cấu hình cho Claude Code và Codex.
- Cung cấp entrypoint Windows để bootstrap và mở workspace.
- Lưu skill source dùng chung trong `skills/`.

## Cấu trúc chính

```text
flex-workstation/
|-- docs/                       # Tài liệu workspace
|-- repos.json                  # Manifest repo được clone khi sync
|-- scripts/                    # Bootstrap và tooling scripts
|-- skills/                     # Skill source dùng chung
|-- workspaces/
|   +-- templates/              # Template được copy ra workspace root
|       |-- AGENTS.md
|       |-- CLAUDE.md
|       |-- .agents/
|       |-- .claude/
|       +-- .codex/
|-- OPEN_CLAUDE.cmd
|-- OPEN_CODEX.cmd
|-- OPEN_WORKSPACE.cmd
|-- SYNC_WORKSPACE.cmd
|-- CLAUDE.md
+-- README.md
```

## Khởi tạo nhanh

Double-click `SYNC_WORKSPACE.cmd` để chạy bootstrap. Script sync các file template từ `workspaces/templates/` ra project root `C:\Workspace\Project\flex-workstation`:

- `CLAUDE.md` và `AGENTS.md`
- `.claude/`, `.agents/` và `.codex/`

Script cũng đọc `repos.json` tại project root workstation và clone các repo còn thiếu về thư mục cha `C:\Workspace\Project`. Repo đã tồn tại sẽ được bỏ qua; bootstrap không tự `git pull` để tránh ảnh hưởng working tree của từng project.

Bootstrap ghi đè runtime config đã có bằng template để workspace hiện tại nhận thay đổi mới khi sync. Riêng `.claude/settings.local.json` được giữ nguyên nếu đã tồn tại vì đây là cấu hình local theo máy/người dùng. Bootstrap không sync skill, agent persona hoặc command từ nguồn ngoài. Sau đó, dùng `OPEN_WORKSPACE.cmd`, `OPEN_CLAUDE.cmd` hoặc `OPEN_CODEX.cmd` theo nhu cầu.

## Cấu hình coding agent

| Công cụ | Template | Runtime target |
| --- | --- | --- |
| Claude Code | `workspaces/templates/.claude/` | `C:\Workspace\Project\flex-workstation\.claude\` |
| Codex agent context | `workspaces/templates/.agents/` và `AGENTS.md` | `C:\Workspace\Project\flex-workstation\.agents\` và `AGENTS.md` |
| Codex CLI | `workspaces/templates/.codex/config.toml` | `C:\Workspace\Project\flex-workstation\.codex/config.toml` |

## Manifest repo

Khai báo repo cần có trong workspace tại `repos.json`:

- `destinationRoot`: thư mục đích, mặc định `..` tức `C:\Workspace\Project`.
- `repositories[].name`: tên thư mục local.
- `repositories[].url`: Git remote URL.
- `repositories[].branch`: nhánh cần clone, tùy chọn.

## Tài liệu

- [CLAUDE.md](CLAUDE.md): quy ước khi làm việc trong `flex-workstation`.
- [docs/onboarding.md](docs/onboarding.md): bootstrap máy mới và cách mở workspace.
- [docs/system-map.md](docs/system-map.md): bản đồ workspace và runtime AI tooling.
- [docs/architecture/overview.md](docs/architecture/overview.md): kiến trúc platform ở mức tổng quan.
- [docs/projects.md](docs/projects.md): danh sách project được theo dõi.
- [docs/tasks.md](docs/tasks.md): task và lịch sử triển khai.
