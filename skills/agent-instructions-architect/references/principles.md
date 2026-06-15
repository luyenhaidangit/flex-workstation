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

## 6. Phép thử từng dòng

Với mỗi dòng trong CLAUDE.md, hỏi: "Bỏ dòng này đi thì Claude có mắc lỗi thực tế không?" Nếu không, cắt hoặc chuyển sang docs. Đây là tiêu chí quyết định vì CLAUDE.md được nạp mọi session.

## 7. Thứ đôi khi cần thuộc về skill hoặc import

CLAUDE.md chỉ chứa điều luôn đúng trong mọi session. Workflow/domain thỉnh thoảng mới cần → skill hoặc slash command. Tài liệu dài nhưng cần pointer → dùng `@path/to/file.md` hoặc link, không chép vào main file.

## 8. Tín hiệu hành vi quan trọng hơn hình thức

Nếu Claude vẫn vi phạm rule đã ghi, nghi ngờ file quá dài, rule quá mơ hồ, hoặc quá nhiều "IMPORTANT" làm mất độ nổi bật. Nếu Claude hỏi lại điều file đã trả lời, rewrite rule cho cụ thể hơn.

## 9. Team rule khác personal note

Project CLAUDE.md thuộc về team và nên commit vào git. Sở thích cá nhân hoặc máy cá nhân chuyển sang `CLAUDE.local.md` / user-global config và gitignore nếu có.

## 10. Không mâu thuẫn cross-tier

Trước khi thêm rule mới, grep xem có rule ngược đâu đó không. Khi review, mâu thuẫn ngầm là loại bug khó thấy nhất.

## 11. Test cold-read

Tự hỏi: "fresh Claude session không có lịch sử conversation, đọc file này có hiểu và làm đúng không?" Nếu phải có context conversation mới hiểu → viết lại.

## 12. Description là cơ chế trigger

SKILL.md và subagent dùng `description` để Claude quyết định có invoke không. Description chung chung → undertrigger. Description cụ thể + hơi pushy về trigger context → đúng tần suất.

## 13. Memory cần đúng type và format

File memory cần frontmatter `name`, `description` (cụ thể, dùng để future-Claude judge relevance), `type` (`user | feedback | project | reference`). Feedback và project memory cần `**Why:**` và `**How to apply:**` trong body.

## 14. Không lưu cái derive được

Code patterns, file paths, git history, debugging recipes → KHÔNG vào memory. Đọc code và `git log` là đủ.
