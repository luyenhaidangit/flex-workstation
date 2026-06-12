# Onboarding workstation

Tài liệu này dành cho người mới clone `flex-workstation` trên máy Windows.

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

```powershell
code flex-workstation.code-workspace
```

Hoặc chạy bootstrap kèm mở workspace:

```powershell
.\bootstrap.ps1 -OpenWorkspace
```

## Ghi chú

- Không nên double-click trực tiếp `bootstrap.ps1`. Windows thường sẽ hỏi chọn app để mở file `.ps1` hoặc mở bằng editor thay vì chạy script.
- Claude Code yêu cầu tài khoản có quyền dùng Claude Code, ví dụ Pro, Max, Team, Enterprise hoặc Console.
- Git for Windows được khuyến nghị để Claude Code có thể dùng Git Bash trên Windows.
- Hướng dẫn cài đặt Claude Code chính thức: <https://code.claude.com/docs/en/setup>.
- Nếu cài bằng WinGet, thỉnh thoảng cập nhật bằng:

```powershell
winget upgrade Anthropic.ClaudeCode
```
