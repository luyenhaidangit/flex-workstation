# CLAUDE.md

`flex-workstation` là workspace điều phối cho nhóm project Flex: tài liệu, bootstrap, skill source và cấu hình AI tooling. Các repo project được clone vào trong project root này dưới dạng Git repo độc lập (xem `workstation.json`).

## Ngôn ngữ

- Dùng tiếng Việt có dấu trong trả lời, tài liệu và ghi chú.
- Giữ nguyên tên file, thư mục, command, package, API, framework và thuật ngữ kỹ thuật bằng English khi đó là định danh kỹ thuật.

## Tooling

| Tool | Mục đích |
| --- | --- |
| `claude` | Claude Code — AI coding agent chính |
| `codex` | Codex CLI — AI coding agent thay thế |
| `rtk` | Proxy shell command để giảm token output |
| `ccusage` | Theo dõi token/cost usage Claude |
| `SYNC_WORKSPACE.cmd` | Bootstrap: clone repos, cài tool, sync flex-agents |

## Cấu trúc project

```text
flex-workstation/
├── docs/            # Tài liệu workspace (system-map, onboarding, tasks)
├── scripts/         # Bootstrap và tooling scripts
├── skills/          # Skill source dùng chung (mỗi skill một thư mục SKILL.md)
├── .claude/         # Cấu hình Claude Code (settings.json, hooks, commands)
├── .agents/         # Cấu hình Codex agent
├── .codex/          # Cấu hình Codex CLI
├── workstation.json # Manifest repo được clone khi bootstrap
├── CLAUDE.md        # File này — context cho Claude Code
├── AGENTS.md        # Context cho Codex agent
└── <repo-con>/      # Repo con độc lập, ignore bởi Git của workstation
```

## Quy tắc làm việc

- Không đưa token, mật khẩu, khóa API, connection string hoặc thông tin nhạy cảm vào repo.
- Không tạo submodule/subtree hoặc liên kết version giữa repo nếu người dùng chưa yêu cầu rõ.
- Không sửa mã nguồn project con khi yêu cầu chỉ thuộc workstation.
- Không xóa hoặc revert thay đổi hiện có nếu không chắc đó là thay đổi do mình tạo.
- Khi thay đổi hành vi, cấu trúc hoặc onboarding, cập nhật `docs/tasks.md` và file tài liệu tương ứng.

## Source-of-truth

| Loại | Vị trí |
| --- | --- |
| Tài liệu workstation | `docs/` |
| Skill dùng chung | `skills/<skill-name>/SKILL.md` |
| Runtime config | `CLAUDE.md`, `AGENTS.md`, `.claude/`, `.agents/`, `.codex/` |

## Entrypoint Windows

| File | Mục đích |
| --- | --- |
| `SYNC_WORKSPACE.cmd` | Bootstrap: clone repos, cài Claude Code / ccusage / rtk, sync flex-agents |
| `OPEN_WORKSTATION.cmd` | Mở workstation trong VS Code |
| `OPEN_CLAUDE.cmd` | Mở Claude Code với `--dangerously-skip-permissions` (chỉ dùng trong workstation tin cậy) |
| `OPEN_CODEX.cmd` | Mở Codex |
| `OPEN_WORKSPACE.cmd` | Alias tương thích → `OPEN_WORKSTATION.cmd` |

## Tài liệu

- Index đầy đủ: `README.md`
- Onboarding/bootstrap: `docs/onboarding.md`
- Bản đồ hệ thống: `docs/system-map.md`
- Task hiện tại: `docs/tasks.md`
