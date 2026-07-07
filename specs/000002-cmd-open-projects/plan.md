# Implementation Plan: Mở Nhanh Các Project Code

**Branch**: `000002-cmd-open-projects` | **Date**: 2026-07-07 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/000002-cmd-open-projects/spec.md`

## Summary

Tạo file `OPEN_CODE.cmd` tại workspace root để mở tất cả sub-repo trong VS Code chỉ bằng một click. File `.cmd` là wrapper mỏng gọi `scripts/open-code.ps1` — script PowerShell đọc `workstation.json`, kiểm tra từng thư mục repo, rồi gọi `code <path>` cho từng repo tồn tại. Các repo chưa được clone sẽ bị bỏ qua kèm thông báo.

## Technical Context

**Language/Version**: Windows Batch (.cmd wrapper) + PowerShell 5.1

**Primary Dependencies**: VS Code CLI (`code` command on PATH); PowerShell 5.1 (built-in Windows 10/11); `workstation.json` (source of truth cho danh sách repo)

**Storage**: N/A — đọc `workstation.json` tại runtime, không lưu state

**Testing**: Manual — chạy script và kiểm tra số cửa sổ VS Code được mở

**Target Platform**: Windows 10 / Windows 11

**Project Type**: Workspace CLI script (automation tool)

**Performance Goals**: Tất cả project mở trong dưới 10 giây

**Constraints**: File launcher PHẢI là `.cmd` để click đúp được từ File Explorer; KHÔNG được yêu cầu cài thêm phần mềm

**Scale/Scope**: 5 repo hiện tại trong `workstation.json`; tự động scale khi thêm repo mới

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|-----------|-------|--------|
| I. Workspace Coordination | File launcher và script nằm trong workstation root/scripts — không chạm vào sub-repo | ✅ PASS |
| II. Spec-Before-Code | Spec `000002` đã hoàn chỉnh trước khi có plan này | ✅ PASS |
| III. Agent-Agnostic Tooling | Script không liên quan đến AI tooling config | N/A |
| IV. Bootstrap Reproducibility | `OPEN_CODE.cmd` phụ thuộc vào `workstation.json` đã có; không cần step setup thêm | ✅ PASS |
| V. Surgical Changes | Chỉ tạo 2 file mới: `OPEN_CODE.cmd` và `scripts/open-code.ps1` | ✅ PASS |

**Verdict**: Không có violation. Tiến hành Phase 1.

## Project Structure

### Documentation (this feature)

```text
specs/000002-cmd-open-projects/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── workstation-schema.md   # JSON input contract
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
OPEN_CODE.cmd            # Entry point — thin wrapper tại workspace root
scripts/
└── open-code.ps1        # PowerShell implementation đọc workstation.json
```

**Structure Decision**: Single-file pattern không đủ vì `.cmd` không có JSON parsing native. Tách wrapper `.cmd` + logic `.ps1` — nhất quán với cách `SYNC_WORKSPACE.cmd` → `scripts/bootstrap.ps1` đang hoạt động trong workspace.
