# Quickstart validation: Chuẩn hóa requirements template

## Điều kiện

- Đứng tại workspace root.
- Có `spec.md` cho feature cần kiểm.

## Kiểm tra

1. Xác nhận `.specify/templates/requirements-template.md` tồn tại và không có placeholder trong artifact đã sinh.
2. Tạo hoặc rà một `checklists/requirements.md` mới.
3. Xác nhận metadata có artifact chính, người/lần/trạng thái review và kết quả tổng hợp.
4. Xác nhận mỗi item có `CHK###`, severity, status và tham chiếu hoặc marker gap.
5. Đánh dấu một item `[Blocker]` là Fail; kết luận phải chặn bước tiếp theo.
6. Rà `$speckit-checklist` vẫn tham chiếu `checklist-template.md` cho checklist domain.
7. Chạy `git diff --check`.

## Kết quả mong đợi

Requirements checklist là quality gate có thể review; checklist domain không bị thay thế và không có lỗi whitespace trong diff.
