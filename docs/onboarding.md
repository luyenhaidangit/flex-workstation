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

Bootstrap kiểm tra `git`, VS Code CLI `code` và `winget`; sau đó copy các file template chưa tồn tại từ `workspaces/templates/` ra `C:\Workspace\Project`:

- `CLAUDE.md` và `AGENTS.md`
- `.claude/` cho Claude Code
- `.agents/` cho Codex agent context
- `.codex/` cho Codex CLI

File và thư mục đã tồn tại ở đích được giữ nguyên. Đây là cơ chế scaffold, không phải đồng bộ ghi đè. Bootstrap không sync skill, agent persona hoặc command từ nguồn ngoài.

Bootstrap cũng kiểm tra/cài `ccusage`, `rtk` và Claude Code khi cần. Dùng `-SkipCcusageInstall`, `-SkipRtkInstall`, `-SkipRtkInit` hoặc `-UseWinget` khi cần kiểm soát các bước này.

## Cấu hình agent

| Công cụ | File cấu hình | Ghi chú |
| --- | --- | --- |
| Claude Code | `.claude/settings.json` | Cấu hình model và permissions dùng chung. |
| Claude Code | `.claude/settings.local.json` | Thiết lập local theo máy/người dùng. |
| Codex CLI | `.codex/config.toml` | Cấu hình model, approval policy và sandbox. |
| Codex | `AGENTS.md`, `.agents/` | Context và resource theo template. |

Skill source dùng chung nằm trong `flex-workstation/skills/`. Bootstrap không đưa các skill này vào runtime target.

## Mở workspace và coding agent

- `OPEN_WORKSPACE.cmd`: mở `C:\Workspace\Project` trong VS Code.
- `OPEN_CLAUDE.cmd`: mở Claude Code tại workspace root với `--dangerously-skip-permissions`; chỉ dùng trong workspace tin cậy.
- `OPEN_CODEX.cmd`: mở Codex tại workspace root; hành vi CLI lấy từ `.codex/config.toml`.

## Troubleshooting

- Nếu `code`, `claude` hoặc `codex` chưa có trong PATH, cài công cụ tương ứng và mở terminal mới.
- Nếu thay đổi template nhưng runtime file đã tồn tại, bootstrap sẽ không ghi đè. Cập nhật file runtime có chủ đích, rồi mirror phần cấu hình ổn định về `workspaces/templates/`.
