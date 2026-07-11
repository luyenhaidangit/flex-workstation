# Kế hoạch triển khai: Speckit Quick

**Branch**: `000006-speckit-quick` | **Ngày**: 2026-07-11 | **Đặc tả**: [spec.md](./spec.md)

**Đầu vào**: Đặc tả tính năng từ `specs/000006-speckit-quick/spec.md`

## Tóm tắt

**Yêu cầu chính từ spec**: Bổ sung entrypoint quick flow tên người dùng nhận biết là `/speckit.quick` để xử lý tác vụ nhỏ mà không cần tạo đủ bộ `spec.md`, `plan.md`, `tasks.md` cho từng thay đổi. Flow phải yêu cầu hoặc suy ra mục tiêu, phạm vi, đầu ra, tiêu chí kiểm tra; phải chặn tác vụ vượt phạm vi quick và hướng sang Speckit đầy đủ.

**Hướng tiếp cận kỹ thuật dự kiến**: Tạo skill mới `speckit-quick` trong `.agents/skills/` với frontmatter `name: "speckit-quick"` và guidance mô tả quick flow. Vì Codex skill name hiện dùng dấu gạch ngang, `/speckit.quick` được giữ như tên hiển thị trong hướng dẫn, còn runtime tương đương là `$speckit-quick` hoặc `/speckit-quick`. Cập nhật tài liệu workflow để người dùng thấy quick flow là lối tắt có điều kiện, không thay thế Speckit đầy đủ.

**Kết quả sau research**: Đã chọn triển khai bằng skill Markdown độc lập trong `.agents/skills/speckit-quick/SKILL.md`, không thêm script/runtime mới, không sửa project con, không tạo dữ liệu/migration. Hợp đồng hành vi được ghi trong `contracts/quick-flow-contract.md`.

## Phạm vi kỹ thuật

**Trong phạm vi**:
- Tạo `.agents/skills/speckit-quick/SKILL.md` làm entrypoint quick flow.
- Cập nhật `docs/speckit/workflow.md` để thêm nhánh quick flow, command table và điều kiện chuyển sang full Speckit.
- Cập nhật `AGENTS.md` và `CLAUDE.md` nếu cần để phản ánh command quick trong hướng dẫn runtime chung.
- Cập nhật `docs/speckit/maintenance.md` để ghi chú quy ước vận hành quick flow.

**Ngoài phạm vi kỹ thuật**:
- Không thay thế hoặc rút gọn workflow `speckit-specify`, `speckit-plan`, `speckit-tasks`, `speckit-implement`.
- Không sửa source code project con trong `flex-*`.
- Không thêm automation đăng ký command ngoài cấu trúc skill hiện có.
- Không thay đổi `.specify/templates/` trừ khi task implementation phát hiện tài liệu workflow bắt buộc cần đồng bộ.
- Không thêm database, API service, migration, permission engine hoặc release pipeline.

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: Markdown skill guidance, không có runtime language mới.

**Service/App liên quan**: `flex-workstation` AI tooling; module chính là `.agents/skills/` và `docs/speckit/`.

**Phụ thuộc chính**: Codex skill loader hiện có, conventions trong `.agents/skills/*/SKILL.md`, constitution `.specify/memory/constitution.md`.

**Lưu trữ**: File trong Git repository; không có DB.

**Kiểm thử**: Static review bằng `rg`, đọc Markdown, kiểm tra frontmatter và manual validation theo `quickstart.md`.

**Nền tảng chạy**: Agent runtime đọc skill Markdown trong workspace; không có service chạy nền.

**Đơn vị deploy**: Commit thay đổi workstation.

**Loại project**: Workspace tooling/documentation.

**Mục tiêu hiệu năng**: Người dùng/agent xác định quick eligibility trong dưới 2 phút khi context đủ rõ; người dùng đọc điều kiện quick trong dưới 5 phút.

**Ràng buộc**: Không ghi secret; không sửa project con nếu yêu cầu chỉ thuộc workstation; không tạo abstraction/script mới cho guidance một lần.

**Quy mô/Phạm vi**: Một skill mới, vài file tài liệu workstation, không ảnh hưởng runtime sản phẩm.

## Kiểm tra constitution

*GATE: Phải đạt trước Phase 0 research. Kiểm tra lại sau Phase 1 design.*

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| Scope Gate | Pass | Pass | Scope khớp MVP: skill quick + guidance + ví dụ/checklist; không mở rộng sang runtime automation. |
| Traceability Gate | Pass | Pass | P1/P2 có mapping sang skill, docs, contract và validation. |
| Test Gate | Pass | Pass | Dùng static/manual validation phù hợp vì thay đổi là Markdown guidance. |
| Security Gate | Pass | Pass | Không xử lý dữ liệu nhạy cảm; skill phải giữ rule không ghi secret. |
| Compatibility Gate | Pass | Pass | Không breaking change; command hiện có giữ nguyên, quick là entrypoint bổ sung. |
| Observability Gate | Pass | Pass | Không có telemetry runtime; audit ở mức báo cáo kết quả và Git diff. |
| Complexity Gate | Pass | Pass | Chọn skill Markdown độc lập, không thêm script/automation mới. |
| Release Gate | Không áp dụng | Không áp dụng | Không có deploy service, migration hoặc feature flag. |

## Câu hỏi kỹ thuật cần research

- **TQ-001**: Entry point `/speckit.quick` nên ánh xạ thế nào với naming convention skill hiện có?
- **TQ-002**: Quick flow nên nằm trong skill mới hay sửa skill Speckit hiện có?
- **TQ-003**: Có cần contract artifact dù không có API/service không?
- **TQ-004**: Cần cập nhật agent context bằng script nào sau Phase 1?

## Thiết kế tổng quan

**Luồng chính**:
1. Người dùng gọi `$speckit-quick`, `/speckit-quick` hoặc nhắc tên hiển thị `/speckit.quick` kèm mô tả tác vụ nhỏ.
2. Skill quick đọc yêu cầu, nêu giả định, phạm vi, file/khu vực liên quan và tiêu chí kiểm tra trước khi sửa.
3. Skill đánh giá eligibility bằng quick gate: mục tiêu rõ, phạm vi nhỏ, rủi ro thấp, kiểm tra được trong phiên, không đụng dữ liệu/quyền/contract/release/nhiều repo.
4. Nếu pass, agent thực hiện thay đổi phẫu thuật, chạy kiểm tra phù hợp và báo cáo file đã đổi, kiểm tra đã chạy hoặc lý do không chạy.
5. Nếu fail hoặc mô tả mơ hồ, agent dừng quick flow, hỏi làm rõ hoặc hướng sang `$speckit-specify`.

**Component/module tham gia**:
- `.agents/skills/speckit-quick/SKILL.md`: định nghĩa behavior contract, input/output, gates, checklist tối thiểu và ví dụ.
- `docs/speckit/workflow.md`: tài liệu người dùng về vị trí quick flow trong Speckit.
- `AGENTS.md`, `CLAUDE.md`: context runtime chung nếu cần thêm dòng command/guardrail.
- `docs/speckit/maintenance.md`: ghi chú maintenance cho quick flow.

**Điểm mở rộng/thay đổi chính**:
- Thêm skill mới thay vì chỉnh các skill core.
- Giữ `/speckit.quick` là tên hiển thị trong nội dung skill, đồng thời document alias thực thi phù hợp runtime.
- Định nghĩa output report bắt buộc cho quick flow.

**Luồng thay thế/lỗi chính**:
- Yêu cầu vượt phạm vi quick: dừng, nêu lý do, đề xuất `$speckit-specify <mô tả nghiệp vụ>`.
- Yêu cầu mơ hồ: hỏi tối đa vài câu cần thiết hoặc thu hẹp phạm vi trước khi sửa.
- Phát hiện file có thay đổi chưa rõ nguồn: làm việc với thay đổi hiện có hoặc hỏi lại nếu không thể tiếp tục an toàn.
- Không chạy được kiểm tra: báo rõ phần đã kiểm, phần chưa kiểm và rủi ro còn lại.

**Thay đổi boundary giữa service/module**:
- Không áp dụng. Chỉ thêm guidance trong workstation.

**Idempotency/Concurrency**:
- Quick flow phải đọc trạng thái hiện có trước khi sửa và tránh tạo trùng artifact hoặc lặp thay đổi.
- Nếu re-run cùng yêu cầu, agent phải báo đã có thay đổi tương ứng hoặc chỉ bổ sung phần còn thiếu.

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|------------|----------------------|---------------------|--------------|-------------|----------|
| US-001 / FR-001 | P1 | Đủ rõ | Tạo skill entrypoint `speckit-quick`; document tên hiển thị `/speckit.quick` và runtime alias. | `.agents/skills/speckit-quick/SKILL.md`, `docs/speckit/workflow.md` | `contracts/quick-flow-contract.md` | Quick Flow Command | Static frontmatter check, manual invocation review |
| US-001 / FR-002 | P1 | Đủ rõ | Skill bắt buộc nêu mục tiêu, phạm vi, đầu ra, tiêu chí kiểm tra trước khi sửa. | `.agents/skills/speckit-quick/SKILL.md` | Quick Intake | Quick Task | Manual validation scenario 1 |
| US-001 / FR-003 | P1 | Đủ rõ | Guidance cho phép xử lý task nhỏ không tạo đủ artifact Speckit riêng, nhưng vẫn giữ report trace tối thiểu. | `.agents/skills/speckit-quick/SKILL.md`, `docs/speckit/workflow.md` | Quick Eligibility | Quick Task | Manual validation scenario 1 |
| US-001 / FR-004 | P1 | Đủ rõ | Output report template nêu thay đổi, phạm vi, kiểm tra, phần chưa làm. | `.agents/skills/speckit-quick/SKILL.md` | Quick Result Report | Quick Task | Manual validation scenario 1 |
| US-002 / FR-005 | P1 | Đủ rõ | Quick Gate liệt kê điều kiện dừng: data, permission, contract, release, nhiều repo, nghiệp vụ chưa specify. | `.agents/skills/speckit-quick/SKILL.md` | Escalation Rule | Escalation Decision | Manual validation scenario 2 |
| US-002 / FR-006 | P1 | Đủ rõ | Escalation output bắt buộc đề xuất `$speckit-specify` trước implementation. | `.agents/skills/speckit-quick/SKILL.md`, `docs/speckit/workflow.md` | Escalation Report | Escalation Decision | Manual validation scenario 2 |
| US-003 / FR-007 | P2 | Đủ rõ | Thêm ví dụ hoàn chỉnh trong skill hoặc docs cho tác vụ tài liệu nhỏ trong workstation. | `.agents/skills/speckit-quick/SKILL.md`, `docs/speckit/workflow.md` | Quick Example | Quick Example | Manual review |
| US-003 / FR-008 | P2 | Đủ rõ | Ví dụ phải có input, quyết định phạm vi, hành động, kiểm tra, báo cáo. | `.agents/skills/speckit-quick/SKILL.md` | Quick Example | Quick Example | Manual review |
| SEC-001 / SEC-002 | P1 | Đủ rõ | Skill ghi rõ quick không được ghi credential/secret hoặc bỏ qua kiểm tra quyền/data/contract. | `.agents/skills/speckit-quick/SKILL.md` | Security Guardrail | Không áp dụng | Static search `secret`, `token`, `credential` guidance |
| NFR-001 / NFR-002 / NFR-003 | P1 | Đủ rõ | Tối ưu nội dung skill ngắn, checklist rõ, report bắt buộc. | `.agents/skills/speckit-quick/SKILL.md`, `docs/speckit/workflow.md` | Không áp dụng | Không áp dụng | Manual readability review |

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---------|------------------|--------------------------|---------------|
| Database/Migration | Không áp dụng | Không có dữ liệu/schema | Xác nhận không có migration/task DB |
| API/Contract | Không có API service; có behavior contract cho skill | Không breaking change vì command core giữ nguyên | Review `contracts/quick-flow-contract.md` |
| Permission/Security | Bổ sung guardrail không dùng quick để bỏ qua quyền/secret | Rủi ro nếu guidance thiếu điều kiện dừng | Static/manual review guardrail |
| Logging/Audit | Không thêm log runtime; báo cáo kết quả là audit tối thiểu | Rủi ro thiếu trace nếu report template mơ hồ | Review output template |
| UI/UX | Tác động tới trải nghiệm command/documentation | Rủi ro nhầm `/speckit.quick` với `/speckit-quick` | Quickstart kiểm alias wording |
| Job/Worker/Integration | Không áp dụng | Không có retry/timeout integration | Xác nhận không tạo script/service mới |

## API/Contract Detail

**Có thay đổi contract không**: Có, ở mức behavior contract của skill/command guidance; không có network API.

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|----------|------|----------|---------------------|------------------------|
| Quick Flow Command | Skill command behavior | Thêm entrypoint quick với input/output/gate rõ | Có | Người dùng workspace, Codex/Claude agent runtime |
| Escalation Report | Skill output | Chuẩn hóa báo cáo khi tác vụ vượt quick | Có | Người dùng workspace |

## Permission Matrix

| Vai trò/Scope | Xem | Tạo | Sửa | Xóa | Duyệt/Xử lý | Ghi chú |
|---------------|-----|-----|-----|-----|-------------|---------|
| Người dùng/agent có quyền sửa workstation | Có | Có | Có | Không mặc định | Có | Chỉ trong phạm vi workstation và file được yêu cầu. |
| Người dùng/agent không có quyền sửa workspace | Có | Không | Không | Không | Không | Quick flow phải dừng nếu không có quyền. |
| Project con `flex-*` | Có nếu cần đọc context | Không | Không | Không | Không | Chỉ sửa khi user nêu rõ project con là phạm vi. |

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Không áp dụng.

**Migration**:
- Không áp dụng vì không có DB/schema.

**Backfill/Cleanup**:
- Không áp dụng.

**Tương thích dữ liệu cũ**:
- Không áp dụng.

**Rủi ro dữ liệu**:
- Không áp dụng; guardrail vẫn cấm quick flow đụng dữ liệu/migration ngoài spec đầy đủ.

**Cách xác minh**:
- Static review đảm bảo plan/tasks không sinh migration hoặc data manipulation.

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| DEC-001 | Tạo `.agents/skills/speckit-quick/SKILL.md` | Khớp source-of-truth skill hiện có, ít rủi ro, dễ gọi bằng Codex skill | Sửa trực tiếp skill core hiện có | Làm tăng rủi ro regression cho workflow đầy đủ |
| DEC-002 | Dùng `speckit-quick` làm tên runtime, `/speckit.quick` làm tên hiển thị | Skill naming hiện dùng dấu gạch ngang; vẫn đáp ứng yêu cầu nhận biết `/speckit.quick` | Tạo folder/skill name có dấu chấm | Có thể không tương thích loader hoặc convention hiện có |
| DEC-003 | Contract Markdown thay vì OpenAPI | Đây là behavior contract cho skill, không phải HTTP API | OpenAPI/JSON schema | Không phù hợp vì không có endpoint/payload service |
| DEC-004 | Manual/static validation | Thay đổi là Markdown guidance, không có code thực thi | Unit/integration test framework mới | Tạo tooling không cần thiết cho scope nhỏ |
| DEC-005 | Không chạy script update agent context | Workspace không có `update-agent-context.ps1`; context agent được cập nhật qua file docs/AGENTS nếu cần | Tạo script mới | Ngoài phạm vi và không cần cho feature này |

## Chiến lược kiểm thử

**Unit test**:
- Không áp dụng vì không có code executable.

**Integration test**:
- Không áp dụng vì không có service/runtime integration mới.

**Contract test**:
- Manual/static check contract: skill có đủ intake, quick gate, escalation, result report và ví dụ theo `contracts/quick-flow-contract.md`.

**Permission/security test**:
- Static review skill để xác nhận có rule không ghi secret/credential và không bypass permission/data/contract.

**E2E/manual test**:
- Theo `quickstart.md`: một request quick hợp lệ phải tạo được pre-change scope + result report; một request vượt phạm vi phải bị từ chối và hướng sang `$speckit-specify`.

**Regression test**:
- `rg` xác nhận command core hiện có vẫn được document; không xóa các bước Speckit đầy đủ.

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/000006-speckit-quick/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── quick-flow-contract.md
└── checklists/
    └── requirements.md
```

### Source code (repository root)

```text
.agents/
└── skills/
    └── speckit-quick/
        └── SKILL.md

docs/
├── speckit/
│   └── workflow.md
└── tasks.md

AGENTS.md
CLAUDE.md
```

**Quyết định cấu trúc**: Dùng `.agents/skills/` vì đây là source skill thực tế trong workspace hiện tại. Không tạo thư mục `skills/` root mới trong feature này.

## Rollout & Rollback

**Kế hoạch rollout**: Commit thay đổi Markdown trong workstation; không cần deploy service.

**Tương thích ngược**: Các command Speckit hiện có giữ nguyên. Quick flow chỉ bổ sung entrypoint mới.

**Feature flag/config**: Không áp dụng.

**Thực thi migration/backfill khi rollout**:
- Không áp dụng.

**Rollback code/config**:
- Revert commit chứa `.agents/skills/speckit-quick/` và cập nhật docs liên quan.

**Rollback dữ liệu/migration**:
- Không áp dụng.

**Điều kiện kích hoạt rollback**:
- Skill quick gây nhầm lẫn nghiêm trọng với workflow đầy đủ hoặc runtime không nhận diện skill mới.

## Observability & Debug

**Log cần có**:
- Không áp dụng cho runtime; quick result report phải nêu `scope`, `files changed`, `checks run`, `not done/risk`.

**Dữ liệu không được log**:
- Token, secret, API key, password, connection string, credential và dữ liệu nhạy cảm.

**Metric cần theo dõi**:
- Không áp dụng trong runtime. Có thể đánh giá thủ công qua feedback/task review.

**Trace/Correlation**:
- Không áp dụng. Trace tối thiểu là Git diff và final report của agent.

**Cách kiểm tra sau release**:
- `rg -n "speckit-quick|speckit.quick|Quick flow" .agents/skills docs AGENTS.md CLAUDE.md`
- Manual dry-run theo `quickstart.md`.

**Tình huống debug chính**:
- Runtime không hiện skill: kiểm frontmatter `name`, folder `.agents/skills/speckit-quick/`.
- Người dùng nhầm quick với full Speckit: kiểm docs và escalation section.
- Agent xử lý task quá lớn bằng quick: kiểm Quick Gate và Escalation Rule.

## Theo dõi độ phức tạp

Không có vi phạm constitution cần biện minh.

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật chặn thiết kế/task generation đã được resolve trong research hoặc ghi rủi ro rõ ràng.
- [x] Thiết kế tổng quan đã mô tả luồng chính, component/module tham gia, điểm thay đổi và boundary nếu có.
- [x] Các tình huống idempotency/concurrency/retry đã được đánh giá hoặc ghi `Không áp dụng`.
- [x] Mỗi `US`/`FR` P1/P2 hoặc FR ảnh hưởng code/data/API/permission có mapping sang module/path, API/contract, data/entity và kiểm thử.
- [x] Tác động tới database, API contract, permission, logging/audit và integration đã được đánh giá hoặc ghi `Không áp dụng`.
- [x] Các contract/API/event thay đổi đã có consumer bị ảnh hưởng và cách kiểm tra compatibility.
- [x] Dữ liệu/migration/backfill/compatibility đã rõ hoặc ghi `Không áp dụng`.
- [x] Quyết định kỹ thuật chính đã có lý do chọn và phương án bị loại.
- [x] Chiến lược kiểm thử đã bao phủ unit, integration, contract, permission/security, E2E/manual và regression khi liên quan.
- [x] Rollout, rollback code/config, rollback dữ liệu/migration, feature flag/config và backward compatibility đã rõ hoặc ghi `Không áp dụng`.
- [x] Observability/debug plan có log field, dữ liệu không được log, metric/trace và cách kiểm tra sau release.
- [x] Không còn cây thư mục mẫu/generic; toàn bộ path trong cấu trúc source code là path thật trong repository.
- [x] Constitution gate không còn blocker trước khi chuyển sang `/speckit-tasks`.
