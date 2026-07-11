---
name: "speckit-quick"
description: "Quick flow cho tác vụ nhỏ, rõ phạm vi và rủi ro thấp trong flex-workstation."
argument-hint: "Mô tả tác vụ nhỏ cần xử lý"
compatibility: "Requires flex-workstation Speckit project structure"
metadata:
  author: "flex-workstation"
  source: "specs/000006-speckit-quick"
user-invocable: true
disable-model-invocation: false
---

# Speckit Quick

## Command Identity

`/speckit.quick` là tên hiển thị của quick flow. Trong runtime hiện hành, dùng `$speckit-quick` cho Codex skill invocation hoặc `/speckit-quick` khi slash command dạng dấu gạch ngang được hỗ trợ.

Ba tên `/speckit.quick`, `$speckit-quick` và `/speckit-quick` phải được hiểu là cùng một quick flow, không phải ba workflow khác nhau.

## Input Intake

Nhận mô tả tác vụ nhỏ từ người dùng. Trước khi sửa file, agent phải xác định hoặc suy ra an toàn:

- Mục tiêu người dùng muốn đạt.
- Phạm vi hoặc file/khu vực dự kiến thay đổi.
- Đầu ra mong đợi.
- Cách kiểm tra tối thiểu trong cùng phiên làm việc.

Nếu thiếu thông tin nhưng có thể suy ra an toàn từ context, nêu rõ giả định rồi tiếp tục. Nếu thiếu thông tin có thể làm đổi phạm vi, hỏi làm rõ hoặc thu hẹp phạm vi trước khi sửa.

## Quick Eligibility Gate

Chỉ xử lý bằng quick flow khi tất cả điều kiện sau đều đúng:

- Mục tiêu rõ.
- Phạm vi nhỏ và nằm trong `flex-workstation` hoặc phạm vi người dùng nêu rõ.
- Rủi ro thấp.
- Có thể kiểm tra trong cùng phiên làm việc.
- Không thay đổi ý nghĩa nghiệp vụ đã duyệt.
- Không đụng data, schema hoặc migration.
- Không thay đổi permission hoặc security model.
- Không thay đổi API, public contract hoặc release behavior.
- Không yêu cầu nhiều repo.

Nếu một điều kiện không đạt, dừng quick flow và dùng `Escalation Report`.

## Safety Guardrails

Quick flow không được:

- Ghi token, password, API key, connection string, credential hoặc secret vào repo.
- Bỏ qua kiểm tra permission, data hoặc contract.
- Tự ý sửa project con khi người dùng chỉ yêu cầu workstation.
- Refactor, format hoặc chỉnh comment ngoài phạm vi tác vụ.
- Tạo đủ artifact Speckit (`spec.md`, `plan.md`, `tasks.md`) cho từng quick task, trừ khi người dùng yêu cầu hoặc task bị escalate sang Speckit đầy đủ.

## Pre-Change Statement

Trước khi sửa file, agent phải nêu ngắn:

- Giả định.
- Phạm vi sẽ chạm.
- Phần ngoài phạm vi.
- Tiêu chí kiểm tra.

Nếu phát hiện quick gate không đạt ở bước này, không sửa file và chuyển sang `Escalation Report`.

## Execution Rules

- Đọc trạng thái hiện có trước khi sửa.
- Thực hiện thay đổi phẫu thuật, chỉ đủ để hoàn thành tác vụ đã nêu.
- Không thêm tính năng suy đoán.
- Không tạo artifact trùng lặp khi re-run cùng yêu cầu.
- Nếu file có thay đổi hiện có, làm việc với thay đổi đó; hỏi lại nếu không thể tiếp tục an toàn.
- Nếu trong lúc thực hiện phát hiện rủi ro vượt quick gate, dừng, nêu rõ phần đã đổi nếu có và chuyển sang `Escalation Report`.

## Completion Report

Khi hoàn tất quick task, báo cáo cuối phải có:

- `scope`: phạm vi đã xử lý.
- `files_changed`: file/khu vực đã thay đổi, hoặc nêu rõ không có file nào đổi.
- `checks_run` / `checks run`: command hoặc manual check đã chạy.
- `checks_not_run` / `checks not run`: kiểm tra không chạy và lý do nếu có.
- `not_done`: phần chưa làm nếu có.
- `risk_remaining`: rủi ro còn lại nếu có.
- `audit`: gồm `actor`, `timestamp`, `action`, `changed artifacts`.

Không đưa secret, token, password, API key, connection string hoặc credential vào báo cáo.

## Escalation Rules

Dừng quick flow nếu task:

- Đụng dữ liệu, schema, migration hoặc backfill.
- Thay đổi permission, security model hoặc kiểm tra quyền.
- Thay đổi API, event, public contract hoặc release behavior.
- Cần sửa nhiều repo.
- Đụng project con khi người dùng không nêu rõ đó là phạm vi.
- Có nghiệp vụ chưa specify hoặc có thể làm đổi MVP/luồng P1/P2 đã duyệt.

Khi dừng, không tiếp tục sửa như quick task.

## Ambiguous Input Handling

Nếu mô tả mơ hồ và có thể làm đổi scope, hỏi làm rõ hoặc đề xuất thu hẹp phạm vi. Không tự sửa với input kiểu "dọn lại", "làm gọn", "tối ưu", "sửa cho đúng" nếu chưa rõ file/khu vực, đầu ra và cách kiểm tra.

Nếu chỉ thiếu chi tiết nhỏ nhưng context đủ rõ, nêu giả định trong `Pre-Change Statement` và tiếp tục.

## Escalation Report

Khi task không đủ điều kiện quick, output phải có:

- `Không xử lý bằng quick flow`.
- Lý do cụ thể, không chỉ nói "quá lớn".
- Bước tiếp theo đề xuất: `$speckit-specify <mô tả nghiệp vụ>`.
- Xác nhận chưa sửa file nếu chưa có thay đổi.
- `audit`: gồm `actor`, `timestamp`, `action`, `escalation reason`.

Nếu đã sửa một phần trước khi phát hiện rủi ro, nêu rõ file đã đổi, phần đã kiểm tra và rủi ro còn lại.

## Complete Quick Example

Input:

```text
$speckit-quick Cập nhật một câu trong docs/speckit/maintenance.md để ghi chú quick flow không dùng cho thay đổi data hoặc permission.
```

Scope decision:

- `quick`: mục tiêu rõ, chỉ sửa một file tài liệu trong workstation, rủi ro thấp, kiểm tra được bằng `rg` hoặc review diff.

Pre-change statement mẫu:

- Giả định: chỉ thêm/làm rõ một câu trong `docs/speckit/maintenance.md`.
- Phạm vi sẽ chạm: section `Quick Flow`.
- Ngoài phạm vi: không sửa skill core, không sửa project con, không tạo spec/plan/tasks mới.
- Tiêu chí kiểm tra: chạy `rg -n "quick flow|data|permission" docs/speckit/maintenance.md`.

Actions:

- Đọc section hiện có.
- Sửa đúng câu cần làm rõ.
- Chạy command kiểm tra.

Completion report mẫu:

- `scope`: section `Quick Flow`.
- `files_changed`: `docs/speckit/maintenance.md`.
- `checks_run`: `rg -n "quick flow|data|permission" docs/speckit/maintenance.md`.
- `checks_not_run`: không có.
- `not_done`: không có.
- `risk_remaining`: thấp; chỉ là guidance tài liệu.
- `audit`: `actor=agent`, `timestamp=<ISO-8601>`, `action=update quick-flow note`, `changed artifacts=docs/speckit/maintenance.md`.

## Escalation Example

Input:

```text
$speckit-quick Thêm quick flow để tự động sửa quyền truy cập người dùng trong flex-auth-service và cập nhật contract API liên quan.
```

Expected output:

- `Không xử lý bằng quick flow`.
- Lý do: task đụng permission, API/public contract và project con `flex-auth-service`.
- Bước tiếp theo: `$speckit-specify <mô tả nghiệp vụ>` để tạo spec đầy đủ trước khi plan/tasks/implementation.
- Xác nhận: chưa sửa file nếu escalation xảy ra trước implementation.
- `audit`: `actor=agent`, `timestamp=<ISO-8601>`, `action=escalate quick request`, `escalation reason=permission + contract + project con`.

## Classification Examples

| Input mẫu | Expected classification | Lý do |
|-----------|-------------------------|-------|
| "Sửa một câu trong `docs/speckit/maintenance.md` để làm rõ quick flow" | `quick` | Tài liệu nhỏ, một file, kiểm tra bằng diff/rg |
| "Đổi tên heading trong `README.md` cho khớp docs" | `quick` | Phạm vi nhỏ, không đổi behavior |
| "Thêm permission mới cho user admin trong `flex-auth-service`" | `cần Speckit đầy đủ` | Đụng permission và project con |
| "Cập nhật API contract cho endpoint đăng nhập" | `cần Speckit đầy đủ` | Đụng public contract |
| "Dọn lại Speckit cho gọn hơn" | `cần Speckit đầy đủ` | Mục tiêu/phạm vi/kiểm tra chưa rõ; phải làm rõ hoặc specify trước khi sửa |

## Completion Criteria

Quick flow hoàn tất khi tác vụ đã được sửa trong phạm vi nhỏ, kiểm tra tối thiểu đã chạy hoặc có lý do không chạy, và completion report đã nêu rõ thay đổi cùng rủi ro còn lại.
