# Ghi chú task workspace

## Speckit templates tiếng Việt

- Toàn bộ template Speckit trong `.specify/templates/` dùng tiếng Việt có dấu cho phần người dùng đọc và review.
- Giữ nguyên technical identifiers như command, file path, package, API, framework, Markdown syntax, placeholder, `[P]`, `[Story]`, `CHK###`, `[Gap]`, `[Spec §X]`, `[Ambiguity]`, `[Conflict]`, `[Assumption]`.
- Spec template chỉ mô tả WHY/WHAT; HOW thuộc plan kỹ thuật. ID trong spec dùng ASCII để dễ search/copy: `MT`, `US`, `AC`, `FR`, `NFR`, `SC`.
- Không sửa trực tiếp skill gốc trong `.agents/skills/**` chỉ để đổi ngôn ngữ artifact. Nếu cần custom output, ưu tiên template workspace và tài liệu workflow.
- Khi validate thay đổi template, chạy static search trên toàn bộ `.specify/templates` và xác nhận `git diff -- .agents/skills` không có thay đổi.
