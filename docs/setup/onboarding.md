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

Bootstrap kiểm tra `git`, VS Code CLI `code` và `winget`; tự động cấu hình UTF-8 cho PowerShell profile và tệp toàn cục `%USERPROFILE%\.wslconfig` (`localhostForwarding=false`) trên Windows; sau đó clone sub-repos và cài tool:

Bootstrap đọc `workstation.json`, clone các repo còn thiếu vào workstation root, và cập nhật repo đã tồn tại bằng `git fetch --prune` + `git pull --ff-only`. Nếu repo có local changes, origin khác cấu hình hoặc đang ở detached HEAD, bootstrap cảnh báo và bỏ qua repo đó để tránh ghi đè thay đổi cục bộ.

`.claude/settings.local.json` được giữ nguyên nếu đã tồn tại vì đây là cấu hình local theo máy/người dùng.

Bootstrap cũng kiểm tra/cài `ccusage`, `rtk`, Antigravity CLI `agy`, `uv`, `specify-cli` và Claude Code khi cần. Với `rtk`, sau khi chạy `rtk init -g --codex`, bootstrap ghi template `scripts/templates/rtk-codex.md` đè lên `~/.codex/RTK.md` — file này do workstation quản lý, không sửa tay ở global. Bootstrap không cài hoặc đồng bộ Flex skill vào thư mục user-local; skill được dùng trực tiếp từ project. Với workspace mới, bootstrap chạy `specify init . --integration agy --script ps` để khởi tạo Spec Kit. Dùng `-SkipAntigravityInstall`, `-SkipCcusageInstall`, `-SkipRtkInstall`, `-SkipRtkInit`, `-SkipSpecifyInstall`, `-SkipSpecifyInit` hoặc `-UseWinget` khi cần kiểm soát các bước này.

Với workspace đã có `.specify/`, bootstrap không tự migration để tránh ghi đè tùy biến. Sau khi worktree sạch, chạy tường minh:

```powershell
.\scripts\migrate-speckit-antigravity.ps1
```

Script kiểm tra `agy`, backup tạm các skill/template/runtime tùy biến, chuyển integration mặc định sang `agy`, rồi khôi phục các artifact đã bảo vệ. Chạy `agy` lần đầu trong terminal để hoàn tất Google sign-in nếu được yêu cầu.

Sau migration, kiểm tra tĩnh runtime và skill source:

```powershell
.\scripts\test-antigravity-runtime.ps1 -RequireCli
```

## Cấu hình agent

| Công cụ | File cấu hình | Ghi chú |
| --- | --- | --- |
| Claude Code | `.claude/settings.json` | Cấu hình model và permissions dùng chung. |
| Claude Code | `.claude/settings.local.json` | Thiết lập local theo máy/người dùng. |
| Codex CLI | `.codex/config.toml` | Cấu hình model, approval policy và sandbox. |
| Codex | `AGENTS.md`, `.agents/` | Context và resource runtime cho Codex. |
| Antigravity IDE/CLI | `AGENTS.md`, `.agents/skills/` | Context chung và slash skill `/speckit-*`. |

Skill Speckit dùng chung có source runtime tại `.agents/skills/`; bootstrap chuyển các đường dẫn tương ứng trong `.claude/skills/` thành junction để Claude Code và Codex đọc cùng một bản. Không có Flex skill nào được cài hoặc đồng bộ vào thư mục global của Claude Code hay Codex.

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
- `OPEN_ANTIGRAVITY.cmd`: mở Antigravity CLI tại workstation root với permission prompt mặc định.

Trong Antigravity, gọi `/skills` để xác nhận skill source đã được nạp, sau đó dùng `/speckit-specify`, `/speckit-docbiz`, `/speckit-plan` và các bước kế tiếp. Không dùng workflow tự chạy toàn bộ Speckit: từng gate vẫn cần được người dùng gọi tường minh.

## Troubleshooting

- Nếu `code`, `agy`, `claude` hoặc `codex` chưa có trong PATH, cài công cụ tương ứng và mở terminal mới.
- Với cấu hình local theo máy/người dùng, sửa trực tiếp `.claude/settings.local.json`.
