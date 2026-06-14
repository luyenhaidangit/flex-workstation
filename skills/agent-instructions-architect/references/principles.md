# Principles — Nguyên tắc viết instructions tốt

Dạy lại các nguyên tắc này khi giải thích quyết định cho user.

## 1. Cụ thể hơn trừu tượng

Bad: "viết code chất lượng cao"
Good: "không thêm try/catch quanh internal code; chỉ validate ở boundary (user input, external API)"

Trừu tượng → model phải đoán → kết quả không nhất quán.

## 2. Why bên cạnh What

Bad: "không mock database trong integration test"
Good: "không mock database trong integration test — Q3/2024 mock pass nhưng prod migration fail, tạo incident"

Why giúp model judge edge case thay vì follow mù.

## 3. Ví dụ thắng rule trừu tượng

Một cặp ví dụ "đúng vs sai" rõ hơn 3 dòng rule. Đặc biệt cần với format/style.

## 4. Đặt đúng tầng

Đặt sai tầng = thông tin rò rỉ vào context không cần (preference cá nhân vào project CLAUDE.md → cả team thấy), hoặc không reach session cần (project convention nằm trong memory → session mới không nhận).

## 5. Lean main file

CLAUDE.md root nên dưới ~500 tokens. Phần dài tách sang rules / sub-CLAUDE.md / memory. `MEMORY.md` là index, không phải nội dung — mỗi entry 1 dòng `- [Title](file.md) — hook`.

## 6. Không mâu thuẫn cross-tier

Trước khi thêm rule mới, grep xem có rule ngược đâu đó không. Khi review, mâu thuẫn ngầm là loại bug khó thấy nhất.

## 7. Test cold-read

Tự hỏi: "fresh Claude session không có lịch sử conversation, đọc file này có hiểu và làm đúng không?" Nếu phải có context conversation mới hiểu → viết lại.

## 8. Description là cơ chế trigger

SKILL.md và subagent dùng `description` để Claude quyết định có invoke không. Description chung chung → undertrigger. Description cụ thể + hơi pushy về trigger context → đúng tần suất.

## 9. Memory cần đúng type và format

File memory cần frontmatter `name`, `description` (cụ thể, dùng để future-Claude judge relevance), `type` (`user | feedback | project | reference`). Feedback và project memory cần `**Why:**` và `**How to apply:**` trong body.

## 10. Không lưu cái derive được

Code patterns, file paths, git history, debugging recipes → KHÔNG vào memory. Đọc code và `git log` là đủ.
