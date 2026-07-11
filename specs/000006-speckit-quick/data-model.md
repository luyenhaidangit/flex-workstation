# Data Model: Speckit Quick

Feature này không tạo database, schema, migration hoặc persistent business data. Các thực thể dưới đây là conceptual entities dùng để thiết kế behavior contract và task implementation.

## Quick Task

**Mô tả**: Một yêu cầu nhỏ được xử lý bằng quick flow.

**Fields**:
- `goal`: mục tiêu người dùng muốn đạt.
- `scope`: file/khu vực dự kiến thay đổi.
- `expected_output`: đầu ra mong đợi.
- `validation`: cách kiểm tra tối thiểu.
- `assumptions`: giả định agent nêu trước khi sửa.
- `risk_level`: `low` hoặc `not_quick`.
- `status`: `intake`, `eligible`, `executing`, `completed`, `escalated`, `blocked`.

**Validation rules**:
- `goal`, `scope`, `expected_output`, `validation` phải có hoặc suy ra được an toàn trước khi sửa.
- `risk_level` phải là `not_quick` nếu task đụng data, permission, contract, migration, release, nhiều repo hoặc nghiệp vụ chưa specify.
- `status` không được chuyển sang `executing` khi còn mơ hồ làm đổi phạm vi.

**Relationships**:
- Có thể sinh một `Quick Result Report`.
- Có thể sinh một `Escalation Decision` nếu không đủ điều kiện quick.

## Quick Example

**Mô tả**: Ví dụ hoàn chỉnh minh họa cách dùng quick flow.

**Fields**:
- `input`: yêu cầu mẫu từ người dùng.
- `scope_decision`: vì sao task đủ hoặc không đủ quick.
- `actions`: hành động agent thực hiện.
- `checks`: kiểm tra đã chạy.
- `report`: báo cáo kết quả mẫu.

**Validation rules**:
- Phải thể hiện input, quyết định phạm vi, hành động, kiểm tra và báo cáo.
- Không được mô tả task có data/permission/contract/release như quick hợp lệ.

## Escalation Decision

**Mô tả**: Kết luận dừng quick flow và chuyển sang Speckit đầy đủ.

**Fields**:
- `reason`: lý do vượt phạm vi quick.
- `trigger`: yếu tố kích hoạt như data, permission, contract, release, many_repos, unclear_business_scope.
- `recommended_next_step`: command đề xuất, mặc định `$speckit-specify <mô tả nghiệp vụ>`.
- `not_changed`: xác nhận chưa sửa file khi escalation xảy ra trước implementation.

**Validation rules**:
- Phải nêu lý do cụ thể, không chỉ nói "quá lớn".
- Phải đề xuất bước tiếp theo.
- Nếu đã sửa một phần trước khi phát hiện rủi ro, report phải nêu rõ file đã đổi và rủi ro còn lại.

## Quick Result Report

**Mô tả**: Báo cáo cuối của quick flow hợp lệ.

**Fields**:
- `scope`: phạm vi đã xử lý.
- `files_changed`: danh sách file/khu vực đã thay đổi.
- `checks_run`: command/manual check đã chạy.
- `checks_not_run`: kiểm tra không chạy và lý do.
- `not_done`: phần chưa làm nếu có.
- `risk_remaining`: rủi ro còn lại nếu có.

**Validation rules**:
- Phải có `files_changed` hoặc nêu rõ không có file nào đổi.
- Phải có `checks_run` hoặc lý do không chạy kiểm tra.
- Không được chứa secret, token, password, API key hoặc connection string.

## State Transitions

```text
intake
  -> eligible
  -> executing
  -> completed

intake
  -> blocked

intake
  -> escalated

eligible
  -> escalated
```

**Transition rules**:
- `intake -> eligible`: chỉ khi quick gate pass.
- `intake -> blocked`: khi thiếu thông tin và không thể suy ra an toàn.
- `intake/eligible -> escalated`: khi phát hiện điều kiện cần Speckit đầy đủ.
- `executing -> completed`: chỉ sau khi thay đổi và kiểm tra/report hoàn tất.
