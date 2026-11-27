# Nghiên cứu kỹ thuật (Phase 0): AI Video Knowledge Base

**Feature**: `000043-ai-video-knowledge-base` | **Phạm vi plan**: chỉ MVP (P1), thiết kế sẵn chỗ mở rộng cho P2/P3 | **Ngày**: 2026-11-27

Căn cứ thực tế đã đọc: `flex-agent-service` (`AGENTS.md`, `Flex.Agent.sln`, `ServiceExtensions.cs`, `AppDbContext.cs`, luồng kết nối Facebook/Instagram), `flex-database` (`AGENTS.md`, `agentdb/`), `flex-microfrontend` (`agent-catalog`, `environment.ts`, routing), `docs/architecture/system-map.md`.

**Chưa xác minh được trong phiên này**: chi tiết API hiện hành của Google Drive và Gemini (tên trường, giới hạn kích thước, thời hạn lưu file, mức token/giây, phiên bản gói NuGet). Các mục đó được đánh dấu `Xác minh khi implement` và phải đối chiếu tài liệu chính thức trước khi viết code tương ứng.

## TQ-001 — Phạm vi OAuth với Google Drive

- **Quyết định**: dùng một scope chỉ đọc cho toàn bộ Drive của tài khoản kết nối (`drive.readonly`), theo luồng OAuth 2.0 authorization code có `access_type=offline` để lấy refresh token.
- **Lý do**: quản trị viên cần chọn thư mục rồi hệ thống đọc đệ quy mọi video con; scope theo từng file do người dùng chọn không phủ được thư mục con. Đáp ứng SEC-004 (không xin quyền ghi/xóa).
- **Phương án đã loại**: scope theo từng file do người dùng chọn qua trình chọn file của Google (không bao phủ thư mục con); tài khoản dịch vụ dùng chung (trái BR-003 và đã bị loại ở bước clarify).
- **Rủi ro còn lại**: scope này thuộc nhóm bị hạn chế nên có thể cần xác minh ứng dụng với Google nếu mở cho nhiều người dùng; với dùng nội bộ có thể chạy ở chế độ thử nghiệm. `Xác minh khi implement`.

## TQ-002 — Nơi lưu trạng thái job nền

- **Quyết định**: Hangfire chạy ngay trong tiến trình `Flex.Agent.Api`, lưu trạng thái job bằng PostgreSQL trong schema riêng `hangfire` của database `videodb`, do chính thư viện quản lý schema.
- **Lý do**: người dùng đã chọn Hangfire; hạ tầng đã có PostgreSQL nên không thêm thành phần mới; lưu trong `videodb` để dữ liệu job nằm cùng database của tính năng.
- **Phương án đã loại**: lưu job trong Redis (cần gói thương mại hoặc gói cộng đồng ít được bảo trì hơn); tự viết hàng đợi bằng bảng PostgreSQL (tái phát minh tính năng đã có); thêm RabbitMQ/MassTransit (thừa cho MVP, đúng nhận định của đề xuất gốc).
- **Rủi ro còn lại**: schema `hangfire` không đi qua Liquibase vì do thư viện tự tạo/nâng cấp; đây là ngoại lệ có chủ đích với quy ước "migration tập trung ở `flex-database`", ghi rõ ở plan và README của `flex-database`. Gói Hangfire cần người dùng xác nhận thêm vào `flex-agent-service` (xem TQ-010).

## TQ-003 — Cách gọi dịch vụ phân tích video (Gemini)

- **Quyết định**: tích hợp qua `HttpClient` có kiểu (typed client) và `System.Text.Json`, đặt sau cổng `IVideoAnalyzer` của lớp Application; MVP gồm hai thao tác: tải video lên dịch vụ lưu file tạm của Gemini rồi gọi sinh nội dung với đầu ra JSON theo schema cố định. Tên model, base URL, timeout, độ phân giải video và bảng giá đều là cấu hình, không viết cứng.
- **Lý do**: không phụ thuộc gói SDK chưa xác minh tương thích `net9.0`; `HttpClient` và `System.Text.Json` đã có sẵn trong framework (nguyên tắc ưu tiên năng lực framework); cổng `IVideoAnalyzer` là seam cho phương án Whisper/Faster Whisper ở giai đoạn sau.
- **Phương án đã loại**: dùng `Microsoft.Extensions.AI` sẵn có trong repo (hiện chỉ gắn với Ollama cho chat, không có đường dẫn rõ cho video); gói SDK cộng đồng (rủi ro bảo trì).
- **Rủi ro còn lại**: giới hạn kích thước/thời lượng video, thời gian xử lý file sau khi tải lên và mức token/giây thay đổi theo model. `Xác minh khi implement` bằng tài liệu chính thức và bộ video mẫu 20–30 video (SC-003, SC-008).

## TQ-004 — Tóm tắt video dài (FR-007)

- **Quyết định**: tải video lên một lần, sau đó phân tích theo từng cửa sổ thời gian (mặc định 15 phút, cấu hình được) bằng offset đầu/cuối của video; mỗi cửa sổ trả transcript, thông tin hình ảnh và tóm tắt cục bộ; một lượt gọi cuối chỉ dùng văn bản để gộp thành tóm tắt đầy đủ, mục lục, kiến thức chính, thẻ, nhóm chủ đề và mức độ. Video ngắn hơn một cửa sổ chỉ cần một lượt.
- **Lý do**: tránh đầu ra bị cắt khi transcript dài và bảo đảm tóm tắt bao quát đầu-giữa-cuối; đúng hướng "tóm tắt phân tầng" của đề xuất gốc.
- **Phương án đã loại**: một lượt gọi duy nhất cho cả video (rủi ro cắt đầu ra và bỏ sót phần giữa); chia theo ranh giới chủ đề tự động ngay MVP (phức tạp, để P2/P3 khi có dữ liệu benchmark).
- **Rủi ro còn lại**: mốc thời gian ở ranh giới cửa sổ có thể lệch; kiểm tra bằng SC-003 (lệch không quá 30 giây).

## TQ-005 — Nhận diện phiên bản nội dung video

- **Quyết định**: khóa nội dung (`content_key`) lấy từ mã băm nội dung do Drive cung cấp cho file nhị phân; nếu không có thì dùng số phiên bản của file (`v` kèm số). Một kết quả phân tích là duy nhất theo (video, `content_key`).
- **Lý do**: đáp ứng BR-001 mà không phải tải nội dung để tự băm; đổi tên hoặc di chuyển không đổi khóa (BR-007).
- **Phương án đã loại**: tự băm file đã tải (tốn băng thông cho cả video không cần xử lý); dùng thời điểm sửa đổi (đổi khi chỉ đổi metadata).
- **Rủi ro còn lại**: trường mã băm và số phiên bản cần xác nhận trên file video thật. `Xác minh khi implement`.
- **Giới hạn MVP**: đồng bộ chỉ cập nhật metadata và `content_key` mới; việc tự phân tích lại khi nội dung đổi thuộc P2 (FR-013/FR-014). Màn hình chi tiết cảnh báo khi `content_key` của video khác `content_key` của kết quả hiện hành và cho phép bấm xử lý lại.

## TQ-006 — Lưu tạm video và dọn dẹp (FR-026)

- **Quyết định**: tải video theo luồng (stream) từ Drive xuống file tạm trong thư mục cấu hình, tải lên Gemini, rồi xóa file tạm và file trên dịch vụ Gemini trong khối `finally`. Có giới hạn kích thước tối đa (cấu hình); vượt ngưỡng thì dừng với mã lỗi `file_too_large`.
- **Lý do**: không giữ bản sao lâu dài; luồng xử lý không nạp cả file vào bộ nhớ.
- **Phương án đã loại**: lưu video vào MinIO (giữ bản sao ngoài ý muốn); truyền thẳng Drive sang Gemini không qua đĩa (không có API nhận luồng liền mạch; khó retry).
- **Rủi ro còn lại**: đĩa tạm đầy khi xử lý song song; giới hạn số job song song theo cấu hình.

## TQ-007 — Hai database trong cùng một service

- **Quyết định**: thêm `VideoDbContext` riêng gắn chuỗi kết nối `ConnectionStrings:VideoDb`; `AppDbContext` và `ConnectionStrings:Default` (agentdb) giữ nguyên. Toàn bộ tính năng nằm sau cờ cấu hình `VideoKnowledge:Enabled` (mặc định tắt); khi tắt thì không đăng ký DbContext, Hangfire và controller, nên môi trường hiện hữu không bị buộc phải có `videodb`.
- **Lý do**: Hiến pháp VI và tiền lệ `agentdb` (database riêng, không dùng chung `flexdb`); không đổi hành vi của service hiện tại.
- **Phương án đã loại**: dùng chung `AppDbContext`/agentdb (người dùng đã chọn database riêng); đặt bảng vào `flexdb` (còn ghi chú "Cần làm rõ" ở `system-map.md`).

## TQ-008 — Phân quyền ở MVP

- **Quyết định**: MVP chỉ cho người có quyền quản trị (`ApplicationAuthorization.CanManage`, hiện dựa trên claim `sub` thuộc danh sách quản trị) kết nối Drive, đồng bộ, khởi chạy xử lý và xem kết quả. Việc đối chiếu quyền xem theo từng người dùng với Drive (FR-015/FR-016, SEC-002) thuộc P2.
- **Lý do**: BR-003 yêu cầu quyền xem kế thừa từ Drive; nếu cho mọi người dùng đã đăng nhập đọc kết quả khi chưa có cơ chế đối chiếu thì rò rỉ nội dung video. Hạn chế theo quản trị viên là mặc định an toàn.
- **Tác động đến spec**: US-002 ghi "người dùng" xem tóm tắt; ở MVP chỉ quản trị viên xem được cho đến khi P2 hoàn thành. Đã ghi rõ ở plan để người dùng xác nhận.

## TQ-009 — Định tuyến và gateway

- **Quyết định**: frontend gọi trực tiếp `flex-agent-service` qua `agentApiBaseUrl` (đã dùng cho `agent-catalog`), không thêm route ở `flex-api-gateway`. Callback OAuth Google chuyển hướng về trang frontend `video-knowledge` kèm mã kết quả.
- **Lý do**: khớp cách `agent-catalog` đang gọi API (`environment.ts`: `agentApiBaseUrl`).
- **Phương án đã loại**: đi qua gateway (chưa có bằng chứng agent-service được route qua gateway; tăng phạm vi sang repo thứ tư).

## TQ-010 — Kiểm thử và gói NuGet mới

- **Quyết định**: tạo project `tests/Flex.Agent.Tests` (xUnit) vì `AGENTS.md` của repo yêu cầu nhưng thư mục chưa tồn tại; test dùng đối tượng giả viết tay, không thêm thư viện mock. Test ràng buộc duy nhất dùng PostgreSQL thật khi có biến môi trường, bỏ qua khi không có. Gói mới cần người dùng xác nhận theo `AGENTS.md` của repo: `Hangfire.AspNetCore`, `Hangfire.PostgreSql`, `Google.Apis.Drive.v3`, `Google.Apis.Auth`, `Microsoft.NET.Test.Sdk`, `xunit`, `xunit.runner.visualstudio`. Phiên bản chốt khi implement sau khi kiểm tra tương thích `net9.0`.
- **Lý do**: Drive và OAuth Google dùng thư viện chính thức của Google (xử lý tải theo luồng, phân trang, làm mới token) thay vì tự viết; Hangfire theo lựa chọn của người dùng.
- **Rủi ro còn lại**: việc thêm gói là quyết định cần xác nhận ở bước `/speckit-tasks` hoặc `/speckit-implement`; không được thêm âm thầm.

## TQ-011 — Mã hóa refresh token

- **Quyết định**: tái dùng `ChannelTokenEncryptionService` (AES-256, khóa `TokenEncryption:Key`) cho refresh token của Drive.
- **Lý do**: đã có, đã được dùng cho token Meta; không tạo cơ chế mã hóa thứ hai.
- **Phương án đã loại**: viết dịch vụ mã hóa mới (trùng lặp); lưu token dạng rõ (vi phạm SEC-003).
- **Rủi ro còn lại**: tên lớp mang chữ "Channel" nhưng dùng cho Drive; chấp nhận ở MVP, đổi tên chung khi có ca dùng thứ ba.

## TQ-012 — Vị trí migration và phạm vi ràng buộc

- **Quyết định**: database `videodb` mới; migration SQL-first theo đúng cấu trúc `agentdb` tại `flex-database/videodb/` (`migrations/V1.1__...sql`, `changelog/db.changelog-master.xml`, `changelog/releases/1.0.0/changelog.xml`, `liquibase.properties` không chứa bí mật), cùng `scripts/migrate-videodb.sh` và `MIGRATE_VIDEODB.cmd`. Theo `AGENTS.md` của `flex-database`: không thêm khóa ngoại và `CHECK`; chỉ thêm chỉ mục duy nhất cho hai quy tắc spec yêu cầu rõ (mỗi video trên một kết nối là duy nhất; mỗi kết quả phân tích duy nhất theo video và `content_key`).
- **Lý do**: bám tiền lệ `agentdb` (xác nhận 2026-08-01 trong `system-map.md`) và quy ước repo `flex-database`.
- **Phương án đã loại**: migration nằm trong `flex-agent-service` (EF migration) hoặc trong repo mới; `flexdb` dùng chung.
- **Lưu ý**: tiền lệ V1.4 của `agentdb` dùng khóa ngoại và `CHECK`; plan này chọn quy ước nghiêm hơn trong `AGENTS.md` hiện hành của `flex-database`.

## TQ-013 — Thuật ngữ và mã trạng thái

- **Quyết định**: thực thể đặt tên theo spec: `DriveConnection`, `VideoSource`, `Video`, `VideoProcessingJob`, `VideoAnalysis`. Trạng thái lưu và trả về dạng chữ thường theo quy ước `flex-database` (`pending`, `downloading`, `processing`, `summarizing`, `indexing`, `completed`, `failed`, `access_denied`); giao diện hiển thị nhãn tiếng Việt qua `app-badge`. Lỗi không hỗ trợ ngôn ngữ dùng `failed` kèm `failure_code = unsupported_language` (FR-028) thay vì thêm trạng thái mới.
- **Lý do**: đúng danh sách trạng thái của spec, đúng quy ước lưu trạng thái của `flex-database`, không phát sinh trạng thái ngoài spec.
- **Ghi chú**: sự kiện realtime (SignalR) chưa thuộc MVP; khi thêm sẽ dùng dạng `video.status.changed` theo `flex-naming-convention`.

## TQ-014 — Khởi chạy xử lý

- **Quyết định**: đồng bộ chỉ phát hiện video và đặt `pending`; quản trị viên chủ động bấm xử lý (chọn video hoặc xử lý toàn bộ video đang chờ, có xác nhận hiển thị số video và tổng thời lượng, có trần số video mỗi lần theo cấu hình). Sau khi bấm, pipeline tự chạy hết các bước.
- **Lý do**: giới hạn chi phí (BR-005, FR-018) thuộc P2 nên MVP chưa có cơ chế chặn; xử lý tự động toàn bộ thư mục có thể phát sinh chi phí ngoài dự kiến.
- **Tác động đến spec**: US-002 viết "tự động tạo tóm tắt"; ở MVP phần "tự động" áp dụng cho pipeline sau khi quản trị viên khởi chạy. Đã ghi ở plan để người dùng xác nhận.
