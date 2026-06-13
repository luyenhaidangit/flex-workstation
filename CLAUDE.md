# CLAUDE.md

Làm việc trong repo `flex-workstation` theo các quy ước dưới đây.

## Vai trò repo

`flex-workstation` là repo điều phối cho nhóm project Flex. Repo này chứa tài liệu, bootstrap, entrypoint mở VS Code và quy ước làm việc.

Không đặt mã nguồn nghiệp vụ của project con trong repo này. Các repo nghiệp vụ phải nằm ngang hàng với `flex-workstation`.

## Cấu trúc local mặc định

Trước khi clone repo mới, tạo thư mục, hoặc cập nhật task/workspace, xác nhận cấu trúc local với người onboard:

```text
C:\Workspace\Project\
|-- flex-workstation\
|-- flex-frontend\
|-- flex-backend\
|-- flex-api-gateway\
+-- ...
```

Câu xác nhận mẫu:

```text
Anh/chị xác nhận các repo Flex sẽ nằm trong C:\Workspace\Project\, ngang hàng với flex-workstation, ví dụ flex-frontend, flex-backend, flex-api-gateway... đúng không?
```

## Quy tắc làm việc

- Dùng tiếng Việt có dấu trong tài liệu, ghi chú và mô tả task.
- Giữ nguyên tên file, thư mục, command, package, API, framework và thuật ngữ kỹ thuật.
- Không đưa token, mật khẩu, khóa API, connection string hoặc thông tin nhạy cảm vào repo.
- Không tạo submodule/subtree hoặc liên kết version giữa repo nếu người dùng chưa yêu cầu rõ.
- Không sửa mã nguồn project con khi yêu cầu chỉ thuộc workstation.
- Không xóa hoặc revert thay đổi hiện có nếu không chắc đó là thay đổi do mình tạo.
- Khi thay đổi hành vi, cấu trúc hoặc onboarding, cập nhật tài liệu liên quan và `docs/tasks.md`.

## Điểm vào cho người dùng

- `START_HERE.cmd`: double-click để chạy bootstrap trên Windows.
- `OPEN_PROJECT.cmd`: double-click để mở `C:\Workspace\Project` trong VS Code.
- `scripts/bootstrap.ps1`: script kỹ thuật, không phải entrypoint double-click.

## Tài liệu cần đọc theo task

- Tổng quan: `README.md`.
- Onboarding/bootstrap: `docs/onboarding.md`.
- Danh sách repo: `docs/projects.md`.
- Kiến trúc/quy ước: `docs/architecture.md`.
- Task hiện tại: `docs/tasks.md`.
- Skill dùng chung: `skills/README.md`.
