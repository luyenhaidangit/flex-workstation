# Bản đồ hệ thống workspace

Tài liệu này mô tả cấu trúc workstation root cho developer và coding agent.

## Snapshot hiện tại

```text
flex-workstation/
├── .agents/              # Cấu hình Codex agent
├── .claude/              # Cấu hình Claude Code (settings.json, hooks, commands)
├── .codex/               # Cấu hình Codex CLI
├── docs/                 # Tài liệu workstation
├── scripts/              # Bootstrap và tooling scripts
├── skills/               # Skill source dùng chung
├── workstation.json      # Manifest repo được clone khi bootstrap
├── flex-agents/          # Repo con độc lập
├── flex-auth-service/    # Repo con độc lập — service xác thực/ủy quyền
├── flex-api-gateway/     # Repo con độc lập — API Gateway
├── flex-microfrontend/   # Repo con độc lập — Frontend client
└── flex-environment/     # Repo con độc lập — Local/dev infrastructure stack
```

## Luồng bootstrap

```text
SYNC_WORKSPACE.cmd
  → scripts\bootstrap.ps1
    → đọc workstation.json
    → clone repo còn thiếu vào flex-workstation\
    → fetch --prune và pull --ff-only repo đã có nếu working tree sạch
    → kiểm tra/cài ccusage và rtk
    → kiểm tra/cài Claude Code nếu thiếu
    → add/update marketplace luyenhaidangit/flex-agents
    → install/update plugin flex-agents@flex-agents
```

Script bỏ qua repo có local changes, origin khác cấu hình hoặc detached HEAD.

## Runtime AI tooling

| Tooling | Vị trí | Mục đích |
| --- | --- | --- |
| Claude Code config | `.claude/` | Settings, hooks, commands cho Claude Code |
| Claude plugin marketplace | `luyenhaidangit/flex-agents` | Cập nhật bộ skill/plugin khi chạy bootstrap |
| Codex agent context | `AGENTS.md`, `.agents/` | Context và cấu hình agent cho Codex |
| Codex CLI config | `.codex/` | Cấu hình Codex CLI |
| Skill source | `skills/` | Nguồn skill dùng chung, không được sync bởi bootstrap |
| `ccusage` | User global CLI | Theo dõi token/cost usage Claude |
| `rtk` | User global CLI | Giảm token shell output |
| Workstation config | `workstation.json` | Manifest repo được clone khi bootstrap |

## Quy tắc source-of-truth

- Sửa tài liệu workspace tại `docs/`.
- Sửa skill tại `skills/<skill-name>/SKILL.md`.
- Sửa runtime config trực tiếp tại `CLAUDE.md`, `AGENTS.md`, `.claude/`, `.agents/`, `.codex/`.
- Repo nghiệp vụ được clone vào `flex-workstation/` theo `workstation.json`, là Git repo độc lập và được ignore bởi Git của workstation.
