# Kiến trúc workspace

Tài liệu này mô tả cách tổ chức các project, tài liệu và skill trong `flex-workstation`.

## Tổng quan

`flex-workstation` được tổ chức như một workspace chung, không giả định sẵn một công nghệ duy nhất. Mỗi project con có thể dùng stack riêng, nhưng vẫn cần tuân thủ quy ước tài liệu và cách ghi nhận task chung.

## Thành phần chính

| Thành phần | Vai trò |
| --- | --- |
| `README.md` | Tài liệu định hướng chính của workspace. |
| `CLAUDE.md` | Chỉ dẫn tổng quan cho Claude Code khi làm việc trong workstation. |
| `config/workspace-skills.json` | Manifest khai báo skill local dùng chung cho workspace Claude. |
| `docs/` | Nơi lưu tài liệu triển khai, task, kiến trúc và quyết định kỹ thuật. |
| `scripts/bootstrap.ps1` | Script bootstrap máy mới sau khi clone workstation. |
| `scripts/sync-workspace-skills.ps1` | Script sync skill local dùng chung vào `C:\Workspace\Project\.claude\skills`. |
| `SETUP_WORKSPACE.cmd` | Entrypoint thân thiện cho người dùng Windows, dùng để double-click chạy bootstrap. |
| `OPEN_WORKSPACE.cmd` | Entrypoint mở nhanh VS Code tại thư mục cha chứa các repo Flex. |
| `OPEN_CLAUDE.cmd` | Entrypoint mở Claude Code tại workspace root với `--dangerously-skip-permissions`. |
| `skills/` | Nơi lưu skill org-share dùng chung giữa các project Flex (Claude Code hoặc AI assistant khác). |
| `templates/project-root/.claude` | Template cấu hình Claude được bootstrap copy ra thư mục cha `C:\Workspace\Project\.claude`. |
| Git project được theo dõi | Các project nghiệp vụ hoặc kỹ thuật nằm cùng nhóm thư mục, được ghi nhận trong `docs/projects.md`. |

## Cấu hình Claude ngoài workstation

Cấu hình Claude dùng chung được đặt ở thư mục cha `C:\Workspace\Project\.claude`, ngang hàng với các repo:

```text
C:\Workspace\Project\
|-- .claude\
|   |-- agents\
|   |-- commands\
|   |-- hooks\
|   |-- skills\
|   +-- settings.local.json
|-- flex-workstation\
|-- flex-frontend\
|-- flex-backend\
+-- flex-api-gateway\
```

`flex-workstation` chỉ chứa template, script và tài liệu để tạo cấu trúc này. Runtime config dùng chung nằm ở `C:\Workspace\Project\.claude`; template nguồn nằm tại `templates/project-root/.claude`.

## Skill dùng chung cho workspace

Skill dùng chung được khai báo trong `config/workspace-skills.json`, sau đó `scripts/sync-workspace-skills.ps1` copy các skill local vào:

```text
C:\Workspace\Project\.claude\skills\
```

Quy ước này tách rõ:

- `config/workspace-skills.json`: source of truth được commit.
- `C:\Workspace\Project\.claude\skills`: artifact runtime được tạo khi bootstrap hoặc sync thủ công.
- `flex-workstation/.claude/skills`: cấu hình local riêng của repo nếu có, không dùng làm nguồn skill chung.

Phase hiện tại chỉ hỗ trợ local skill folder. Marketplace/plugin của Claude nên xử lý bằng cơ chế riêng vì lifecycle khác với workspace-local skills.

## Kiến trúc project con

`flex-workstation` không chứa mã nguồn của các repo nghiệp vụ — chỉ giữ vai trò điều phối, tài liệu, bootstrap và cấu hình workspace. Các repo Flex nằm ngang hàng trong `C:\Workspace\Project\` (chi tiết và bước xác nhận: [docs/onboarding.md](onboarding.md)).

Khi thêm project mới, nên dùng cấu trúc tối thiểu:

```text
project-name/
|-- README.md
|-- src/
|-- tests/
+-- docs/
```

Trong đó:

- `README.md`: mục đích project, cách chạy, cách kiểm thử, các lệnh thường dùng.
- `src/`: mã nguồn chính.
- `tests/`: kiểm thử tự động nếu project có code.
- `docs/`: tài liệu riêng của project, ví dụ kiến trúc chi tiết, API, nghiệp vụ hoặc ghi chú triển khai.

## Quy ước kiến trúc

- Tách rõ tài liệu workspace và tài liệu của từng project con.
- Không đặt logic dùng riêng của một project vào thư mục dùng chung nếu chưa có nhu cầu tái sử dụng thật sự.
- Khi một quy trình được dùng lặp lại nhiều lần, cân nhắc chuyển thành skill trong `skills/`.
- Mỗi quyết định kiến trúc quan trọng nên được ghi lại trong `docs/` hoặc tài liệu riêng của project liên quan.

## Theo dõi Git project chung

Workspace này không cần chứa trực tiếp toàn bộ mã nguồn của các project khác. Thay vào đó, các Git repo có thể được theo dõi bằng đường dẫn tuyệt đối trong `docs/projects.md`.

Quy ước này phù hợp khi muốn dùng `flex-workstation` như một trung tâm điều phối:

- Giữ tài liệu tổng hợp, task chung và skill chung tại `flex-workstation`.
- Giữ mã nguồn của từng project trong repo riêng, đặt ngang hàng với `flex-workstation` trong thư mục cha đã xác nhận.
- Ghi rõ đường dẫn local, vai trò, stack và trạng thái của từng project.
- Không dùng submodule nếu chưa có nhu cầu version hóa quan hệ giữa các repo.

## Danh sách project

Danh sách chi tiết được quản lý tại [docs/projects.md](projects.md).

| Project | Mục đích | Công nghệ | Trạng thái | Ghi chú |
| --- | --- | --- | --- | --- |
| `flex-api-gateway` | API Gateway cho nhóm project Flex | .NET solution, Docker, Jenkins | Dự kiến | Local path mục tiêu: `C:\Workspace\Project\flex-api-gateway`. |
