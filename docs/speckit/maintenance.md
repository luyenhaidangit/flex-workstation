# Speckit Maintenance

Ghi chú bảo trì Speckit, runtime guidance, CLI kiểm tra tĩnh và constitution cho `flex-workstation`.

## Constitution & Kiến trúc hiện hành

- Constitution hiện ở version `1.4.0`: hỗ trợ phân tầng `Light Track` / `Compact Spec Track` / `Full Spec Track`, Specialist Skill Gate hai pha qua `flex-using-agent-skills`, kiểm tra tĩnh đa nền tảng qua `scripts/speckit-cli.js`, và quy trình Closeout khép kín ngay trong nhánh `converged` của `speckit-converge`.
- Ba runtime (Codex `$speckit-*`, Antigravity `/speckit-*`, Claude Code `/speckit-*`) dùng chung source `.agents/skills/`.
- `speckit-specify` bật model-invocation (không đặt `disable-model-invocation: true`) để nhận yêu cầu tạo feature bằng ngôn ngữ tự nhiên; 10 skill `speckit-*` còn lại giữ `disable-model-invocation: true` để khóa cứng cơ chế user-gated giữa các bước.

## Quy ước bảo trì

- Khi thay đổi hành vi Speckit, template hoặc runtime guidance, đồng bộ `docs/speckit/` và chạy cả 2 lệnh kiểm tra cơ học:
  - `node scripts/validate-skills.js` (kiểm tra frontmatter, routing table, độ dài dòng, `HARD STOP` và `ACTIVE_FEATURE_DIRECTORY` cho cả `flex-*` lẫn `speckit-*`).
  - `powershell -NoProfile -File scripts/test-antigravity-runtime.ps1` (hoặc `pwsh` nếu có).
- Mọi thao tác giải quyết đường dẫn feature, khởi tạo spec (`setup-specify`), đọc `.specify/extensions.yml` (`HOOKS`), kiểm tra điều kiện tiên quyết (`check-prereqs`, `setup-plan`, `setup-tasks`) và kiểm tra tĩnh (`validate`) ưu tiên gọi `node scripts/speckit-cli.js` (thuần Node stdlib, chạy giống hệt nhau trên Windows local và Linux Cloud container `CLAUDE_CODE_REMOTE=true`).
- Các file `.specify/scripts/powershell/*.ps1` vẫn được giữ lại cho mục đích tương thích ngược với Spec Kit upstream / script bootstrap Windows; các skill `speckit-*` không gọi trực tiếp các script PowerShell này.
- Không để biến môi trường `SPECIFY_FEATURE_DIRECTORY` ghi đè ngược vào `.specify/feature.json`; khi cần ghim cục bộ cho từng máy/phiên, dùng `.specify/feature.local.json` (đã gitignore, qua cờ `--pin`).
- Giữ `.specify/templates/*.md` tinh gọn (chỉ chứa khung output và comment nhắc ngắn); quy tắc hướng dẫn dài và ví dụ mẫu cho AI phải đặt trong thư mục `references/` của skill tương ứng (như `.agents/skills/speckit-tasks/references/task-generation-rules.md` và `.agents/skills/speckit-checklist/references/domain-examples.md`).
- Trong `requirements-template.md`, giữ mặc định `- [ ] ... [Status: Chưa kiểm]` để `speckit-cli.js validate --stage specify` phát hiện được trường hợp AI bỏ sót không chấm từng mục `CHK###`.
- `speckit-implement` chỉ đặt `Trạng thái: Đang triển khai`; việc chuyển sang `Trạng thái: Hoàn thành` và ghi `Ngày reconcile cuối` thuộc độc quyền nhánh `converged` của `speckit-converge` sau khi đã pass Final Specialist Review và `speckit-cli.js validate --stage converge --verify-closed`.
- Không sửa nát nội dung tiếng Anh của các skill gốc trong `.agents/skills/speckit-*` chỉ để dịch câu chữ sang tiếng Việt; quy tắc xuất bảng báo cáo/câu hỏi tiếng Việt được điều phối tập trung từ `AGENTS.md`.
- Khi upgrade `specify-cli` / Spec Kit upstream: không nhận tự động file đè lên `.agents/skills/` hoặc `.specify/templates/`. Diff thủ công với `.specify/integrations/claude.manifest.json` và `.specify/integrations/speckit.manifest.json` (xem `scripts/migrate-speckit-antigravity.ps1` cho danh sách `$protectedPaths` cần bảo toàn — bổ sung giữ `scripts/speckit-cli.js`, `scripts/validate-speckit-artifact.js`, `.agents/skills/speckit-tasks/references/` và `.agents/skills/speckit-checklist/references/`).
