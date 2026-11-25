# Speckit Template Guidelines

Quy ước thiết kế và bảo trì bộ template Speckit tiếng Việt gọn nhẹ cho `flex-workstation`.

Tài liệu này là checklist bảo trì cho `.specify/templates/`. Để tối ưu context window (~60% tiết kiệm token mỗi feature), **các quy tắc hướng dẫn dài và anti-examples cho AI được tách sang `references/` của từng skill**, còn file trong `.specify/templates/` chỉ giữ khung xương output và comment chỉ dẫn 1 dòng.

## Quy tắc chung

- Phần người dùng đọc/review trong `.specify/templates/` và mọi bảng báo cáo của lệnh Speckit dùng **tiếng Việt có dấu**.
- Giữ nguyên technical identifiers: command, file path, package, API, framework, Markdown syntax, placeholder, `[P]`, `[US#]`, `CHK###`, `[Gap]`, `[Spec §X]`, `[Ambiguity]`, `[Conflict]`, `[Assumption]`.
- Với section không áp dụng: giữ nguyên heading để ổn định cấu trúc đánh số, nhưng chỉ ghi gọn 1 dòng `Không áp dụng — <lý do ngắn>` (không render bảng rỗng nhiều dòng).
- Kiểm tra sau khi sửa template bằng `node scripts/speckit-cli.js validate --feature <id> --stage <specify|plan|tasks|implement|converge>`.

## Spec Template (`spec-template.md`)

- Chỉ mô tả **WHY + WHAT**; HOW thuộc `plan.md`. Giữ cố định đánh số đề mục `§1–§20` (và `## Clarifications` giữa `§18` và `§19`) để tương thích với `speckit-clarify`, `speckit-docbiz` và `speckit-plan`.
- Header bắt buộc có: `Branch`, `Ngày tạo`, `Chế độ Spec` (`Compact` / `Full`), `Trạng thái` (`Bản nháp` → `Đang triển khai` ở `implement` → `Hoàn thành` ở `converge` closeout; ngoại lệ sửa tay duy nhất là `Đã thay thế bởi <feature-id>`), `Ngày reconcile cuối` (mặc định `Chưa reconcile`), `Người phụ trách` và `Stakeholder xác nhận` (`{{GIT_USER_NAME}}`).
- ID chuẩn ASCII: `MVP`, `MT`, `US`, `AC`, `FR` (kèm `[P1]`/`[P2]`/`[P3]`), `BR`, `SEC`, `NFR`, `SC`.
- `§19` chỉ giữ 3 cổng tham chiếu gọn (trỏ sang `checklists/requirements.md`, `§18` và `§20`) để không lặp lại 16 tiêu chí của `requirements.md`.
- `§20` lưu kết quả Documentation Impact Gate của `/speckit-docbiz` (mặc định `CHƯA ĐÁNH GIÁ`).

## Plan Template (`plan-template.md`)

- Hỗ trợ 2 chế độ theo `spec.md`:
  - `Compact` (1 repo, không đổi DB dùng chung, không breaking public contract): nhúng thẳng quyết định research, entity/data và lệnh quickstart ngay trong `plan.md`, không đẻ thêm file rời `research.md`, `data-model.md`, `quickstart.md`.
  - `Full`: sinh đầy đủ các artifact Phase 0/1.
- Bắt buộc khai `Service / Repo liên quan` khớp `specs/<id>/repos.md` (do `flex-repo-scope` tạo) và `Convention skill áp dụng` theo từng repo.
- Bắt buộc đánh giá `Database đích & Repo chứa migration` đối chiếu `docs/architecture/system-map.md` (Constitution VI), tách biệt rollback code/config với rollback dữ liệu/migration, và liệt kê dữ liệu nhạy cảm cấm log.
- Giữ marker `# [XÓA NẾU KHÔNG DÙNG]` trong khối cây thư mục mẫu để `speckit-cli.js validate --stage plan` tự động bắt lỗi nếu chưa thay bằng path thật.

## Requirements & Checklist Templates (`requirements-template.md`, `checklist-template.md`)

- `requirements-template.md` sinh `checklists/requirements.md` bắt buộc ở `/speckit-specify`. Toàn bộ 16 mục `CHK001–CHK016` mặc định khởi tạo ở `- [ ] ... [Status: Chưa kiểm]` để chống thiên kiến AI tự kế thừa trạng thái `Pass` sẵn.
- Quy ước checkbox đồng nhất trên mọi checklist: `Pass`, `Không áp dụng` và `Fail (ngoại lệ đã phê duyệt)` dùng `[x]`; `Fail` chưa duyệt hoặc `Chưa kiểm` dùng `[ ]` và chặn gate `/speckit-implement`.
- Đường dẫn bước tiếp theo trong template phải phản ánh đúng thứ tự `/speckit-clarify` → `/speckit-docbiz` → `/speckit-plan`.

## Tasks Template (`tasks-template.md`) & Rules Reference

- Khung output nằm tại `.specify/templates/tasks-template.md`; toàn bộ quy tắc chi tiết (atomic sizing, ranh giới `Foundational`, xử lý xung đột file `[P]`, an toàn migration, multi-clause FR và anti-examples) nằm tại `.agents/skills/speckit-tasks/references/task-generation-rules.md`.
- Output cuối chỉ sinh phase cho User Story có thật trong `spec.md`, mọi task có ID tuần tự `T001+` kèm file path (và tên class/method nếu sửa file cũ) hoặc command cụ thể, có `Independent Test`, `Definition of Done`, và `Traceability Matrix` liệt kê Task ID thực tế.

## Constitution Template (`constitution-template.md`)

- Giữ cấu trúc chuẩn bộ luật kiểm chứng được (`Quy định`, `Lý do`, `Áp dụng cho`, `Cách kiểm tra`, `Ngoại lệ`), thứ tự ưu tiên Source of Truth (`constitution.md` > `spec.md` > `plan.md` > `tasks.md` > code), bảng Cổng chất lượng, Definition of Done và bảng Ngoại lệ có trạng thái.
