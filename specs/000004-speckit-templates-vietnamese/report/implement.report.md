# Báo cáo implement: Việt hóa toàn bộ template Speckit

**Ngày**: 2026-07-07

**Feature**: `specs/000004-speckit-templates-vietnamese`

## Kết quả

- Checklist gate đạt: `requirements.md` có 16/16 item hoàn tất.
- Đã xác nhận đủ 5 template trong `.specify/templates/`.
- Đã Việt hóa các heading hiển thị còn sót trong template:
  - `.specify/templates/tasks-template.md`: `Notes` -> `Ghi chú`
  - `.specify/templates/constitution-template.md`: `Governance` -> `Quản trị`
- Đã cập nhật artifact feature để thống nhất policy giữ section tương đương, không bắt buộc giữ label English trong output.
- Đã đánh dấu T001-T025 hoàn tất trong `tasks.md`.

## Validation

- `rtk rg --files .specify/templates`: đủ 5 template trong scope.
- `rtk rg "Purpose|Created|Feature|Summary|Technical Context|Constitution Check|Project Structure|Organization|Path Conventions|Notes|Core Principles|Governance|Requirements|Success Criteria" .specify/templates`: không còn hit.
- `rtk rg "CHK###|\\[P\\]|\\[Story\\]|\\[TÊN TÍNH NĂNG\\]|\\[TÍNH NĂNG\\]|\\[LOẠI CHECKLIST\\]|\\[PROJECT_NAME\\]|/speckit-|\\.specify/templates|spec.md|plan.md|tasks.md" .specify/templates`: marker, placeholder, command và path cần thiết vẫn còn.
- `rtk powershell -NoProfile -Command "git diff -- .agents/skills"`: không có diff.
- `rtk powershell -NoProfile -Command "git diff --check"`: không có lỗi whitespace; Git chỉ cảnh báo LF sẽ được đổi sang CRLF theo cấu hình.
- `rtk rg "^- \\[ \\] T[0-9]{3}" specs/000004-speckit-templates-vietnamese/tasks.md`: không còn task mở.

## Ghi chú

`.specify/extensions.yml` hiện là `hooks: {}`, nên không có hook trước hoặc sau implement cần chạy.
