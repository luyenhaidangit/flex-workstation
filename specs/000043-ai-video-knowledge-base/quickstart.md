# Quickstart kiểm chứng: AI Video Knowledge Base (MVP)

Dùng sau `/speckit-implement`. Mọi giá trị bí mật lấy từ biến môi trường hoặc user-secrets, không ghi vào repo.

## 1. Chuẩn bị

1. Tạo database `videodb` và chạy migration: `flex-database` → `MIGRATE_VIDEODB.cmd` (Windows) hoặc `scripts/migrate-videodb.sh`. Kiểm tra `liquibase history` có changeset 1.0.0.
2. Cấu hình `flex-agent-service` (mẫu ở `appsettings.Example.json`): `ConnectionStrings:VideoDb`, `VideoKnowledge:Enabled=true`, `Google:ClientId`, `Google:ClientSecret`, `Google:RedirectUri`, `Gemini:ApiKey`, `TokenEncryption:Key` (đã có).
3. Chạy `flex-agent-service` và `flex-microfrontend`; đăng nhập bằng tài khoản quản trị.

## 2. Kịch bản chính (US-001 → US-003)

| Bước | Thao tác | Kết quả mong đợi |
| --- | --- | --- |
| 1 | Màn hình Kho tri thức video → Kết nối Google Drive, đồng ý quyền chỉ đọc | Trạng thái "Đã kết nối" kèm tài khoản; DB có 1 dòng `drive_connections`, token ở dạng mã hóa |
| 2 | Chọn thư mục chứa 3–5 video mẫu → Đồng bộ | Video xuất hiện ở trạng thái `pending`, có tên và thời lượng (SC-001) |
| 3 | Chọn video → Xử lý | Trạng thái đi qua `downloading → processing → summarizing → indexing → completed` |
| 4 | Mở chi tiết video | Có tóm tắt, mục lục theo mốc thời gian, kiến thức chính, thẻ, nhóm chủ đề, mức độ (SC-002, SC-003) |
| 5 | Tìm theo từ khóa nằm trong tóm tắt | Video xuất hiện trong kết quả (SC-004) |

## 3. Kịch bản biên

| Tình huống | Kỳ vọng |
| --- | --- |
| Đồng bộ lần hai khi không đổi gì | `unchanged` = số video cũ, không tạo bản ghi trùng (BR-001) |
| Đổi tên hoặc di chuyển video trong thư mục nguồn rồi đồng bộ | Tên cập nhật, kết quả phân tích giữ nguyên (BR-007) |
| Video có quyền tải bị tắt | `access_denied`, `failure_code = download_not_allowed`; không crash job |
| Video không phải tiếng Việt | `failed`, `failure_code = unsupported_language` (FR-028) |
| Video vượt giới hạn kích thước | `failed`, `failure_code = file_too_large` |
| Bấm xử lý lại video đang chạy | `409 video_in_progress` |
| Người dùng không phải quản trị gọi API | `403` |
| Sau mỗi lần xử lý | Thư mục tạm không còn file video; file tạm trên dịch vụ phân tích đã bị xóa (FR-026) |

## 4. Lệnh kiểm tra tự động

```bash
dotnet build Flex.Agent.sln
dotnet test tests/Flex.Agent.Tests
```

```bash
node scripts/speckit-cli.js validate --feature specs/000043-ai-video-knowledge-base --stage plan
```

Lệnh Angular (`npm run build`/test) chạy trong `flex-microfrontend` theo script có sẵn của repo.
