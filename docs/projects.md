# Danh sách Git project được theo dõi

Tài liệu này ghi nhận các Git repo được quản lý chung bởi `flex-workstation`. Các repo này có thể nằm ngoài thư mục `flex-workstation`, nhưng vẫn được theo dõi để tiện tổng hợp task, kiến trúc và trạng thái triển khai.

## Quy ước

- `flex-workstation` giữ vai trò điều phối, không tự động chứa mã nguồn của các project khác.
- Mặc định các repo Flex nằm ngang hàng trong thư mục cha `C:\Workspace\Project`.
- Mỗi project được ghi bằng tên repo, đường dẫn local, vai trò, công nghệ chính và trạng thái.
- Khi thêm project mới, cập nhật bảng bên dưới và bổ sung task liên quan trong `docs/tasks.md`.
- Khi muốn VS Code theo dõi project trong Source Control, cập nhật thêm `flex-workstation.code-workspace`.
- Nếu cần liên kết version giữa nhiều repo, cân nhắc dùng Git submodule hoặc Git subtree sau khi có yêu cầu rõ ràng.

## Cấu trúc local cần xác nhận

Trước khi clone hoặc thêm repo mới vào workspace, cần xác nhận với người onboard cấu trúc local dự kiến:

```text
C:\Workspace\Project\
|-- flex-workstation\
|-- flex-frontend\
|-- flex-backend\
|-- flex-api-gateway\
+-- ...
```

Nếu người onboard chọn thư mục khác, cập nhật lại bảng project và file `flex-workstation.code-workspace` theo đường dẫn thực tế.

## Project đang theo dõi

| Project | Local path | Vai trò | Công nghệ nhận diện | Trạng thái Git | Ghi chú |
| --- | --- | --- | --- | --- | --- |
| `flex-workstation` | `C:\Workspace\Project\flex-workstation` | Workstation điều phối, tài liệu và bootstrap | Markdown, PowerShell, VS Code workspace | Đang theo dõi | Repo trung tâm, không chứa mã nguồn nghiệp vụ. |
| `flex-frontend` | `C:\Workspace\Project\flex-frontend` | Frontend cho nhóm project Flex | Chưa xác định | Dự kiến | Cần xác nhận repository URL trước khi clone. |
| `flex-backend` | `C:\Workspace\Project\flex-backend` | Backend cho nhóm project Flex | Chưa xác định | Dự kiến | Cần xác nhận repository URL trước khi clone. |
| `flex-api-gateway` | `C:\Workspace\Project\flex-api-gateway` | API Gateway cho nhóm project Flex | `.sln`, `Dockerfile`, `Jenkinsfile` | Dự kiến | Repo riêng, không nhúng vào `flex-workstation`. |

## Lệnh kiểm tra nhanh

```powershell
git -C C:\Workspace\Project\flex-api-gateway status --short
```

Nếu lệnh không trả về dòng nào, working tree của project đang sạch.

## Cấu hình VS Code

Mở nhanh toàn bộ thư mục cha chứa các repo Flex bằng cách double-click:

```text
OPEN_PROJECT.cmd
```

Hoặc chạy:

```powershell
code C:\Workspace\Project
```

Các project cũng được khai báo trong `flex-workstation.code-workspace`. Mở file workspace bằng lệnh:

```powershell
code C:\Workspace\Project\flex-workstation\flex-workstation.code-workspace
```

Task VS Code có sẵn:

- `git: status all tracked projects`
- `git: status flex-workstation`
- `git: status flex-api-gateway`
