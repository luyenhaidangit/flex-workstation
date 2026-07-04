# Danh sách Git project được theo dõi

Tài liệu này ghi nhận các Git repo được quản lý chung bởi `flex-workstation`. Các repo project được clone vào trong workstation root và được ignore bởi Git của workstation.

## Quy ước

- Mỗi project được ghi bằng tên repo, đường dẫn local, vai trò, công nghệ chính và trạng thái.
- Khi thêm project mới, cập nhật bảng bên dưới, khai báo Git URL trong `workstation.json` nếu repo cần được clone khi sync, và bổ sung task liên quan trong `docs/tasks.md` nếu có việc triển khai tiếp theo.
- Bản đồ hệ thống hiện tại nằm ở [system-map.md](system-map.md).
- Cấu trúc local mặc định và bước xác nhận onboarding: xem [onboarding.md](onboarding.md).

## Project đang theo dõi

| Project | Local path | Vai trò | Công nghệ nhận diện | Trạng thái | Ghi chú |
| --- | --- | --- | --- | --- | --- |
| `flex-workstation` | `.` | Workstation điều phối, tài liệu, bootstrap và AI tooling | Markdown, PowerShell, VS Code workspace | Đang dùng | Repo trung tâm, không chứa mã nguồn nghiệp vụ. |
| `flex-agents` | `flex-agents/` | Repository agent độc lập | Markdown, plugin/runtime files cho coding agents | Clone/update khi sync | Bootstrap update Claude plugin qua marketplace `luyenhaidangit/flex-agents`; repo local được pull khi sync nếu working tree sạch. |
| `flex-auth-service` | `flex-auth-service/` | Dịch vụ xác thực/ủy quyền | .NET / ASP.NET Core theo `SPEC.md` hiện có | Clone/update khi sync | Tài liệu/spec riêng nằm trong repo này. |
| `flex-microfrontend` | `flex-microfrontend/` | Frontend client cho nhóm project Flex | Angular / Node.js theo `README.md` và `package.json` | Clone/update khi sync | README hiện ghi tên `flex-client`. |
| `flex-backend` | `flex-backend/` | Backend cho nhóm project Flex | Chưa xác định | Dự kiến | Cần xác nhận repository URL trước khi clone. |
| `flex-api-gateway` | `flex-api-gateway/` | API Gateway cho nhóm project Flex | `.sln`, `.csproj`, `Dockerfile`, `Jenkinsfile` | Clone/update khi sync | Repo riêng, được ignore bởi Git của workstation. |
| `flex-environment` | `flex-environment/` | Local/dev infrastructure stack | Docker Compose: Redis, RabbitMQ, Jenkins, Portainer, MinIO, Elasticsearch, Kibana, Ollama, `flex-ai-gateway` | Clone/update khi sync | DB primary hiện dùng Oracle Cloud; Oracle local container đang comment out. |

Các repo có URL clone chính thức được khai báo trong `workstation.json`. `SYNC_WORKSPACE.cmd` dùng cấu hình này để clone repo còn thiếu và pull repo đã có nếu working tree sạch.

## Lệnh kiểm tra nhanh

Chạy từ workstation root:

```powershell
git status --short
git -C flex-agents status --short
git -C flex-auth-service status --short
git -C flex-api-gateway status --short
git -C flex-microfrontend status --short
git -C flex-environment status --short
```

Nếu lệnh không trả về dòng nào, working tree của project đang sạch.

## Cấu hình VS Code

Mở nhanh workstation root chứa các repo Flex bằng cách double-click:

```text
OPEN_WORKSTATION.cmd
```

Hoặc chạy từ workstation root:

```powershell
code .
```

Task VS Code có sẵn:

- `git: status all tracked projects`
- `git: status flex-workstation`
- `git: status flex-agents`
- `git: status flex-api-gateway`
