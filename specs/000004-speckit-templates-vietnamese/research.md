# Research: Việt hóa toàn bộ template Speckit

## Decision: Cập nhật toàn bộ `.specify/templates/*.md`

**Rationale**: Người dùng muốn cập nhật toàn bộ template, không chỉ checklist. `.specify/templates/` hiện có 5 template dùng cho các artifact chính của Speckit. Cập nhật tất cả trong một feature giúp ngôn ngữ artifact sinh ra nhất quán.

**Alternatives considered**:
- Chỉ sửa `checklist-template.md`: loại bỏ vì không đáp ứng scope mới.
- Tách thành nhiều feature nhỏ theo từng template: loại bỏ vì thay đổi cùng loại, cùng vị trí, có thể validate chung.

## Decision: Không sửa `.agents/skills/**`

**Rationale**: Skill gốc có thể được sync lại từ upstream hoặc dùng chung giữa agent. Template workspace là điểm custom phù hợp hơn cho ngôn ngữ đầu ra, ít rủi ro hơn sửa skill runtime.

**Alternatives considered**:
- Sửa skill instruction để ép tiếng Việt: loại bỏ vì người dùng đã nêu mong muốn không sửa skill gốc.
- Dùng hook bắt buộc trong `.specify/extensions.yml`: loại bỏ vì chưa có command mở rộng thật và dễ chặn workflow.

## Decision: Giữ nguyên technical identifiers

**Rationale**: Command, path, placeholder, marker `[P]`, `[Story]`, `CHK###`, YAML/TOML keys, API/framework names cần chính xác để Speckit và người dùng hiểu đúng workflow.

**Alternatives considered**:
- Dịch toàn bộ tiếng Anh: loại bỏ vì dễ làm sai định danh kỹ thuật hoặc giảm khả năng trace.

## Decision: Validation bằng static search và diff checks

**Rationale**: Feature chủ yếu là Markdown/template. Static search phát hiện nhanh heading/label tiếng Anh phổ biến còn sót; `git diff -- .agents/skills` xác nhận skill gốc không bị sửa; `git diff --check` bắt lỗi whitespace cơ bản.

**Alternatives considered**:
- Thêm test framework mới: loại bỏ vì quá nặng cho thay đổi template.
- Chỉ review thủ công: chưa đủ để phát hiện scope drift hoặc thay đổi ngoài phạm vi.
