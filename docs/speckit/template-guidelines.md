# Speckit Template Guidelines

Quy ước thiết kế và bảo trì template Speckit tiếng Việt cho `flex-workstation`.

Tài liệu này không phải template runtime và không được Speckit đọc trực tiếp. Runtime chỉ dùng các file trong `.specify/templates/`. Khi sửa template runtime, dùng tài liệu này làm checklist để giữ artifact sinh ra ổn định, có traceability và phù hợp tiếng Việt có dấu.

## Cách dùng

- Khi sửa `.specify/templates/spec-template.md`, rà section `Spec Template`.
- Khi sửa `.specify/templates/plan-template.md`, rà section `Plan Template`.
- Khi sửa `.specify/templates/tasks-template.md`, rà section `Tasks Template`.
- Khi sửa `.specify/templates/checklist-template.md`, rà section `Checklist Template`.
- Khi sửa `.specify/templates/requirements-template.md`, rà section `Requirements Template`.
- Khi sửa `.specify/templates/constitution-template.md`, rà section `Constitution Template`.
- Sau khi sửa template, chạy static validation theo feature/spec liên quan và kiểm tra artifact sinh ra không còn placeholder hoặc marker ví dụ ngoài chủ đích.

## Quy tắc chung

- Toàn bộ template Speckit trong `.specify/templates/` dùng tiếng Việt có dấu cho phần người dùng đọc và review.
- Giữ nguyên technical identifiers như command, file path, package, API, framework, Markdown syntax, placeholder, `[P]`, `[Story]`, `CHK###`, `[Gap]`, `[Spec §X]`, `[Ambiguity]`, `[Conflict]`, `[Assumption]`.

## Spec Template

- Spec template chỉ mô tả WHY/WHAT; HOW thuộc plan kỹ thuật. ID trong spec dùng ASCII để dễ search/copy: `MT`, `US`, `AC`, `FR`, `BR`, `SEC`, `NFR`, `SC`.
- Spec template cần có phạm vi MVP, mapping `US`/`AC` về `FR`, và trạng thái dữ liệu/lỗi phổ biến để tránh scope creep và giúp task/test traceable.
- Spec template cần có người phụ trách, stakeholder xác nhận, và quy tắc nghiệp vụ `BR` để làm rõ ai quyết định scope/rule. Hai trường metadata mặc định dùng `git config user.name`.
- Spec template cần tách phân quyền/bảo mật, audit/lịch sử thay đổi, và checklist sẵn sàng lập plan kỹ thuật để tránh chuyển sang `/plan` khi spec còn mơ hồ.
- Không xóa section tùy chọn trong spec template; ghi `Không áp dụng` để giữ cấu trúc ổn định cho AI/automation.
- `FR` cần có priority `[P1]`/`[P2]`/`[P3]` và trace ngược về `US`/`AC`; `Thực thể dữ liệu` đứng trước phân quyền/audit để làm rõ đối tượng nghiệp vụ trước khi xác định quyền.

## Plan Template

- Plan template phải nối spec với thiết kế kỹ thuật bằng traceability từ `US`/`FR` sang module/path, API/contract, data/entity và kiểm thử tương ứng.
- Plan template cần có phạm vi kỹ thuật, phân tích tác động, quyết định kỹ thuật, rollout/rollback, observability/debug và checklist sẵn sàng trước khi chạy `/speckit-tasks`.
- Plan template cần có tóm tắt đúng lifecycle, câu hỏi kỹ thuật cần research, thiết kế tổng quan, chiến lược kiểm thử, và dữ liệu/migration riêng cho feature có DB/data.
- Bối cảnh kỹ thuật trong plan template ưu tiên ví dụ gần hệ thống backend/enterprise: service/app liên quan, đơn vị deploy, nền tảng chạy, framework/package/internal SDK, storage và test stack thực tế.
- Rollback trong plan template cần tách rollback code/config với rollback dữ liệu/migration; observability phải ghi rõ dữ liệu không được log như token, secret, API key hoặc dữ liệu nhạy cảm.
- Constitution gate trong plan template cần dùng bảng có trạng thái ban đầu và trạng thái sau design để review được hai mốc kiểm tra.
- Plan template cần tách chi tiết `API/Contract Detail`, `Permission Matrix`, và đánh giá idempotency/concurrency/retry khi feature có API, quyền, hoặc xử lý lặp.
- `Dữ liệu & Migration` mô tả dữ liệu cần xử lý; `Rollout & Rollback` chỉ mô tả cách thực thi migration/backfill khi release để tránh ghi trùng.
- `Chiến lược kiểm thử` đứng trước `Cấu trúc project` để source/test path thật được quyết định sau khi đã rõ lớp test cần có.
- Với section không áp dụng trong plan template, ghi `Không áp dụng` thay vì xóa section để giữ cấu trúc ổn định cho AI/automation.

## Constitution Template

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

## Checklist Template

- Checklist template phải là quality gate có loại checklist, artifact chính được kiểm, nguồn tham chiếu, kết quả tổng hợp, severity `[Blocker]`/`[High]`/`[Medium]`/`[Low]`, tag chuẩn và kết luận chuyển bước.
- Checklist item phải kiểm một vấn đề cụ thể, trả lời được bằng Pass/Fail/Không áp dụng, và có format ghi fail gồm `Phát hiện`, `Ảnh hưởng`, `Đề xuất`, `Tham chiếu`.
- Checklist template cần có người review, trạng thái/lần review, số item `Không áp dụng`, rule kết luận `Pass`/`Pass có điều kiện`/`Fail`, owner/deadline cho item fail, tag `[Constitution]`/`[Readiness]`, evidence cho item quan trọng và bảng ngoại lệ được phê duyệt.
- Checklist template cần có `Checklist ID`, bước hiện tại/tiếp theo, artifact đã kiểm, status từng item `[Status: Pass/Fail/Không áp dụng/Chưa kiểm]`, quy tắc đánh dấu `Không áp dụng`, tag `[Data]`/`[Migration]`, và quy tắc mã `CHK###` duy nhất.

## Requirements Template

- Requirements template là quality gate bắt buộc do `$speckit-specify` sinh tại `checklists/requirements.md`; không dùng cho checklist domain tùy biến.
- Template cần có metadata review, artifact `spec.md`, kết quả tổng hợp, rule `Pass`/`Pass có điều kiện`/`Fail`, transition gate và bảng ngoại lệ được phê duyệt.
- Mỗi item phải có mã `CHK###`, severity, status, một tiêu chí kiểm chất lượng requirement và tham chiếu hoặc marker phù hợp; item Fail phải dùng format phát hiện, ảnh hưởng, đề xuất, tham chiếu, owner và hạn xử lý.
- `$speckit-specify` phải resolve template này; không fallback về Markdown hard-code nếu template không có.

## Tasks Template

- Tasks template phải giữ cấu trúc phase theo Spec Kit nhưng task sinh ra phải atomic, có ID tuần tự `T001`, có path/command cụ thể, có đầu ra kiểm chứng được và trace được về `US`/`FR`/`AC`/`BR`/`SEC`/`NFR` khi áp dụng.
- `[P]` trong tasks template chỉ nghĩa là parallelizable, không liên quan tới priority `P1`/`P2`/`P3`; không đánh dấu `[P]` cho task sửa cùng file hoặc phụ thuộc task khác.
- `/speckit-tasks` không được giữ task ví dụ, placeholder như `[Entity]`/`[endpoint]`/`[file]`, hoặc `TXXX` trong output cuối; task không có file path cụ thể là không hợp lệ trừ task validate/review có command rõ ràng.
- Tasks template cần có coverage requirements để đảm bảo mỗi user story, acceptance criteria quan trọng, requirement P1/P2, business rule, permission rule, entity, contract và constraint trong plan có task hoặc validation tương ứng.
- Với feature backend/enterprise, tasks template cần sinh task cho migration, permission, contract, observability, audit/logging, feature flag, rollout/rollback khi `plan.md` đánh dấu liên quan; không đẩy toàn bộ security/observability xuống Polish.
- Mỗi user story trong tasks template phải có `Independent Test` cụ thể, kể cả manual validation; không dùng placeholder chung chung như "kiểm tra hoạt động đúng".
- Foundational phase trong tasks template chỉ chứa task dùng chung cho ít nhất 2 user stories, điều kiện bắt buộc cho mọi story, schema/base infrastructure, hoặc contract/security foundation toàn feature; task story-specific phải nằm trong phase của story tương ứng.
- Tasks template cần có rule xử lý conflict file tổng hợp như endpoint/router/module: nếu nhiều stories cùng sửa một file, phải tách file theo use case hoặc ghi rõ integration/dependency task.
- Task có phụ thuộc rõ phải ghi dependency task ID; mỗi user story cần có `Definition of Done`, và output cuối nên có `Traceability Matrix` map `US`/`FR`/`AC`/`BR`/`SEC`/`NFR` sang task.
- Tasks template cần có rule riêng cho data/migration safety và API/event contract: không gộp migration schema với business handler, có backward compatibility/backfill/rollback note khi cần, và contract quan trọng có implementation/test task tương ứng.
- Không sinh test task hình thức; test task phải map với acceptance criteria, contract, business rule, permission rule hoặc regression risk cụ thể.
- Output cuối của `/speckit-tasks` chỉ sinh phase cho user story thật trong `spec.md`, không giữ placeholder, `TXXX`, `Phase N`, phase ví dụ hoặc tự tạo đủ `US1`/`US2`/`US3` khi spec không có.
- Nếu một user story không có automated test task, tasks output phải có manual validation task hoặc command validation task để dev có task verify cụ thể.
- `Traceability Matrix` trong tasks output phải dùng task ID thực tế, không dùng range nếu range chứa task không liên quan hoặc task optional đã bị bỏ.
- Task sửa file có sẵn phải nêu rõ class, method, section, endpoint group hoặc config key cần sửa; không viết chung chung kiểu "cập nhật file X".
