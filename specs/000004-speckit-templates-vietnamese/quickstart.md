# Quickstart: Validation cho template Speckit tiếng Việt

## Prerequisites

- Đứng tại workspace root `C:\Workspace\Project\flex-workstation`.
- Có `rtk`, PowerShell và `rg` trong môi trường làm việc.

## Scenario 1: Kiểm tra danh sách template trong scope

Chạy:

```powershell
rtk rg --files .specify/templates
```

Expected outcome:
- Có đủ 5 file: `spec-template.md`, `plan-template.md`, `tasks-template.md`, `checklist-template.md`, `constitution-template.md`.

## Scenario 2: Kiểm tra nhãn tiếng Anh phổ biến còn sót

Chạy:

```powershell
rtk rg "Purpose|Created|Feature|Summary|Technical Context|Constitution Check|Project Structure|Organization|Path Conventions|Notes|Core Principles|Governance|Requirements|Success Criteria" .specify/templates
```

Expected outcome:
- Không còn heading/label tiếng Anh phổ biến trong phần người đọc.
- Kết quả còn lại, nếu có, phải là placeholder, technical identifier, thuật ngữ workflow hoặc ví dụ có chủ đích.

## Scenario 3: Kiểm tra technical identifiers còn nguyên

Chạy:

```powershell
rtk rg "CHK###|\\[P\\]|\\[Story\\]|\\[FEATURE NAME\\]|\\[PROJECT_NAME\\]|/speckit-|\\.specify/templates|spec.md|plan.md|tasks.md" .specify/templates
```

Expected outcome:
- Các marker, command, path và placeholder kỹ thuật vẫn còn khi template cần chúng.

## Scenario 4: Kiểm tra skill gốc không bị sửa

Chạy:

```powershell
rtk powershell -NoProfile -Command "git diff -- .agents/skills"
```

Expected outcome:
- Không có diff trong `.agents/skills/**`.

## Scenario 5: Kiểm tra patch cơ bản

Chạy:

```powershell
rtk powershell -NoProfile -Command "git diff --check"
```

Expected outcome:
- Không có lỗi whitespace.

## Scenario 6: Kiểm tra phạm vi thay đổi

Chạy:

```powershell
rtk powershell -NoProfile -Command "git status --short"
```

Expected outcome:
- Chỉ có template, docs và artifact feature liên quan thay đổi.
- Không có thay đổi trong sub-repo.
