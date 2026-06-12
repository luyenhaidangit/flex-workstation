# CLAUDE.md

Chỉ dẫn nền cho Claude Code trong repo `flex-workstation`. Giữ file này ngắn để giảm token nền; đọc tài liệu chi tiết trong `README.md` và `docs/` khi task cần.

## Vai trò repo

`flex-workstation` là repo điều phối cho nhóm project Flex. Repo này chứa tài liệu, bootstrap, entrypoint mở VS Code và quy ước làm việc; không chứa mã nguồn nghiệp vụ của các project con.

Repo nghiệp vụ phải nằm ngang hàng với `flex-workstation`, không nằm bên trong repo này.

## Cấu trúc local mặc định

Trước khi clone repo mới, tạo thư mục, hoặc cập nhật task/workspace, xác nhận với người onboard cấu trúc:

```text
C:\Workspace\Project\
|-- flex-workstation\
|-- flex-frontend\
|-- flex-backend\
|-- flex-api-gateway\
+-- ...
```

Câu xác nhận gợi ý:

```text
Anh/chị xác nhận các repo Flex sẽ nằm trong C:\Workspace\Project\, ngang hàng với flex-workstation, ví dụ flex-frontend, flex-backend, flex-api-gateway... đúng không?
```

## Quy tắc làm việc

- Dùng tiếng Việt có dấu trong tài liệu, ghi chú và mô tả task.
- Giữ nguyên tên file, thư mục, command, package, API, framework và thuật ngữ kỹ thuật phổ biến.
- Không đưa token, mật khẩu, khóa API, connection string hoặc thông tin nhạy cảm vào repo.
- Không tự tạo submodule/subtree hoặc liên kết version giữa repo nếu người dùng chưa yêu cầu rõ.
- Không sửa mã nguồn project con khi yêu cầu chỉ thuộc `flex-workstation`.
- Không xóa hoặc revert thay đổi hiện có nếu không chắc đó là thay đổi do mình tạo.

## Điểm vào cho người dùng

- `START_HERE.cmd`: double-click để chạy bootstrap trên Windows.
- `OPEN_PROJECT.cmd`: double-click để mở `C:\Workspace\Project` trong VS Code.
- `scripts/bootstrap.ps1`: script kỹ thuật, không phải entrypoint double-click.

Nếu sửa onboarding hoặc công cụ cài đặt, cập nhật các file liên quan: `README.md`, `docs/onboarding.md`, `docs/tasks.md`, và entrypoint tương ứng.

## Tài liệu cần đọc theo task

- Tổng quan: `README.md`.
- Onboarding/bootstrap: `docs/onboarding.md`.
- Danh sách repo: `docs/projects.md`.
- Kiến trúc/quy ước: `docs/architecture.md`.
- Task hiện tại: `docs/tasks.md`.
- Skill dùng chung: `skills/README.md`.

## Kiểm tra tối thiểu

Sau thay đổi, chạy kiểm tra phù hợp với phạm vi. Ví dụ:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\bootstrap.ps1 -SkipClaudeInstall
Get-Content -Raw -Encoding UTF8 .vscode\tasks.json | ConvertFrom-Json | Out-Null
git status --short
```
