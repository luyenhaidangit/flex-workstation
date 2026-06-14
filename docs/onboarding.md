# Onboarding workstation

Tài liệu này dành cho người mới clone `flex-workstation` trên máy Windows.

## Xác nhận cấu trúc thư mục

Trước khi clone thêm project hoặc cập nhật workspace, cần xác nhận với người onboard rằng các repository sẽ được đặt ngang hàng trong thư mục cha:

```text
C:\Workspace\Project\
|-- flex-workstation\
|-- flex-frontend\
|-- flex-backend\
|-- flex-api-gateway\
+-- ...
```

Trong đó:

- `flex-workstation` là repo điều phối, chứa tài liệu, bootstrap và chỉ dẫn cho AI.
- `flex-frontend`, `flex-backend`, `flex-api-gateway` là ví dụ các repo nghiệp vụ hoặc kỹ thuật sẽ được clone thêm.
- Các repo project không đặt bên trong `flex-workstation`.
- Nếu người onboard dùng đường dẫn khác, cần cập nhật lại `docs/projects.md`, `OPEN_WORKSPACE.cmd` và các task VS Code liên quan nếu có.

Câu xác nhận gợi ý:

```text
Anh/chị xác nhận các repo Flex sẽ nằm trong C:\Workspace\Project\, ngang hàng với flex-workstation, ví dụ flex-frontend, flex-backend, flex-api-gateway... đúng không?
```

## Chạy bootstrap

Trên Windows, cách đơn giản nhất là double-click file ở root repo:

```text
SETUP_WORKSPACE.cmd
```

File này sẽ tự chạy `scripts/bootstrap.ps1` bằng PowerShell, bao gồm bước sync skill dùng chung, và giữ cửa sổ lại để bạn đọc kết quả.

Nếu muốn chạy thủ công, mở PowerShell tại thư mục repo và chạy:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\bootstrap.ps1
```

Script sẽ:

- Kiểm tra `git`, VS Code CLI `code`, `winget`.
- Copy `templates/project-root/CLAUDE.md` ra `C:\Workspace\Project\CLAUDE.md` nếu chưa có.
- Copy template cấu hình Claude từ `templates/project-root/.claude` ra `C:\Workspace\Project\.claude`.
- Sync skill local dùng chung từ `config/workspace-skills.json` vào `C:\Workspace\Project\.claude\skills`.
- Kiểm tra Claude Code CLI `claude`.
- Nếu thiếu Claude Code, tự chạy native installer chính thức. Trên Windows:

```powershell
irm https://claude.ai/install.ps1 | iex
```

Trên macOS, Linux hoặc WSL:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Nếu muốn dùng WinGet trên Windows thay vì native installer:

```powershell
.\scripts\bootstrap.ps1 -UseWinget
```

## Cấu hình Claude được tạo sẵn

Bootstrap copy template `templates/project-root/.claude` ra `C:\Workspace\Project\.claude` (thư mục cha chứa các repo Flex). File/thư mục đã tồn tại ở đích được giữ nguyên, không ghi đè; `settings.json` và `settings.local.json` chỉ được kiểm tra JSON hợp lệ.

Quy ước:

- `settings.json`: cấu hình dùng chung cho workspace, ví dụ model mặc định.
- `settings.local.json`: cấu hình local theo máy/người dùng, ví dụ permissions.
- Hook bảo vệ skill runtime trong `settings.json` gọi `flex-workstation\scripts\check-skill-path.ps1`, vì script dùng chung nằm trong workstation source chứ không nằm trong runtime `.claude\scripts`.

Bootstrap cũng copy `templates/project-root/CLAUDE.md` ra `C:\Workspace\Project\CLAUDE.md` nếu chưa có. File này giúp Claude hiểu rằng `flex-workstation` là source-of-truth khi Claude được mở tại workspace root.

Chi tiết cấu trúc `.claude` và vai trò từng thư mục con: xem [docs/architecture.md](architecture.md).

## Skill dùng chung cho workspace

Khai báo skill local dùng chung tại:

```text
config/workspace-skills.json
```

Ví dụ thêm một skill local:

```json
{
  "localSkills": [
    {
      "name": "backend-dotnet",
      "path": "C:/Workspace/Shared/skills/backend-dotnet"
    }
  ]
}
```

Yêu cầu của mỗi skill folder:

- Có file `SKILL.md`.
- Nếu không khai báo `name`, script sẽ đọc `name:` trong frontmatter của `SKILL.md`.
- Mặc định không ghi đè skill đã tồn tại ở `C:\Workspace\Project\.claude\skills`.

Sync thủ công:

```powershell
.\scripts\sync-workspace-skills.ps1
```

Hoặc double-click:

```text
SYNC_WORKSPACE_SKILLS.cmd
```

Nếu Claude Code đang mở sẵn tại `C:\Workspace\Project`, sau khi sync hãy chạy trong Claude:

```text
/reload-skills
```

Hoặc đóng session và mở lại bằng `OPEN_CLAUDE.cmd`.

Ghi đè khi muốn cập nhật lại từ nguồn:

```powershell
.\scripts\sync-workspace-skills.ps1 -Force
```

Không sửa trực tiếp file trong `C:\Workspace\Project\.claude\skills`; hook `scripts/check-skill-path.ps1` sẽ chặn thao tác này để tránh mất thay đổi khi sync lại.

## Đăng nhập Claude Code

Sau khi cài xong, mở terminal mới tại repo và chạy:

```powershell
claude
```

Làm theo hướng dẫn đăng nhập trên trình duyệt. Nếu cần kiểm tra cấu hình:

```powershell
claude --version
claude doctor
```

## Mở workspace

Để mở nhanh toàn bộ thư mục cha chứa các repo Flex, double-click:

```text
OPEN_WORKSPACE.cmd
```

File này sẽ mở:

```text
C:\Workspace\Project
```

Đây là cách thân thiện nhất khi các repo nằm ngang hàng với `flex-workstation`.

```powershell
code C:\Workspace\Project
```

Hoặc chạy bootstrap kèm mở workspace:

```powershell
.\scripts\bootstrap.ps1 -OpenWorkspace
```

## Mở Claude full access

Nếu cần mở Claude Code tại workspace root với quyền bỏ qua prompt permission, double-click:

```text
OPEN_CLAUDE.cmd
```

File này chạy tại:

```text
C:\Workspace\Project
```

và gọi:

```powershell
claude --dangerously-skip-permissions
```

Chỉ dùng chế độ này trong workspace tin cậy vì Claude sẽ không hỏi trước khi dùng tool hoặc sửa file.

## Ghi chú

- Không nên double-click trực tiếp `scripts/bootstrap.ps1`. Windows thường sẽ hỏi chọn app để mở file `.ps1` hoặc mở bằng editor thay vì chạy script.
- Claude Code yêu cầu tài khoản có quyền dùng Claude Code, ví dụ Pro, Max, Team, Enterprise hoặc Console.
- Git for Windows được khuyến nghị để Claude Code có thể dùng Git Bash trên Windows.
- Hướng dẫn cài đặt Claude Code chính thức: <https://code.claude.com/docs/en/setup>.
- Nếu cài bằng WinGet, thỉnh thoảng cập nhật bằng:

```powershell
winget upgrade Anthropic.ClaudeCode
```
