# Contract: Quick Flow Command

Contract này mô tả hành vi observable của quick flow. Đây không phải HTTP API.

## Command Identity

**User-facing name**: `/speckit.quick`

**Runtime aliases**:
- `$speckit-quick` trong Codex skill invocation.
- `/speckit-quick` trong runtime hỗ trợ slash command dạng dấu gạch ngang.

Skill implementation phải nói rõ các alias này trỏ tới cùng một quick flow.

## Input Contract

Quick flow nhận mô tả tác vụ nhỏ từ người dùng. Input hợp lệ nên có:

- Mục tiêu.
- Phạm vi hoặc file/khu vực liên quan.
- Đầu ra mong đợi.
- Cách kiểm tra tối thiểu.

Nếu input thiếu thông tin nhưng agent suy ra được an toàn từ context, agent có thể nêu giả định và tiếp tục. Nếu thiếu thông tin có thể làm đổi phạm vi, agent phải hỏi làm rõ hoặc dừng.

## Pre-Change Statement

Trước khi sửa file, quick flow phải nêu ngắn:

- Giả định.
- Phạm vi sẽ chạm.
- Phần ngoài phạm vi.
- Tiêu chí kiểm tra.

## Quick Eligibility Gate

Task chỉ được xử lý bằng quick flow khi tất cả điều kiện sau đúng:

- Mục tiêu rõ.
- Phạm vi nhỏ và nằm trong workstation hoặc phạm vi user nêu rõ.
- Rủi ro thấp.
- Có thể kiểm tra trong cùng phiên làm việc.
- Không thay đổi ý nghĩa nghiệp vụ đã duyệt.
- Không đụng dữ liệu/schema/migration.
- Không thay đổi quyền/security model.
- Không thay đổi API/public contract/release behavior.
- Không yêu cầu nhiều repo.

## Escalation Contract

Nếu task không đủ điều kiện quick, output phải có:

- `Không xử lý bằng quick flow`.
- Lý do cụ thể.
- Bước tiếp theo đề xuất, thường là `$speckit-specify <mô tả nghiệp vụ>`.
- Xác nhận chưa sửa file nếu chưa có thay đổi.

## Completion Report Contract

Khi hoàn tất quick task, output phải có:

- Phạm vi đã xử lý.
- File/khu vực đã thay đổi.
- Kiểm tra đã chạy.
- Kiểm tra không chạy và lý do nếu có.
- Phần chưa làm hoặc rủi ro còn lại nếu có.

## Safety Contract

Quick flow không được:

- Ghi token, password, API key, connection string hoặc credential vào repo.
- Bỏ qua kiểm tra quyền, dữ liệu hoặc contract.
- Tự ý sửa project con khi user chỉ yêu cầu workstation.
- Refactor hoặc format ngoài phạm vi task.
- Tạo artifact Speckit đầy đủ cho từng quick task trừ khi user yêu cầu hoặc flow bị escalate.
