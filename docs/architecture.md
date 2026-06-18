# Quy ước kiến trúc workspace

File này chỉ ghi các quy ước kiến trúc bền vững của `flex-workstation`. Không dùng file này để lặp lại bản đồ hệ thống, danh sách repo hoặc chi tiết runtime.

## Nơi đọc thông tin

| Nhu cầu | Tài liệu |
| --- | --- |
| Bản đồ nhanh toàn workspace | [system-map.md](system-map.md) |
| Thành phần hệ thống, data architecture, deployment view, risks | [architecture/overview.md](architecture/overview.md) |
| Danh sách repo được theo dõi | [projects.md](projects.md) |
| Bootstrap máy mới và cách mở workspace | [onboarding.md](onboarding.md) |
| Task và lịch sử việc đã làm | [tasks.md](tasks.md) |

## Quy ước tổ chức

- `flex-workstation` là repo điều phối: tài liệu, bootstrap, template, skill source và cấu hình assistant.
- Repo nghiệp vụ nằm ngang hàng với `flex-workstation` trong `C:\Workspace\Project`, không đặt lồng bên trong `flex-workstation`.
- Tài liệu tổng hợp toàn workspace đặt trong `flex-workstation/docs`.
- Tài liệu chi tiết của từng project đặt trong `docs/` của chính project đó.
- Runtime generated config của Claude/Codex nằm ở `C:\Workspace\Project\.claude` và `C:\Workspace\Project\.agents`; source-of-truth nằm trong `flex-workstation`.

## Quy ước khi thêm hoặc đổi thành phần

- Khi thêm/bớt repo: cập nhật [projects.md](projects.md), [system-map.md](system-map.md) và [architecture/overview.md](architecture/overview.md) nếu ảnh hưởng đến kiến trúc tổng thể.
- Khi đổi bootstrap, template hoặc sync flow: cập nhật [onboarding.md](onboarding.md) và [system-map.md](system-map.md).
- Khi đổi database, gateway, service boundary hoặc infrastructure chính: cập nhật [architecture/overview.md](architecture/overview.md) và cân nhắc thêm ADR.
- Khi tạo skill dùng chung: sửa source trong `flex-workstation/skills`, khai báo trong `config/workspace-assistants.json`, rồi chạy `SYNC_WORKSPACE.cmd`.
