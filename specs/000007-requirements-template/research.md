# Research: Chuẩn hóa requirements template

## DEC-001 — Tách requirements template khỏi checklist template

**Decision**: Tạo `.specify/templates/requirements-template.md` riêng.

**Rationale**: `requirements.md` là quality gate bắt buộc, còn `checklist-template.md` là khung cho checklist domain tùy biến của `$speckit-checklist`. Một template riêng loại bỏ sự mơ hồ về vai trò và tránh làm template domain bị cứng theo workflow specify.

**Alternatives considered**:

- Tái dùng `checklist-template.md`: Không chọn vì cần placeholder và hướng dẫn dành cho nhiều loại checklist.
- Giữ Markdown hard-code trong `$speckit-specify`: Không chọn vì template workspace không được áp dụng.

## DEC-002 — Không có fallback hard-code

**Decision**: `$speckit-specify` phải dừng rõ ràng nếu không resolve được requirements template.

**Rationale**: Fallback khiến artifact mất cấu trúc review mà không bị phát hiện.

**Alternatives considered**:

- Fallback về checklist cũ: Không chọn vì tái tạo chính lỗi cần sửa.
