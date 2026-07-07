# Bản đồ hệ thống workspace

Tài liệu này mô tả cấu trúc `flex-workstation` cho developer và coding agent.

## Snapshot hiện tại

```text
flex-workstation/
├── .claude/              # Cấu hình Claude Code, hooks, commands và skills runtime
├── .codex/               # Cấu hình Codex CLI
├── .specify/             # Spec Kit runtime, templates, scripts và workflows
├── .vscode/              # VS Code workspace tasks
├── docs/                 # Tài liệu workstation
├── scripts/              # Bootstrap và tooling scripts
├── specs/                # Spec Kit feature specs
├── flex-agents/          # Repo con độc lập - skill/plugin cho coding agents
├── flex-auth-service/    # Repo con độc lập - service xác thực/ủy quyền
├── flex-api-gateway/     # Repo con độc lập - API Gateway
├── flex-microfrontend/   # Repo con độc lập - frontend client
├── flex-environment/     # Repo con độc lập - local/dev infrastructure stack
├── AGENTS.md             # Context cho Codex agent
├── CLAUDE.md             # Context cho Claude Code
├── README.md             # Index và hướng dẫn tổng quan
└── workstation.json      # Manifest repo được clone khi bootstrap
```

Các repo con được clone vào trong root này nhưng là Git repo độc lập và được ignore bởi Git của workstation.

## Manifest repo

`workstation.json` là source-of-truth cho danh sách repo được sync bởi bootstrap. Hiện manifest khai báo:

| Repo | URL |
| --- | --- |
| `flex-agents` | `https://github.com/luyenhaidangit/flex-agents.git` |
| `flex-auth-service` | `https://github.com/luyenhaidangit/flex-auth-service` |
| `flex-api-gateway` | `https://github.com/luyenhaidangit/flex-api-gateway.git` |
| `flex-microfrontend` | `https://github.com/luyenhaidangit/flex-microfrontend` |
| `flex-environment` | `https://github.com/luyenhaidangit/flex-environment` |

Nếu thêm repo mới, thêm entry vào `repositories.items`. Trường `branch` là tùy chọn; nếu không có, script clone theo default branch của remote và pull theo branch hiện tại của repo local.

## Projects

| Project | Vai trò | Công nghệ |
| --- | --- | --- |
| `flex-agents` | Repository skill/plugin cho coding agents | Markdown, runtime files |
| `flex-auth-service` | Service xác thực/ủy quyền | .NET / ASP.NET Core |
| `flex-api-gateway` | API Gateway | .NET, Dockerfile, Jenkinsfile |
| `flex-microfrontend` | Frontend client | Angular, Node.js |
| `flex-environment` | Local/dev infrastructure stack | Docker Compose |

## Luồng bootstrap

```text
SYNC_WORKSPACE.cmd
  → scripts\bootstrap.ps1
    → kiểm tra git, VS Code CLI code và winget
    → kiểm tra runtime config CLAUDE.md, AGENTS.md, .claude, .agents, .codex
    → scripts\sync-repositories.ps1 -PullExisting
      → đọc workstation.json
      → clone repo còn thiếu vào flex-workstation\
      → fetch --prune và pull --ff-only repo đã có nếu working tree sạch
    → kiểm tra/cài ccusage
    → kiểm tra/cài rtk và chạy rtk init nếu cần
    → kiểm tra/cài Claude Code nếu thiếu
    → kiểm tra/cài uv và specify-cli
    → initialize Spec Kit nếu .specify\templates chưa có
    → add/update marketplace luyenhaidangit/flex-agents
    → install/update plugin flex-agents@flex-agents
```

Script bỏ qua repo có local changes, origin khác cấu hình hoặc đang ở detached HEAD. Nếu repo có branch khác `branch` trong manifest, script cảnh báo nhưng vẫn pull branch hiện tại.

## Runtime AI tooling

| Tooling | Vị trí | Mục đích |
| --- | --- | --- |
| Claude Code config | `CLAUDE.md`, `.claude/` | Context, settings, hooks, commands và skill runtime cho Claude Code |
| Claude plugin marketplace | `luyenhaidangit/flex-agents` | Cập nhật bộ skill/plugin khi chạy bootstrap |
| Codex agent context | `AGENTS.md` | Context và quy tắc làm việc cho Codex |
| Codex CLI config | `.codex/` | Cấu hình Codex CLI |
| Spec Kit | `.specify/`, `specs/` | Template, workflow và feature specs |
| VS Code tasks | `.vscode/tasks.json` | Shortcut command khi dùng `Terminal: Run Task` trong VS Code |
| `ccusage` | User global CLI | Theo dõi token/cost usage Claude |
| `rtk` | User global CLI | Giảm token output khi chạy shell command |
| `uv` | User global CLI | Cài và quản lý `specify-cli` |
| Workstation config | `workstation.json` | Manifest repo được clone khi bootstrap |

## Source-of-truth

- Tài liệu workstation: `README.md`, `docs/`.
- Manifest repo con: `workstation.json`.
- Runtime config: `CLAUDE.md`, `AGENTS.md`, `.claude/`, `.codex/`.
- Spec Kit: `.specify/`, `specs/`.
- VS Code task shortcuts: `.vscode/tasks.json`.
- Repo nghiệp vụ: các repo con trong `workstation.json`.

Khi cập nhật hành vi chung trong `CLAUDE.md`, rà lại `AGENTS.md` để Codex có quy tắc tương đương nhưng dùng đúng thuật ngữ/tooling Codex.
