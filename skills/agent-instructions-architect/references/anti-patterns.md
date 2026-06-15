# Anti-patterns thường gặp

Dùng khi Review (Chế độ 2) để đối chiếu và nhận diện vấn đề.

| Anti-pattern | Dấu hiệu nhận biết | Fix |
|---|---|---|
| **CLAUDE.md kể chuyện** | CLAUDE.md > 500 tokens, có đoạn giải thích kiến trúc dài | Chuyển sang `docs/architecture.md`, CLAUDE.md chỉ giữ rules ngắn |
| **Dòng không vượt phép thử xóa** | Bỏ dòng đó đi Claude vẫn không mắc lỗi đáng kể | Xóa hoặc chuyển sang docs; chỉ giữ rule làm đổi hành vi |
| **Workflow thỉnh thoảng mới cần nằm trong CLAUDE.md** | CLAUDE.md chứa checklist/domain workflow dài cho task hiếm | Chuyển thành skill / slash command; CLAUDE.md chỉ giữ pointer nếu thật cần |
| **Rule bị bỏ qua vì chìm trong nhiễu** | User nói "đã ghi rồi mà Claude vẫn làm sai" | Cắt bớt file, rewrite rule cụ thể hơn, chỉ dùng IMPORTANT cho luật thật sự quan trọng |
| **Chép docs thay vì import/link** | CLAUDE.md chứa API docs, tutorial, mô tả dài | Thay bằng `@path/to/doc.md` hoặc link tới docs |
| **Memory không có Why** | "user thích X" mà không nói tại sao | Thêm `**Why:**` — incident, preference, hay constraint gì? |
| **`MEMORY.md` phình** | Nội dung memory viết thẳng vào index thay vì file con | Tách ra file con, index chỉ giữ 1 dòng pointer |
| **Rule chung chung** | "viết code sạch", "test đầy đủ" | Viết cụ thể: ai, ở đâu, tiêu chí gì |
| **Trùng CLAUDE.md và memory** | Cùng preference ở 2 nơi | Giữ ở CLAUDE.md (stable), xóa khỏi memory |
| **Subagent description mơ hồ** | "researcher" — main agent không biết khi nào delegate | Thêm trigger context cụ thể, ví dụ khi nào NÊN và KHÔNG NÊN dùng |
| **Instruction nhắc file không tồn tại** | Nhắc đến file/function/flag đã rename/xóa | Grep verify trước khi tin, xóa hoặc cập nhật reference |
| **User-specific lọt vào project CLAUDE.md** | "tôi thích dùng vim" trong CLAUDE.md root | Chuyển sang `~/.claude/CLAUDE.md` |
| **Local note bị commit thành team rule** | Path tuyệt đối, token cá nhân, permission tạm, setup riêng máy nằm trong project CLAUDE.md | Chuyển sang `CLAUDE.local.md` / user-global và gitignore |
| **Skill description không pushy đủ** | "skill làm X" — Claude undertrigger | Thêm trigger context cụ thể, liệt kê nhiều ngữ cảnh |
| **Mix tầng trong 1 file** | File vừa chứa project convention, user preference, memory | Tách rõ từng phần ra đúng tầng |
