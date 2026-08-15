# flex-workstation

`flex-workstation` là workspace điều phối: quản lý tài liệu, bootstrap, skill source và cấu hình AI tooling dùng chung cho các project Flex.

## Mục đích

- Tập trung tài liệu định hướng cho các project trong cùng workspace.
- Cung cấp entrypoint Windows để bootstrap và mở workspace.
- Lưu skill source dùng chung trong `skills/`.

## Cấu trúc chính

```text
flex-workstation/
├── docs/            # Tài liệu workspace
├── scripts/         # Bootstrap và tooling scripts
├── skills/          # Skill source dùng chung
├── .claude/         # Cấu hình Claude Code
├── .agents/         # Cấu hình Codex agent
├── .codex/          # Cấu hình Codex CLI
├── workstation.json # Manifest repo được clone khi bootstrap
├── CLAUDE.md        # Context cho Claude Code
├── AGENTS.md        # Context cho Codex agent
└── <repo-con>/      # Repo con độc lập, ignore bởi Git của workstation
```

## Khởi tạo nhanh

Double-click `SYNC_WORKSPACE.cmd` để chạy bootstrap. Script sẽ:

- Cấu hình mã hóa UTF-8 cho PowerShell và tự động thiết lập toàn cục `%USERPROFILE%\.wslconfig` (`localhostForwarding=false`) cho WSL2 trên Windows.
- Đọc `workstation.json` và clone repo còn thiếu vào `flex-workstation/`.
- Cập nhật repo đã có bằng `git fetch --prune` + `git pull --ff-only`.
- Kiểm tra và cài Claude Code, `ccusage`, `rtk` nếu thiếu.

Repo đang có local changes, origin khác cấu hình hoặc đang ở detached HEAD sẽ được cảnh báo và bỏ qua. Sau khi sync xong, dùng `OPEN_VSCODE.cmd`, `OPEN_CLAUDE.cmd` hoặc `OPEN_CODEX.cmd` theo nhu cầu.

## Entrypoint Windows

| File | Mục đích |
| --- | --- |
| `SYNC_WORKSPACE.cmd` | Bootstrap: clone/pull repos trong manifest và cài tool |
| `OPEN_VSCODE.cmd` | Mở workstation trong VS Code |
| `OPEN_CLAUDE.cmd` | Mở Claude Code với `--dangerously-skip-permissions` |
| `OPEN_CODEX.cmd` | Mở Codex |

## Cấu hình coding agent

| Công cụ | Runtime config |
| --- | --- |
| Claude Code | `.claude/`, `CLAUDE.md` |
| Codex agent | `.agents/`, `AGENTS.md` |
| Codex CLI | `.codex/` |

## Cấu hình workstation

Khai báo repo cần có trong workspace tại `workstation.json`:

- `repositories.items[].name`: tên thư mục local.
- `repositories.items[].url`: Git remote URL.
- `repositories.items[].branch`: nhánh cần clone, tùy chọn.

## Tài liệu

- [CLAUDE.md](CLAUDE.md): quy ước khi làm việc trong `flex-workstation`.
- [TASKS.md](TASKS.md): theo dõi spec Speckit đang chạy song song.
- [SPEC.md](SPEC.md): quy ước đặt tên thư mục, file, skill và namespace.
- [docs/setup/onboarding.md](docs/setup/onboarding.md): bootstrap máy mới và cách mở workspace.
- [docs/architecture/system-map.md](docs/architecture/system-map.md): bản đồ workspace, runtime AI tooling và tổng quan kiến trúc hệ thống.
- [docs/architecture/liquibase-sql-first.md](docs/architecture/liquibase-sql-first.md): quy ước triển khai PostgreSQL/pgvector bằng Liquibase SQL-first trong `flex-database`.
- [docs/speckit/workflow.md](docs/speckit/workflow.md): luồng sử dụng Speckit.
- [docs/speckit/template-guidelines.md](docs/speckit/template-guidelines.md): quy ước thiết kế và bảo trì template Speckit.
- [docs/speckit/maintenance.md](docs/speckit/maintenance.md): ghi chú bảo trì Speckit/runtime.
- [docs/projects.md](docs/projects.md): danh sách project được theo dõi.
