# Research: Mở Nhanh Các Project Code

**Date**: 2026-07-07 | **Feature**: 000002-cmd-open-projects

## Decision Log

### D-01: Định dạng script — `.cmd` wrapper + `.ps1` logic

**Decision**: `OPEN_CODE.cmd` là wrapper gọi PowerShell; logic thực tế trong `scripts/open-code.ps1`

**Rationale**: `.cmd` không có JSON parsing native. PowerShell có `ConvertFrom-Json` built-in, không cần install thêm gì. Pattern này đã được dùng trong workspace (`SYNC_WORKSPACE.cmd` → `scripts/bootstrap.ps1`) — nhất quán, không cần giải thích thêm.

**Alternatives considered**:
- Pure `.cmd` với `for /f` parsing JSON: brittle, không handle nested JSON tốt, khó maintain
- `.ps1` trực tiếp (không có `.cmd` wrapper): không click đúp được từ File Explorer theo mặc định trên Windows

---

### D-02: Cách gọi VS Code — `code <path>`

**Decision**: Dùng `code <absolute-path>` để mở từng repo trong cửa sổ VS Code riêng

**Rationale**: `code <path>` mở folder trong cửa sổ mới. `code --new-window <path>` cũng làm được nhưng verbose hơn không cần thiết. VS Code CLI đã được add vào PATH khi cài VS Code trên Windows.

**Alternatives considered**:
- `Start-Process code <path>`: không cần thiết, `code` là CLI command có thể gọi trực tiếp
- Mở tất cả trong một workspace VS Code (`.code-workspace` file): phức tạp hơn, khó maintain khi thêm/bớt repo

---

### D-03: Đọc `workstation.json` — PowerShell native JSON

**Decision**: `Get-Content workstation.json | ConvertFrom-Json` để parse danh sách repo

**Rationale**: Built-in PowerShell 5.1, không cần dependency ngoài. Path `repositories.items[].name` đã rõ từ cấu trúc hiện có.

**Alternatives considered**:
- Hardcode danh sách repo: vi phạm YC-001 và TC-004 — không scale khi thêm repo mới
- `jq` CLI tool: cần install thêm, không có sẵn trên Windows

---

### D-04: Xử lý repo chưa clone

**Decision**: Bỏ qua silently với `Write-Host` thông báo tên repo bị skip; tiếp tục các repo còn lại

**Rationale**: Phù hợp với YC-004 và YC-005. Không dừng toàn bộ quá trình vì một repo chưa có.

---

### D-05: Đường dẫn tuyệt đối vs tương đối

**Decision**: Dùng `$PSScriptRoot` để xác định workspace root trong script `.ps1`; `workstation.json` được đọc relative to `$PSScriptRoot\..` (vì script nằm trong `scripts/`)

**Rationale**: Cho phép script chạy đúng dù được gọi từ bất kỳ thư mục nào (qua `.cmd` wrapper hay terminal).
