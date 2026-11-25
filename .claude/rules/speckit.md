---
paths:
  - "specs/**"
  - ".specify/**"
---

# Speckit Lifecycle Reference

Quy tắc chi tiết khi thao tác trực tiếp trên các artifact Speckit (`specs/`, `.specify/`).

## Cú pháp theo runtime

| Runtime | Cú pháp gọi skill Speckit |
| --- | --- |
| Codex | `$speckit-<command>` |
| Antigravity IDE/CLI và Claude Code | `/speckit-<command>` |

`speckit-specify` bật model-invocation cho câu mô tả feature tự nhiên; 10 skill `speckit-*` còn lại đặt `disable-model-invocation: true` tại `.agents/skills/` để bảo vệ gate người dùng chủ động gọi. Không tạo workflow `/speckit` tự chạy toàn bộ vòng đời.

## Setup (chạy một lần cho project)

Thiết lập nguyên tắc: `$speckit-constitution` hoặc `/speckit-constitution`

## Thứ tự các bước mỗi feature (hỗ trợ `--feature <id>` khi làm song song)

| Bước | Codex | Antigravity / Claude | Ghi chú |
| --- | --- | --- | --- |
| 1 | `$speckit-specify <mô tả nghiệp vụ>` | `/speckit-specify <mô tả nghiệp vụ>` | Chỉ WHAT + WHY — tự gắn `Chế độ Spec: Compact` hoặc `Full` |
| 2 | `$speckit-clarify` | `/speckit-clarify` | **Optional** — tối đa 5 câu làm rõ; chạy trước `docbiz`/`plan` để giảm rework |
| 2a | `$speckit-docbiz` | `/speckit-docbiz` | **Gate bắt buộc trước bước 4** — chạy sau lần cập nhật cuối `spec.md`; đánh giá và chỉ cập nhật doc khi có tác động nghiệp vụ đáng kể |
| 3 | `$speckit-checklist [domain]` | `/speckit-checklist [domain]` | **Optional** — tạo checklist domain (ux, security, api) |
| 4 | `$speckit-plan <tech stack + architecture>` | `/speckit-plan <tech stack + architecture>` | Tạo `repos.md` (qua `flex-repo-scope` nếu chạm sub-repo) + thiết kế kỹ thuật |
| 5 | `$speckit-tasks` | `/speckit-tasks` | Sinh task list theo dependency order + chạy static validation |
| 6 | `$speckit-taskstoissues` | `/speckit-taskstoissues` | **Optional** — chuyển tasks → GitHub Issues |
| 7 | `$speckit-analyze` | `/speckit-analyze` | **Optional** — cross-artifact quality gate trước implement (ưu tiên `research` subagent) |
| 8 | `$speckit-implement` | `/speckit-implement` | Thực thi tasks (`Trạng thái: Đang triển khai`); dừng hỏi nếu checklist chưa pass |
| 9 | `$speckit-converge` | `/speckit-converge` | Còn gap/vi phạm kỹ thuật → append task vào `tasks.md` và quay lại bước 8; 0 gap → tự chạy Final Specialist Review + Spec Reconciliation (`Ngày reconcile cuối`) + chốt `Trạng thái: Hoàn thành` |

Skills Speckit nằm tại `.agents/skills/` — source of truth dùng chung cho Codex, Antigravity và Claude Code. Mọi bảng báo cáo và câu hỏi tương tác của lệnh Speckit đều xuất tiếng Việt có dấu dù mẫu trong skill gốc viết tiếng Anh.
