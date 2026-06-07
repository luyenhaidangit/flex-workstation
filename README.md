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
|   |-- projects.md
|   +-- tasks.md
|-- skills/
|   +-- README.md
|-- .gitattributes
|-- flex-workstation.code-workspace
+-- README.md
```

## Tài liệu chính

- [docs/tasks.md](docs/tasks.md): danh sách task cần triển khai, trạng thái, độ ưu tiên và ghi chú thực hiện.
- [docs/architecture.md](docs/architecture.md): mô tả kiến trúc tổng quan, danh sách project, trách nhiệm của từng project và quy ước tích hợp.
- [docs/projects.md](docs/projects.md): danh sách các Git project được theo dõi chung trong workspace.
- [skills/README.md](skills/README.md): mô tả cách tổ chức skill dùng chung trong workspace.

## Mở workspace trong VS Code

Để VS Code theo dõi đồng thời các Git repo đã khai báo, mở file:

```powershell
code flex-workstation.code-workspace
```

File workspace hiện khai báo:

- `flex-workstation`
- `flex-api-gateway`

Sau khi mở bằng file này, tab Source Control của VS Code sẽ hiển thị các repository trong cùng một workspace.

## Quy ước triển khai

- Mỗi project con nên có thư mục riêng, tài liệu mục đích riêng và hướng dẫn chạy tối thiểu.
- Task mới nên được ghi vào `docs/tasks.md` trước khi triển khai để tránh mất ngữ cảnh.
- Thay đổi kiến trúc hoặc cách tổ chức thư mục cần được cập nhật vào `docs/architecture.md`.
- Skill dùng chung nên đặt trong `skills/` và có mô tả rõ: khi nào dùng, đầu vào cần có, quy trình thực hiện, và kết quả mong đợi.

## Trạng thái hiện tại

Workspace đang ở giai đoạn khởi tạo. Các tài liệu nền đã được chuẩn bị để tiếp tục bổ sung project con, task cụ thể và skill dùng chung.
