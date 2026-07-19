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
- `$speckit-specify` phải dò thư mục cùng short-name trước khi tạo feature; khi có kết quả trùng, phải dừng để người dùng chọn cập nhật spec hiện có hoặc tạo feature mới.
- `$speckit-tasks` phải tuân theo Test Gate trong constitution: sinh test task cho rủi ro cần xác minh trong `plan.md`, hoặc manual/command validation kèm lý do không áp dụng automated test; không được coi test là tùy chọn chỉ vì không có yêu cầu riêng.
- `speckit-docbiz` là optional hook sau `speckit-specify` và `speckit-clarify` để đồng bộ tài liệu BA khi `spec.md` thay đổi. Không gắn sau `speckit-converge` vì converge chỉ append `tasks.md`.
- `$speckit-analyze` và `$speckit-converge` phải inventory `MT`/`US`/`AC`/`FR`/`BR`/`SEC`/`NFR`/`SC`; `BR`/`SEC`/`NFR` có work phải có implementation, test hoặc validation coverage theo Traceability Gate.
- Các command Speckit có feature scope phải mở đầu Completion Report bằng `ACTIVE_FEATURE_DIRECTORY`; khi làm song song, dùng `SPECIFY_FEATURE_DIRECTORY` trong từng PowerShell session thay vì tin vào `.specify/feature.json` là con trỏ duy nhất.
- Không sửa trực tiếp skill gốc trong `.agents/skills/**` chỉ để đổi ngôn ngữ artifact. Nếu cần custom output, ưu tiên template workspace và tài liệu workflow.
- Khi validate thay đổi template, chạy static search trên toàn bộ `.specify/templates` và rà `git diff -- .agents/skills`.

## Requirements Quality Gate

- `checklists/requirements.md` là quality gate bắt buộc của `$speckit-specify` và phải được sinh từ `.specify/templates/requirements-template.md`.
- Trong `checklists/requirements.md`, `Status: Pass` và `Status: Không áp dụng` dùng checkbox `[x]`; chỉ `Status: Fail` dùng `[ ]` và chặn gate `$speckit-implement`.
- `$speckit-checklist` tiếp tục dùng `.specify/templates/checklist-template.md` để tạo checklist tùy biến theo domain; không thay thế hoặc ghi đè requirements quality gate.
