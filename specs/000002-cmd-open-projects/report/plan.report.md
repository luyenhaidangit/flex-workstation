# Plan Report: Mở Nhanh Các Project Code

**Feature**: 000002-cmd-open-projects | **Date**: 2026-07-07

## Tổng quan

Phase plan hoàn tất. Tính năng có độ phức tạp thấp — 2 file cần tạo, không có dependency ngoài ngoài VS Code CLI và PowerShell built-in.

## Deliverables dự kiến (tasks sẽ được chi tiết tại /speckit-tasks)

| # | Task | Dependency |
|---|------|------------|
| 1 | Tạo `scripts/open-code.ps1` — đọc `workstation.json`, mở từng repo với `code` | Không có |
| 2 | Tạo `OPEN_CODE.cmd` — wrapper gọi `scripts/open-code.ps1` | Task 1 |
| 3 | Kiểm tra thủ công theo quickstart.md | Task 1, 2 |

## Risks đã xác định

| Rủi ro | Khả năng | Biện pháp |
|--------|----------|-----------|
| VS Code không có trong PATH | Trung | Script kiểm tra và thông báo lỗi rõ ràng |
| `workstation.json` thay đổi cấu trúc | Thấp | Script đọc đúng path `repositories.items[].name` |

## Assumptions

- VS Code đã được cài và `code` command available trong PATH
- Workspace đã bootstrap ít nhất một lần
- PowerShell 5.1 (built-in Windows 10/11)

## Estimated effort

**~30 phút** — 2 file nhỏ, không có logic phức tạp, không cần test suite.
