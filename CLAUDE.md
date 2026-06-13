# CLAUDE.md

Repo `flex-workstation` là workspace điều phối cho nhóm project Flex: tài liệu, bootstrap, entrypoint VS Code và quy ước làm việc. Không chứa mã nguồn nghiệp vụ; các repo nghiệp vụ nằm ngang hàng với `flex-workstation`. Cấu trúc local đầy đủ và bước xác nhận onboarding: xem `docs/onboarding.md`.

## Quy tắc làm việc

- Dùng tiếng Việt có dấu trong tài liệu, ghi chú và mô tả task. Giữ nguyên tên file, thư mục, command, package, API, framework và thuật ngữ kỹ thuật bằng tiếng Anh.
- Không đưa token, mật khẩu, khóa API, connection string hoặc thông tin nhạy cảm vào repo.
- Không tạo submodule/subtree hoặc liên kết version giữa repo nếu người dùng chưa yêu cầu rõ.
- Không sửa mã nguồn project con khi yêu cầu chỉ thuộc workstation.
- Không xóa hoặc revert thay đổi hiện có nếu không chắc đó là thay đổi do mình tạo — tránh ghi đè work-in-progress của thành viên khác hoặc session Claude trước.
- Khi thay đổi hành vi, cấu trúc hoặc onboarding, cập nhật `docs/tasks.md` và file tương ứng:
  - Onboarding/bootstrap → `docs/onboarding.md`
  - Kiến trúc/quy ước kỹ thuật → `docs/architecture.md`
  - Danh sách project con → `docs/projects.md`
  - Skill dùng chung → `config/workspace-skills.json`

## Entrypoint Windows

- `SETUP_WORKSPACE.cmd`: double-click để chạy bootstrap.
- `OPEN_WORKSPACE.cmd`: double-click để mở `C:\Workspace\Project` trong VS Code.
- `OPEN_CLAUDE.cmd`: double-click để mở Claude Code tại `C:\Workspace\Project` với `--dangerously-skip-permissions`; chỉ dùng trong workspace tin cậy.
- `SYNC_WORKSPACE_SKILLS.cmd`: double-click để sync skill local dùng chung từ `config/workspace-skills.json`.
- `scripts/bootstrap.ps1`: script kỹ thuật bên trong, không phải entrypoint double-click.

## Tài liệu

- Index đầy đủ và mục đích từng tài liệu: `README.md`
- Task hiện tại: `docs/tasks.md`
