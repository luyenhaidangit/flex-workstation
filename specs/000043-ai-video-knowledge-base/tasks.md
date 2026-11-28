---
description: "Danh sách task triển khai AI Video Knowledge Base (MVP P1)"
---

# Tasks: AI Video Knowledge Base

**Đầu vào**: Artifacts thiết kế từ `/specs/000043-ai-video-knowledge-base/` (`spec.md`, `plan.md`, `data-model.md`, `contracts/video-knowledge-api.md`, `research.md`, `quickstart.md`, `repos.md`)  
**Chế độ Spec**: Full  
**Test Gate**: Mọi rủi ro trong `plan.md` đều có task test tự động (viết fail trước khi code) hoặc task manual/command validation kèm lý do không áp dụng automated test.

## Format: `- [ ] T### [P?] [US#?] Mô tả hành động cụ thể kèm file path hoặc command`

- **`T###`**: Mã tăng tuần tự.
- **`[P]`**: Chạy song song được (khác file, không phụ thuộc task chưa xong trong cùng phase; không liên quan priority `P1`/`P2`).
- **`[US#]`**: Bắt buộc cho phase User Story. Đánh số theo `spec.md`: `US1` = US-001 (kết nối Drive, nguồn, danh sách video), `US2` = US-002 (tóm tắt có cấu trúc), `US3` = US-003 (tiến độ, lỗi, xử lý lại).

**Phạm vi**: chỉ P1 theo `plan.md`. US-004..US-009 (P2/P3) không có task; `IVideoAnalyzer`, `content_key` và các cột `input_tokens`/`output_tokens` là chỗ mở rộng.

**Điểm cần người dùng chốt trước khi code** (xem T001, T002):
- Gói NuGet mới (theo `flex-agent-service/AGENTS.md`).
- Bốn điểm lệch giữa `spec.md` và `plan.md`/`data-model.md`: chỉ quản trị viên xem được ở MVP; xử lý do quản trị viên khởi chạy; `video_analyses` chưa có tóm tắt nhanh và transcript dù FR-004/AC-004 yêu cầu; tìm kiếm từ khóa (FR-019, P3) được kéo vào MVP.

---

## Phase 1: Setup (Shared Infrastructure)

**Mục đích**: Chốt các quyết định chặn và dựng khung dự án test, package, cấu hình mẫu.

- [x] T001 Xác nhận với người dùng danh sách gói NuGet mới trước khi thêm (`flex-agent-service/AGENTS.md` cấm thêm gói khi chưa xác nhận): `Hangfire.AspNetCore`, `Hangfire.PostgreSql`, `Google.Apis.Drive.v3`, `Google.Apis.Auth`, `Microsoft.NET.Test.Sdk`, `xunit`, `xunit.runner.visualstudio`. Kết quả kiểm tra được: câu trả lời xác nhận (hoặc danh sách gói bị loại) được ghi lại trong phiên làm việc trước khi chạy T004 và T003. **Quyết định 2026-11-28: người dùng xác nhận đủ 7 gói**; phiên bản chốt ở T004 sau khi kiểm tra tương thích `net9.0`.
- [x] T002 Trình người dùng các điểm lệch cần xác nhận rồi ghi quyết định: (1) DEC-008 chỉ quản trị viên xem được kết quả trong khi US-002 nói "người dùng"; (2) DEC-009 xử lý do quản trị viên bấm khởi chạy trong khi US-002 nói "tự động"; (3) `data-model.md` bảng `video_analyses` chưa có cột tóm tắt nhanh và không lưu transcript, trong khi FR-004, FR-006, AC-004 yêu cầu tóm tắt nhanh (đọc ~30 giây) và transcript có mốc thời gian; (4) tìm kiếm từ khóa là FR-019 (P3) nhưng `plan.md` đưa vào MVP. Kết quả kiểm tra được: với mỗi điểm, người dùng chọn "chấp nhận lệch" hoặc "quay lại `/speckit-plan` sửa"; nếu chọn sửa thì dừng trước T006 (điểm (3) ảnh hưởng schema) và T101. **Quyết định 2026-11-28: người dùng chấp nhận cả 4 điểm lệch**, giữ nguyên `data-model.md` (không có tóm tắt nhanh, không lưu transcript ở MVP).
- [ ] T003 Tạo project xUnit `flex-agent-service/tests/Flex.Agent.Tests/Flex.Agent.Tests.csproj` (tham chiếu `Flex.Agent.Domain`, `Flex.Agent.Application`, `Flex.Agent.Infrastructures`; không thêm thư viện mock) và thêm vào `flex-agent-service/Flex.Agent.sln` (phụ thuộc T001). Kiểm tra: `dotnet build Flex.Agent.sln` thành công.
- [ ] T004 [P] Thêm `PackageReference` `Hangfire.AspNetCore`, `Hangfire.PostgreSql`, `Google.Apis.Drive.v3`, `Google.Apis.Auth` vào `flex-agent-service/src/Flex.Agent.Infrastructures/Flex.Agent.Infrastructures.csproj`, chốt phiên bản tương thích `net9.0` (phụ thuộc T001). Kiểm tra: `dotnet restore Flex.Agent.sln` thành công.
- [ ] T005 [P] Thêm vào `flex-agent-service/src/Flex.Agent.Api/appsettings.Example.json` các khóa chỉ chứa placeholder: `ConnectionStrings:VideoDb`; `VideoKnowledge` (`Enabled=false`, `TempDirectory`, `MaxFileSizeBytes`, `MaxParallelJobs`, `MaxBatchSize`, `WindowMinutes=15`, `MaxAttempts`); `Google` (`ClientId`, `ClientSecret`, `RedirectUri`, `FrontendCallbackBaseUrl`); `Gemini` (`ApiKey`, `Model`, `BaseUrl`, `TimeoutSeconds`). Kiểm tra: không có giá trị thật, chạy `node scripts/speckit-cli.js` không liên quan; hook `secret-guard` không chặn.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Mục đích**: Schema, domain, persistence, cờ tính năng, bộ lọc quyền và khung frontend dùng chung cho cả ba user story.

### Database `videodb` (`flex-database`)

- [ ] T006 [P] Tạo `flex-database/videodb/migrations/V1.1__init_video_tables.sql` với 6 bảng theo mô hình dữ liệu của plan (`drive_connections`, `video_sources`, `videos`, `video_processing_jobs`, `video_analyses`, `video_chapters`), `snake_case`, khóa chính `uuid`, trạng thái `VARCHAR` chữ thường, không khóa ngoại, không `CHECK`; đúng hai chỉ mục duy nhất `ux_videos_connection_file (drive_connection_id, drive_file_id)` và `ux_video_analyses_video_content (video_id, content_key)`, cùng các chỉ mục thường đã liệt kê. Chỉ tạo schema, không chạm `agentdb`/`flexdb`.
- [ ] T007 Tạo `flex-database/videodb/changelog/db.changelog-master.xml` và `flex-database/videodb/changelog/releases/1.0.0/changelog.xml` (changeset `sqlFile` trỏ tới T006, theo đúng mẫu `agentdb`; không `seeders` vì không có seed) (phụ thuộc T006).
- [ ] T008 [P] Tạo `flex-database/videodb/liquibase.properties` theo mẫu `agentdb` nhưng không chứa bí mật (url `jdbc:postgresql://127.0.0.1:5432/videodb`, username/password lấy từ tham số hoặc biến môi trường) và `flex-database/videodb/seeders/.gitkeep`.
- [ ] T009 [P] Tạo `flex-database/scripts/migrate-videodb.sh` và `flex-database/MIGRATE_VIDEODB.cmd` mô phỏng `migrate-agentdb.sh`/`MIGRATE_AGENTDB.cmd`: tự tạo database `videodb` nếu chưa có, chạy `validate` rồi `update`; `DB_PASS` bắt buộc đến từ biến môi trường, không có mật khẩu mặc định trong file.
- [ ] T010 [P] Cập nhật `flex-database/README.md`: thêm `videodb`, lệnh `MIGRATE_VIDEODB.cmd`, và ghi rõ ngoại lệ có chủ đích: schema `hangfire` trong `videodb` do thư viện Hangfire tự quản lý, không nằm trong Liquibase.
- [ ] T011 Kiểm tra migration không ghi vào DB: từ `flex-database/videodb` chạy `liquibase --changelog-file=changelog/db.changelog-master.xml validate` rồi `liquibase --changelog-file=changelog/db.changelog-master.xml update-sql`; rà soát SQL sinh ra chỉ có 6 `CREATE TABLE`, hai chỉ mục duy nhất, không có `FOREIGN KEY`/`CHECK` (phụ thuộc T007, T008). Không cần backward-compatibility check và backfill vì database mới.
- [ ] T012 Với sự cho phép của người dùng, tạo và migrate database dev: `flex-database/MIGRATE_VIDEODB.cmd`; kiểm tra `liquibase history` có changeset `1.0.0` và `\dt` trong `videodb` liệt kê đủ 6 bảng. Nếu schema sai thì sửa bằng changeset mới (forward-fix), không sửa changeset đã chạy (phụ thuộc T011, T009).

### Domain (`flex-agent-service`)

- [ ] T013 [P] Viết test (phải fail trước khi code) `flex-agent-service/tests/Flex.Agent.Tests/Videos/VideoStatusTransitionTests.cs`: các chuyển trạng thái hợp lệ theo spec §8 và mô hình dữ liệu của plan (`pending→downloading→processing→summarizing→indexing→completed`; mọi bước active→`failed`; `pending/downloading→access_denied`; `failed/completed/access_denied→pending`) và từ chối các chuyển không hợp lệ (ví dụ `completed→downloading`, `access_denied→processing`).
- [ ] T014 [P] Tạo `flex-agent-service/src/Flex.Agent.Domain/Videos/VideoStatus.cs`: hằng chuỗi 8 trạng thái chữ thường và bảng quy tắc chuyển trạng thái hợp lệ.
- [ ] T015 [P] Tạo `flex-agent-service/src/Flex.Agent.Domain/Videos/VideoFailureCodes.cs`: hằng `unsupported_language`, `file_too_large`, `download_not_allowed`, `provider_error`, `connection_revoked`.
- [ ] T016 Tạo `flex-agent-service/src/Flex.Agent.Domain/Videos/Video.cs` (kế thừa nền `Entity` trong `Domain/Common`): trường theo `data-model.md`, phương thức chuyển trạng thái dùng T014, `DenyAccess(failureCode)`, `Fail(failureCode)`, `ResetForReprocess()` và `UpdateFromDrive(name, contentKey, durationSeconds, sizeBytes, modifiedAt)` (đổi tên không xóa kết quả; đổi `content_key` chỉ cập nhật khóa). Làm test T013 chuyển xanh (phụ thuộc T013, T014, T015).
- [ ] T017 [P] Tạo `flex-agent-service/src/Flex.Agent.Domain/Videos/DriveConnection.cs`: `AccountEmail`, `EncryptedRefreshToken`, `Status` (`active`/`revoked`), `ConnectedBy`, phương thức `Revoke()` xóa token và `Reconnect(encryptedToken, email)`.
- [ ] T018 [P] Tạo `flex-agent-service/src/Flex.Agent.Domain/Videos/VideoSource.cs`: `DriveFolderId`, `FolderName`, `Status` (`active`/`removed`), `LastSyncedAt`, `Remove()`.
- [ ] T019 [P] Tạo `flex-agent-service/src/Flex.Agent.Domain/Videos/VideoProcessingJob.cs`: `VideoId`, `ContentKey`, `Status`, `Attempt`, `FailureCode`, `HangfireJobId`, `InputTokens`/`OutputTokens` (chỗ sẵn cho P2), `StartedAt`/`FinishedAt`.
- [ ] T020 [P] Tạo `flex-agent-service/src/Flex.Agent.Domain/Videos/VideoAnalysis.cs`: `VideoId`, `ContentKey`, `Summary`, `KeyPoints`, `Tags`, `TopicGroup`, `Difficulty` (`beginner`/`intermediate`/`advanced`), `ModelName`, phương thức ghi đè nội dung khi xử lý lại cùng `ContentKey` (BR-001).
- [ ] T021 [P] Tạo `flex-agent-service/src/Flex.Agent.Domain/Videos/VideoChapter.cs`: `AnalysisId`, `OrderNo`, `StartSeconds`, `EndSeconds`, `Title`, `Summary`, `VisualNotes`.

### Application nền

- [ ] T022 [P] Tạo `flex-agent-service/src/Flex.Agent.Application/Videos/VideoKnowledgeOptions.cs` (POCO thuần: `Enabled`, `TempDirectory`, `MaxFileSizeBytes`, `MaxParallelJobs`, `MaxBatchSize`, `WindowMinutes`, `MaxAttempts`). Đặt ở `Application` thay vì `Infrastructures` như `plan.md` vì các handler `Application` cần đọc `MaxBatchSize` mà `Application` không được tham chiếu `Infrastructures`; việc bind cấu hình vẫn nằm ở `Infrastructures`.
- [ ] T023 [P] Tạo `flex-agent-service/src/Flex.Agent.Application/Videos/VideoKnowledgeException.cs`: ngoại lệ nghiệp vụ mang `Code` thuộc danh sách trong `contracts/video-knowledge-api.md` (`not_connected`, `connection_revoked`, `folder_not_found`, `video_not_found`, `video_in_progress`, `batch_too_large`, `access_denied`) kèm thông điệp tiếng Việt không lộ chi tiết nội bộ hay token.

### Persistence

- [ ] T024 Tạo `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/Persistence/VideoDbContext.cs`: `DbSet` cho 6 thực thể, áp các cấu hình bên dưới; tách biệt hoàn toàn với `AppDbContext` (phụ thuộc T016, T017, T018, T019, T020, T021).
- [ ] T025 [P] Tạo `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/Persistence/Configurations/DriveConnectionConfiguration.cs`, `VideoSourceConfiguration.cs`, `VideoConfiguration.cs`: ánh xạ bảng `snake_case`, độ dài cột theo mô hình dữ liệu của plan, chỉ mục duy nhất `ux_videos_connection_file` và chỉ mục thường `(status)`, `(video_source_id)`, `(drive_connection_id, status)`.
- [ ] T026 [P] Tạo `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/Persistence/Configurations/VideoProcessingJobConfiguration.cs`, `VideoAnalysisConfiguration.cs`, `VideoChapterConfiguration.cs`: ánh xạ `jsonb` cho `key_points`/`tags`, chỉ mục duy nhất `ux_video_analyses_video_content`, chỉ mục thường `(video_id, created_at)` và `(analysis_id, order_no)`.
- [ ] T027 [P] Viết test tích hợp `flex-agent-service/tests/Flex.Agent.Tests/Videos/Persistence/VideoUniqueIndexIntegrationTests.cs` chạy trên PostgreSQL thật, bỏ qua (skip có thông báo) khi thiếu biến môi trường `VIDEODB_TEST_CONNECTION`: chèn hai `videos` cùng `(drive_connection_id, drive_file_id)` phải vi phạm ràng buộc; chèn hai `video_analyses` cùng `(video_id, content_key)` phải vi phạm ràng buộc (BR-001, BR-007).

### Cờ tính năng, DI và quyền

- [ ] T028 [P] Viết test (fail trước) `flex-agent-service/tests/Flex.Agent.Tests/Videos/VideoKnowledgeRegistrationTests.cs`: với `VideoKnowledge:Enabled=false`, `AddVideoKnowledge` không đăng ký `VideoDbContext`, Hangfire hay bất kỳ dịch vụ `Videos` nào và không đòi `ConnectionStrings:VideoDb`; `VideoKnowledgeControllerFeatureProvider` loại `VideoKnowledgeController` khỏi danh sách controller; với `Enabled=true` thì `VideoDbContext` được đăng ký.
- [ ] T029 Tạo `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/VideoKnowledgeServiceCollectionExtensions.cs` với `AddVideoKnowledge(IServiceCollection, IConfiguration)`: bind `VideoKnowledgeOptions`; nếu `Enabled=false` thì trả về ngay không đăng ký gì; nếu bật thì đăng ký `VideoDbContext` dùng `ConnectionStrings:VideoDb` với `UseNpgsql(...).UseSnakeCaseNamingConvention()`. Các story sau bổ sung đăng ký vào chính file này (phụ thuộc T022, T024, T028).
- [ ] T030 [P] Tạo `flex-agent-service/src/Flex.Agent.Api/Extensions/VideoKnowledgeControllerFeatureProvider.cs` (`IApplicationFeatureProvider<ControllerFeature>`) loại `VideoKnowledgeController` khi cờ tắt, để nhóm endpoint chỉ tồn tại khi `Enabled=true`.
- [ ] T031 Sửa `flex-agent-service/src/Flex.Agent.Api/Extensions/ServiceExtensions.cs`, phương thức `AddInfrastructure`: gọi `services.AddVideoKnowledge(configuration)` và đăng ký T030 qua `ConfigureApplicationPartManager`, không đổi đăng ký `AppDbContext` hiện có (phụ thuộc T029, T030). Kiểm tra: test T028 xanh.
- [ ] T032 [P] Viết test (fail trước) `flex-agent-service/tests/Flex.Agent.Tests/Videos/VideoKnowledgeAuthorizationFilterTests.cs`: người dùng chưa đăng nhập hoặc không phải quản trị (`ApplicationAuthorization.CanManage=false`) nhận `403`; quản trị viên đi qua; endpoint đánh dấu `[AllowAnonymous]` được bỏ qua kiểm tra (SEC-002, BR-003).
- [ ] T033 Tạo `flex-agent-service/src/Flex.Agent.Api/Controllers/VideoKnowledgeAuthorizationFilter.cs` (`IAsyncAuthorizationFilter`) gọi `ApplicationAuthorization.CanManage` và tôn trọng `[AllowAnonymous]`; làm test T032 xanh (phụ thuộc T032).
- [ ] T034 Tạo `flex-agent-service/src/Flex.Agent.Api/Controllers/VideoKnowledgeController.cs` (khung): `[ApiController]`, `[Authorize]`, route `api/video-knowledge`, áp T033, inject `ISender`, hàm ánh xạ `VideoKnowledgeException.Code` sang HTTP status và `ErrorResponseDto { Code, Message }` hiện có của service. Các endpoint do từng story thêm (phụ thuộc T023, T033).

### Frontend nền (`flex-microfrontend`)

- [ ] T035 [P] Tạo `flex-microfrontend/src/app/features/video-knowledge/video-knowledge.module.ts` và `video-knowledge-routing.module.ts` mô phỏng `agent-catalog` (import `UIModule`, `SharedModule`, `PaginationModule`, `FormsModule`); chưa khai báo component, các story bổ sung.
- [ ] T036 [P] Tạo `flex-microfrontend/src/app/features/video-knowledge/video-knowledge.config.ts`: bảng nhãn tiếng Việt và màu `app-badge` cho 8 trạng thái, bảng thông điệp dễ hiểu cho `failureCode` (`download_not_allowed`, `file_too_large`, `unsupported_language`, `provider_error`, `connection_revoked`, `access_denied`), hằng chu kỳ polling.

**Checkpoint**: Foundation hoàn tất — bắt đầu triển khai từng User Story.

---

## Phase 3: User Story 1 - Kết nối Google Drive và xem danh sách video (Priority: P1) MVP

**Goal**: Quản trị viên kết nối Drive bằng OAuth chỉ đọc, chọn thư mục nguồn, đồng bộ và thấy danh sách video kèm trạng thái; video không có quyền tải được gắn `access_denied`; kết nối bị thu hồi được báo rõ.  
**Independent Test**: Kết nối tài khoản có thư mục chứa video, chọn thư mục, bấm Đồng bộ: danh sách hiển thị đúng số video, tên, thời lượng, ngày cập nhật, link Drive gốc và trạng thái `pending`; video không có quyền tải là `access_denied`; đồng bộ lần hai không tạo bản ghi trùng.

### Tests / Validation cho User Story 1

- [ ] T037 [P] [US1] Viết test `flex-agent-service/tests/Flex.Agent.Tests/Videos/Connections/DriveOAuthStateTests.cs` với kho state giả: `Start` tạo `state` ngẫu nhiên có hạn dùng và gắn với `sub` quản trị viên; `Complete` từ chối `state` sai, thiếu, hết hạn hoặc đã dùng một lần và khi đó không đổi mã, không lưu token (SEC-001).
- [ ] T038 [P] [US1] Viết test `flex-agent-service/tests/Flex.Agent.Tests/Videos/Connections/CompleteDriveConnectionHandlerTests.cs`: refresh token chỉ được lưu qua `IDriveTokenProtector` (không có dạng rõ trong thực thể), URL xin quyền chỉ chứa scope chỉ đọc của Drive và `access_type=offline` (SEC-003, SEC-004), kết nối lại khi `revoked` thì cập nhật token và đặt `active`.
- [ ] T039 [P] [US1] Viết test `flex-agent-service/tests/Flex.Agent.Tests/Videos/Connections/GetAndDisconnectDriveTests.cs`: `GetDriveConnectionQuery` trả `connected=false` khi chưa kết nối, trả `status=revoked` khi bị thu hồi (AC-003), và view trả về không có thuộc tính nào chứa chữ `token` (SEC-003); `DisconnectDriveCommand` xóa token, đặt `revoked`, giữ dữ liệu video đã có.
- [ ] T040 [P] [US1] Viết test `flex-agent-service/tests/Flex.Agent.Tests/Videos/Sources/VideoSourceHandlersTests.cs`: thêm nguồn hợp lệ → `active`; chưa kết nối → `not_connected`; kết nối `revoked` → `connection_revoked`; thư mục không tồn tại → `folder_not_found`; thêm trùng thư mục không tạo bản ghi thứ hai; gỡ nguồn đặt `removed` và không xóa video, kết quả đã có (FR-001 nhiều thư mục, FR-002).
- [ ] T041 [P] [US1] Viết test `flex-agent-service/tests/Flex.Agent.Tests/Videos/Sync/SyncVideoSourceHandlerTests.cs` với Drive client giả: quét đệ quy cả thư mục con và chỉ nhận file video (AC-001); video mới ở `pending` với tên, thời lượng, ngày cập nhật; lần đồng bộ thứ hai trả `unchanged = số video cũ`, `discovered = 0` và không tạo bản ghi trùng (BR-001); đổi tên hoặc di chuyển → `updated`, cập nhật tên, giữ `id` và kết quả phân tích (BR-007); `content_key` đổi → cập nhật `content_key`; `canDownload=false` → `access_denied` kèm `download_not_allowed` và không đưa vào xử lý (AC-002, FR-003, BR-002); video đang xử lý không bị đổi trạng thái bởi đồng bộ.
- [ ] T042 [P] [US1] Viết test `flex-agent-service/tests/Flex.Agent.Tests/Videos/Sync/SyncConcurrencyAndRevocationTests.cs`: hai lần đồng bộ chạy chồng nhau khi repository trả lỗi trùng khóa duy nhất thì được tính "đã tồn tại" chứ không lỗi và không tạo trùng; Drive trả `invalid_grant` giữa chừng → kết nối chuyển `revoked`, lệnh ném `connection_revoked`, không đồng bộ thêm (AC-003).
- [ ] T043 [P] [US1] Viết test `flex-agent-service/tests/Flex.Agent.Tests/Videos/Queries/GetVideosQueryTests.cs`: phân trang trả `items`, `page`, `pageSize`, `total` đúng; lọc theo `status`; mỗi item có tên, thời lượng, ngày cập nhật, `driveUrl`, trạng thái, `failureCode`; trạng thái rỗng trả danh sách trống chứ không lỗi.
- [ ] T044 [P] [US1] Viết test `flex-agent-service/tests/Flex.Agent.Tests/Videos/Connections/DriveLoggingSafetyTests.cs` với `ILogger` ghi lại thông điệp: chạy `Start`, `Complete`, `Disconnect`, `Sync` với client giả trả token `secret-refresh-token`; khẳng định không dòng log nào chứa token, mã `code`, `client_secret` hay URL có chữ ký (SEC-003, SEC-005 của plan) và có các event `video_connection.connected`, `video_connection.disconnected`, `video_sync.completed` kèm `userId`.
- [ ] T045 [P] [US1] Viết test phản chiếu `flex-agent-service/tests/Flex.Agent.Tests/Videos/VideoKnowledgeControllerPermissionTests.cs`: duyệt mọi action của `VideoKnowledgeController`, chỉ action `callback` có `[AllowAnonymous]`, các action còn lại chịu bộ lọc quản trị (SEC-002, BR-003); test này tự phủ các endpoint story sau thêm vào.
- [ ] T046 [P] [US1] Viết spec `flex-microfrontend/src/app/features/video-knowledge/services/video-knowledge.service.spec.ts` bằng `HttpTestingController`: đường dẫn và phương thức của `getConnection`, `startConnect`, `disconnect`, `listFolders`, `listSources`, `addSource`, `removeSource`, `syncSource`, `getVideos` đều dưới `${environment.agentApiBaseUrl}/api/video-knowledge`.

### Implementation cho User Story 1

- [ ] T047 [US1] Tạo `flex-agent-service/src/Flex.Agent.Application/Videos/Abstractions/IDriveClient.cs` và `flex-agent-service/src/Flex.Agent.Application/Videos/Abstractions/DriveModels.cs`: `BuildAuthorizationUrl(state)`, `ExchangeCodeAsync(code)`, `ListFoldersAsync(connectionId, parentId)`, `GetFolderAsync`, `ListVideosAsync(connectionId, folderId)` đệ quy trả `DriveVideoFile` (id, tên, mime, kích thước, thời lượng, ngày sửa, `ContentKey`, `CanDownload`), `RevokeAsync`, ngoại lệ `DriveConnectionRevokedException`.
- [ ] T048 [P] [US1] Tạo trong `flex-agent-service/src/Flex.Agent.Application/Videos/Abstractions/`: `IDriveTokenProtector.cs` (`Protect`/`Unprotect`), `IDriveConnectionRepository.cs`, `IVideoSourceRepository.cs`.
- [ ] T049 [P] [US1] Tạo `flex-agent-service/src/Flex.Agent.Application/Videos/Abstractions/IVideoRepository.cs` (phương thức cho US1: `FindByDriveFileAsync`, `AddIfNotExistsAsync` trả kết quả "đã tồn tại" khi trùng khóa duy nhất, `UpdateAsync`, `QueryAsync(VideoListFilter)`, `SaveChangesAsync`) và `flex-agent-service/src/Flex.Agent.Application/Videos/Abstractions/IDriveOAuthStateStore.cs` (tạo, đọc và tiêu thụ `state` một lần kèm `sub`). Lưu ý: `IIntegrationSessionStore` hiện có gắn với `agentId` và `channel` của Meta nên không dùng được cho Drive như `plan.md` ghi; dùng kho state riêng đặt trên Redis sẵn có.
- [ ] T050 [P] [US1] Tạo `flex-agent-service/src/Flex.Agent.Application/Videos/Connections/StartDriveConnection/StartDriveConnectionCommand.cs`: tạo `state` qua T049, trả `authorizationUrl` chỉ xin scope chỉ đọc của Drive (SEC-001, SEC-004), log `video_connection.started` không kèm bí mật.
- [ ] T051 [P] [US1] Tạo `flex-agent-service/src/Flex.Agent.Application/Videos/Connections/CompleteDriveConnection/CompleteDriveConnectionCommand.cs`: tiêu thụ `state` một lần, đổi mã lấy token, mã hóa qua `IDriveTokenProtector`, lưu `DriveConnection` `active` kèm email tài khoản; trả outcome `Success`/`InvalidState`/`Error` để controller chuyển hướng; không log token (SEC-003).
- [ ] T052 [P] [US1] Tạo `flex-agent-service/src/Flex.Agent.Application/Videos/Connections/GetDriveConnection/GetDriveConnectionQuery.cs` kèm view `{ connected, accountEmail, status }` không có token.
- [ ] T053 [P] [US1] Tạo `flex-agent-service/src/Flex.Agent.Application/Videos/Connections/DisconnectDrive/DisconnectDriveCommand.cs`: thu hồi token ở Google (lỗi thu hồi không chặn), xóa token đã lưu, đặt `revoked`, log `video_connection.disconnected` kèm `userId`.
- [ ] T054 [P] [US1] Tạo `flex-agent-service/src/Flex.Agent.Application/Videos/Sources/ListDriveFolders/ListDriveFoldersQuery.cs`: duyệt thư mục con theo `parentId`; chưa kết nối → `not_connected`, bị thu hồi → `connection_revoked`.
- [ ] T055 [P] [US1] Tạo `flex-agent-service/src/Flex.Agent.Application/Videos/Sources/AddVideoSource/AddVideoSourceCommand.cs`: kiểm tra kết nối và thư mục tồn tại, tạo `VideoSource` `active`, bỏ qua trùng thư mục, log `video_source.added`.
- [ ] T056 [P] [US1] Tạo `flex-agent-service/src/Flex.Agent.Application/Videos/Sources/ListVideoSources/ListVideoSourcesQuery.cs`.
- [ ] T057 [P] [US1] Tạo `flex-agent-service/src/Flex.Agent.Application/Videos/Sources/RemoveVideoSource/RemoveVideoSourceCommand.cs`: đặt `removed`, không xóa video và kết quả đã có, log `video_source.removed`.
- [ ] T058 [US1] Tạo `flex-agent-service/src/Flex.Agent.Application/Videos/Sync/SyncVideoSource/SyncVideoSourceCommand.cs`: quét đệ quy, chỉ nhận file video; upsert theo `(drive_connection_id, drive_file_id)`; video mới `pending`; đổi tên, di chuyển hoặc `content_key` chỉ cập nhật metadata (BR-007); `CanDownload=false` → `access_denied` + `download_not_allowed` (FR-003, BR-002); không đổi trạng thái video đang xử lý; trùng khóa duy nhất do đồng bộ chồng nhau tính là `unchanged`; `DriveConnectionRevokedException` → đặt kết nối `revoked` rồi ném `connection_revoked` (AC-003); cập nhật `last_seen_at`, `last_synced_at`; trả `{ discovered, updated, unchanged }` và log `video_sync.completed` (phụ thuộc T047, T048, T049).
- [ ] T059 [P] [US1] Tạo `flex-agent-service/src/Flex.Agent.Application/Videos/Queries/GetVideos/GetVideosQuery.cs` kèm `VideoListItemView.cs` và `VideoListFilter`: lọc `status`, phân trang, trả `driveUrl` dựng từ `drive_file_id`. Chưa có `keyword` (thêm ở US3).
- [ ] T060 [P] [US1] Tạo `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/Persistence/DriveConnectionRepository.cs` và `VideoSourceRepository.cs` triển khai các cổng ở T048 trên `VideoDbContext`.
- [ ] T061 [P] [US1] Tạo `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/Persistence/VideoRepository.cs` triển khai phương thức US1 của T049; bắt `PostgresException` mã `23505` trên `ux_videos_connection_file` và dịch thành kết quả "đã tồn tại".
- [ ] T062 [P] [US1] Tạo `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/Security/DriveTokenProtector.cs` bọc `ChannelTokenEncryptionService` (AES-256, khóa `TokenEncryption:Key`) cho refresh token Drive; không tạo cơ chế mã hóa mới.
- [ ] T063 [P] [US1] Tạo `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/Drive/RedisDriveOAuthStateStore.cs` trên Redis hiện có: khóa `video:drive:state:{state}` có TTL ngắn, tiêu thụ nguyên tử một lần.
- [ ] T064 [P] [US1] Tạo `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/Drive/GoogleDriveOptions.cs` (`ClientId`, `ClientSecret`, `RedirectUri`, `FrontendCallbackBaseUrl`) bind từ section `Google`; không có giá trị mặc định chứa bí mật.
- [ ] T065 [P] [US1] Tạo `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/Drive/GoogleDriveClient.Auth.cs` (khai báo `partial class GoogleDriveClient`, constructor, `BuildAuthorizationUrl`, `ExchangeCodeAsync`, `RevokeAsync`, ánh xạ lỗi `invalid_grant` sang `DriveConnectionRevokedException`). Xác minh tên tham số OAuth hiện hành của Google trước khi viết (research TQ-001).
- [ ] T066 [P] [US1] Tạo `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/Drive/GoogleDriveClient.Listing.cs` (`ListFoldersAsync`, `GetFolderAsync`, `ListVideosAsync` đệ quy có phân trang; yêu cầu các trường mã băm hoặc số phiên bản để tính `ContentKey`, `capabilities.canDownload`, thời lượng; xác minh tên trường trên file video thật theo research TQ-005).
- [ ] T067 [US1] Sửa `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/VideoKnowledgeServiceCollectionExtensions.cs`, `AddVideoKnowledge`: đăng ký repository, `DriveTokenProtector`, `RedisDriveOAuthStateStore`, `GoogleDriveClient` dưới `IDriveClient`, bind `GoogleDriveOptions`; kiểm tra MediatR trong `ServiceExtensions.cs` đã quét assembly `Application` để nhận handler `Videos` (phụ thuộc T029, T060, T061, T062, T063, T064, T065, T066).
- [ ] T068 [P] [US1] Tạo `flex-agent-service/src/Flex.Agent.Api/DTOs/Videos/AddVideoSourceRequest.cs` (`driveFolderId` bắt buộc, giới hạn độ dài).
- [ ] T069 [US1] Sửa `flex-agent-service/src/Flex.Agent.Api/Controllers/VideoKnowledgeController.cs`: thêm `POST /connections/drive/connect` (`200 { authorizationUrl }`), `GET /connections/drive/callback` (`[AllowAnonymous]`, bảo vệ bằng `state`, `302` về `{FrontendCallbackBaseUrl}/video-knowledge?connection=success|error`), `GET /connections/drive`, `DELETE /connections/drive` (`204`), chỉ gửi `ISender` (phụ thuộc T034, T050, T051, T052, T053).
- [ ] T070 [US1] Sửa `flex-agent-service/src/Flex.Agent.Api/Controllers/VideoKnowledgeController.cs`: thêm `GET /drive/folders?parentId=`, `POST /sources` (`201`), `GET /sources`, `DELETE /sources/{id}` (`204`), `POST /sources/{id}/sync` (`200 { discovered, updated, unchanged }`) (phụ thuộc T069, T068, T054, T055, T056, T057, T058).
- [ ] T071 [US1] Sửa `flex-agent-service/src/Flex.Agent.Api/Controllers/VideoKnowledgeController.cs`: thêm `GET /videos?status=&page=&pageSize=` trả `{ items, page, pageSize, total }` (phụ thuộc T070, T059).
- [ ] T072 [P] [US1] Tạo `flex-microfrontend/src/app/features/video-knowledge/models/video-knowledge.model.ts`: `DriveConnection`, `DriveFolder`, `VideoSource`, `SyncResult`, `VideoListItem`, `PagedResult<T>`.
- [ ] T073 [US1] Tạo `flex-microfrontend/src/app/features/video-knowledge/services/video-knowledge.service.ts` gọi `${environment.agentApiBaseUrl}/api/video-knowledge`: các phương thức đã nêu ở T046; làm spec đó xanh (phụ thuộc T046, T072).
- [ ] T074 [P] [US1] Tạo component `flex-microfrontend/src/app/features/video-knowledge/components/video-connection-panel/video-connection-panel.component.ts`, `.html`, `.scss`: nút Kết nối/Ngắt kết nối, hiển thị tài khoản và trạng thái; khi `revoked` thì báo cần kết nối lại và không cho đồng bộ (AC-003); đọc `?connection=success|error` để báo kết quả.
- [ ] T075 [P] [US1] Tạo component `flex-microfrontend/src/app/features/video-knowledge/components/video-source-modal/video-source-modal.component.ts`, `.html`, `.scss`: duyệt cây thư mục, hiển thị thông báo rõ nội dung video trong thư mục được chọn sẽ được gửi tới dịch vụ AI bên ngoài (Gemini) và bắt buộc tick xác nhận trước khi chọn (SEC-005, BR-008).
- [ ] T076 [P] [US1] Tạo component `flex-microfrontend/src/app/features/video-knowledge/components/video-list/video-list.component.ts`, `.html`, `.scss`: bảng video (tên, thời lượng, ngày cập nhật, link Drive gốc, trạng thái bằng `app-badge` theo T036), phân trang dùng `PaginationModule`, trạng thái trống kèm hướng dẫn kết nối/chọn nguồn; hiển thị thông báo "Tính năng chưa được bật" khi API trả `404`.
- [ ] T077 [US1] Tạo component trang `flex-microfrontend/src/app/features/video-knowledge/components/video-knowledge-page/video-knowledge-page.component.ts`, `.html`, `.scss` ghép T074, danh sách nguồn kèm nút Đồng bộ/Gỡ, T075 và T076 (phụ thuộc T074, T075, T076, T073).
- [ ] T078 [US1] Khai báo component vào `flex-microfrontend/src/app/features/video-knowledge/video-knowledge.module.ts` và route `''` trong `video-knowledge-routing.module.ts`; thêm route lazy `video-knowledge` trong `flex-microfrontend/src/app/pages/pages-routing.module.ts` và mục menu "Kho tri thức video" trong `flex-microfrontend/src/app/layouts/sidebar/menu.ts` theo mẫu `agent-catalog-module` (phụ thuộc T077, T035).
- [ ] T079 [US1] Validation US1: chạy `dotnet test Flex.Agent.sln --filter "FullyQualifiedName~Videos"` và `npm test -- --watch=false --browsers=ChromeHeadless` (trong `flex-microfrontend`); sau đó làm theo `quickstart.md` mục 1 và bước 1–2: kết nối Drive, chọn 3–5 video mẫu, đồng bộ; xác nhận DB có `drive_connections` với token dạng mã hóa, video `pending`, đồng bộ lần hai `unchanged` đúng và không có bản ghi trùng, đổi tên video rồi đồng bộ giữ nguyên `id`, video tắt quyền tải là `access_denied`; thời gian từ lúc bắt đầu tới khi thấy danh sách đầu tiên dưới 5 phút (SC-001) (phụ thuộc T012, T078, T071).

**Definition of Done (US1)**: Mọi task US1 xong, Independent Test pass, quyền quản trị và validation đầu vào được xử lý, test phản chiếu T045 xanh, không có token trong log hay response, cờ `VideoKnowledge:Enabled=false` vẫn khởi động như cũ.

---

## Phase 4: User Story 2 - Đọc bản tóm tắt có cấu trúc của một video (Priority: P1)

**Goal**: Quản trị viên khởi chạy xử lý một hoặc nhiều video `pending`; hệ thống tải tạm, phân tích lời nói và hình ảnh bằng Gemini theo cửa sổ thời gian, lưu tóm tắt, mục lục có mốc thời gian, kiến thức chính, thẻ, nhóm chủ đề, mức độ; xóa mọi bản sao tạm; mỗi phiên bản nội dung chỉ phân tích một lần.  
**Independent Test**: Với một video mẫu có cả lời nói và slide, bấm Xử lý: trạng thái đi qua `downloading → processing → summarizing → indexing → completed`; trang chi tiết có đủ trường tóm tắt, mốc thời gian mục lục dẫn đúng vị trí, thông tin hình ảnh có mặt; thư mục tạm và file trên Gemini đã được xóa; xử lý lại cùng phiên bản không tạo kết quả thứ hai.

### Tests / Validation cho User Story 2

- [ ] T080 [P] [US2] Viết test `flex-agent-service/tests/Flex.Agent.Tests/Videos/Analysis/AnalysisWindowPlannerTests.cs` và `ChapterNormalizerTests.cs`: video 40 phút với cửa sổ 15 phút cho 3 cửa sổ `0–15`, `15–30`, `30–40` phút; video ngắn hơn một cửa sổ chỉ một lượt; mốc chương tuyệt đối không âm, sắp theo thời gian, không vượt thời lượng video, không chồng lấn; các chương phủ đầu, giữa và cuối video (FR-007, AC-007; SC-003 lệch ≤ 30 giây là kiểm thử thủ công ở task benchmark).
- [ ] T081 [P] [US2] Viết test `flex-agent-service/tests/Flex.Agent.Tests/Videos/Gemini/GeminiResponseParserTests.cs`: JSON đúng schema được đọc đủ tóm tắt, chương, `visualNotes`, thẻ, nhóm chủ đề, mức độ, ngôn ngữ phát hiện, cờ có lời nói; JSON thiếu trường hoặc sai kiểu cho kết quả lỗi `provider_error` không ném ngoại lệ không kiểm soát; giá trị `difficulty` lạ được chuẩn hóa hoặc bỏ trống.
- [ ] T082 [P] [US2] Viết test `flex-agent-service/tests/Flex.Agent.Tests/Videos/Processing/ProcessVideosCommandTests.cs`: vượt `MaxBatchSize` → `batch_too_large` và không xếp hàng video nào; chỉ video `pending` được xếp hàng, các video đang chạy, `completed` cùng `content_key` (BR-001), `access_denied` và video thuộc nguồn đã `removed` hoặc không tồn tại được tính vào `skipped` (BR-008, SEC-005); kết quả `{ queued, skipped }` đúng; mỗi video một job độc lập (NFR-003).
- [ ] T083 [P] [US2] Viết test `flex-agent-service/tests/Flex.Agent.Tests/Videos/Processing/ReprocessVideoCommandTests.cs`: `failed`/`completed`/`access_denied` → `pending` rồi xếp hàng; đang chạy → `video_in_progress` (409); không tồn tại → `video_not_found`; xử lý lại video `completed` cùng `content_key` ghi đè kết quả cũ chứ không tạo bản thứ hai (BR-001).
- [ ] T084 [P] [US2] Viết test `flex-agent-service/tests/Flex.Agent.Tests/Videos/Processing/RunVideoProcessingCommandTests.cs` với Drive client, analyzer, kho file tạm và khóa giả viết tay: đường đi thành công qua đủ 5 trạng thái theo đúng thứ tự và lưu `video_analyses` + `video_chapters`; job chạy lại khi đã có kết quả cùng `(video, content_key)` thì không gọi analyzer lần hai (BR-001, SC-006); `content_key` của video đổi giữa lúc xử lý → bỏ kết quả cũ và đặt lại `pending`; không lấy được khóa theo `video_id` → bỏ qua; khởi động lại giữa chừng (video đang ở `downloading`/`processing` khi job được chạy lại) thì tiếp tục và không tạo kết quả trùng (NFR-003).
- [ ] T085 [P] [US2] Viết test `flex-agent-service/tests/Flex.Agent.Tests/Videos/Processing/RunVideoProcessingFailureTests.cs`: file tạm và file trên dịch vụ phân tích bị xóa trong cả đường thành công, đường lỗi và khi ném ngoại lệ (FR-026); `canDownload=false` khi chạy → `access_denied` + `download_not_allowed`, không thử lại (BR-002, BR-004); vượt `MaxFileSizeBytes` → `failed` + `file_too_large`, không thử lại; ngôn ngữ phát hiện khác tiếng Việt → `failed` + `unsupported_language`, không lưu `video_analyses` (FR-028, BR-010); video không có lời nói nhưng có hình vẫn được tóm tắt, video im lặng và không có hình được ghi nhận "Không có nội dung đáng tóm tắt" ở trạng thái `completed` (spec §6); lỗi tạm thời (mạng, 429, 5xx) ném lại để Hangfire thử lại và tăng `attempt` (AC-009, FR-010); hết `MaxAttempts` → `failed` + `provider_error`; `DriveConnectionRevokedException` → kết nối `revoked`, video `failed` + `connection_revoked`, không thử lại.
- [ ] T086 [P] [US2] Viết test `flex-agent-service/tests/Flex.Agent.Tests/Videos/Queries/GetVideoDetailQueryTests.cs`: trả metadata, trạng thái, `failureCode`, phân tích mới nhất (`summary`, `keyPoints`, `tags`, `topicGroup`, `difficulty`, `chapters` có `orderNo`, `startSeconds`, `endSeconds`, `title`, `summary`, `visualNotes`), `driveUrl` và `contentChanged=true` khi `videos.content_key` khác `content_key` của kết quả hiện hành (FR-008, research TQ-005); không có id → `video_not_found`.
- [ ] T087 [P] [US2] Viết spec `flex-microfrontend/src/app/features/video-knowledge/components/video-detail/video-detail.component.spec.ts` và `flex-microfrontend/src/app/features/video-knowledge/components/video-process-modal/video-process-modal.component.spec.ts`: trang chi tiết hiển thị đủ các trường, định dạng mốc `mm:ss`, mục lục mở link Drive gốc, hiển thị `visualNotes`, cảnh báo và nút Xử lý lại khi `contentChanged`; modal xác nhận hiển thị số video và tổng thời lượng, thông báo gửi tới dịch vụ AI bên ngoài, và báo lỗi `batch_too_large` bằng thông điệp tiếng Việt.
- [ ] T088 [P] [US2] Bổ sung vào `flex-microfrontend/src/app/features/video-knowledge/services/video-knowledge.service.spec.ts` các ca cho `getVideo`, `processVideos`, `reprocess` (URL, phương thức, thân yêu cầu).

### Implementation cho User Story 2

- [ ] T089 [US2] Sửa `flex-agent-service/src/Flex.Agent.Application/Videos/Abstractions/IDriveClient.cs`: thêm `GetFileAsync(connectionId, fileId)` để kiểm tra lại `CanDownload` và kích thước lúc chạy, `OpenDownloadStreamAsync(connectionId, fileId)` trả luồng, ngoại lệ `DriveDownloadNotAllowedException` (phụ thuộc T047).
- [ ] T090 [P] [US2] Tạo `flex-agent-service/src/Flex.Agent.Application/Videos/Abstractions/IVideoAnalyzer.cs` và `flex-agent-service/src/Flex.Agent.Application/Videos/Abstractions/VideoAnalysisModels.cs`: `UploadAsync(filePath)` trả handle, `AnalyzeWindowAsync(handle, startSeconds, endSeconds)` trả ngôn ngữ, cờ có lời nói, tóm tắt cục bộ, chương, `visualNotes`, `MergeAsync(windows)` trả tóm tắt đầy đủ, mục lục, kiến thức chính, thẻ, nhóm chủ đề, mức độ, `DeleteAsync(handle)`, ngoại lệ phân biệt lỗi tạm thời và lỗi vĩnh viễn.
- [ ] T091 [P] [US2] Tạo trong `flex-agent-service/src/Flex.Agent.Application/Videos/Abstractions/`: `IVideoJobScheduler.cs` (xếp hàng job theo `videoId`, `contentKey`), `IVideoProcessingLock.cs` (khóa theo `video_id`), `IVideoTempFileStore.cs` (tạo file tạm từ luồng, hủy file khi dispose).
- [ ] T092 [US2] Sửa `flex-agent-service/src/Flex.Agent.Application/Videos/Abstractions/IVideoRepository.cs`: thêm `GetByIdAsync`, `AddJobAsync`, `UpdateJobAsync`, `SaveAnalysisAsync` (upsert theo `(video_id, content_key)` kèm chương), `GetLatestAnalysisAsync` (phụ thuộc T049).
- [ ] T093 [P] [US2] Tạo `flex-agent-service/src/Flex.Agent.Application/Videos/Analysis/AnalysisWindowPlanner.cs`: chia thời lượng thành các cửa sổ theo `WindowMinutes`; làm test trong T080 chuyển xanh.
- [ ] T094 [P] [US2] Tạo `flex-agent-service/src/Flex.Agent.Application/Videos/Analysis/ChapterNormalizer.cs`: đưa mốc về tuyến tính tuyệt đối, kẹp trong thời lượng, sắp xếp và loại chồng lấn; làm test còn lại trong T080 chuyển xanh.
- [ ] T095 [P] [US2] Tạo `flex-agent-service/src/Flex.Agent.Application/Videos/Processing/ProcessVideos/ProcessVideosCommand.cs`: kiểm tra `MaxBatchSize`, chỉ xếp hàng video `pending` thuộc nguồn `active`, chuyển video sang chờ job qua `IVideoJobScheduler`, trả `{ queued, skipped }`, log `video_job.queued` (phụ thuộc T091, T092).
- [ ] T096 [P] [US2] Tạo `flex-agent-service/src/Flex.Agent.Application/Videos/Processing/ReprocessVideo/ReprocessVideoCommand.cs`: `failed`/`completed`/`access_denied` → `pending` rồi xếp hàng; đang chạy → `video_in_progress`.
- [ ] T097 [US2] Tạo `flex-agent-service/src/Flex.Agent.Application/Videos/Processing/RunVideoProcessing/RunVideoProcessingCommand.cs`: lấy khóa theo `video_id`; bỏ qua nếu đã có kết quả cùng `(video, content_key)`; kiểm tra lại `canDownload` và kích thước (`download_not_allowed`, `file_too_large`); `downloading` → tải luồng ra file tạm; `processing` → tải lên analyzer và phân tích từng cửa sổ; kiểm tra ngôn ngữ chỉ khi có lời nói (`unsupported_language`); `summarizing` → gộp; `indexing` → lưu `video_analyses` và `video_chapters` rồi `completed`; xử lý video im lặng, không có hình hoặc không có lời nói; so lại `content_key` trước khi lưu; xóa file tạm và file trên analyzer trong `finally`; phân loại lỗi tạm thời và vĩnh viễn, tham số `isLastAttempt`; ghi `video_processing_jobs` và log `video_job.started|completed|failed` kèm `videoId`, `jobId`, `status`, `failureCode`, không log nội dung video (phụ thuộc T089, T090, T091, T092, T093, T094, T084, T085).
- [ ] T098 [P] [US2] Tạo `flex-agent-service/src/Flex.Agent.Application/Videos/Queries/GetVideoDetail/GetVideoDetailQuery.cs` kèm `VideoDetailView.cs` theo contract, tính `contentChanged` (phụ thuộc T092).
- [ ] T099 [P] [US2] Tạo `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/Drive/GoogleDriveClient.Download.cs` (partial của T065): `GetFileAsync`, `OpenDownloadStreamAsync` theo luồng, dịch `403` do không có quyền tải thành `DriveDownloadNotAllowedException`.
- [ ] T100 [P] [US2] Tạo `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/Gemini/GeminiOptions.cs` (`ApiKey`, `Model`, `BaseUrl`, `TimeoutSeconds`, độ phân giải/khung hình video) bind từ section `Gemini`; không viết cứng tên model, URL hay bảng giá.
- [ ] T101 [P] [US2] Tạo `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/Gemini/GeminiPrompts.cs`: prompt tiếng Việt và JSON schema phản hồi cố định cho phân tích cửa sổ (ngôn ngữ, cờ có lời nói, tóm tắt, chương kèm mốc, `visualNotes` cho slide, màn hình, văn bản trên hình) và cho lượt gộp chỉ dùng văn bản (tóm tắt đầy đủ, mục lục, kiến thức chính, thẻ, nhóm chủ đề, mức độ); yêu cầu đầu ra tiếng Việt, giữ thuật ngữ kỹ thuật tiếng Anh (BR-010, FR-005).
- [ ] T102 [P] [US2] Tạo `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/Gemini/GeminiResponseParser.cs` bằng `System.Text.Json`; làm T081 chuyển xanh (phụ thuộc T081).
- [ ] T103 [P] [US2] Tạo `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/Gemini/GeminiVideoAnalyzer.Files.cs` (khai báo `partial class GeminiVideoAnalyzer` với typed `HttpClient`, tải file lên dịch vụ file tạm của Gemini, chờ file sẵn sàng, xóa file). Xác minh API Files hiện hành, giới hạn kích thước và thời hạn lưu theo tài liệu chính thức trước khi viết (`research.md` TQ-003).
- [ ] T104 [US2] Tạo `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/Gemini/GeminiVideoAnalyzer.Analysis.cs`: `AnalyzeWindowAsync` dùng offset đầu/cuối của cửa sổ và `MergeAsync` gọi một lượt chỉ văn bản; `429` và `5xx` ném lỗi tạm thời, `4xx` khác ném lỗi vĩnh viễn `provider_error`; không log nội dung hay khóa API (phụ thuộc T101, T102, T103, T100).
- [ ] T105 [P] [US2] Tạo `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/Jobs/VideoTempFileStore.cs` (ghi luồng vào `TempDirectory`, xóa khi dispose, từ chối vượt `MaxFileSizeBytes`) và `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/Jobs/PostgresVideoProcessingLock.cs` (khóa tư vấn PostgreSQL theo `video_id`).
- [ ] T106 [P] [US2] Sửa `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/Persistence/VideoRepository.cs`: triển khai các phương thức mới của T092; `SaveAnalysisAsync` ghi đè theo `ux_video_analyses_video_content`, thay toàn bộ chương của kết quả đó trong một giao dịch.
- [ ] T107 [P] [US2] Tạo `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/Jobs/VideoProcessingHangfireJob.cs` (điểm vào Hangfire gọi `RunVideoProcessingCommand`, giới hạn thử lại theo `MaxAttempts`, truyền `isLastAttempt` từ số lần thử của Hangfire) và `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/Jobs/HangfireVideoJobScheduler.cs` triển khai `IVideoJobScheduler`.
- [ ] T108 [US2] Sửa `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/VideoKnowledgeServiceCollectionExtensions.cs`, `AddVideoKnowledge`: cấu hình Hangfire dùng PostgreSQL `ConnectionStrings:VideoDb` với schema `hangfire`, `AddHangfireServer` với `WorkerCount = MaxParallelJobs`, typed `HttpClient` cho Gemini, đăng ký analyzer, kho file tạm, khóa, scheduler (phụ thuộc T067, T099, T104, T105, T106, T107).
- [ ] T109 [P] [US2] Tạo `flex-agent-service/src/Flex.Agent.Api/DTOs/Videos/ProcessVideosRequest.cs` (`videoIds` không rỗng, tối đa theo cấu hình).
- [ ] T110 [US2] Sửa `flex-agent-service/src/Flex.Agent.Api/Controllers/VideoKnowledgeController.cs`: thêm `POST /videos/process` (`202 { queued, skipped }`), `POST /videos/{id}/reprocess` (`202`, `409` khi `video_in_progress`), `GET /videos/{id}` (`200`/`404`) (phụ thuộc T071, T095, T096, T098, T109).
- [ ] T111 [P] [US2] Sửa `flex-microfrontend/src/app/features/video-knowledge/models/video-knowledge.model.ts`: thêm `VideoDetail`, `VideoAnalysis`, `VideoChapter`, `ProcessResult`.
- [ ] T112 [US2] Sửa `flex-microfrontend/src/app/features/video-knowledge/services/video-knowledge.service.ts`: thêm `getVideo`, `processVideos`, `reprocess`; làm T088 xanh (phụ thuộc T073, T111, T088).
- [ ] T113 [P] [US2] Tạo component `flex-microfrontend/src/app/features/video-knowledge/components/video-detail/video-detail.component.ts`, `.html`, `.scss`: tóm tắt, kiến thức chính, thẻ, nhóm chủ đề, mức độ, mục lục có mốc `mm:ss`, `visualNotes`, link Drive gốc; chọn một mục mở link Drive gốc kèm mốc thời gian (kiểm tra Drive có hỗ trợ tham số thời gian không; nếu không thì hiển thị mốc cạnh link) (AC-005); cảnh báo và nút Xử lý lại khi `contentChanged`.
- [ ] T114 [P] [US2] Tạo component `flex-microfrontend/src/app/features/video-knowledge/components/video-process-modal/video-process-modal.component.ts`, `.html`, `.scss`: xác nhận số video và tổng thời lượng sắp xử lý, nhắc nội dung sẽ gửi tới dịch vụ AI bên ngoài, gọi `processVideos`, hiển thị `queued`/`skipped` và lỗi `batch_too_large`.
- [ ] T115 [US2] Sửa `flex-microfrontend/src/app/features/video-knowledge/components/video-list/video-list.component.ts` và `video-list.component.html`: ô chọn video `pending`, nút Xử lý mở T114, liên kết tới trang chi tiết, polling theo chu kỳ trong T036 khi còn video ở trạng thái đang xử lý và dừng khi rời trang (phụ thuộc T076, T114, T112).
- [ ] T116 [US2] Khai báo T113 và T114 trong `flex-microfrontend/src/app/features/video-knowledge/video-knowledge.module.ts` và thêm route `:id` trong `video-knowledge-routing.module.ts` (phụ thuộc T078, T113, T114).
- [ ] T117 [US2] Validation US2: chạy `dotnet test Flex.Agent.sln --filter "FullyQualifiedName~Videos"` và `npm test -- --watch=false --browsers=ChromeHeadless`; điền `Gemini:ApiKey`, `ConnectionStrings:VideoDb` bằng user-secrets/biến môi trường rồi làm theo `quickstart.md` bước 3–4 và các tình huống biên: xử lý 1 video mẫu có slide, xác nhận trạng thái đi đúng thứ tự, trang chi tiết đủ trường; xử lý lại video đang chạy trả `409`; video không phải tiếng Việt `failed/unsupported_language`; video vượt kích thước `failed/file_too_large`; sau mỗi lần xử lý thư mục `TempDirectory` rỗng và file trên Gemini đã xóa (FR-026); `SELECT count(*) FROM video_analyses` không đổi sau khi xử lý lại cùng phiên bản (SC-006) (phụ thuộc T108, T110, T116, T079).

**Definition of Done (US2)**: Mọi task US2 xong, Independent Test pass, lỗi tạm thời và lỗi quyền được xử lý riêng, không log token, API key hay nội dung video, không để lại file tạm, luồng US1 không bị gãy.

---

## Phase 5: User Story 3 - Theo dõi tiến độ xử lý và xử lý lỗi (Priority: P1)

**Goal**: Quản trị viên thấy tổng số video và số lượng theo từng trạng thái, nguyên nhân dễ hiểu của video lỗi, và yêu cầu xử lý lại; tìm video theo từ khóa trên tên, tóm tắt và thẻ (phần kéo từ P3 theo `plan.md`).  
**Independent Test**: Đưa vào một lô gồm video bình thường, video không có quyền tải và video hỏng: màn tổng quan hiển thị đúng tổng và số theo 8 trạng thái; video lỗi cho thấy nguyên nhân tiếng Việt và nút Xử lý lại; gõ từ khóa có trong tóm tắt thì video xuất hiện trong kết quả.

### Tests / Validation cho User Story 3

- [ ] T118 [P] [US3] Viết test tích hợp `flex-agent-service/tests/Flex.Agent.Tests/Videos/Persistence/VideoKeywordSearchIntegrationTests.cs` (PostgreSQL thật, skip khi thiếu `VIDEODB_TEST_CONNECTION`): `keyword` khớp không phân biệt hoa thường trên tên video, `summary` và `tags`; ký tự `%`, `_`, `\` trong từ khóa được thoát chứ không hoạt động như wildcard; kết hợp `keyword` với `status` và phân trang cho `total` đúng; video chưa có phân tích vẫn tìm được theo tên.
- [ ] T119 [P] [US3] Viết spec `flex-microfrontend/src/app/features/video-knowledge/components/video-overview/video-overview.component.spec.ts`: hiển thị tổng số và số lượng cho đủ 8 trạng thái với nhãn tiếng Việt, một lời gọi thất bại không làm vỡ toàn bộ khối, cập nhật lại khi danh sách polling đổi (AC-008).
- [ ] T120 [P] [US3] Viết spec `flex-microfrontend/src/app/features/video-knowledge/components/video-list/video-list.component.spec.ts`: ô tìm kiếm gửi `keyword` sau debounce, lọc theo trạng thái, hiển thị nguyên nhân lỗi tiếng Việt từ `failureCode`, nút Xử lý lại chỉ có ở `failed` và `access_denied`, `409` hiện thông báo video đang xử lý, trạng thái trống khi chưa có nguồn và khi không có kết quả (AC-010, spec §6).

### Implementation cho User Story 3

- [ ] T121 [US3] Sửa `flex-agent-service/src/Flex.Agent.Application/Videos/Queries/GetVideos/GetVideosQuery.cs` (thêm `Keyword` vào `VideoListFilter`), `flex-agent-service/src/Flex.Agent.Application/Videos/Abstractions/IVideoRepository.cs` (chữ ký `QueryAsync`) và `flex-agent-service/src/Flex.Agent.Infrastructures/Videos/Persistence/VideoRepository.cs`, phương thức `QueryAsync`: lọc `ILIKE` đã thoát wildcard trên `videos.name`, `video_analyses.summary` và `tags` (jsonb ép về text, xác minh cú pháp EF Core khi implement); làm T118 xanh (phụ thuộc T118, T059, T106).
- [ ] T122 [US3] Sửa `flex-agent-service/src/Flex.Agent.Api/Controllers/VideoKnowledgeController.cs`, action `GET /videos`: nhận thêm tham số `keyword` và chuyển vào truy vấn (phụ thuộc T110, T121).
- [ ] T123 [US3] Sửa `flex-microfrontend/src/app/features/video-knowledge/services/video-knowledge.service.ts`: thêm tham số `keyword` cho `getVideos` và `getStatusCounts()` gọi song song `GET /videos?status={s}&pageSize=1` cho từng trạng thái trong 8 trạng thái, lấy `total` (dùng đúng contract hiện có, không thêm endpoint đếm) (phụ thuộc T112).
- [ ] T124 [P] [US3] Tạo component `flex-microfrontend/src/app/features/video-knowledge/components/video-overview/video-overview.component.ts`, `.html`, `.scss`: tổng số video và số theo 8 trạng thái bằng `app-badge`; làm T119 xanh (phụ thuộc T119, T123).
- [ ] T125 [US3] Sửa `flex-microfrontend/src/app/features/video-knowledge/components/video-list/video-list.component.ts` và `video-list.component.html`: ô tìm kiếm có debounce, bộ lọc trạng thái, cột nguyên nhân lỗi dùng thông điệp từ T036, nút Xử lý lại cho `failed` và `access_denied` (xử lý `409`); làm T120 xanh (phụ thuộc T120, T115, T123).
- [ ] T126 [US3] Sửa `flex-microfrontend/src/app/features/video-knowledge/components/video-knowledge-page/video-knowledge-page.component.ts` và `.html`: thêm khối T124 phía trên danh sách, dùng chung một chu kỳ polling để làm mới cả tổng quan lẫn danh sách (phụ thuộc T077, T124, T125).
- [ ] T127 [US3] Khai báo T124 trong `flex-microfrontend/src/app/features/video-knowledge/video-knowledge.module.ts` (phụ thuộc T116, T124).
- [ ] T128 [US3] Validation US3: chạy `dotnet test Flex.Agent.sln --filter "FullyQualifiedName~Videos"` và `npm test -- --watch=false --browsers=ChromeHeadless`; làm theo `quickstart.md` bước 5 và mục 3: tạo lô gồm video bình thường, video tắt quyền tải và file hỏng; xác nhận số theo trạng thái khớp truy vấn `SELECT status, count(*) FROM videos GROUP BY status`, video lỗi hiện nguyên nhân tiếng Việt và Xử lý lại chạy được sau khi khắc phục, từ khóa trong tóm tắt, trong thẻ và trong tên đều tìm ra video (phụ thuộc T122, T127, T117).

**Definition of Done (US3)**: Mọi task US3 xong, Independent Test pass, `keyword` không gây lỗi hay wildcard ngoài ý muốn, không làm gãy US1/US2.

---

## Final Phase: Polish & Cross-Cutting Concerns

- [ ] T129 [P] Cập nhật `docs/architecture/system-map.md`: mục "5. Data Architecture" thêm database `videodb` (migration ở `flex-database/videodb/`, schema `hangfire` do Hangfire quản lý) và mục "4. Projects" ghi module Video Knowledge nằm trong `flex-agent-service`, kèm cờ `VideoKnowledge:Enabled`. Đây là cập nhật còn lại theo `plan.md` mục "Tác động tài liệu nghiệp vụ". `docs/business/14-ai-video-knowledge-base.md` chỉ sửa nếu người dùng xác nhận khác đi ở T002.
- [ ] T130 Rà soát log: chạy `git grep -n -E "Log(Information|Warning|Error|Debug|Critical)" -- flex-agent-service/src/Flex.Agent.Application/Videos flex-agent-service/src/Flex.Agent.Infrastructures/Videos` và xác nhận không câu log nào chứa token, `client_secret`, API key Gemini, `TokenEncryption:Key`, chuỗi kết nối, nội dung video, URL tải có chữ ký hay tiêu đề `Authorization`; mọi event dùng tên `video_*` theo `plan.md` (SEC-003, SEC-005).
- [ ] T131 Kiểm tra chéo quyền: gọi từng endpoint trong `contracts/video-knowledge-api.md` bằng JWT của người dùng không phải quản trị và khi không có JWT; mọi endpoint trừ `callback` trả `403`/`401`; `callback` với `state` sai chuyển hướng `?connection=error`; không phản hồi nào chứa token (SEC-001, SEC-002, BR-003) (phụ thuộc T128).
- [ ] T132 Hồi quy khi cờ tắt: đặt `VideoKnowledge:Enabled=false` và không cấu hình `ConnectionStrings:VideoDb`, chạy `dotnet run --project src/Flex.Agent.Api/Flex.Agent.Api.csproj` trong `flex-agent-service`; xác nhận service khởi động như cũ, endpoint hiện có hoạt động, `GET /api/video-knowledge/videos` trả `404`.
- [ ] T133 Đo NFR-002: nạp 500 dòng `videos` mẫu vào `videodb` dev bằng SQL, đo `GET /api/video-knowledge/videos` và `GET /api/video-knowledge/videos/{id}` bằng `curl -w "%{time_total}"`; mỗi lời gọi dưới 3 giây (có `keyword` và không có `keyword`).
- [ ] T134 Chạy `dotnet build Flex.Agent.sln` và `dotnet test Flex.Agent.sln` trong `flex-agent-service`; chạy `npm run build` và `npm test -- --watch=false --browsers=ChromeHeadless` trong `flex-microfrontend`; mọi lệnh thoát với mã 0.
- [ ] T135 Đánh giá bộ video mẫu 20–30 video theo `quickstart.md`: kiểm tra SC-002 (đọc tóm tắt video 60 phút trong ≤ 5 phút), SC-003 (≥ 90% ý chính, mốc mục lục lệch ≤ 30 giây), SC-004 (≥ 80% nội dung chỉ có trên hình xuất hiện), SC-008 (chi phí AI trên mỗi giờ video, đọc từ mức dùng token do Gemini trả về), NFR-001 (90% video dưới 60 phút hoàn tất trong 30 phút); cần người dùng cung cấp bộ video và chấp thuận chi phí AI trước khi chạy, ghi kết quả vào PR (phụ thuộc T128).
- [ ] T136 Chạy lại toàn bộ `quickstart.md` mục 2 và mục 3 trên môi trường dev sau khi mọi story xong, ghi rõ bước nào đạt hoặc chưa kiểm chứng; nếu việc gửi log tới backend tập trung chưa được truy vấn thật thì báo "đã cấu hình, chưa kiểm chứng" theo `plan.md` (phụ thuộc T134, T132).

---

## Validation Commands

- **Build**: `dotnet build Flex.Agent.sln` (trong `flex-agent-service`); `npm run build` (trong `flex-microfrontend`).
- **Tests**: `dotnet test Flex.Agent.sln` (trong `flex-agent-service`; test PostgreSQL cần `VIDEODB_TEST_CONNECTION`); `npm test -- --watch=false --browsers=ChromeHeadless` (trong `flex-microfrontend`).
- **Migration**: `liquibase --changelog-file=changelog/db.changelog-master.xml validate` và `update-sql` (trong `flex-database/videodb`); `flex-database/MIGRATE_VIDEODB.cmd` chỉ chạy khi người dùng cho phép.
- **Quickstart / Smoke check**: `specs/000043-ai-video-knowledge-base/quickstart.md`, mục 1–4.

---

## Traceability Matrix

| Nguồn (`MVP` / `US` / `FR` / `AC` / `BR` / `SEC` / `NFR`) | Covered by Task IDs |
|---|---|
| MVP-001 | T050, T051, T058, T077 |
| MVP-002 | T097, T104, T101 |
| MVP-003 | T076, T113, T124, T098 |
| MVP-004 | T097, T084, T085, T107 |
| US-001 / AC-001 | T041, T058, T066, T076, T079 |
| US-001 / AC-002 | T041, T058, T085, T097 |
| US-001 / AC-003 | T039, T042, T058, T052, T074 |
| US-002 / AC-004 | T086, T098, T113 (tóm tắt nhanh và transcript: xem T002) |
| US-002 / AC-005 | T087, T113 |
| US-002 / AC-006 | T101, T081, T085, T113 |
| US-002 / AC-007 | T080, T093, T094, T135 |
| US-003 / AC-008 | T119, T123, T124, T128 |
| US-003 / AC-009 | T085, T097, T107 |
| US-003 / AC-010 | T120, T125, T083, T096 |
| FR-001 (kết nối OAuth; chọn một hoặc nhiều thư mục) | T037, T038, T040, T050, T051, T055, T065 |
| FR-002 (liệt kê đệ quy kèm tên, thời lượng, ngày cập nhật, link, trạng thái) | T041, T043, T058, T059, T076 |
| FR-003 (kiểm tra quyền tải, gắn `access_denied` kèm lý do) | T041, T058, T085, T097, T099 |
| FR-004 (bộ thông tin tiếng Việt) | T086, T098, T101, T002 |
| FR-005 (lời nói và hình ảnh) | T101, T104, T081 |
| FR-006 (mốc thời gian) | T080, T094, T113 |
| FR-007 (bao quát video dài) | T080, T093, T104 |
| FR-008 (phiên bản nội dung) | T086, T098, T113 |
| FR-009 (8 trạng thái và số liệu tổng hợp) | T013, T016, T036, T124 |
| FR-010 (thử lại có giới hạn; lỗi quyền không thử lại) | T085, T097, T107 |
| FR-011 (nguyên nhân dễ hiểu; xử lý lại) | T120, T125, T083, T096, T110 |
| FR-026 (không giữ bản sao video) | T085, T097, T105, T117 |
| FR-028 (ngôn ngữ không phải tiếng Việt) | T085, T097, T101 |
| FR-019 (chỉ phần từ khóa kéo vào MVP theo `plan.md`) | T118, T121, T122, T125 |
| BR-001 (xử lý tối đa một lần mỗi phiên bản) | T027, T041, T084, T083, T106 |
| BR-002 (chỉ xử lý khi có quyền tải) | T041, T085, T097 |
| BR-003 (quyền xem: chỉ quản trị ở MVP) | T032, T033, T045, T131, T002 |
| BR-004 (lỗi tạm thời thử lại; lỗi quyền và dữ liệu không) | T085, T097 |
| BR-006 (nhận định truy ngược về mốc thời gian) | T080, T094, T113 |
| BR-007 (đổi tên không mất kết quả) | T041, T058, T016 |
| BR-008 (chỉ gửi AI với thư mục đã chọn) | T075, T082, T095 |
| BR-010 (chỉ tiếng Việt) | T085, T101, T097 |
| SEC-001 (kiểm tra quyền, `state` OAuth) | T037, T032, T063, T131 |
| SEC-002 (quyền theo người dùng; ở MVP chỉ quản trị) | T032, T045, T033, T131 |
| SEC-003 (bảo vệ thông tin xác thực) | T038, T039, T044, T062, T130 |
| SEC-004 (quyền Drive tối thiểu) | T038, T050, T065 |
| SEC-005 (thông báo trước khi gửi AI ngoài) | T075, T114, T082 |
| NFR-001 | T108, T135 |
| NFR-002 | T133, T043 |
| NFR-003 (lỗi một video không dừng video khác; khởi động lại không mất tiến độ) | T082, T084, T107, T108 |
| Data model, migration, rollback | T006, T007, T011, T012, T027 |
| Contract `/api/video-knowledge/*` (13 endpoint) | T069, T070, T071, T110, T122, T045 |
| Feature flag `VideoKnowledge:Enabled` và rollback | T028, T029, T030, T031, T132 |
| Observability và danh mục cấm log | T044, T097, T130 |
| Tài liệu hệ thống (`plan.md` mục Tác động tài liệu nghiệp vụ) | T129 |
| SC-001 | T079 |
| SC-002, SC-003, SC-004, SC-008 | T135 |
| SC-005 | T085, T128 |
| SC-006 | T084, T083, T117 |
| SC-007 | T131 (ở MVP chỉ quản trị viên xem được; kiểm thử đa tài khoản theo quyền Drive thuộc P2) |

---

## Dependencies & Parallel Opportunities

- **Thứ tự Phase**: `Setup` → `Foundational` → `US1` → `US2` → `US3` → `Polish`. US2 cần danh sách video và kết nối Drive của US1; US3 cần endpoint danh sách của US1 và `reprocess` của US2.
- **Chặn bởi quyết định người dùng**: T001 chặn T003 và T004 (nên mọi test C#); T002 có thể buộc quay lại `/speckit-plan` và sửa `data-model.md` trước T006.
- **Song song (`[P]`) trong Foundational**: cụm DB (T006, T008, T009, T010); cụm domain (T014, T015, T017, T018, T019, T020, T021); cụm frontend nền (T035, T036).
- **File tổng hợp dùng chung, nên các task sửa chúng là tuần tự, không `[P]`**: `VideoKnowledgeController.cs` (T034 → T069 → T070 → T071 → T110 → T122); `VideoKnowledgeServiceCollectionExtensions.cs` (T029 → T067 → T108); `IVideoRepository.cs` và `VideoRepository.cs` (T049 → T092 → T121); `video-knowledge.module.ts` (T078 → T116 → T127); `video-knowledge.service.ts` (T073 → T112 → T123); `video-list.component.*` (T076 → T115 → T125).
- **Song song trong US1**: toàn bộ test T037…T046; các handler T050…T057 và T059; cụm hạ tầng T060…T066; ba component frontend T074, T075, T076.
- **Song song trong US2**: toàn bộ test T080…T088; T093 với T094; T099, T100, T101, T102, T103, T105, T106, T107; T113 với T114.
- **Song song trong US3**: ba test T118, T119, T120.

---

## Checklist chất lượng trước khi implement

- [ ] Không còn placeholder (`[FeatureName]`, `[Entity]`, `TXXX`) hay story giả định ngoài `spec.md`.
- [ ] Mọi task có ID tuần tự từ `T001`, có file path cụ thể (kèm tên class/method nếu sửa file cũ) hoặc command cụ thể.
- [ ] Không có hai task `[P]` cùng phase sửa chung một file; các phụ thuộc đã ghi rõ `(phụ thuộc T###)`.
- [ ] Mỗi User Story có `Independent Test`, `Definition of Done`, và test/validation task phủ rủi ro trong `plan.md`.
- [ ] `Traceability Matrix` đã phủ đủ `MVP`/`US`/`FR`/`BR`/`SEC`/`NFR` của phạm vi P1 (kể cả từng vế của FR đa điều kiện).
