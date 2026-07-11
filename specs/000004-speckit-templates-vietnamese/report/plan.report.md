# Plan Report: Việt hóa toàn bộ template Speckit

**Feature**: `000004-speckit-templates-vietnamese`
**Created**: 2026-07-07
**Plan**: [../plan.md](../plan.md)

## Tổng số tasks đã plan

Dự kiến 25 task trong `tasks.md`, tập trung vào 5 template Speckit, validation và tài liệu workflow.

## Danh sách tasks theo dependency

1. Rà danh sách template trong `.specify/templates/`.
2. Chốt quy tắc giữ technical identifiers và không sửa `.agents/skills/**`.
3. Việt hóa `spec-template.md`, `plan-template.md`, `tasks-template.md`, `checklist-template.md`, `constitution-template.md`.
4. Rà từng template để giữ cấu trúc workflow bắt buộc.
5. Chạy static search tiếng Anh phổ biến trên toàn bộ `.specify/templates`.
6. Kiểm tra technical identifiers còn nguyên.
7. Xác nhận `git diff -- .agents/skills` không có thay đổi.
8. Chạy `git diff --check`.
9. Cập nhật `docs/speckit/templates.md` và `docs/speckit/workflow.md`.

## Risks và assumptions

**Risks**:
- Dịch nhầm placeholder hoặc marker kỹ thuật.
- Việt hóa làm mất section mà command Speckit phụ thuộc.
- Một số thuật ngữ tiếng Anh kỹ thuật còn lại bị hiểu nhầm là chưa Việt hóa.

**Assumptions**:
- Phạm vi áp dụng cho 5 template trong `.specify/templates/`.
- Không dịch hồi tố artifact cũ ngoài artifact feature cần cập nhật scope.
- Không sửa trực tiếp `.agents/skills/**`.
- Technical identifiers giữ nguyên English.

## Estimated effort

Nhỏ đến trung bình: khoảng 1 phiên làm việc, chủ yếu là sửa Markdown và validation bằng `rg`/`git diff`.
