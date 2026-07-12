# Speckit Maintenance

Ghi chú bảo trì Speckit, runtime guidance và constitution cho `flex-workstation`.

## Constitution

- Constitution hiện ở version `1.2.0`, mở rộng theo template Speckit hiện hành với Source of Truth, cổng chất lượng, Definition of Done, ngoại lệ và lịch sử thay đổi.
- Tài liệu workflow Speckit phải nêu rõ hai dạng command: `$speckit-*` cho Codex skill invocation và `/speckit-*` cho slash command khi runtime hỗ trợ.

## Quy ước bảo trì

- Khi thay đổi hành vi Speckit, template Speckit hoặc runtime guidance, cập nhật tài liệu tương ứng trong `docs/speckit/`.
- Khi thay đổi onboarding hoặc cấu trúc workspace, cập nhật `docs/setup/onboarding.md` hoặc `docs/architecture/system-map.md`.
- Khi thay đổi quy tắc hành vi chung trong `CLAUDE.md`, rà lại `AGENTS.md` để Codex nhận cùng tiêu chuẩn ở dạng phù hợp với Codex.
- Khi sửa prompt hoặc skill, giữ diff tối thiểu, không lặp/mâu thuẫn và kiểm tra trực tiếp phần đã sửa.
- Không sửa trực tiếp skill gốc trong `.agents/skills/**` chỉ để đổi ngôn ngữ artifact. Nếu cần custom output, ưu tiên template workspace và tài liệu workflow.
- Khi validate thay đổi template, chạy static search trên toàn bộ `.specify/templates` và rà `git diff -- .agents/skills`.

## Requirements Quality Gate

- `checklists/requirements.md` là quality gate bắt buộc của `$speckit-specify` và phải được sinh từ `.specify/templates/requirements-template.md`.
- `$speckit-checklist` tiếp tục dùng `.specify/templates/checklist-template.md` để tạo checklist tùy biến theo domain; không thay thế hoặc ghi đè requirements quality gate.

## Quick Flow

- `$speckit-quick` là quick flow cho tác vụ nhỏ, rủi ro thấp trong workstation.
- `/speckit.quick` là tên hiển thị; runtime dùng `$speckit-quick` hoặc `/speckit-quick` tùy agent.
- Quick flow phải nêu pre-change statement trước khi sửa và completion report sau khi hoàn tất.
- Quick flow không dùng cho thay đổi data, permission, contract, migration, release, public API hoặc nhiều repo.
- Nếu task vượt quick gate, dừng quick flow và hướng người dùng sang `$speckit-specify <mô tả nghiệp vụ>` trước khi implementation.
