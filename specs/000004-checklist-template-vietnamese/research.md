# Research: Sửa template checklist Speckit sang tiếng Việt

## Decision: Giữ phạm vi ở nguồn sinh checklist mới

**Rationale**: Spec yêu cầu sửa nội dung template/hướng dẫn sinh checklist, không dịch hồi tố checklist cũ và không đổi workflow. Cách này đáp ứng đúng vấn đề người dùng nêu, đồng thời tuân thủ nguyên tắc thay đổi phẫu thuật.

**Alternatives considered**:
- Dịch toàn bộ checklist cũ trong `specs/`: loại bỏ vì ngoài phạm vi.
- Đổi tên command/workflow sang tiếng Việt: loại bỏ vì định danh kỹ thuật cần giữ nguyên.

## Decision: Sửa cả canonical template và skill instruction liên quan

**Rationale**: `.specify/templates/checklist-template.md` chứa nhãn meta/category tiếng Anh; `.agents/skills/speckit-checklist/SKILL.md` hướng dẫn agent tạo checklist bằng nhiều heading/category tiếng Anh; `.agents/skills/speckit-specify/SKILL.md` có block checklist chất lượng spec bằng tiếng Anh. Nếu chỉ sửa template Markdown, agent vẫn có thể sinh checklist tiếng Anh từ instruction.

**Alternatives considered**:
- Chỉ sửa `.specify/templates/checklist-template.md`: không đủ vì command skill có nội dung hướng dẫn và fallback tiếng Anh.
- Chỉ sửa skill instruction: không đủ vì template canonical vẫn sinh nhãn tiếng Anh.

## Decision: Giữ nguyên technical identifiers bằng English

**Rationale**: `command`, file path, Markdown syntax, `CHK###`, tên file và tên thư mục là định danh kỹ thuật. Dịch các phần này có thể làm sai workflow hoặc giảm khả năng trace.

**Alternatives considered**:
- Dịch toàn bộ mọi từ tiếng Anh: loại bỏ vì gây rủi ro sai định danh kỹ thuật.

## Decision: Validation bằng static search và sinh thử checklist khi khả thi

**Rationale**: Feature chủ yếu là nội dung template. Static search phát hiện nhanh các nhãn tiếng Anh phổ biến còn sót; sinh thử checklist chứng minh đầu ra mới đọc được bằng tiếng Việt.

**Alternatives considered**:
- Thêm test framework mới: loại bỏ vì quá nặng cho thay đổi Markdown/template.
- Chỉ review thủ công: chưa đủ để phát hiện nhãn tiếng Anh còn sót.
