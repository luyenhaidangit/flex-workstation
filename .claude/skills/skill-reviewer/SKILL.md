---
name: skill-reviewer
description: >
  Dùng khi người dùng muốn "review skill X", "audit SKILL.md",
  "skill này có vấn đề gì không", "check chất lượng skill Y",
  "skill viết đúng chưa", "cải thiện skill". Không dùng khi user muốn
  AI sửa hẳn (→ skill-creator) hoặc chạy eval/tạo skill mới.
  Output: báo cáo điểm/100 theo 5 trục + danh sách fix suggestions cụ thể.
---

# Skill Reviewer

Audit nhanh một SKILL.md hiện có theo 5 trục tiêu chí, trả báo cáo có điểm + fix suggestions cụ thể. Không chạy eval, không tạo skill mới.

## Khi nào dùng skill này (không dùng `skill-creator`)

- User muốn biết skill hiện tại **có vấn đề gì** — chỉ cần chẩn đoán, chưa cần chữa
- Muốn **điểm số nhanh** trước khi quyết định có cần đầu tư cải tiến không
- Muốn **checklist cụ thể** để tự sửa

Nếu user muốn tạo mới hoặc chạy eval → dùng `skill-creator` thay thế.

## Quy trình

### 1. Xác định target

Nhận diện skill cần review từ yêu cầu:
- Tên skill → tìm trong `.claude/skills/<name>/SKILL.md` (runtime path) hoặc `flex-workstation/.claude/skills/<name>/SKILL.md` (source path)
- Nếu không rõ → hỏi 1 câu: "Skill nào bạn muốn review?"

### 2. Thu thập thông tin

**Input yêu cầu:** tên skill hoặc path đến SKILL.md.
**Input tùy chọn:** focus area cụ thể (vd: "chỉ check Trục 1", "tập trung safety").

Đọc song song:
- `SKILL.md` của skill target
- Kiểm tra sự tồn tại của các file/thư mục được nhắc đến trong body (references/, scripts/, assets/)
- Kiểm tra `flex-workstation/config/workspace-skills.json` để xem skill có được đăng ký chưa

### 3. Chấm điểm theo 5 trục

Đọc chi tiết tiêu chí từng trục trong `references/rubric.md` trước khi chấm — vì rubric là source-of-truth duy nhất; chấm từ memory dễ lệch khi rubric được cập nhật. Với mỗi trục: ghi điểm, liệt kê issues cụ thể (file:line nếu có).

### 4. Tổng hợp và trả kết quả

Trả báo cáo theo format sau — không thêm bớt cấu trúc:

```
## Skill Review: [skill-name]
**Score: XX/100**

| Trục | Điểm | Tối đa |
|---|---|---|
| Description/Trigger | X | 25 |
| Cấu trúc body | X | 15 |
| Completeness & Operational clarity | X | 25 |
| Chất lượng instructions | X | 25 |
| Workspace conventions | X | 10 |

### Issues (theo mức độ ưu tiên)
1. `[file:line]` — [vấn đề ngắn gọn] → [fix cụ thể]
2. ...

### Không có vấn đề tại
- [điểm đã làm tốt, nếu có]

### Tóm tắt
[1-2 câu nhận xét tổng + khuyến nghị bước tiếp theo]
```

Xem ví dụ end-to-end hoàn chỉnh tại `references/example-report.md`.

Nếu điểm < 70: khuyến nghị dùng `skill-creator` để cải tiến.
Nếu điểm 70–84: liệt kê issues ưu tiên cao để user tự sửa.
Nếu điểm ≥ 85: chỉ ra 1-2 điểm có thể polish thêm nếu muốn.

Task hoàn thành khi báo cáo đã được trả trong chat và user chưa yêu cầu làm gì thêm.

## Nguyên tắc chấm điểm

- **Không chỉnh sửa SKILL.md đang được review** — chỉ đọc và báo cáo. Mọi thay đổi là việc của user hoặc skill-creator; sửa trong khi review tạo feedback loop và bias kết quả.
- **Pure read-only** — không tạo file, không chạy command có side effect, không fetch external URL trong quá trình review; chỉ dùng thao tác đọc/inspect.
- Chấm theo **bằng chứng trong file**, không theo ý định.
- Nếu một tiêu chí không áp dụng được (vd skill không có references/) → ghi rõ "N/A" và không trừ điểm.
- Issues phải **cụ thể và có fix**:
  - Bad: `"description chưa tốt"`
  - Good: `"SKILL.md:3 — description thiếu NOT-trigger → thêm 'Không dùng khi user muốn tạo skill mới (dùng skill-creator thay thế)'"`
- Tối đa **7 issues** — thà ít mà actionable.
