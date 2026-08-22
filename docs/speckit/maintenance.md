# Speckit Maintenance

Ghi chú bảo trì Speckit, runtime guidance và constitution cho `flex-workstation`.

## Constitution

- Constitution hiện ở version `1.3.0`, bổ sung Specialist Skill Gate: Speckit luôn route qua `flex-using-agent-skills` và chỉ áp dụng các skill Flex phù hợp với artifact thực tế.
- Tài liệu workflow Speckit phải nêu rõ hai dạng command: `$speckit-*` cho Codex và `/speckit-*` cho Antigravity IDE/CLI cùng Claude Code. Ba runtime dùng chung source `.agents/skills/`; không thêm workflow tự chạy toàn bộ Speckit.

## Quy ước bảo trì

- Khi thay đổi hành vi Speckit, template Speckit hoặc runtime guidance, cập nhật tài liệu tương ứng trong `docs/speckit/`.
- Khi thay đổi onboarding hoặc cấu trúc workspace, cập nhật `docs/setup/onboarding.md` hoặc `docs/architecture/system-map.md`.
- Khi thay đổi quy tắc hành vi chung trong `CLAUDE.md`, rà lại `AGENTS.md` để Codex nhận cùng tiêu chuẩn ở dạng phù hợp với Codex.
- Khi sửa prompt hoặc skill, giữ diff tối thiểu, không lặp/mâu thuẫn và kiểm tra trực tiếp phần đã sửa.
- `$speckit-specify` phải dò thư mục cùng short-name trước khi dispatch `before_specify` hook hoặc tạo feature; khi có kết quả trùng, phải dừng để người dùng chọn cập nhật spec hiện có hoặc tạo feature mới. Update mode giữ `requirements.md` hiện có và chỉ re-validate status/tổng hợp, không copy đè lịch sử review hay ngoại lệ.
- `$speckit-tasks` phải tuân theo Test Gate trong constitution: sinh test task cho rủi ro cần xác minh trong `plan.md`, hoặc manual/command validation kèm lý do không áp dụng automated test; không được coi test là tùy chọn chỉ vì không có yêu cầu riêng.
- `speckit-docbiz` là Documentation Impact Gate bắt buộc sau lần cập nhật cuối của `spec.md` và trước `speckit-plan`. Skill phải đánh giá tác động trước: chỉ cập nhật section của tài liệu hiện hữu khi thay đổi nghiệp vụ là đáng kể; chỉ tạo tài liệu mới khi không có tài liệu phù hợp, đồng thời cập nhật `docs/business/business-docs-index.md`. Không dùng hook tự chạy và không gắn sau `speckit-converge` vì converge chỉ append `tasks.md`.
- `$speckit-plan` và `$speckit-implement` phải gọi `flex-using-agent-skills` một lần sau khi technical context hoặc artifact scope đã rõ; giữ Speckit là lifecycle owner và chỉ lấy specialist skill bổ sung, không route đệ quy cùng command.
- `$speckit-converge` chỉ xác nhận coverage với spec/plan/tasks. Khi converged, feature vẫn phải đi qua một final specialist review được route bằng `flex-using-agent-skills` trước khi được xem là hoàn thành hoặc sẵn sàng PR.
- `$speckit-analyze` và `$speckit-converge` phải inventory `MT`/`US`/`AC`/`FR`/`BR`/`SEC`/`NFR`/`SC`; `BR`/`SEC`/`NFR` có work phải có implementation, test hoặc validation coverage theo Traceability Gate.
- Các command Speckit có feature scope phải mở đầu Completion Report bằng `ACTIVE_FEATURE_DIRECTORY`; khi làm song song, dùng `SPECIFY_FEATURE_DIRECTORY` trong từng PowerShell session thay vì tin vào `.specify/feature.json` là con trỏ duy nhất.
- `$speckit-taskstoissues` ưu tiên GitHub MCP; khi MCP không có, dùng `gh issue list/create` với `--repo` lấy từ `origin`. Nếu không xác thực hoặc không deduplicate được issue hiện có, phải dừng trước khi tạo issue. Mỗi issue mới phải có mô tả task, trace `[US#]`, link/path đến `spec.md`/`plan.md`/`tasks.md`, và label `feature:<feature-dir>` để tự đứng được trên GitHub.
- Không sửa trực tiếp skill gốc trong `.agents/skills/**` chỉ để đổi ngôn ngữ artifact. Nếu cần custom output, ưu tiên template workspace và tài liệu workflow.
- Khi validate thay đổi template, chạy static search trên toàn bộ `.specify/templates` và rà `git diff -- .agents/skills`.
- Khi upgrade Spec Kit, không nhận tự động file upstream mà manifest đang theo dõi. Diff từng file trong `.specify/integrations/agy.manifest.json`, `.specify/integrations/claude.manifest.json` và `.specify/integrations/speckit.manifest.json` với custom source hiện hành; chỉ merge thay đổi được review, rồi cập nhật manifest/hash theo cơ chế chính thức của tool. `claude.manifest.json` được giữ cho audit; `agy.manifest.json` là integration mặc định. Các skill `.agents/skills/` và template/script tùy biến phải được bảo toàn qua `scripts/migrate-speckit-antigravity.ps1`.

## Requirements Quality Gate

- `checklists/requirements.md` là quality gate bắt buộc của `$speckit-specify` và phải được sinh từ `.specify/templates/requirements-template.md`.
- Trong `checklists/requirements.md`, `Status: Pass`, `Status: Không áp dụng` và `Status: Fail (ngoại lệ đã phê duyệt)` dùng checkbox `[x]`; chỉ `Status: Fail` chưa được phê duyệt dùng `[ ]` và chặn gate `$speckit-implement`. Ngoại lệ đã phê duyệt phải giữ fail evidence, owner, hạn xử lý và người phê duyệt/hạn xem lại.
- `$speckit-checklist` tiếp tục dùng `.specify/templates/checklist-template.md` để tạo checklist tùy biến theo domain; không thay thế hoặc ghi đè requirements quality gate.
