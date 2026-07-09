# Ghi chú task workspace

## Speckit templates tiếng Việt

- Toàn bộ template Speckit trong `.specify/templates/` dùng tiếng Việt có dấu cho phần người dùng đọc và review.
- Giữ nguyên technical identifiers như command, file path, package, API, framework, Markdown syntax, placeholder, `[P]`, `[Story]`, `CHK###`, `[Gap]`, `[Spec §X]`, `[Ambiguity]`, `[Conflict]`, `[Assumption]`.
- Spec template chỉ mô tả WHY/WHAT; HOW thuộc plan kỹ thuật. ID trong spec dùng ASCII để dễ search/copy: `MT`, `US`, `AC`, `FR`, `BR`, `SEC`, `NFR`, `SC`.
- Spec template cần có phạm vi MVP, mapping `US`/`AC` về `FR`, và trạng thái dữ liệu/lỗi phổ biến để tránh scope creep và giúp task/test traceable.
- Spec template cần có người phụ trách, stakeholder xác nhận, và quy tắc nghiệp vụ `BR` để làm rõ ai quyết định scope/rule.
- Spec template cần tách phân quyền/bảo mật, audit/lịch sử thay đổi, và checklist sẵn sàng lập plan kỹ thuật để tránh chuyển sang `/plan` khi spec còn mơ hồ.
- Không xóa section tùy chọn trong spec template; ghi `Không áp dụng` để giữ cấu trúc ổn định cho AI/automation.
- `FR` cần có priority `[P1]`/`[P2]`/`[P3]` và trace ngược về `US`/`AC`; `Thực thể dữ liệu` đứng trước phân quyền/audit để làm rõ đối tượng nghiệp vụ trước khi xác định quyền.
- Plan template phải nối spec với thiết kế kỹ thuật bằng traceability từ `US`/`FR` sang module/path, API/contract, data/entity và kiểm thử tương ứng.
- Plan template cần có phạm vi kỹ thuật, phân tích tác động, quyết định kỹ thuật, rollout/rollback, observability/debug và checklist sẵn sàng trước khi chạy `/speckit-tasks`.
- Plan template cần có tóm tắt đúng lifecycle, câu hỏi kỹ thuật cần research, thiết kế tổng quan, chiến lược kiểm thử, và dữ liệu/migration riêng cho feature có DB/data.
- Bối cảnh kỹ thuật trong plan template ưu tiên ví dụ gần hệ thống backend/enterprise: service/app liên quan, đơn vị deploy, nền tảng chạy, framework/package/internal SDK, storage và test stack thực tế.
- Rollback trong plan template cần tách rollback code/config với rollback dữ liệu/migration; observability phải ghi rõ dữ liệu không được log như token, secret, API key hoặc dữ liệu nhạy cảm.
- Constitution gate trong plan template cần dùng bảng có trạng thái ban đầu và trạng thái sau design để review được hai mốc kiểm tra.
- Plan template cần tách chi tiết `API/Contract Detail`, `Permission Matrix`, và đánh giá idempotency/concurrency/retry khi feature có API, quyền, hoặc xử lý lặp.
- `Dữ liệu & Migration` mô tả dữ liệu cần xử lý; `Rollout & Rollback` chỉ mô tả cách thực thi migration/backfill khi release để tránh ghi trùng.
- `Chiến lược kiểm thử` đứng trước `Cấu trúc project` để source/test path thật được quyết định sau khi đã rõ lớp test cần có.
- Constitution template phải là bộ luật kiểm được, không chỉ là tuyên ngôn: mỗi principle cần có `Quy định`, `Lý do`, `Áp dụng cho`, `Cách kiểm tra`, `Ngoại lệ`.
- Constitution template cần định nghĩa phạm vi áp dụng, keyword `PHẢI`/`KHÔNG ĐƯỢC`/`NÊN`/`CÓ THỂ`, cổng chất lượng, ngoại lệ/biện minh độ phức tạp, quản trị và lịch sử thay đổi.
- Cổng chất lượng trong constitution phải map được sang `spec.md`, `plan.md`, `tasks.md`, review và release: scope, traceability, test, security, compatibility, observability và complexity.
- Constitution template cần có Source of Truth: `constitution.md` > `spec.md` > `plan.md` > `tasks.md` > code implementation.
- Không sinh `tasks.md` khi còn câu hỏi `CẦN LÀM RÕ` chặn phạm vi, thiết kế, dữ liệu, permission, contract hoặc rollout; nếu đi tiếp phải ghi rủi ro và người phê duyệt trong `plan.md`.
- Task trong `tasks.md` phải có đầu ra kiểm tra được, tránh task mơ hồ như "cập nhật logic" hoặc "tối ưu code" nếu không nêu module, hành vi và tiêu chí hoàn thành.
- Constitution template cần có checklist review tối thiểu và Release Gate để kiểm rollout, rollback, migration/backfill, observability và smoke test trước release.
- Traceability trong constitution phải bao phủ `US`/`FR`/`BR`/`SEC`/`NFR` quan trọng, không chỉ `US`/`FR`.
- Constitution template cần định nghĩa rõ câu hỏi `CẦN LÀM RÕ` chặn là câu hỏi có thể làm đổi MVP, luồng P1/P2, data/migration, API/contract, permission, rollout/rollback hoặc test strategy chính.
- Constitution template cần có tiêu chuẩn cho `research.md`, `contracts/`, `data-model.md`, `Definition of Done`, và format ngoại lệ có trạng thái.
- Checklist template phải là quality gate có loại checklist, artifact chính được kiểm, nguồn tham chiếu, kết quả tổng hợp, severity `[Blocker]`/`[High]`/`[Medium]`/`[Low]`, tag chuẩn và kết luận chuyển bước.
- Checklist item phải kiểm một vấn đề cụ thể, trả lời được bằng Pass/Fail/Không áp dụng, và có format ghi fail gồm `Phát hiện`, `Ảnh hưởng`, `Đề xuất`, `Tham chiếu`.
- Với section không áp dụng trong plan template, ghi `Không áp dụng` thay vì xóa section để giữ cấu trúc ổn định cho AI/automation.
- Không sửa trực tiếp skill gốc trong `.agents/skills/**` chỉ để đổi ngôn ngữ artifact. Nếu cần custom output, ưu tiên template workspace và tài liệu workflow.
- Khi validate thay đổi template, chạy static search trên toàn bộ `.specify/templates` và xác nhận `git diff -- .agents/skills` không có thay đổi.
