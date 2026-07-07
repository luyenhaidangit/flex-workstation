<!--
BÁO CÁO TÁC ĐỘNG ĐỒNG BỘ
==================
Thay đổi phiên bản: 1.1.0 → 1.1.1
Section đã sửa:
  - Nguyên tắc II: Spec-Before-Code — mở rộng mô tả vai trò từng command trong luồng
  - Quy trình phát triển — cấu trúc lại thành Thiết lập + Theo từng tính năng, bổ sung đầy đủ lệnh
  - Nhãn hiển thị — Việt hóa heading và metadata của constitution
Đã thêm: Không có
Đã bỏ: Không có
Template đã cập nhật:
  ✅ .specify/templates/plan-template.md — gate kiểm tra quy ước còn hiệu lực, không thay đổi
  ✅ .specify/templates/spec-template.md — không bị ảnh hưởng bởi thay đổi này
  ✅ .specify/templates/tasks-template.md — không bị ảnh hưởng bởi thay đổi này
  ✅ .specify/templates/constitution-template.md — Việt hóa label hiển thị, giữ placeholder kỹ thuật
TODO hoãn lại: Không có
-->

# Quy ước flex-workstation

## Nguyên tắc cốt lõi

### I. Điều phối workspace thay vì triển khai

flex-workstation điều phối — không triển khai. Repository này chứa tài liệu, bootstrap scripts, skill source và AI tooling config dùng chung. Các sub-repo là Git repo độc lập, được clone vào workspace root và tự quản lý code của mình.

MUST: Mọi thay đổi code sản phẩm phải nằm trong sub-repo tương ứng, không phải trong workstation root.
MUST NOT: Tạo submodule, subtree hoặc version link giữa repo khi chưa có yêu cầu rõ ràng.
MUST NOT: Sửa source code của sub-repo khi yêu cầu chỉ thuộc phạm vi workstation.

### II. Spec trước code (không thương lượng)

Mọi tính năng bắt đầu bằng spec nghiệp vụ trước khi có bất kỳ implementation nào. Spec là nguồn sự thật duy nhất — code theo sau spec, không phải ngược lại.

Luồng speckit phân vai trò rõ ràng:
- `/speckit-specify` nhận mô tả nghiệp vụ (WHAT + WHY) — không có tech stack.
- `/speckit-plan` nhận tech stack và architecture — đây là nơi kỹ thuật được quyết định.
- `/speckit-implement` chỉ chạy sau khi spec, plan và tasks đã đầy đủ.

MUST: Chạy `/speckit-specify` với mô tả nghiệp vụ trước bất kỳ implementation nào.
MUST: Tech stack và architecture được truyền vào `/speckit-plan`, không vào `/speckit-specify`.
MUST: Spec được lưu tại `specs/<feature-id>/spec.md` và commit vào repo.
MUST: Cập nhật spec khi scope thay đổi — spec là living document.
MUST NOT: Implement feature không có trong spec hoặc task list.

### III. Tooling không phụ thuộc agent

Cấu hình AI tooling không lock-in vào một agent cụ thể. Claude Code, Codex CLI và Copilot đều phải có thể hoạt động từ cùng workspace root với cấu hình riêng của chúng.

MUST: Mỗi agent có runtime config riêng (`.claude/`, `.agents/`, `.codex/`).
MUST: Skill source dùng chung lưu tại `skills/` — không hardcode vào config của một agent.
MUST NOT: Đưa API key, token hoặc credential vào bất kỳ file config nào trong repo.

### IV. Bootstrap có thể tái lập

Máy mới phải đạt trạng thái làm việc đầy đủ chỉ bằng một lệnh: `SYNC_WORKSPACE.cmd`. Không yêu cầu setup thủ công ngoài script này.

MUST: Mọi tool dependency (Claude Code, uv, specify-cli, rtk, ccusage) được kiểm tra và cài tự động qua `scripts/bootstrap.ps1`.
MUST: `specify init` chạy tự động với `--force --script-type ps` để không cần tương tác.
MUST: `.claude/settings.local.json` được giữ nguyên nếu đã tồn tại — đây là config theo máy/người dùng.
MUST NOT: Yêu cầu bước setup thủ công nào không được document trong `docs/onboarding.md`.

### V. Chỉ thay đổi phẫu thuật

Chỉ thay đổi đúng những gì cần. Không thêm tính năng suy đoán, không tạo abstraction cho code dùng một lần, không "cải thiện" code không liên quan đến yêu cầu hiện tại.

MUST: Xóa import/biến/hàm mà chính thay đổi hiện tại làm thừa.
MUST NOT: Tự ý xóa dead code từ trước khi chưa được yêu cầu.
MUST NOT: Refactor, format hoặc thêm comment vào code không liên quan đến task đang làm.
SHOULD: Khi phát hiện dead code không liên quan, nhắc người dùng — không tự xóa.

## Chính sách sub-repo

Sub-repo là Git repo độc lập được khai báo trong `workstation.json`. Bootstrap clone chúng vào workspace root và cập nhật bằng `git pull --ff-only`.

- Repo có local changes, origin khác cấu hình hoặc detached HEAD: bootstrap cảnh báo và bỏ qua — không force overwrite.
- Thêm repo mới: bổ sung entry vào `workstation.json`, không tạo submodule.
- Workstation Git ignore toàn bộ sub-repo directory — mỗi repo tự quản lý history của mình.

## Quy trình phát triển

### Thiết lập (chạy một lần cho project)

1. Mở workspace: `OPEN_CLAUDE.cmd` hoặc `OPEN_CODEX.cmd`
2. Thiết lập nguyên tắc: `/speckit-constitution`

### Mỗi tính năng (lặp lại)

| Bước | Lệnh | Ghi chú |
|------|---------|---------|
| 1 | `/speckit-specify <mô tả nghiệp vụ>` | Chỉ WHAT + WHY — không có tech stack |
| 2 | `/speckit-clarify` | **Tùy chọn** — tối đa 5 câu làm rõ; chạy trước plan để giảm rework |
| 3 | `/speckit-checklist [domain]` | **Tùy chọn** — tạo checklist domain (ux, security, api); là gate của implement |
| 4 | `/speckit-plan <tech stack + architecture>` | Tech stack và architecture được truyền vào đây |
| 5 | `/speckit-tasks` | Sinh task list theo dependency order |
| 6 | `/speckit-taskstoissues` | **Tùy chọn** — chuyển tasks.md thành GitHub Issues |
| 7 | `/speckit-analyze` | **Tùy chọn** — cross-artifact quality gate trước implement |
| 8 | `/speckit-implement` | Thực thi tasks; tự dừng nếu checklist còn item chưa tick |
| 9 | `/speckit-converge` | Nếu còn gap: append task bổ sung vào tasks.md → quay lại bước 8 |

Mọi thay đổi hành vi quan trọng của workstation phải được phản ánh trong `docs/` trước khi merge.

## Quản trị

Quy ước này là tài liệu cao nhất của `flex-workstation`. Mọi quyết định về tooling, workflow và cấu trúc phải nhất quán với các nguyên tắc trên.

Quy trình sửa đổi:
- MAJOR bump: xóa hoặc tái định nghĩa nguyên tắc cốt lõi → yêu cầu thảo luận và PR riêng.
- MINOR bump: thêm nguyên tắc hoặc section mới, mở rộng hướng dẫn hiện có.
- PATCH bump: làm rõ, sửa lỗi chính tả, tinh chỉnh không thay đổi nghĩa.

Sau mỗi lần sửa đổi: cập nhật `LAST_AMENDED_DATE`, tăng `CONSTITUTION_VERSION`, commit với message `docs: amend constitution to vX.Y.Z`.

**Phiên bản**: 1.1.1 | **Phê chuẩn**: 2026-07-05 | **Sửa đổi gần nhất**: 2026-07-08
