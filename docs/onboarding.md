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
- Nếu người onboard dùng đường dẫn khác, cần cập nhật lại `docs/projects.md`, `OPEN_PROJECT.cmd` và các task VS Code liên quan nếu có.

Câu xác nhận gợi ý:

```text
Anh/chị xác nhận các repo Flex sẽ nằm trong C:\Workspace\Project\, ngang hàng với flex-workstation, ví dụ flex-frontend, flex-backend, flex-api-gateway... đúng không?
```

## Chạy bootstrap

Trên Windows, cách đơn giản nhất là double-click file ở root repo:

```text
START_HERE.cmd
```

File này sẽ tự chạy `bootstrap.ps1` bằng PowerShell và giữ cửa sổ lại để bạn đọc kết quả.

Nếu muốn chạy thủ công, mở PowerShell tại thư mục repo và chạy:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\bootstrap.ps1
```

Script sẽ:

- Kiểm tra `git`, VS Code CLI `code`, `winget`.
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
.\bootstrap.ps1 -UseWinget
```

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
OPEN_PROJECT.cmd
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
.\bootstrap.ps1 -OpenWorkspace
```

## Ghi chú

- Không nên double-click trực tiếp `bootstrap.ps1`. Windows thường sẽ hỏi chọn app để mở file `.ps1` hoặc mở bằng editor thay vì chạy script.
- Dùng `OPEN_PROJECT.cmd` khi muốn mở VS Code tại thư mục cha `C:\Workspace\Project`.
- Claude Code yêu cầu tài khoản có quyền dùng Claude Code, ví dụ Pro, Max, Team, Enterprise hoặc Console.
- Git for Windows được khuyến nghị để Claude Code có thể dùng Git Bash trên Windows.
- Hướng dẫn cài đặt Claude Code chính thức: <https://code.claude.com/docs/en/setup>.
- Nếu cài bằng WinGet, thỉnh thoảng cập nhật bằng:

```powershell
winget upgrade Anthropic.ClaudeCode
```
