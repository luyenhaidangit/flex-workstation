# Quickstart: Validation cho template checklist tiếng Việt

## Prerequisites

- Đứng tại workspace root `C:\Workspace\Project\flex-workstation`.
- Có `rtk`, PowerShell và `rg` trong môi trường làm việc.

## Scenario 1: Kiểm tra nhãn checklist tiếng Anh còn sót

Chạy:

```powershell
rtk rg "Purpose|Created|Feature|Content Quality|Requirement Completeness|Feature Readiness|Notes|Checklist Purpose|Acceptance Criteria Quality|Scenario Coverage|Edge Case Coverage" .specify/templates .agents/skills
```

Expected outcome:
- Không còn nhãn checklist tiếng Anh trong phần template/hướng dẫn sinh checklist mà người dùng sẽ đọc.
- Các kết quả còn lại, nếu có, phải là technical identifier, trích dẫn có chủ đích hoặc nội dung ngoài phạm vi.

## Scenario 2: Kiểm tra template canonical

Chạy:

```powershell
rtk powershell -NoProfile -Command "Get-Content -Raw -LiteralPath '.specify/templates/checklist-template.md'"
```

Expected outcome:
- Tiêu đề, nhãn meta, ghi chú và category mẫu trong template là tiếng Việt có dấu.
- Markdown checkbox `- [ ]` và mã `CHK###` vẫn giữ nguyên.

## Scenario 3: Kiểm tra instruction của checklist command

Chạy:

```powershell
rtk rg "Unit Tests for English|Requirement Completeness|Requirement Clarity|WRONG|CORRECT|Purpose|Created|Feature|Notes" .agents/skills/speckit-checklist/SKILL.md .agents/skills/speckit-specify/SKILL.md
```

Expected outcome:
- Instruction sinh checklist không còn ép heading/category tiếng Anh cho checklist mới.
- Nếu còn từ tiếng Anh, chúng phải là định danh kỹ thuật hoặc ví dụ được giữ có chủ đích.

## Scenario 4: Sinh thử checklist mới nếu workflow sẵn sàng

Chạy command checklist theo workflow hiện hành với focus ngắn, ví dụ:

```text
$speckit-checklist requirements
```

Expected outcome:
- File checklist mới trong `specs/000004-checklist-template-vietnamese/checklists/` dùng tiếng Việt cho tiêu đề, mục đích, nhóm item và ghi chú.
- Item vẫn ở dạng kiểm tra chất lượng requirement, không biến thành bước test implementation.

## Scenario 5: Kiểm tra phạm vi thay đổi

Chạy:

```powershell
rtk git status --short
```

Expected outcome:
- Chỉ có các file template/skill/spec artifact liên quan feature này thay đổi.
- Không có thay đổi trong sub-repo.
