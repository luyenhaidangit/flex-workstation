# Data Model: Việt hóa toàn bộ template Speckit

## Speckit Template

Đại diện cho một file Markdown trong `.specify/templates/`.

**Fields**:
- `file_path`: path template, ví dụ `.specify/templates/tasks-template.md`.
- `artifact_type`: loại artifact template sinh ra, ví dụ spec, plan, tasks, checklist, constitution.
- `reader_content`: heading, mô tả, ghi chú, comment và sample content dành cho người đọc.
- `technical_identifiers`: command, path, placeholder, marker, code block hoặc key cần giữ nguyên.
- `required_structure`: section hoặc format bắt buộc để command Speckit dùng được.

**Validation rules**:
- `reader_content` phải dùng tiếng Việt có dấu.
- `technical_identifiers` phải giữ nguyên khi cần chính xác.
- `required_structure` không được bị xóa hoặc làm sai vai trò workflow.

## Template Set

Đại diện cho toàn bộ scope template được cập nhật trong feature này.

**Fields**:
- `templates`: danh sách file template trong `.specify/templates/`.
- `language_policy`: quy tắc dùng tiếng Việt có dấu cho phần người đọc.
- `identifier_policy`: quy tắc giữ nguyên technical identifiers.
- `validation_queries`: các static search dùng để bắt nhãn tiếng Anh còn sót.

**Validation rules**:
- Phải bao phủ đủ 5 template: `spec-template.md`, `plan-template.md`, `tasks-template.md`, `checklist-template.md`, `constitution-template.md`.
- Không được yêu cầu sửa `.agents/skills/**`.
- Phải có validation toàn bộ `.specify/templates`.

## Generated Artifact

Đại diện cho artifact mới được sinh từ template sau khi Việt hóa.

**Fields**:
- `artifact_path`: path artifact được sinh.
- `source_template`: template dùng để sinh artifact.
- `visible_language`: ngôn ngữ hiển thị cho người đọc.
- `preserved_identifiers`: danh sách định danh kỹ thuật được giữ nguyên.

**Validation rules**:
- Artifact mới phải dễ review bằng tiếng Việt.
- Placeholder/marker kỹ thuật phải còn chính xác.
- Artifact không được chứa thông tin nhạy cảm.

## Relationships

- Một `Template Set` gồm nhiều `Speckit Template`.
- Một `Speckit Template` có thể sinh nhiều `Generated Artifact`.
- Một `Generated Artifact` tham chiếu đúng một `source_template`.
