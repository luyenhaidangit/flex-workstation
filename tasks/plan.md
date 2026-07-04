# Plan — Chuẩn hóa quy ước đặt tên (flex-workstation)

## Context

SPEC.md đã được tạo tại root của flex-workstation để định nghĩa quy ước đặt tên
cho thư mục, file, skill/agent/command và namespace. Audit toàn bộ workstation cho
thấy hầu hết file đã tuân thủ; chỉ có 1 vi phạm mềm cần sửa. Plan này triển khai
các bước còn lại để đưa SPEC vào thực tế: sửa vi phạm, tạo công cụ kiểm tra, và
gắn kết tài liệu.

## Kết quả audit

| Khu vực | Vi phạm cứng | Vi phạm mềm |
|---|---|---|
| Root-level files | 0 | 0 |
| `docs/` | 0 | 0 |
| `requirements/` | 0 | 1 — `testcase.md` nên là `test-case.md` |
| `scripts/` | 0 | 0 |
| `skills/` | 0 | 0 |

## Phạm vi

Chỉ repo `flex-workstation` (không đụng vào repo con).

---

## Tasks

### Task 1 — Fix vi phạm: `testcase.md` → `test-case.md`

**File:** `requirements/000001/testcase.md`

**Acceptance criteria:**
- `requirements/000001/testcase.md` không còn tồn tại
- `requirements/000001/test-case.md` tồn tại với nội dung nguyên vẹn
- Grep `testcase.md` trả về 0 kết quả

### Task 2 — Tạo lint script: `scripts/validate-naming.ps1`

Kiểm tra: `docs/`, `requirements/`, `scripts/`, `skills/` theo SPEC.md.

**Acceptance criteria:**
- Script chạy không lỗi
- Output rõ: violations hoặc `✓ No violations found`
- Chạy sau Task 1 → 0 violations

### [Checkpoint] Không còn vi phạm; công cụ kiểm tra sẵn sàng.

### Task 3 — Gắn SPEC.md vào README.md

Thêm reference đến SPEC.md trong section Tài liệu của README.md.

**Acceptance criteria:**
- `README.md` có link đến `SPEC.md`

### Task 4 — Cập nhật TASKS.md

Đánh dấu "Chuẩn hóa quy ước đặt tên project" là Done.

---

## Verification

```powershell
.\scripts\validate-naming.ps1
# → ✓ No violations found

ls requirements\000001\
# → phải thấy test-case.md, không thấy testcase.md

Select-String -Path README.md -Pattern "SPEC"
# → ít nhất 1 match
```
