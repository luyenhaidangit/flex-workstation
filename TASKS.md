# TASKS

Theo dõi các spec đang chạy song song trong `flex-workstation`, khi có nhiều feature Speckit được triển khai cùng lúc ở các repo con khác nhau.

> Bảng này chỉ theo dõi spec **tạo mới hoặc cập nhật kể từ khi file này ra đời**. 22 spec đã tồn tại trước đó trong `specs/` không được backfill vào đây — trạng thái của chúng vẫn nằm trong field `**Trạng thái**` ở từng `spec.md`.

## Cách dùng

- Thêm một dòng khi bắt đầu `/speckit-specify` cho feature mới.
- Cập nhật cột **Trạng thái** khi feature đi qua các bước trong [docs/speckit/workflow.md](docs/speckit/workflow.md) (Nháp → Clarify → Plan → Tasks → Implementing → Done). Dùng `Paused` nếu tạm dừng.
- Xoá dòng khỏi bảng khi feature đã Done và không cần theo dõi nữa (lịch sử vẫn còn trong `spec.md` và git log).
- File này cập nhật thủ công — không có script sinh tự động.

## Spec đang theo dõi

| Spec | Repo | Trạng thái | Người phụ trách | Cập nhật | Ghi chú |
| --- | --- | --- | --- | --- | --- |
| _(chưa có)_ | | | | | |

<!--
Ví dụ một dòng:
| specs/000026-vi-du | flex-agent-service | Plan | Luyện Hải Đăng | 2026-08-01 | Chờ review plan.md |
-->
