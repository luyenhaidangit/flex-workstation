# Security rules

<!--
  KHÔNG có frontmatter `paths:` => nạp vào MỌI session, cùng độ ưu tiên với
  .claude/CLAUDE.md. Giữ thật ngắn, đây là "thuế context" cố định.
-->

- NEVER hardcode secret, API key, connection string. Đọc từ env; khai báo tên biến mới vào `.env.example`.
- NEVER log hoặc in ra token, password, PII (email, SĐT, CCCD, số thẻ).
- Truy vấn DB luôn tham số hoá. NEVER nối chuỗi SQL.
- Mọi input từ ngoài (HTTP, webhook, file upload, queue message) phải validate trước khi dùng.
- Endpoint mới phải khai báo rõ yêu cầu auth/authz. Mặc định là **deny**, opt-in mới public.
- Dependency mới: hỏi trước. Không tự thêm package để giải quyết việc 20 dòng code làm được.
