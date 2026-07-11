# Research: Speckit Quick

## DEC-001: Tạo skill mới thay vì sửa skill core

**Decision**: Tạo `.agents/skills/speckit-quick/SKILL.md`.

**Rationale**: Quick flow là entrypoint bổ sung với hành vi khác workflow core. Skill mới giữ thay đổi nhỏ, tách biệt, dễ review và không làm tăng rủi ro regression cho `speckit-specify`, `speckit-plan`, `speckit-tasks` hoặc `speckit-implement`.

**Alternatives considered**:
- Sửa `speckit-implement` để nhận mode quick: loại vì làm mờ boundary giữa quick task và implementation task đầy đủ.
- Sửa `speckit-specify` để tạo spec tối giản: loại vì spec yêu cầu quick không bắt buộc tạo đủ artifact cho từng thay đổi nhỏ.

**Rủi ro còn lại**: Người dùng có thể không biết skill mới nếu tài liệu workflow không cập nhật rõ.

## DEC-002: Ánh xạ `/speckit.quick` sang runtime alias có dấu gạch ngang

**Decision**: Dùng `speckit-quick` làm tên skill/runtime; trong skill và docs ghi `/speckit.quick` là tên hiển thị/người dùng nhận biết, với alias thực thi `$speckit-quick` hoặc `/speckit-quick`.

**Rationale**: Các skill hiện có trong `.agents/skills/` dùng naming dạng `speckit-*`. Dấu chấm trong tên command có thể không được mọi runtime hỗ trợ. Cách này giữ compatibility mà vẫn đáp ứng requirement người dùng nhận biết `/speckit.quick`.

**Alternatives considered**:
- Đặt folder `speckit.quick`: loại vì lệch convention và có rủi ro loader/command không nhận.
- Chỉ dùng `/speckit.quick`: loại vì không chắc runtime hiện hành hỗ trợ dấu chấm.

**Rủi ro còn lại**: Cần diễn đạt rõ để tránh người dùng nghĩ có hai flow khác nhau.

## DEC-003: Dùng behavior contract Markdown

**Decision**: Tạo `contracts/quick-flow-contract.md` để định nghĩa input, pre-change statement, quick gate, escalation output và completion report.

**Rationale**: Feature không có HTTP API/event/schema. Contract đúng nhất là hành vi observable của command/skill để tasks và review kiểm được.

**Alternatives considered**:
- Không tạo contracts: loại vì spec yêu cầu entrypoint và report có hành vi công khai với user/agent.
- OpenAPI/JSON Schema: loại vì không có service endpoint.

**Rủi ro còn lại**: Contract test sẽ là static/manual review thay vì automated test.

## DEC-004: Validation bằng static search và manual dry-run

**Decision**: Dùng `rg`, đọc frontmatter, review contract và dry-run theo `quickstart.md`.

**Rationale**: Thay đổi là Markdown guidance. Thêm test framework hoặc script mới sẽ vượt phạm vi và tăng complexity không cần thiết.

**Alternatives considered**:
- Viết script parse Markdown/frontmatter: loại vì scope nhỏ và không có parser hiện hành trong repo.
- Dùng automated e2e agent invocation: loại vì runtime invocation không ổn định trong repository test.

**Rủi ro còn lại**: Manual validation phụ thuộc reviewer; quickstart phải ghi expected outcome cụ thể.

## DEC-005: Không cập nhật agent context bằng script

**Decision**: Không chạy script update agent context vì `.specify/scripts/powershell/` không có script tương ứng. Nếu cần context runtime, cập nhật trực tiếp `AGENTS.md`/`CLAUDE.md` trong implementation tasks.

**Rationale**: Skill plan yêu cầu chạy agent script nếu có. Workspace hiện chỉ có `check-prerequisites.ps1`, `common.ps1`, `create-new-feature.ps1`, `setup-plan.ps1`, `setup-tasks.ps1`; không có update-agent-context script.

**Alternatives considered**:
- Tạo script update context mới: loại vì ngoài phạm vi và không cần để hoàn thành feature.

**Rủi ro còn lại**: Nếu runtime ngoài Codex cần registry riêng, sẽ phát hiện ở implementation/validation.
