<!--
SYNC IMPACT REPORT
==================
Version change: (template) → 1.0.0
Added sections: Core Principles (I–V), Sub-Repo Policy, Development Workflow, Governance
Removed sections: N/A (initial ratification)
Templates updated:
  ✅ .specify/templates/plan-template.md — Constitution Check gate applicable
  ✅ .specify/templates/spec-template.md — aligned with spec-driven principle
  ✅ .specify/templates/tasks-template.md — aligned with task structure
Deferred TODOs: None
-->

# flex-workstation Constitution

## Core Principles

### I. Workspace Coordination Over Implementation

flex-workstation điều phối — không triển khai. Repository này chứa tài liệu, bootstrap scripts, skill source và AI tooling config dùng chung. Các sub-repo là Git repo độc lập, được clone vào workspace root và tự quản lý code của mình.

MUST: Mọi thay đổi code sản phẩm phải nằm trong sub-repo tương ứng, không phải trong workstation root.
MUST NOT: Tạo submodule, subtree hoặc version link giữa repo khi chưa có yêu cầu rõ ràng.
MUST NOT: Sửa source code của sub-repo khi yêu cầu chỉ thuộc phạm vi workstation.

### II. Spec-Before-Code (NON-NEGOTIABLE)

Mọi tính năng bắt đầu bằng `/speckit-specify`. Không có implementation nào được viết trước khi có spec đã được review. Spec là nguồn sự thật duy nhất — code theo sau spec, không phải ngược lại.

MUST: Chạy `/speckit-specify` trước bất kỳ implementation nào.
MUST: Spec được lưu tại `specs/<feature-branch>/spec.md` và commit vào repo.
MUST: Cập nhật spec khi scope thay đổi — spec là living document.
MUST NOT: Implement feature không có trong spec hoặc task list.

### III. Agent-Agnostic Tooling

Cấu hình AI tooling không lock-in vào một agent cụ thể. Claude Code, Codex CLI và Copilot đều phải có thể hoạt động từ cùng workspace root với cấu hình riêng của chúng.

MUST: Mỗi agent có runtime config riêng (`.claude/`, `.agents/`, `.codex/`).
MUST: Skill source dùng chung lưu tại `skills/` — không hardcode vào config của một agent.
MUST NOT: Đưa API key, token hoặc credential vào bất kỳ file config nào trong repo.

### IV. Bootstrap Reproducibility

Máy mới phải đạt trạng thái làm việc đầy đủ chỉ bằng một lệnh: `SYNC_WORKSPACE.cmd`. Không yêu cầu setup thủ công ngoài script này.

MUST: Mọi tool dependency (Claude Code, uv, specify-cli, rtk, ccusage) được kiểm tra và cài tự động qua `scripts/bootstrap.ps1`.
MUST: `specify init` chạy tự động với `--force --script-type ps` để không cần tương tác.
MUST: `.claude/settings.local.json` được giữ nguyên nếu đã tồn tại — đây là config theo máy/người dùng.
MUST NOT: Yêu cầu bước setup thủ công nào không được document trong `docs/onboarding.md`.

### V. Surgical Changes Only

Chỉ thay đổi đúng những gì cần. Không thêm tính năng suy đoán, không tạo abstraction cho code dùng một lần, không "cải thiện" code không liên quan đến yêu cầu hiện tại.

MUST: Xóa import/biến/hàm mà chính thay đổi hiện tại làm thừa.
MUST NOT: Tự ý xóa dead code từ trước khi chưa được yêu cầu.
MUST NOT: Refactor, format hoặc thêm comment vào code không liên quan đến task đang làm.
SHOULD: Khi phát hiện dead code không liên quan, nhắc người dùng — không tự xóa.

## Sub-Repo Policy

Sub-repo là Git repo độc lập được khai báo trong `workstation.json`. Bootstrap clone chúng vào workspace root và cập nhật bằng `git pull --ff-only`.

- Repo có local changes, origin khác cấu hình hoặc detached HEAD: bootstrap cảnh báo và bỏ qua — không force overwrite.
- Thêm repo mới: bổ sung entry vào `workstation.json`, không tạo submodule.
- Workstation Git ignore toàn bộ sub-repo directory — mỗi repo tự quản lý history của mình.

## Development Workflow

1. Mở workspace: `OPEN_CLAUDE.cmd` hoặc `OPEN_CODEX.cmd`
2. Tạo spec feature: `/speckit-specify <mô tả>`
3. Clarify nếu cần: `/speckit-clarify`
4. Plan kỹ thuật: `/speckit-plan`
5. Breakdown tasks: `/speckit-tasks`
6. Implement: `/speckit-implement`
7. Khi thay đổi behavior/structure/onboarding: cập nhật `TASKS.md` và doc liên quan.

Mọi thay đổi hành vi quan trọng của workstation phải được phản ánh trong `docs/` trước khi merge.

## Governance

Constitution này là tài liệu cao nhất của `flex-workstation`. Mọi quyết định về tooling, workflow và cấu trúc phải nhất quán với các nguyên tắc trên.

Amendment procedure:
- MAJOR bump: xóa hoặc tái định nghĩa nguyên tắc cốt lõi → yêu cầu thảo luận và PR riêng.
- MINOR bump: thêm nguyên tắc hoặc section mới.
- PATCH bump: làm rõ, sửa lỗi chính tả, tinh chỉnh không thay đổi nghĩa.

Sau mỗi amendment: cập nhật `LAST_AMENDED_DATE`, tăng `CONSTITUTION_VERSION`, commit với message `docs: amend constitution to vX.Y.Z`.

**Version**: 1.0.0 | **Ratified**: 2026-07-05 | **Last Amended**: 2026-07-05
