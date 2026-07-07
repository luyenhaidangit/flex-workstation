# Quickstart Validation Guide: Mở Nhanh Các Project Code

**Date**: 2026-07-07 | **Feature**: 000002-cmd-open-projects

## Prerequisites

1. Workspace đã bootstrap xong (`SYNC_WORKSPACE.cmd` đã chạy ít nhất một lần)
2. VS Code đã cài và lệnh `code` có thể gọi từ terminal
3. `workstation.json` tồn tại tại workspace root

## Kiểm tra nhanh prerequisites

```powershell
# Tại workspace root
code --version          # Phải in ra version VS Code
Test-Path workstation.json   # Phải trả về True
```

## Scenario 1: Happy path — tất cả repo đã clone

**Mục đích**: Xác nhận YC-001, YC-002, YC-003, TC-001, TC-002

**Setup**: Ít nhất 1 repo trong `workstation.json` đã được clone (thư mục tồn tại)

**Chạy**:
```cmd
OPEN_CODE.cmd
```
hoặc double-click vào `OPEN_CODE.cmd` từ File Explorer

**Kết quả mong đợi**:
- Mỗi repo được clone mở trong một cửa sổ VS Code riêng biệt
- Không có error message
- Toàn bộ hoàn tất trong dưới 10 giây

---

## Scenario 2: Một repo chưa clone

**Mục đích**: Xác nhận YC-004, YC-005

**Setup**: Đổi tên tạm một thư mục repo (ví dụ: `flex-agents` → `flex-agents-bak`)

**Chạy**:
```cmd
OPEN_CODE.cmd
```

**Kết quả mong đợi**:
- Các repo còn lại vẫn được mở bình thường
- Terminal hiển thị: `[SKIP] flex-agents: thư mục không tồn tại` (hoặc tương tự)
- Script không dừng ở giữa chừng

**Cleanup**: Đổi tên lại thư mục về `flex-agents`

---

## Scenario 3: Chạy từ terminal

**Mục đích**: Xác nhận YC-007

**Chạy** (từ bất kỳ thư mục nào):
```cmd
cd C:\Workspace\Project\flex-workstation
OPEN_CODE.cmd
```

**Kết quả mong đợi**: Giống Scenario 1

---

## Scenario 4: Thêm repo mới vào workstation.json

**Mục đích**: Xác nhận TC-004

**Setup**:
1. Thêm entry vào `workstation.json`:
   ```json
   { "name": "test-repo-temp", "url": "..." }
   ```
2. Tạo thư mục giả: `mkdir test-repo-temp`

**Chạy**: `OPEN_CODE.cmd`

**Kết quả mong đợi**: `test-repo-temp` được mở trong VS Code mà không cần sửa `OPEN_CODE.cmd`

**Cleanup**: Xóa thư mục `test-repo-temp`, hoàn tác thay đổi `workstation.json`

---

## Liên kết

- Input schema: [contracts/workstation-schema.md](contracts/workstation-schema.md)
- Data model: [data-model.md](data-model.md)
- Implementation files: `OPEN_CODE.cmd`, `scripts/open-code.ps1`
