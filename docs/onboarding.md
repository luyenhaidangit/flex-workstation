# Onboarding workstation

Tài liệu này hướng dẫn bootstrap `flex-workstation` trên Windows.

## Cấu trúc workspace

Các repository project Flex được clone vào trong workstation root khi chạy sync. Đây là các Git repo độc lập và được ignore bởi Git của workstation:

```text
flex-workstation\
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

Bootstrap kiểm tra `git`, VS Code CLI `code` và `winget`; sau đó clone sub-repos và cài tool:

Bootstrap đọc `workstation.json`, clone các repo còn thiếu vào workstation root, và cập nhật repo đã tồn tại bằng `git fetch --prune` + `git pull --ff-only`. Nếu repo có local changes, origin khác cấu hình hoặc đang ở detached HEAD, bootstrap cảnh báo và bỏ qua repo đó để tránh ghi đè thay đổi cục bộ.

`.claude/settings.local.json` được giữ nguyên nếu đã tồn tại vì đây là cấu hình local theo máy/người dùng.

Bootstrap cũng kiểm tra/cài `ccusage`, `rtk`, `uv`, `specify-cli` và Claude Code khi cần. Với `rtk`, sau khi chạy `rtk init -g --codex`, bootstrap ghi template `scripts/templates/rtk-codex.md` đè lên `~/.codex/RTK.md` — file này do workstation quản lý, không sửa tay ở global. Sau khi có Claude Code, bootstrap add/update marketplace `luyenhaidangit/flex-agents`, install plugin `flex-agents@flex-agents` nếu thiếu, rồi chạy `claude plugin update flex-agents@flex-agents` để lấy bộ skill/plugin mới nhất. Bootstrap cũng chạy `specify init . --integration claude` để khởi tạo spec-kit nếu `.specify/templates/` chưa tồn tại. Dùng `-SkipCcusageInstall`, `-SkipRtkInstall`, `-SkipRtkInit`, `-SkipSpecifyInstall`, `-SkipSpecifyInit` hoặc `-UseWinget` khi cần kiểm soát các bước này.

## Cấu hình agent

| Công cụ | File cấu hình | Ghi chú |
| --- | --- | --- |
| Claude Code | `.claude/settings.json` | Cấu hình model và permissions dùng chung. |
| Claude Code | `.claude/settings.local.json` | Thiết lập local theo máy/người dùng. |
| Codex CLI | `.codex/config.toml` | Cấu hình model, approval policy và sandbox. |
| Codex | `AGENTS.md`, `.agents/` | Context và resource runtime cho Codex. |

Skill source dùng chung nằm trong `flex-workstation/skills/`. Bootstrap không đưa các skill local này vào runtime target; bộ skill Claude Code được cập nhật qua plugin `flex-agents@flex-agents`.

## Cấu hình workstation

Danh sách repo được clone khi sync nằm ở `workstation.json`, trong `repositories.items`. Thêm repo mới bằng cách bổ sung entry:

```json
{
  "name": "ten-repo",
  "url": "https://github.com/org/ten-repo.git",
  "branch": "main"
}
```

Trường `branch` là tùy chọn. Không đưa token hoặc credential vào URL trong manifest.

## Mở workstation và coding agent

- `OPEN_VSCODE.cmd`: mở workstation root trong VS Code.
- `OPEN_CLAUDE.cmd`: mở Claude Code tại workstation root với `--dangerously-skip-permissions`; chỉ dùng trong workstation tin cậy.
- `OPEN_CODEX.cmd`: mở Codex tại workstation root; hành vi CLI lấy từ `.codex/config.toml`.

## Troubleshooting

- Nếu `code`, `claude` hoặc `codex` chưa có trong PATH, cài công cụ tương ứng và mở terminal mới.
- Với cấu hình local theo máy/người dùng, sửa trực tiếp `.claude/settings.local.json`.
