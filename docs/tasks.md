# Danh sách task triển khai

Tài liệu này dùng để theo dõi các việc cần làm trong workspace `flex-workstation`.

## Trạng thái

- `Todo`: chưa bắt đầu.
- `In progress`: đang thực hiện.
- `Blocked`: đang bị chặn, cần thêm thông tin hoặc quyết định.
- `Done`: đã hoàn tất.

## Task khởi tạo

| Trạng thái | Độ ưu tiên | Task | Ghi chú |
| --- | --- | --- | --- |
| Done | Cao | Tạo tài liệu mục đích workspace | Cập nhật trong `README.md`. |
| Done | Cao | Tạo tài liệu kiến trúc ban đầu | Xem `docs/architecture.md`. |
| Done | Trung bình | Tạo thư mục skill dùng chung | Xem `skills/README.md`. |
| Done | Cao | Xác định danh sách project con | Đã thêm `flex-api-gateway` vào `docs/projects.md`. |
| Done | Cao | Ghi nhận Git project `flex-api-gateway` | Local path mục tiêu: `C:\Workspace\Project\flex-api-gateway`. |
| Done | Cao | Tạo task VS Code cho workstation | Xem `.vscode/tasks.json`. |
| Done | Cao | Tạo bootstrap cho máy mới | Xem `scripts/bootstrap.ps1` và `docs/onboarding.md`. |
| Done | Cao | Tạo chỉ dẫn Claude Code tổng quan | Xem `CLAUDE.md`. |
| Done | Cao | Tạo entrypoint double-click cho Windows | Xem `START_HERE.cmd`. |
| Done | Cao | Tạo entrypoint mở nhanh VS Code tại thư mục cha | Xem `OPEN_PROJECT.cmd`. |
| Done | Cao | Bổ sung bước xác nhận cấu trúc local khi onboarding | Repo Flex nằm ngang hàng trong `C:\Workspace\Project`. |
| Todo | Cao | Chuẩn hóa quy ước đặt tên project | Cần thống nhất tên thư mục, tên module và namespace. |
| Todo | Trung bình | Bổ sung hướng dẫn chạy từng project | Mỗi project con nên có `README.md` riêng. |
| Todo | Trung bình | Bổ sung quy trình kiểm thử | Xác định test command, coverage và quy ước CI nếu có. |

## Cách thêm task mới

Khi thêm task mới, nên ghi rõ:

- Mục tiêu cần đạt.
- Phạm vi thay đổi.
- Project hoặc thư mục liên quan.
- Điều kiện hoàn tất.
- Rủi ro hoặc phần đang thiếu thông tin.

Mẫu task:

```text
| Todo | Cao | Tên task | Mục tiêu, phạm vi, điều kiện hoàn tất. |
```
