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
| Done | Cao | Tạo tài liệu kiến trúc ban đầu | Xem `docs/architecture/overview.md`. |
| Done | Trung bình | Tạo thư mục skill dùng chung | Xem `skills/README.md`. |
| Done | Cao | Xác định danh sách project con | Đã thêm `flex-api-gateway` vào `docs/projects.md`. |
| Done | Cao | Ghi nhận Git project `flex-api-gateway` | Local path mục tiêu ban đầu là `C:\Workspace\Project\flex-api-gateway`; hiện cấu hình sync clone vào `C:\Workspace\Project\flex-workstation\flex-api-gateway`. |
| Done | Cao | Tạo task VS Code cho workstation | Xem `.vscode/tasks.json`. |
| Done | Cao | Tạo bootstrap cho máy mới | Xem `scripts/bootstrap.ps1` và `docs/onboarding.md`. |
| Done | Cao | Tạo chỉ dẫn Claude Code tổng quan | Xem `CLAUDE.md`. |
| Done | Cao | Tạo entrypoint double-click cho Windows | Xem `SYNC_WORKSPACE.cmd`. |
| Done | Cao | Tạo entrypoint mở nhanh VS Code tại workstation root | Xem `OPEN_WORKSTATION.cmd`; `OPEN_WORKSPACE.cmd` là alias tương thích. |
| Done | Cao | Tạo entrypoint mở Claude tại workstation root | Xem `OPEN_CLAUDE.cmd`. |
| Done | Cao | Tạo entrypoint mở Codex tại workstation root | Xem `OPEN_CODEX.cmd`. |
| Done | Cao | Hợp nhất entrypoint sync workspace | `SYNC_WORKSPACE.cmd` chạy bootstrap, sync template Claude/Codex, sync repo project và chuẩn bị local tooling. |
| Done | Cao | Thêm cấu hình clone/update repo khi sync workspace | `workstation.json` tại project root workstation khai báo repo Flex trong `repositories.items`; `scripts/bootstrap.ps1` clone repo còn thiếu vào `C:\Workspace\Project\flex-workstation` và pull repo đã tồn tại nếu working tree sạch. |
| Done | Cao | Chuyển đích clone repo vào workstation | Bootstrap mặc định clone repo con vào project root workstation; `.gitignore` bỏ qua các thư mục repo con. |
| Done | Cao | Hợp nhất cập nhật repo project vào sync | `SYNC_WORKSPACE.cmd` gọi `scripts/sync-repositories.ps1 -PullExisting`; không cần entrypoint update repo riêng. |
| Done | Cao | Bổ sung bước xác nhận cấu trúc local khi onboarding | Cấu trúc ban đầu đặt repo Flex ngang hàng trong `C:\Workspace\Project`; hiện đã chuyển đích clone vào project root workstation. |
| Done | Cao | Bootstrap cấu hình Claude ngoài workstation | Trước đây sync template `workspaces/templates/.claude` ra `C:\Workspace\Project\.claude`; hiện đã chuyển runtime target vào `flex-workstation`. |
| Done | Cao | Thêm template `.claude/settings.json` | Dùng cho cấu hình workspace chung; `settings.local.json` giữ cấu hình local theo máy/người dùng. |
| Done | Cao | Bootstrap root memory cho Claude tại workstation root | Trước đây copy `workspaces/templates/CLAUDE.md` ra `C:\Workspace\Project\CLAUDE.md`; hiện runtime target là `C:\Workspace\Project\flex-workstation\CLAUDE.md`. |
| Done | Cao | Đơn giản hóa bootstrap workspace | Bootstrap sync template `.claude`, `.agents`, `.codex`, `CLAUDE.md` và `AGENTS.md`; không còn sync skill hoặc external source. |
| Done | Cao | Bổ sung cấu hình Codex | Trước đây bootstrap sync `workspaces/templates/.codex/config.toml` ra `C:\Workspace\Project\.codex/config.toml`; hiện đã chuyển runtime target vào `flex-workstation`. |
| Done | Trung bình | Tạo skill `agent-instructions-architect` | Skill quản lý tầng instructions Claude Code (CLAUDE.md, memory, rules, subagent, SKILL.md, slash command, output style) với 3 chế độ Generate/Review/Improve. Skill source nằm tại `flex-workstation\skills`. |
| Done | Trung bình | Refactor tầng instructions workstation | Lean CLAUDE.md (~550→260 từ), bỏ trùng lặp cross-file: tree cấu trúc local chỉ ở `onboarding.md`, bootstrap chi tiết chỉ ở `onboarding.md`, quy tắc chỉ ở `CLAUDE.md`. Tổng line giảm 599→401. Đổi "Codex" thành "Claude Code". |
| Done | Cao | Bổ sung bản đồ hệ thống workspace | Thêm `docs/system-map.md`, link từ `README.md`, cập nhật `docs/projects.md` với `flex-auth-service`. |
| Done | Cao | Chuyển project root AI tooling vào `flex-workstation` | `OPEN_WORKSTATION.cmd`, `OPEN_CLAUDE.cmd`, `OPEN_CODEX.cmd` và bootstrap dùng `C:\Workspace\Project\flex-workstation` làm project root; template runtime config sync vào repo này. |
| Done | Cao | Chuẩn hóa entrypoint mở workstation | Thêm `OPEN_WORKSTATION.cmd`; `OPEN_WORKSPACE.cmd` chỉ còn là alias tương thích để tránh mở nhầm thư mục cha. |
| Done | Trung bình | Tạo skill `architecture-documenter` | Skill viết/review tài liệu kiến trúc hệ thống dựa trên evidence, Mermaid, risk review và ADR suggestions. |
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
