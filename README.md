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

- Đọc `workstation.json` và clone repo còn thiếu vào `flex-workstation/`.
- Cập nhật repo đã có bằng `git fetch --prune` + `git pull --ff-only`.
- Kiểm tra và cài Claude Code, `ccusage`, `rtk` nếu thiếu.
- Cập nhật marketplace và plugin `flex-agents`.

Repo đang có local changes, origin khác cấu hình hoặc đang ở detached HEAD sẽ được cảnh báo và bỏ qua. Sau khi sync xong, dùng `OPEN_WORKSTATION.cmd`, `OPEN_CLAUDE.cmd` hoặc `OPEN_CODEX.cmd` theo nhu cầu.

## Entrypoint Windows

| File | Mục đích |
| --- | --- |
| `SYNC_WORKSPACE.cmd` | Bootstrap: clone repos, cài tool, sync flex-agents |
| `OPEN_WORKSTATION.cmd` | Mở workstation trong VS Code |
| `OPEN_CLAUDE.cmd` | Mở Claude Code với `--dangerously-skip-permissions` |
| `OPEN_CODEX.cmd` | Mở Codex |
| `OPEN_WORKSPACE.cmd` | Alias tương thích → `OPEN_WORKSTATION.cmd` |

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
- [SPEC.md](SPEC.md): quy ước đặt tên thư mục, file, skill và namespace.
- [docs/onboarding.md](docs/onboarding.md): bootstrap máy mới và cách mở workspace.
- [docs/system-map.md](docs/system-map.md): bản đồ workspace và runtime AI tooling.
- [docs/projects.md](docs/projects.md): danh sách project được theo dõi.
- [docs/tasks.md](docs/tasks.md): task và lịch sử triển khai.
