# Danh sách Git project được theo dõi

Tài liệu này ghi nhận các Git repo được quản lý chung bởi `flex-workstation`. Các repo này có thể nằm ngoài thư mục `flex-workstation`, nhưng vẫn được theo dõi để tiện tổng hợp task, kiến trúc và trạng thái triển khai.

## Quy ước

- `flex-workstation` giữ vai trò điều phối, không tự động chứa mã nguồn của các project khác.
- Mỗi project được ghi bằng tên repo, đường dẫn local, vai trò, công nghệ chính và trạng thái.
- Khi thêm project mới, cập nhật bảng bên dưới và bổ sung task liên quan trong `docs/tasks.md`.
- Khi muốn VS Code theo dõi project trong Source Control, cập nhật thêm `flex-workstation.code-workspace`.
- Nếu cần liên kết version giữa nhiều repo, cân nhắc dùng Git submodule hoặc Git subtree sau khi có yêu cầu rõ ràng.

## Project đang theo dõi

| Project | Local path | Vai trò | Công nghệ nhận diện | Trạng thái Git | Ghi chú |
| --- | --- | --- | --- | --- | --- |
| `flex-api-gateway` | `C:\Workspace\Personal\flex-api-gateway` | API Gateway cho nhóm project Flex | `.sln`, `Dockerfile`, `Jenkinsfile` | Sạch tại thời điểm thêm | Repo riêng, không nhúng vào `flex-workstation`. |

## Lệnh kiểm tra nhanh

```powershell
git -C C:\Workspace\Personal\flex-api-gateway status --short
```

Nếu lệnh không trả về dòng nào, working tree của project đang sạch.

## Cấu hình VS Code

Các project đang được khai báo trong `flex-workstation.code-workspace`. Mở workspace bằng lệnh:

```powershell
code C:\Workspace\Personal\flex-workstation\flex-workstation.code-workspace
```

Task VS Code có sẵn:

- `git: status all tracked projects`
- `git: status flex-workstation`
- `git: status flex-api-gateway`
