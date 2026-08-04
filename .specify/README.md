# `.specify/`

Thư mục runtime của Speckit cho `flex-workstation`. Đây là nơi các lệnh
`/speckit-*` (hoặc `$speckit-*` trong Codex) đọc cấu hình, nguyên tắc và
template khi sinh/kiểm tra artifact (`spec.md`, `plan.md`, `tasks.md`, ...).

Muốn hiểu **luồng làm việc** (bước nào chạy trước/sau, khi nào cần
`clarify`/`checklist`, sơ đồ mermaid đầy đủ) đọc
[`docs/speckit/workflow.md`](../docs/speckit/workflow.md) — đó là tài liệu
canonical, không phải thư mục này.

## Cấu trúc

| Đường dẫn | Nội dung |
|---|---|
| `memory/constitution.md` | Nguyên tắc cốt lõi, gate chất lượng, Definition of Done — nguồn ưu tiên cao nhất khi có mâu thuẫn giữa các artifact |
| `templates/` | Template runtime mà Speckit dùng để sinh `spec.md`, `plan.md`, `tasks.md`, `checklist`, `requirements.md`, `constitution.md` |
| `workflows/workflow-registry.json` | Registry lệnh Speckit đã cài; `speckit` trong đây là shortcut legacy, không phải workflow chuẩn |
| `feature.json` | Con trỏ tới feature đang active (khi làm song song nhiều feature, ưu tiên biến môi trường `SPECIFY_FEATURE_DIRECTORY` thay vì tin file này) |
| `extensions.yml`, `integration.json`, `init-options.json`, `integrations/` | Cấu hình cài đặt/hook của Speckit, không cần sửa tay trừ khi thêm hook mới |

## Không sửa ở đây nếu...

- Muốn đổi **luồng làm việc** hoặc thứ tự lệnh → sửa
  [`docs/speckit/workflow.md`](../docs/speckit/workflow.md).
- Muốn đổi **quy ước thiết kế template** (không phải nội dung template) →
  sửa [`docs/speckit/template-guidelines.md`](../docs/speckit/template-guidelines.md)
  trước, rồi mới sửa file trong `templates/`.
- Muốn ghi chú **bảo trì/quyết định vận hành** Speckit → sửa
  [`docs/speckit/maintenance.md`](../docs/speckit/maintenance.md).

Mọi thay đổi hành vi Speckit/template/runtime PHẢI cập nhật tài liệu tương
ứng trong `docs/speckit/` (xem `CLAUDE.md` gốc của workstation).
