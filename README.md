# flex-workstation

`flex-workstation` là workspace dùng chung để quản lý các project cá nhân, tài liệu triển khai, danh sách task, kiến trúc hệ thống, và các skill có thể tái sử dụng trong quá trình làm việc với Codex.

## Mục đích

- Tập trung hóa tài liệu định hướng cho các project trong cùng một workspace.
- Theo dõi các task cần triển khai theo từng giai đoạn.
- Ghi lại kiến trúc, quy ước kỹ thuật, cách tổ chức thư mục và trách nhiệm của từng project.
- Lưu trữ các skill dùng chung để có thể tái sử dụng giữa nhiều project.
- Giảm việc phải giải thích lại bối cảnh khi tiếp tục làm việc trong các phiên sau.

## Cấu trúc thư mục

```text
flex-workstation/
|-- .vscode/
|   +-- tasks.json
|-- docs/
|   |-- architecture.md
|   |-- onboarding.md
|   |-- projects.md
|   +-- tasks.md
|-- scripts/
|   +-- bootstrap.ps1
|-- skills/
|   +-- README.md
|-- templates/
|   +-- project-root/
|       +-- .claude/
|-- .gitattributes
|-- CLAUDE.md
|-- OPEN_PROJECT.cmd
|-- README.md
+-- START_HERE.cmd
```

## Tài liệu chính

- [docs/tasks.md](docs/tasks.md): danh sách task cần triển khai, trạng thái, độ ưu tiên và ghi chú thực hiện.
- [docs/architecture.md](docs/architecture.md): mô tả kiến trúc tổng quan, danh sách project, trách nhiệm của từng project và quy ước tích hợp.
- [docs/onboarding.md](docs/onboarding.md): hướng dẫn bootstrap máy mới sau khi clone workspace.
- [docs/projects.md](docs/projects.md): danh sách các Git project được theo dõi chung trong workspace.
- [skills/README.md](skills/README.md): mô tả cách tổ chức skill dùng chung trong workspace.
- [CLAUDE.md](CLAUDE.md): chỉ dẫn tổng quan để Claude Code hiểu vai trò, quy trình và quy ước làm việc trong workstation.

## Khởi tạo nhanh sau khi clone

Trước khi clone thêm repo nghiệp vụ, cần xác nhận cấu trúc local dự kiến:

```text
C:\Workspace\Project\
|-- flex-workstation\
|-- flex-frontend\
|-- flex-backend\
|-- flex-api-gateway\
+-- ...
```

Các repo như `flex-frontend`, `flex-backend`, `flex-api-gateway` nên nằm ngang hàng với `flex-workstation`, không nằm bên trong `flex-workstation`.

Nếu đang dùng Windows và muốn thao tác đơn giản nhất, double-click:

```text
START_HERE.cmd
```

File này sẽ tự gọi `scripts/bootstrap.ps1` bằng PowerShell và giữ cửa sổ lại để đọc kết quả.

Bootstrap cũng copy template cấu hình Claude từ `templates/project-root/.claude` ra thư mục cha:

```text
C:\Workspace\Project\.claude\
|-- agents\
|-- commands\
|-- hooks\
|-- skills\
+-- settings.local.json
```

File đã tồn tại ở `C:\Workspace\Project\.claude` sẽ được giữ nguyên, không ghi đè.

Để mở nhanh toàn bộ thư mục cha `C:\Workspace\Project` trong VS Code, double-click:

```text
OPEN_PROJECT.cmd
```

Mở PowerShell tại thư mục repo và chạy:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\bootstrap.ps1
```

Script bootstrap sẽ kiểm tra các công cụ tối thiểu và tự cài Claude Code bằng native installer chính thức nếu máy chưa có `claude`.

Trên Windows, script dùng lệnh PowerShell chính thức:

```powershell
irm https://claude.ai/install.ps1 | iex
```

Trên macOS, Linux hoặc WSL, lệnh native installer tương ứng là:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Nếu muốn dùng WinGet trên Windows thay vì native installer:

```powershell
.\scripts\bootstrap.ps1 -UseWinget
```

Sau khi cài xong, chạy:

```powershell
claude
```

để đăng nhập và bắt đầu làm việc với repo.

## Mở workspace trong VS Code

Để VS Code theo dõi toàn bộ thư mục cha chứa các repo Flex, double-click:

```text
OPEN_PROJECT.cmd
```

Hoặc chạy trực tiếp:

```
code C:\Workspace\Project
```

Sau khi mở thư mục cha, tab Source Control của VS Code sẽ hiển thị các repository nằm trong `C:\Workspace\Project`.

## Quy ước triển khai

- Mỗi project con nên có thư mục riêng, tài liệu mục đích riêng và hướng dẫn chạy tối thiểu.
- Công cụ bắt buộc hoặc khuyến nghị cho người mới nên được đưa vào `scripts/bootstrap.ps1`, entrypoint thân thiện nên đặt tại `START_HERE.cmd` hoặc `OPEN_PROJECT.cmd`, và ghi lại tại `docs/onboarding.md`.
- Task mới nên được ghi vào `docs/tasks.md` trước khi triển khai để tránh mất ngữ cảnh.
- Thay đổi kiến trúc hoặc cách tổ chức thư mục cần được cập nhật vào `docs/architecture.md`.
- Skill dùng chung nên đặt trong `skills/` và có mô tả rõ: khi nào dùng, đầu vào cần có, quy trình thực hiện, và kết quả mong đợi.

## Trạng thái hiện tại

Workspace đang ở giai đoạn khởi tạo. Các tài liệu nền đã được chuẩn bị để tiếp tục bổ sung project con, task cụ thể và skill dùng chung.
