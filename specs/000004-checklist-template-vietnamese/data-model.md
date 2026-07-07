# Data Model: Sửa template checklist Speckit sang tiếng Việt

## Checklist Template

Đại diện cho nguồn nội dung được dùng để tạo file checklist mới.

**Fields**:
- `title_pattern`: mẫu tiêu đề checklist.
- `metadata_labels`: nhãn meta như mục đích, ngày tạo, feature/artifact liên quan.
- `generation_note`: ghi chú về command sinh checklist.
- `category_headings`: nhóm item checklist.
- `item_format`: định dạng checkbox và mã item, ví dụ `- [ ] CHK###`.
- `notes_section`: hướng dẫn tick item, ghi chú và liên kết tài liệu.

**Validation rules**:
- Nội dung hướng tới người dùng phải là tiếng Việt có dấu.
- Technical identifiers phải giữ nguyên khi cần chính xác.
- Markdown checkbox và numbering phải giữ nguyên khả năng sử dụng.

## Checklist Skill Instruction

Đại diện cho hướng dẫn agent dùng để sinh checklist theo ngữ cảnh feature.

**Fields**:
- `purpose_explanation`: giải thích checklist dùng để kiểm tra chất lượng requirement.
- `generation_steps`: các bước setup, đọc context, tạo file và report.
- `category_guidance`: danh sách nhóm chất lượng requirement.
- `item_guidance`: mẫu câu và quy tắc viết item.
- `anti_examples`: ví dụ sai cần tránh.
- `reporting_guidance`: nội dung cần báo cáo sau khi sinh checklist.

**Validation rules**:
- Các heading và hướng dẫn người dùng đọc phải bằng tiếng Việt.
- Ví dụ item nên dùng tiếng Việt, trừ định danh như `[Gap]`, `[Spec §X]`, `CHK###` nếu quyết định giữ.
- Không làm mất ràng buộc “check requirements, not implementation”.

## Generated Checklist

Đại diện cho file checklist mới được tạo sau khi template/hướng dẫn đã sửa.

**Fields**:
- `title`: tiêu đề checklist.
- `purpose`: mục đích.
- `created_date`: ngày tạo.
- `feature_link`: link tới artifact liên quan.
- `categories`: nhóm kiểm tra.
- `items`: danh sách checkbox có mã tuần tự.
- `notes`: ghi chú sử dụng.

**Validation rules**:
- Các nhãn phổ biến như `Purpose`, `Created`, `Feature`, `Notes`, `Content Quality` không xuất hiện trong phần người dùng đọc, trừ khi là trích dẫn hoặc ví dụ cần kiểm tra.
- Item có thể được tick trong Markdown.
- Mỗi item vẫn kiểm tra chất lượng yêu cầu, không biến thành test implementation.

## Relationships

- Một `Checklist Template` có thể sinh nhiều `Generated Checklist`.
- Một `Checklist Skill Instruction` điều khiển cách agent diễn giải template và yêu cầu feature.
- Một `Generated Checklist` tham chiếu một artifact như `spec.md`, `plan.md` hoặc `tasks.md`.
