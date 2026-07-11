# Quickstart: Validate Speckit Quick Plan

## Prerequisites

- Đang ở root `flex-workstation`.
- Feature artifact đã có:
  - `specs/000006-speckit-quick/spec.md`
  - `specs/000006-speckit-quick/plan.md`
  - `specs/000006-speckit-quick/research.md`
  - `specs/000006-speckit-quick/data-model.md`
  - `specs/000006-speckit-quick/contracts/quick-flow-contract.md`

## Static Validation

Sau khi implementation hoàn tất, chạy:

```powershell
rg -n "speckit-quick|speckit\.quick|Quick flow|quick flow" .agents/skills docs AGENTS.md CLAUDE.md
```

Expected outcome:
- Có `.agents/skills/speckit-quick/SKILL.md`.
- Có nhắc tới `/speckit.quick` là tên hiển thị.
- Có alias `$speckit-quick` hoặc `/speckit-quick`.
- Có documentation trong `docs/speckit/workflow.md`.

Kiểm frontmatter:

```powershell
Get-Content -First 20 .agents/skills/speckit-quick/SKILL.md
```

Expected outcome:
- Có `name: "speckit-quick"`.
- Có `user-invocable: true`.
- Description nói rõ quick flow cho tác vụ nhỏ.

## Manual Scenario 1: Quick Task Hợp Lệ

Input mẫu:

```text
$speckit-quick Cập nhật một câu trong docs/speckit/maintenance.md để ghi chú quick flow không dùng cho thay đổi data hoặc permission.
```

Expected pre-change statement:
- Nêu giả định task chỉ sửa `docs/speckit/maintenance.md`.
- Nêu ngoài phạm vi: không sửa skill/core workflow khác nếu không cần.
- Nêu cách kiểm tra: đọc diff hoặc `rg` câu vừa thêm.

Expected completion report:
- Nêu `docs/speckit/maintenance.md` đã thay đổi.
- Nêu kiểm tra đã chạy hoặc lý do không chạy.
- Nêu phần chưa làm nếu có.

## Manual Scenario 2: Task Phải Escalate

Input mẫu:

```text
$speckit-quick Thêm quick flow để tự động sửa quyền truy cập người dùng trong flex-auth-service và cập nhật contract API liên quan.
```

Expected outcome:
- Quick flow dừng.
- Báo lý do: đụng permission, contract và project con.
- Đề xuất dùng `$speckit-specify <mô tả nghiệp vụ>` trước implementation.
- Xác nhận không sửa file nếu chưa thực hiện thay đổi.

## Manual Scenario 3: Input Mơ Hồ

Input mẫu:

```text
$speckit-quick Dọn lại Speckit cho gọn hơn.
```

Expected outcome:
- Agent không tự sửa ngay.
- Agent hỏi làm rõ hoặc thu hẹp phạm vi vì mục tiêu/phạm vi/kiểm tra chưa rõ.

## Regression Check

Chạy:

```powershell
rg -n "\$speckit-specify|\$speckit-plan|\$speckit-tasks|\$speckit-implement" docs/speckit/workflow.md AGENTS.md
```

Expected outcome:
- Workflow Speckit đầy đủ vẫn còn được document.
- Quick flow không thay thế các bước core.
