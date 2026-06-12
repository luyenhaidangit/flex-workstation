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
| Done | Cao | Theo dõi Git project `flex-api-gateway` | Local path: `C:\Workspace\Personal\flex-api-gateway`. |
| Done | Cao | Tạo VS Code multi-root workspace | Xem `flex-workstation.code-workspace` và `.vscode/tasks.json`. |
| Done | Cao | Tạo bootstrap cho máy mới | Xem `bootstrap.ps1` và `docs/onboarding.md`. |
| Done | Cao | Tạo chỉ dẫn Claude Code tổng quan | Xem `CLAUDE.md`. |
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
