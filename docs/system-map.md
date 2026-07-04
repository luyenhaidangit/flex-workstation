# Bản đồ hệ thống workspace

Tài liệu này mô tả workspace `C:\Workspace\Project` cho developer và coding agent. Project root cho AI tooling là `C:\Workspace\Project\flex-workstation`. Luồng bootstrap dưới đây được xác nhận từ `SYNC_WORKSPACE.cmd`, `scripts/bootstrap.ps1` và `workspaces/templates/`.

## Snapshot hiện tại

```text
C:\Workspace\Project\
|-- flex-workstation\     # Source-of-truth cho bootstrap, template và tài liệu
|   |-- .agents\          # Runtime template cho Codex agent
|   |-- .claude\          # Runtime cấu hình Claude Code
|   |-- .codex\           # Runtime cấu hình Codex CLI
|-- flex-auth-service\    # Service xác thực/ủy quyền
|-- flex-api-gateway\     # API Gateway
|-- flex-microfrontend\   # Frontend client
+-- flex-environment\     # Local/dev infrastructure stack
```

## Luồng bootstrap

```text
flex-workstation\SYNC_WORKSPACE.cmd
  → scripts\bootstrap.ps1
    → sync file template từ workspaces\templates\
       vào C:\Workspace\Project\flex-workstation\
    → kiểm tra/cài ccusage và rtk
    → kiểm tra/cài Claude Code nếu thiếu
    → add/update marketplace `luyenhaidangit/flex-agents`
    → install/update plugin `flex-agents@flex-agents`
```

`Confirmed`: bootstrap sync `CLAUDE.md`, `AGENTS.md`, `.claude`, `.agents` và `.codex` từ template ra project root `C:\Workspace\Project\flex-workstation`. File đích đã tồn tại được ghi đè bằng template, trừ `.claude/settings.local.json` nếu đã có vì đây là cấu hình local theo máy/người dùng.

`Confirmed`: bootstrap không đọc `workspace-assistants.json` và không chạy `sync-workspace-skills.ps1`. Skill source trong `flex-workstation/skills/` vẫn không được copy vào runtime target. Riêng Claude plugin `flex-agents@flex-agents` được install/update qua marketplace `luyenhaidangit/flex-agents`.

## Runtime AI tooling

| Tooling | Source-of-truth | Runtime target | Mục đích |
| --- | --- | --- | --- |
| Claude Code instruction/config | `workspaces/templates/CLAUDE.md`, `.claude/` | `C:\Workspace\Project\flex-workstation\CLAUDE.md`, `.claude/` | Context, model và permission cho Claude Code. |
| Claude plugin marketplace | `luyenhaidangit/flex-agents` | Claude Code user plugin `flex-agents@flex-agents` | Cập nhật bộ skill/plugin dùng trong Claude Code khi chạy bootstrap. |
| Codex instruction/config | `workspaces/templates/AGENTS.md`, `.agents/`, `.codex/` | `C:\Workspace\Project\flex-workstation\AGENTS.md`, `.agents/`, `.codex/` | Context cho Codex và cấu hình Codex CLI. |
| Skill source | `flex-workstation/skills/` | Không có runtime target do bootstrap quản lý | Lưu source dùng chung, không được sync bởi bootstrap. |
| `ccusage` | `scripts/ensure-ccusage.ps1` | User global CLI | Theo dõi token/cost usage. |
| `rtk` | `scripts/ensure-rtk.ps1` | User global CLI + cấu hình global | Giảm token shell output. |

## Quy tắc source-of-truth

- Sửa template bootstrap tại `flex-workstation/workspaces/templates/`.
- Sửa tài liệu workspace tại `flex-workstation/docs/`.
- Kỳ vọng `SYNC_WORKSPACE.cmd` cập nhật runtime config đã tồn tại từ template; sửa cấu hình dùng chung tại `workspaces/templates/`, rồi chạy sync để đẩy ra workspace root.
- Không đặt mã nguồn nghiệp vụ trong `flex-workstation`; mỗi project nghiệp vụ là một repo ngang hàng.
