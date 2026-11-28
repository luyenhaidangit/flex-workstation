# Kế hoạch triển khai: AI Video Knowledge Base

**Branch**: `000043-ai-video-knowledge-base` | **Ngày**: 2026-11-27 | **Chế độ Spec**: Full | **Đặc tả**: [spec.md](./spec.md)  
**Đầu vào**: `/specs/000043-ai-video-knowledge-base/spec.md` và phạm vi repo tại [repos.md](./repos.md)

## Tóm tắt

- **Yêu cầu chính từ spec**: Phạm vi MVP (P1) gồm US-001 (kết nối Google Drive và chọn thư mục), US-002 (tự động tạo tóm tắt có mục lục/mốc thời gian/thông tin hình ảnh), US-003 (theo dõi tiến độ, nguyên nhân lỗi và xử lý lại), cùng FR-001–FR-011, FR-026, FR-028, BR, SEC, NFR liên quan. Ngoài ra MVP kéo sớm phần tìm theo từ khóa trên tên, `summary`, `tags` (spec xếp là FR-019, P3) để duyệt kho; đây là điểm lệch đã được chấp nhận ở mục Câu hỏi kỹ thuật. P2 (cập nhật tự động, đối chiếu quyền, chi phí) và P3 (vector, RAG, phân tích sâu) chỉ để sẵn chỗ mở rộng.
- **Hướng tiếp cận kỹ thuật**: Thêm vertical slice `Videos` vào `flex-agent-service` (.NET 9, MediatR, Hangfire chạy cùng host, `VideoDbContext` trên database riêng `videodb`), tích hợp Google Drive (OAuth chỉ đọc, refresh token mã hóa) và Gemini qua cổng `IVideoAnalyzer`; migration Liquibase ở `flex-database/videodb/`; giao diện Angular `video-knowledge` trong `flex-microfrontend` theo mẫu `agent-catalog`. Toàn bộ nằm sau cờ `VideoKnowledge:Enabled`.
- **Kết quả research**: [research.md](./research.md) chốt TQ-001…TQ-014; không còn câu hỏi chặn thiết kế. Các điểm `Xác minh khi implement` (API Drive/Gemini hiện hành, phiên bản gói) không đổi kiến trúc.

## Phạm vi kỹ thuật

- **Trong phạm vi**: `flex-agent-service` (Domain/Application/Infrastructures/Api + project test mới), `flex-database` (`videodb`), `flex-microfrontend` (module `video-knowledge`, route, menu) — đúng [repos.md](./repos.md).
- **Ngoài phạm vi kỹ thuật**: Đồng bộ tự động/Changes API, đối chiếu quyền theo từng người dùng, giới hạn và theo dõi chi phí, Whisper/FFmpeg/keyframe, pgvector và RAG, SignalR realtime, route qua `flex-api-gateway`, manifest `flex-k8s`/`flex-environment`.

## Bối cảnh kỹ thuật

- **Ngôn ngữ / Framework**: C# / .NET 9, ASP.NET Core, MediatR 12.5, EF Core 9 + Npgsql; Angular 16 (Skote/Bootstrap 5).
- **Service / Repo liên quan**: `flex-agent-service` (Edit), `flex-database` (Edit), `flex-microfrontend` (Edit); các repo khác Skip.
- **Convention skill áp dụng**: `flex-agent-service` → `flex-dotnet-engineering`, `flex-codebase-architect`, `flex-naming-convention`; `flex-database` → `flex-database-engineering`; `flex-microfrontend` → `flex-frontend-engineering`; phạm vi repo → `flex-repo-scope`.
- **Lưu trữ & Phụ thuộc chính**: PostgreSQL `videodb` (dữ liệu + schema `hangfire`), Redis (đã có, lưu `state` OAuth), Google Drive API, Gemini API.
- **Kiểm thử & Đơn vị deploy**: xUnit (project `tests/Flex.Agent.Tests` mới), Karma hiện có ở frontend; deploy cùng container `flex-agent-service`, không có worker riêng.
- **Mục tiêu hiệu năng & Ràng buộc**: dưới 500 video (NFR); mốc chương lệch ≤ 30 giây (SC-003); không giữ bản sao video lâu dài (FR-026); số job song song và kích thước tối đa cấu hình được.

## Kiểm tra constitution

*GATE: Đánh giá trước Phase 0 và xác nhận lại sau Phase 1 design.*

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú / Dẫn chứng |
|------|--------------------|-----------------------|---------------------|
| Scope & Traceability Gate | Pass | Pass | Bảng traceability bên dưới phủ US-001..003, FR-001..011/026/028, BR, SEC, NFR; P2/P3 ghi rõ ngoài phạm vi |
| Test & Security Gate | Pass | Pass | Test quyền quản trị, mã hóa token, dọn file tạm, chuyển trạng thái; SEC-001..005 có biện pháp ở mục Permission/Observability |
| Compatibility & DB Placement (VI) | Pass | Pass | `videodb` + `flex-database/videodb/` theo tiền lệ `agentdb` (`system-map.md`, xác nhận 2026-08-01); không đổi `agentdb`/`flexdb`; hành vi cũ không đổi nhờ cờ cấu hình tắt mặc định |
| Observability & Complexity Gate | Pass | Pass có ghi chú | Serilog/ECS theo `SeriLogger`, không log token/nội dung video; tính phức tạp: xem mục Theo dõi độ phức tạp |
| Specialist Skill Gate | Pass | Pass | Đã áp dụng các skill nêu ở Bối cảnh kỹ thuật |

## Câu hỏi kỹ thuật & Quyết định thiết kế

Chi tiết lý do và phương án loại ở [research.md](./research.md).

| Mã | Vấn đề / Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại |
|----|---------------------|----------|------------|-------------------|
| DEC-001 | Vị trí mã nguồn | Slice `Videos` trong `flex-agent-service` | Người dùng chọn; tái dùng OAuth, mã hóa token, JWT, logging | Repo mới (khuyến nghị ban đầu của agent, bị người dùng không chọn) |
| DEC-002 | Database | `videodb` riêng, migration ở `flex-database/videodb/` | Tiền lệ `agentdb`, Hiến pháp VI | Dùng chung agentdb/flexdb |
| DEC-003 | Job nền | Hangfire in-process, lưu PostgreSQL schema `hangfire` | Người dùng chọn; không thêm hạ tầng | Redis, bảng tự viết, RabbitMQ |
| DEC-004 | Phân tích video | `IVideoAnalyzer` + Gemini qua `HttpClient`, JSON schema cố định | Không phụ thuộc SDK chưa xác minh; seam cho Whisper sau này | SDK cộng đồng, `Microsoft.Extensions.AI` |
| DEC-005 | Video dài | Cửa sổ 15 phút + gộp một lượt văn bản | Tránh cắt đầu ra, bao quát toàn video | Một lượt duy nhất |
| DEC-006 | Idempotency | `content_key` (hash Drive hoặc revision), duy nhất theo (video, content_key) | BR-001, BR-007 | Tự băm file, dùng modified time |
| DEC-007 | Lưu video | Tải luồng ra file tạm, xóa trong `finally` | FR-026 | Lưu MinIO |
| DEC-008 | Phân quyền MVP | Chỉ quản trị viên | BR-003 chưa có cơ chế đối chiếu → mặc định an toàn | Mở cho mọi user đã đăng nhập |
| DEC-009 | Khởi chạy xử lý | Quản trị viên chủ động bấm; có trần số video mỗi lần | Chưa có chặn chi phí ở MVP | Tự xử lý toàn thư mục khi đồng bộ |
| DEC-010 | Route | Frontend gọi trực tiếp `agentApiBaseUrl` | Khớp `agent-catalog` | Qua gateway |

**Bốn điểm lệch so với spec — người dùng đã chấp nhận ngày 2026-11-28** (xem `tasks.md` T002): (1) ở MVP chỉ quản trị viên xem được tóm tắt, dù US-002 nói "người dùng" (DEC-008); (2) "tự động tạo tóm tắt" áp dụng cho pipeline sau khi quản trị viên khởi chạy, không phải ngay khi đồng bộ thấy video mới (DEC-009); (3) `video_analyses` chưa có tóm tắt nhanh và MVP không lưu transcript, dù FR-004, FR-006, AC-004 yêu cầu; (4) tìm theo từ khóa (FR-019, P3) được kéo vào MVP. (1) và (2) là hệ quả của việc P2 (đối chiếu quyền, chặn chi phí) nằm ngoài MVP; (3) và (4) giữ nguyên `data-model.md`.

**Quyết định bổ sung khi lập tasks**: (a) `state` OAuth dùng kho riêng `IDriveOAuthStateStore` trên Redis vì `IIntegrationSessionStore` hiện có gắn với `agentId` và `channel` của Meta; (b) tổng quan theo trạng thái (AC-008) do frontend lấy `total` từ `GET /videos?status=&pageSize=1` cho từng trạng thái, không thêm endpoint; (c) khi cờ tắt API trả `404`, frontend hiển thị "Tính năng chưa được bật" thay vì ẩn menu (menu sidebar là tĩnh).

## Thiết kế tổng quan

- **Luồng xử lý chính**: (1) Quản trị viên kết nối Drive qua OAuth → refresh token mã hóa lưu `drive_connections`. (2) Chọn thư mục → `video_sources`. (3) Đồng bộ quét đệ quy, upsert `videos` theo (`drive_connection_id`, `drive_file_id`), đặt `pending`. (4) Khởi chạy xử lý → mỗi video một job Hangfire: kiểm tra `canDownload` → tải luồng ra file tạm → tải lên Gemini → phân tích theo cửa sổ → gộp → lưu `video_analyses`/`video_chapters` → xóa file tạm và file trên Gemini → `completed`. (5) Giao diện duyệt, tìm theo từ khóa, xem chi tiết.
- **Component / Module tham gia & Boundary**: `Domain/Videos` (thực thể, trạng thái, quy tắc chuyển trạng thái); `Application/Videos` (command/query MediatR theo use case; cổng `IDriveClient`, `IVideoAnalyzer`, `IVideoRepository`, `IDriveOAuthStateStore`, `IDriveTokenProtector`, `IVideoJobScheduler`; `VideoKnowledgeOptions` là POCO đặt ở đây vì handler cần đọc `MaxBatchSize`); `Infrastructures/Videos` (`VideoDbContext`, repository, Drive client, Gemini analyzer, Hangfire job, kho `state` OAuth trên Redis); `Api` (`VideoKnowledgeController` chỉ gửi `ISender`). Ranh giới cũ không đổi.
- **Luồng lỗi & Idempotency / Concurrency**: Job idempotent theo (`video_id`, `content_key`); khóa tư vấn PostgreSQL theo `video_id` chặn chạy song song; Hangfire retry hữu hạn cho lỗi tạm thời (mạng, 429/5xx), lỗi vĩnh viễn (`unsupported_language`, `file_too_large`, `download_not_allowed`) không retry. Ràng buộc duy nhất ở DB là nguồn sự thật; adapter dịch vi phạm ràng buộc thành kết quả "đã tồn tại". Mất quyền hoặc token bị thu hồi → `access_denied`/`connection_revoked`.

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Hướng xử lý kỹ thuật | Module / Path dự kiến | API / Contract | Data / Entity | Kiểm thử |
|---|---|---|---|---|---|---|
| US-001 / FR-001, SEC-001, SEC-003, SEC-004 | P1 | OAuth Drive chỉ đọc; `state` ở Redis; mã hóa refresh token | `Application/Videos/Connections`, `Api/Controllers/VideoKnowledgeController.cs` | `/connections/drive*` | `drive_connections` | Unit (state, mã hóa), integration callback |
| US-001 / FR-001 (chọn một hoặc nhiều thư mục) | P1 | Duyệt thư mục, chọn nguồn; thông báo gửi AI ngoài trước khi chọn (SEC-005, BR-008) | `Application/Videos/Sources` | `/drive/folders`, `/sources*` | `video_sources` | Unit handler, UI manual |
| US-001 / FR-002, FR-003, BR-001, BR-002, BR-007 | P1 | Đồng bộ upsert theo `drive_file_id`, cập nhật `content_key`/tên | `Application/Videos/Sync` | `/sources/{id}/sync` | `videos` | Unit upsert; integration unique index |
| US-002 / FR-005, FR-026; US-003 / FR-009, FR-010 | P1 | Job Hangfire, máy trạng thái, thử lại có giới hạn, file tạm xóa trong `finally` | `Infrastructures/Videos/Processing` | `/videos/process`, `/videos/{id}/reprocess` | `video_processing_jobs`, `videos.status` | Unit chuyển trạng thái, test dọn file tạm |
| US-002 / FR-004, FR-006, FR-007, FR-008 | P1 | Phân tích theo cửa sổ + gộp, JSON schema cố định | `Infrastructures/Videos/Gemini`, `Application/Videos/Analysis` | (nội bộ) | `video_analyses`, `video_chapters` | Unit parser/gộp bằng analyzer giả; benchmark SC-002/003/008 thủ công |
| US-002 / FR-028 | P1 | Phát hiện ngôn ngữ không phải tiếng Việt → `failed/unsupported_language` | `Application/Videos/Analysis` | `failureCode` | `videos.failure_code` | Unit |
| US-003 / FR-009, FR-011 | P1 | Tổng quan theo 8 trạng thái (frontend gọi `GET /videos?status=&pageSize=1` lấy `total`), nguyên nhân lỗi từ `failureCode`, xử lý lại | `Application/Videos/Queries`, `Application/Videos/Processing` | `GET /videos`, `POST /videos/{id}/reprocess` | `videos` | Unit query, UI manual |
| FR-019 (kéo sớm, P3) | P1 (giới hạn) | Tìm từ khóa không phân biệt hoa thường trên tên, `summary`, `tags`; thoát wildcard; phân trang | `Application/Videos/Queries` | `GET /videos?keyword=` | `videos`, `video_analyses` | Integration PostgreSQL, UI manual |
| SEC-002, SEC-005, BR-003 | P1 (giới hạn) | Chỉ quản trị viên; không log token/nội dung | Controller + `ApplicationAuthorization` | mọi endpoint | — | Permission test 403 |
| NFR-001..004 | P1 | Giới hạn song song/kích thước/lô bằng cấu hình | `Application/Videos/VideoKnowledgeOptions.cs` | `batch_too_large` | — | Unit giới hạn |
| US-004..009, FR-012..025, FR-027 | P2/P3 | Không thực hiện; `IVideoAnalyzer`, cột `input/output_tokens`, `content_key` là chỗ mở rộng | — | — | — | Không áp dụng |

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược / Rủi ro | Cách kiểm tra |
|---------|------------------|----------------------------|---------------|
| Database / Migration | Database mới `videodb`, 6 bảng, 2 chỉ mục duy nhất | Không chạm `agentdb`; schema `hangfire` ngoài Liquibase (ngoại lệ có chủ đích) | `liquibase validate` + `update-sql`; smoke query |
| API / Contract | Nhóm endpoint mới | Không đổi endpoint cũ | Contract check theo `contracts/` |
| Permission / Security | Token Drive lưu mã hóa; quản trị viên duy nhất | Scope Drive hạn chế cần xác minh ứng dụng | Permission test; rà soát log |
| Logging / Audit | Event `video.*` theo style `channel_connection.started` | Rò token nếu log sai | Test/rà soát danh mục cấm log |
| UI / UX | Menu và route `video-knowledge` | Không ảnh hưởng màn cũ | Manual theo quickstart |
| Job / Worker / Integration | Hangfire trong host API, gọi Drive/Gemini | Timeout, 429, đĩa tạm đầy | Integration với client giả; giới hạn song song |

## API/Contract Detail

**Có thay đổi contract không**: Có — chỉ thêm mới, chi tiết ở [contracts/video-knowledge-api.md](./contracts/video-knowledge-api.md).

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|----------|------|----------|---------------------|-----------------------|
| `/api/video-knowledge/*` (13 endpoint) | API | Thêm mới | Có | `flex-microfrontend` (module mới) |

## Permission Matrix

| Vai trò / Scope | Xem | Tạo | Sửa | Xóa | Duyệt/Xử lý | Điều kiện / Ghi chú |
|-----------------|-----|-----|-----|-----|-------------|---------------------|
| Quản trị viên (`CanManage`) | Có | Có (kết nối, nguồn) | Không áp dụng | Có (gỡ nguồn, ngắt kết nối) | Có (đồng bộ, xử lý, xử lý lại) | Duy nhất ở MVP |
| Người dùng đã đăng nhập khác | Không | Không | Không | Không | Không | Chờ P2 (đối chiếu quyền Drive) |
| Chưa đăng nhập | Không | Không | Không | Không | Không | Riêng `callback` OAuth là anonymous, bảo vệ bằng `state` |

## Dữ liệu & Migration

- **Có thay đổi dữ liệu/schema không**: Có.
- **Database đích & Repo chứa migration**: `videodb` (mới) — migration tại `flex-database/videodb/`, theo tiền lệ `agentdb` đã xác nhận ngày 2026-08-01 trong `docs/architecture/system-map.md`; không đặt vào `flexdb` (mục còn "Cần làm rõ").
- **Chi tiết Migration / Backfill / Tương thích dữ liệu cũ**: [data-model.md](./data-model.md). Cấu trúc `videodb/{migrations,seeders,changelog,liquibase.properties}`, `V1.1__init_video_tables.sql`, release `1.0.0`, `scripts/migrate-videodb.sh`, `MIGRATE_VIDEODB.cmd`; changeset bất biến, sửa lỗi bằng changeset mới. Không backfill (database mới).
- **Rủi ro & Cách xác minh dữ liệu**: ghi sai ràng buộc duy nhất → chạy hai lần đồng bộ liên tiếp và kiểm tra không trùng; `liquibase update-sql` được rà soát trước khi chạy; không chạy `update` lên DB thật nếu chưa được yêu cầu.

## Chiến lược kiểm thử

- **Unit test**: máy trạng thái video, `content_key`, upsert đồng bộ, gộp kết quả cửa sổ, phát hiện ngôn ngữ, giới hạn lô/kích thước, mã hóa token (analyzer/Drive client giả viết tay).
- **Integration / Contract test**: ràng buộc duy nhất trên PostgreSQL thật (chỉ chạy khi có biến môi trường); contract theo `contracts/`.
- **Permission / Security test**: người không phải quản trị nhận 403; token không xuất hiện trong response/log; `state` OAuth sai bị từ chối.
- **E2E / Manual / Quickstart validation**: [quickstart.md](./quickstart.md), kèm bộ 20–30 video mẫu cho SC-002/003/008.
- **Regression test**: build và test hiện có của `flex-agent-service`; khi cờ `VideoKnowledge:Enabled=false` thì service khởi động như cũ.

## Tác động tài liệu nghiệp vụ

- **Kết quả Documentation Impact Gate (`spec.md` §20)**: CÓ CẬP NHẬT.
- **Tài liệu hiện hữu đã cập nhật**: `docs/business/14-ai-video-knowledge-base.md`, `docs/business/business-docs-index.md` (mục 5) — đã làm ở bước docbiz.
- **Cập nhật còn lại sau implementation**: `docs/architecture/system-map.md` (thêm `videodb` và module Video Knowledge); `docs/business/14-...` chỉ cập nhật nếu bốn điểm lệch MVP ở trên được xác nhận khác đi (hiện đã chấp nhận).

## Cấu trúc project

### Artifacts của feature
`specs/000043-ai-video-knowledge-base/`: `spec.md`, `plan.md`, `repos.md`, `research.md`, `data-model.md`, `contracts/video-knowledge-api.md`, `quickstart.md`, `tasks.md` *(sinh bởi `/speckit-tasks`)*.

### Source code

```text
flex-agent-service/
├── src/Flex.Agent.Domain/Videos/            # Video, DriveConnection, VideoAnalysis, VideoStatus
├── src/Flex.Agent.Application/Videos/       # Connections/, Sources/, Sync/, Processing/, Analysis/, Queries/, Abstractions/ (IDriveClient, IVideoAnalyzer, ...), VideoKnowledgeOptions
├── src/Flex.Agent.Infrastructures/Videos/   # VideoDbContext, repositories, Drive/, Gemini/, Jobs/, kho state OAuth (Redis), đăng ký DI
├── src/Flex.Agent.Api/Controllers/VideoKnowledgeController.cs
├── src/Flex.Agent.Api/appsettings.Example.json   # chỉ placeholder
└── tests/Flex.Agent.Tests/                  # project mới (xUnit)

flex-database/
├── videodb/{migrations/V1.1__init_video_tables.sql, seeders/, changelog/db.changelog-master.xml, changelog/releases/1.0.0/changelog.xml, liquibase.properties}
├── scripts/migrate-videodb.sh
├── MIGRATE_VIDEODB.cmd
└── README.md

flex-microfrontend/
└── src/app/features/video-knowledge/        # module, routing, components (list, detail, connect, process-modal), services, models, config
    (+ đăng ký route trong pages-routing.module.ts và mục menu ở layouts/sidebar/menu.ts)
```

**Quyết định cấu trúc**: bám cấu trúc 4 project hiện có của `flex-agent-service` (slice theo tính năng trong từng project), `videodb` mô phỏng đúng `agentdb`, module Angular mô phỏng `features/agent-catalog`.

## Rollout & Rollback

- **Kế hoạch rollout & Feature flag/config**: (1) chạy migration `videodb`; (2) thêm cấu hình và bí mật qua môi trường; (3) deploy `flex-agent-service` với `VideoKnowledge:Enabled=true`; (4) deploy frontend. Cờ mặc định tắt.
- **Rollback code/config**: đặt `VideoKnowledge:Enabled=false` hoặc revert bản deploy; khi API trả `404` (cờ tắt) trang `video-knowledge` hiển thị "Tính năng chưa được bật" (menu sidebar là tĩnh nên không ẩn được).
- **Rollback dữ liệu/migration & Điều kiện kích hoạt**: database mới nên không ảnh hưởng dữ liệu cũ; lỗi schema xử lý bằng changeset forward-fix, không sửa changeset đã chạy. Kích hoạt khi tỷ lệ job lỗi vượt ngưỡng hoặc phát hiện lộ token.

## Observability & Debug

- **Log / Metric / Trace cần có**: Serilog/ECS theo `SeriLogger` (`service.name = agent-service`); event `video_connection.connected`, `video_sync.completed`, `video_job.started|completed|failed` kèm `videoId`, `jobId`, `status`, `failureCode`, `traceId`, `userId` (`sub`).
- **Dữ liệu KHÔNG ĐƯỢC log**: access/refresh token, `client_secret`, API key Gemini, `TokenEncryption:Key`, chuỗi kết nối, nội dung/transcript video, URL tải có chữ ký, tiêu đề Authorization.
- **Cách kiểm tra sau release**: gọi `GET /connections/drive`, chạy đồng bộ + xử lý một video mẫu, truy vấn log theo `video_job.*`, xác nhận thư mục tạm trống. Việc gửi log tới backend tập trung chỉ được xác nhận khi truy vấn thực tế; nếu chưa chạy thì báo "đã cấu hình, chưa kiểm chứng".

## Theo dõi độ phức tạp

| ID / Nguyên tắc | Vì sao cần | Phương án đơn giản hơn bị loại vì | Người phê duyệt & Hạn xử lý |
|-----------------|------------|-----------------------------------|-----------------------------|
| Đặt miền video trong `flex-agent-service` (nền tảng AI Agent đa tenant) | Người dùng chọn; tái dùng OAuth, mã hóa token, JWT, logging | Repo mới sạch ranh giới hơn nhưng phải nhân bản hạ tầng; agent đã nêu rủi ro lẫn miền | Người dùng đã chấp nhận ở bước plan; xem lại khi P2/P3 làm module phình to (tách repo) |
| Hai DbContext/hai database trong một service | Hiến pháp VI yêu cầu database riêng | Dùng chung `agentdb` bị loại theo lựa chọn người dùng | Người dùng đã chấp nhận |
| Schema `hangfire` ngoài Liquibase | Thư viện tự quản lý schema | Tự viết migration cho bảng Hangfire dễ lệch phiên bản | Ghi ở README `flex-database` khi implement |
| Thêm gói NuGet (Hangfire, Google, xUnit) | Cần cho tính năng và test | Tự viết (tái phát minh) | **Chờ người dùng xác nhận** theo `AGENTS.md` của repo, ở `/speckit-tasks` hoặc `/speckit-implement` |

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật và `repos.md` (nếu chạm repo con) đã rõ, khớp MVP của `spec.md`.
- [x] Mọi câu hỏi kỹ thuật chặn thiết kế/task đã được chốt (trong `research.md` hoặc bảng quyết định ở trên).
- [x] Mỗi `US`/`FR`/`BR`/`SEC`/`NFR` quan trọng đã map sang module/path, contract, data và kiểm thử.
- [x] Database đích và repo chứa migration đã đối chiếu `docs/architecture/system-map.md` (hoặc ghi `Không áp dụng`).
- [x] Chiến lược kiểm thử, rollout/rollback và observability (kèm danh mục cấm log secret) đã rõ.
- [x] Khối cấu trúc source code đã thay hoàn toàn bằng path thật (không còn khối cây mẫu của template).
- [x] Bảng Kiểm tra constitution không còn blocker chưa được phê duyệt.
