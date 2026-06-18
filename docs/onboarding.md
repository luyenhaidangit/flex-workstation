# Onboarding workstation

Tài liệu này dành cho người mới clone `flex-workstation` trên máy Windows.

## Xác nhận cấu trúc thư mục

Trước khi clone thêm project hoặc cập nhật workspace, cần xác nhận với người onboard rằng các repository sẽ được đặt ngang hàng trong thư mục cha:

```text
C:\Workspace\Project\
|-- flex-workstation\
|-- flex-auth-service\
|-- flex-api-gateway\
|-- flex-microfrontend\
|-- flex-environment\
+-- ...
```

Trong đó:

- `flex-workstation` là repo điều phối, chứa tài liệu, bootstrap và chỉ dẫn cho AI.
- `flex-auth-service`, `flex-api-gateway`, `flex-microfrontend`, `flex-environment` là các repo project/infrastructure nằm cùng workspace.
- Các repo project không đặt bên trong `flex-workstation`.
- Nếu người onboard dùng đường dẫn khác, cần cập nhật lại `docs/projects.md`, `OPEN_WORKSPACE.cmd` và các task VS Code liên quan nếu có.

Câu xác nhận gợi ý:

```text
Anh/chị xác nhận các repo Flex sẽ nằm trong C:\Workspace\Project\, ngang hàng với flex-workstation, ví dụ flex-auth-service, flex-api-gateway, flex-microfrontend, flex-environment... đúng không?
```

## Chạy bootstrap

Trên Windows, cách đơn giản nhất là double-click file ở root repo:

```text
SYNC_WORKSPACE.cmd
```

File này sẽ tự chạy `scripts/bootstrap.ps1` bằng PowerShell, bao gồm chuẩn bị cấu hình Claude/Codex, sync skill dùng chung, kiểm tra/cài Claude Code nếu cần, và giữ cửa sổ lại để bạn đọc kết quả.

Nếu muốn chạy thủ công, mở PowerShell tại thư mục repo và chạy:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\bootstrap.ps1
```

Script sẽ:

- Kiểm tra `git`, VS Code CLI `code`, `winget`.
- Copy `templates/project-root/CLAUDE.md` ra `C:\Workspace\Project\CLAUDE.md` nếu chưa có.
- Copy `templates/project-root/AGENTS.md` ra `C:\Workspace\Project\AGENTS.md` nếu chưa có.
- Copy template cấu hình Claude từ `templates/project-root/.claude` ra `C:\Workspace\Project\.claude`.
- Copy template cấu trúc Codex từ `templates/project-root/.agents` ra `C:\Workspace\Project\.agents`.
- Sync skill local dùng chung từ `config/workspace-assistants.json` vào `C:\Workspace\Project\.claude\skills` và `C:\Workspace\Project\.agents\skills`.
- Kiểm tra/cài `ccusage` để theo dõi usage của Claude Code/Codex.
- Kiểm tra/cài `rtk` và init hook global cho Claude Code/Copilot, Codex nếu có thể.
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

Nếu chỉ muốn bỏ qua cài `ccusage` trong lần bootstrap này:

```powershell
.\scripts\bootstrap.ps1 -SkipCcusageInstall
```

Nếu chỉ muốn bỏ qua cài hoặc init `rtk` trong lần bootstrap này:

```powershell
.\scripts\bootstrap.ps1 -SkipRtkInstall
.\scripts\bootstrap.ps1 -SkipRtkInit
```

Sau khi `rtk` được cài/init lần đầu, mở lại Claude Code hoặc Codex session mới để hook/global instruction được nạp.

## Cấu hình Claude/Codex được tạo sẵn

Bootstrap copy template `templates/project-root/.claude` ra `C:\Workspace\Project\.claude` và `templates/project-root/.agents` ra `C:\Workspace\Project\.agents` (thư mục cha chứa các repo Flex). File/thư mục đã tồn tại ở đích được giữ nguyên, không ghi đè; `settings.json` và `settings.local.json` chỉ được kiểm tra JSON hợp lệ.

Quy ước:

- `settings.json`: cấu hình dùng chung cho workspace, ví dụ model mặc định.
- `settings.local.json`: cấu hình local theo máy/người dùng, ví dụ permissions.
- Hook bảo vệ skill runtime trong `settings.json` gọi `flex-workstation\scripts\check-skill-path.ps1`, vì script dùng chung nằm trong workstation source chứ không nằm trong runtime `.claude\scripts`.

Bootstrap cũng copy `templates/project-root/CLAUDE.md` ra `C:\Workspace\Project\CLAUDE.md` và `templates/project-root/AGENTS.md` ra `C:\Workspace\Project\AGENTS.md` nếu chưa có. Hai file này giúp Claude/Codex hiểu rằng `flex-workstation` là source-of-truth khi assistant được mở tại workspace root.

Chi tiết cấu trúc `.claude` và vai trò từng thư mục con: xem [docs/architecture.md](architecture.md).

## Skill dùng chung cho workspace

Khai báo skill local dùng chung tại:

```text
config/workspace-assistants.json
```

Ví dụ thêm một skill local:

```json
{
  "assistants": {
    "claude": {
      "enabled": true,
      "targets": {
        "skills": ".claude/skills"
      }
    },
    "codex": {
      "enabled": true,
      "targets": {
        "skills": ".agents/skills"
      }
    }
  },
  "localSkills": [
    {
      "name": "backend-dotnet",
      "path": "C:/Workspace/Shared/skills/backend-dotnet"
    }
  ]
}
```

Nếu chỉ muốn sync skill cho một assistant, đổi `enabled` của assistant còn lại thành `false`.

External source hiện đang tắt mặc định (`externalSources: []`). Nếu cần bật lại, thêm cấu hình theo mẫu:

```json
{
  "externalSources": [
    {
      "name": "agent-skills",
      "url": "https://github.com/addyosmani/agent-skills.git",
      "cloneTo": "skills-external/agent-skills",
      "sync": {
        "skills": "skills",
        "commands": ".claude/commands",
        "agents": "agents"
      }
    }
  ]
}
```

Khi được bật, external source được clone vào `skills-external/` lúc sync lần đầu. Thư mục này là vendor cache, không commit và không sửa tay. Sync bình thường không kéo update mới từ remote; nếu cần cập nhật vendor, chạy `.\scripts\sync-workspace-skills.ps1 -PullVendors` hoặc `.\scripts\bootstrap.ps1 -PullVendors`.

## Custom external skill

Khi muốn tùy biến một skill lấy từ external source:

1. Copy thư mục skill từ `skills-external/<source>/skills/<skill-name>` sang `skills/<skill-name>`.
2. Giữ cùng `name` trong `skills/<skill-name>/SKILL.md` để local skill override external skill.
3. Thêm entry tương ứng vào `localSkills` trong `config/workspace-assistants.json`.
4. Chạy `SYNC_WORKSPACE.cmd`.

Khi sync, log sẽ hiển thị `[local override]` nếu local skill đang ghi đè skill cùng tên từ external source.

Yêu cầu của mỗi skill folder:

- Có file `SKILL.md`.
- Nếu không khai báo `name`, script sẽ đọc `name:` trong frontmatter của `SKILL.md`.
- Không sửa trực tiếp skill đã sync ở `C:\Workspace\Project\.claude\skills` hoặc `C:\Workspace\Project\.agents\skills`, vì đây là runtime artifact và sẽ bị ghi đè ở lần sync sau.

Nếu chỉ cần chạy phần sync skill kỹ thuật mà không chạy toàn bộ bootstrap, dùng:

```powershell
.\scripts\sync-workspace-skills.ps1
```

Entrypoint double-click chuẩn cho toàn workspace vẫn là:

```text
SYNC_WORKSPACE.cmd
```

Nếu Claude Code đang mở sẵn tại `C:\Workspace\Project`, sau khi sync hãy chạy trong Claude:

```text
/reload-skills
```

Hoặc đóng session và mở lại bằng `OPEN_CLAUDE.cmd`.

Nếu Codex đang mở sẵn tại `C:\Workspace\Project` mà skill mới chưa xuất hiện, mở session Codex mới.

Kéo update mới từ external source khi cần:

```powershell
.\scripts\sync-workspace-skills.ps1 -PullVendors
```

Không sửa trực tiếp file trong `C:\Workspace\Project\.claude\skills` hoặc `C:\Workspace\Project\.agents\skills`; hook `scripts/check-skill-path.ps1` sẽ chặn thao tác này khi dùng Claude để tránh mất thay đổi khi sync lại.

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

## Mở AI usage monitor

Để theo dõi nhanh usage/cost AI, double-click:

```text
OPEN_AI_USAGE_MONITOR.cmd
```

File này chạy `scripts/open-ai-usage-monitor.ps1`. Nếu thiếu `ccusage`, script sẽ thử cài global bằng `npm install -g ccusage@latest` hoặc package manager khả dụng khác, rồi mở unified daily monitor trong 30 ngày gần nhất cho mọi coding AI CLI mà `ccusage` phát hiện. Monitor hiển thị `TOTAL` trước, sau đó sắp xếp ngày mới nhất lên đầu:

```powershell
ccusage daily --all --since <today-minus-30-days>
```

Muốn xem riêng Claude Code billing block 5 giờ:

```powershell
.\scripts\open-ai-usage-monitor.ps1 -View claude-blocks
```

## Ghi chú

- Không nên double-click trực tiếp `scripts/bootstrap.ps1`. Windows thường sẽ hỏi chọn app để mở file `.ps1` hoặc mở bằng editor thay vì chạy script.
- Claude Code yêu cầu tài khoản có quyền dùng Claude Code, ví dụ Pro, Max, Team, Enterprise hoặc Console.
- Git for Windows được khuyến nghị để Claude Code có thể dùng Git Bash trên Windows.
- Hướng dẫn cài đặt Claude Code chính thức: <https://code.claude.com/docs/en/setup>.
- Nếu cài bằng WinGet, thỉnh thoảng cập nhật bằng:

```powershell
winget upgrade Anthropic.ClaudeCode
```
