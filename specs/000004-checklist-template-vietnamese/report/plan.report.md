# Plan Report: Sửa template checklist Speckit sang tiếng Việt

**Feature**: `000004-checklist-template-vietnamese`
**Created**: 2026-07-07
**Plan**: [../plan.md](../plan.md)

## Tổng số tasks đã plan

Dự kiến 7 task implementation, sẽ được chuẩn hóa trong `tasks.md` ở bước `$speckit-tasks`.

## Danh sách tasks theo dependency

1. Rà soát toàn bộ nguồn sinh checklist trong `.specify/templates/` và `.agents/skills/`.
2. Sửa `.specify/templates/checklist-template.md` sang tiếng Việt, giữ nguyên Markdown syntax và `CHK###`.
3. Sửa `.agents/skills/speckit-checklist/SKILL.md` để hướng dẫn sinh checklist bằng tiếng Việt.
4. Sửa block checklist chất lượng spec trong `.agents/skills/speckit-specify/SKILL.md`.
5. Kiểm tra static các nhãn checklist tiếng Anh phổ biến còn sót.
6. Sinh thử checklist mới nếu workflow sẵn sàng.
7. Cập nhật `docs/tasks.md` nếu thay đổi này được xem là thay đổi hành vi/onboarding của workstation.

## Risks và assumptions

**Risks**:
- Dịch sai làm thay đổi ý nghĩa checklist requirement-quality.
- Bỏ sót nguồn sinh checklist trong skill instruction.
- Dịch nhầm technical identifier khiến command/path/mã item không còn chính xác.

**Assumptions**:
- Phạm vi chỉ áp dụng cho checklist mới sinh từ template/hướng dẫn đã sửa.
- Không dịch hồi tố checklist cũ.
- Technical identifiers giữ nguyên English.

## Estimated effort

Nhỏ: khoảng 1 phiên làm việc ngắn sau khi `tasks.md` được sinh, chủ yếu là sửa Markdown và validation bằng `rg`.
