# Onboarding workstation

Tài liệu này hướng dẫn bootstrap `flex-workstation` trên Windows.

## Cấu trúc workspace

Các repository được đặt ngang hàng trong `C:\Workspace\Project`:

```text
C:\Workspace\Project\
|-- flex-workstation\
|-- flex-auth-service\
|-- flex-api-gateway\
|-- flex-microfrontend\
|-- flex-environment\
+-- ...
```

## Chạy bootstrap

Double-click:

```text
SYNC_WORKSPACE.cmd
```

Hoặc chạy thủ công từ thư mục `flex-workstation`:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\bootstrap.ps1
```

Bootstrap kiểm tra `git`, VS Code CLI `code` và `winget`; sau đó sync các file template từ `workspaces/templates/` ra project root `C:\Workspace\Project\flex-workstation`:

- `CLAUDE.md` và `AGENTS.md`
- `.claude/` cho Claude Code
- `.agents/` cho Codex agent context
- `.codex/` cho Codex CLI

File runtime đã tồn tại ở đích được ghi đè bằng template khi sync để workspace hiện tại nhận thay đổi mới. Riêng `.claude/settings.local.json` được giữ nguyên nếu đã tồn tại vì đây là cấu hình local theo máy/người dùng.

Bootstrap cũng kiểm tra/cài `ccusage`, `rtk` và Claude Code khi cần. Sau khi có Claude Code, bootstrap add/update marketplace `luyenhaidangit/flex-agents`, install plugin `flex-agents@flex-agents` nếu thiếu, rồi chạy `claude plugin update flex-agents@flex-agents` để lấy bộ skill/plugin mới nhất. Dùng `-SkipCcusageInstall`, `-SkipRtkInstall`, `-SkipRtkInit` hoặc `-UseWinget` khi cần kiểm soát các bước này.

## Cấu hình agent

| Công cụ | File cấu hình | Ghi chú |
| --- | --- | --- |
| Claude Code | `.claude/settings.json` | Cấu hình model và permissions dùng chung. |
| Claude Code | `.claude/settings.local.json` | Thiết lập local theo máy/người dùng. |
| Codex CLI | `.codex/config.toml` | Cấu hình model, approval policy và sandbox. |
| Codex | `AGENTS.md`, `.agents/` | Context và resource theo template. |

Skill source dùng chung nằm trong `flex-workstation/skills/`. Bootstrap không đưa các skill local này vào runtime target; bộ skill Claude Code được cập nhật qua plugin `flex-agents@flex-agents`.

## Mở workspace và coding agent

- `OPEN_WORKSPACE.cmd`: mở `C:\Workspace\Project\flex-workstation` trong VS Code.
- `OPEN_CLAUDE.cmd`: mở Claude Code tại project root `C:\Workspace\Project\flex-workstation` với `--dangerously-skip-permissions`; chỉ dùng trong workspace tin cậy.
- `OPEN_CODEX.cmd`: mở Codex tại project root `C:\Workspace\Project\flex-workstation`; hành vi CLI lấy từ `.codex/config.toml`.

## Troubleshooting

- Nếu `code`, `claude` hoặc `codex` chưa có trong PATH, cài công cụ tương ứng và mở terminal mới.
- Nếu thay đổi template, chạy lại `SYNC_WORKSPACE.cmd` để cập nhật runtime file tương ứng. Với cấu hình local theo máy/người dùng, sửa trực tiếp `.claude/settings.local.json`.
