# Kế hoạch triển khai: Migrate datastore flex-auth-service từ Oracle sang PostgreSQL

**Branch**: `000009-auth-postgres-migration` | **Ngày**: 2026-07-27 | **Đặc tả**: [spec.md](file:///C:/Workspace/Project/flex-workstation/specs/000009-auth-postgres-migration/spec.md)

**Đầu vào**: Đặc tả tính năng từ `/specs/000009-auth-postgres-migration/spec.md`

---

## Tóm tắt

**Yêu cầu chính từ spec**:
- MT-001 / US-001 / FR-001 / FR-002: Tạo mới PostgreSQL database `aspnetidentity` cho `flex-auth-service` theo chuẩn migration PostgreSQL + Liquibase SQL-first trong repo `flex-database`.
- MT-002 / US-002 / FR-003 / FR-004: Migrate toàn bộ tầng truy cập dữ liệu của `flex-auth-service` từ Oracle sang PostgreSQL; xóa hoàn toàn cấu hình, driver, wallet và tham chiếu kết nối Oracle.

**Hướng tiếp cận kỹ thuật dự kiến**:
- Sử dụng `Npgsql.EntityFrameworkCore.PostgreSQL` làm DB provider trong `Flex.Infrastructures`.
- Cập nhật `EntityFrameworkCoreExtensions.cs`: loại bỏ cấu hình Oracle Wallet, chuyển sang `options.UseNpgsql(connectionString)`.
- Xóa `OracleWalletConfiguration.cs` và section `OracleWallet` trong `appsettings.json` & `appsettings.Development.json`.
- Cập nhật các configuration EF Core (`UserConfiguration`, `InboxMessageConfiguration`, `OutboxMessageConfiguration`...): bỏ `BoolToCharConverter` (chuyển sang native `boolean`), đổi `CLOB` thành `text`.
- Cập nhật `InboxStore.cs`: đổi việc bắt `OracleException` (`ORA-00001`) sang `PostgresException` (`SqlState == "23505"`).
- Tạo changeset Liquibase cho schema PostgreSQL `aspnetidentity` tại `flex-database/aspnetidentity/changelog/`.

**Kết quả sau research**: Tất cả các điểm chưa rõ (TQ-001, TQ-002, TQ-003) đã được giải quyết chi tiết trong [research.md](file:///C:/Workspace/Project/flex-workstation/specs/000009-auth-postgres-migration/research.md).

---

## Phạm vi kỹ thuật

**Trong phạm vi**:
- Repo `flex-auth-service`:
  - `src/Flex.Infrastructures`: Cấu hình EF Core DbContext Npgsql, entity configurations, `InboxStore.cs`.
  - `src/Flex.Auth`: File cấu hình `appsettings.json` và `appsettings.Development.json`.
  - File dự án `.csproj`: Thay package `Oracle.EntityFrameworkCore` bằng `Npgsql.EntityFrameworkCore.PostgreSQL`.
- Repo `flex-database`:
  - Thư mục `aspnetidentity/changelog/`: Thêm master changelog và changeset SQL tạo schema bảng PostgreSQL cho `aspnetidentity`.

**Ngoài phạm vi kỹ thuật**:
- Multi-tenant, tenant/role, JWT theo tenant.
- SSO/OAuth2, đổi mật khẩu qua email, MFA.
- Script migrate dữ liệu từ Oracle (chưa có dữ liệu production thật).

---

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: .NET 9.0 (C# 13)
**Service/App liên quan**: `flex-auth-service` (Web API Service) & `flex-database` (Database Liquibase Management)
**Phụ thuộc chính**: EF Core 9.0.11, Npgsql.EntityFrameworkCore.PostgreSQL 9.0.3, ASP.NET Core Identity
**Lưu trữ**: PostgreSQL 16+ (Database `aspnetidentity`)
**Kiểm thử**: xUnit, `dotnet test`, manual API testing qua cURL/Postman
**Nền tảng chạy**: Linux container / Windows service / Docker Compose
**Đơn vị deploy**: Container image `flex-auth-service`, Liquibase migration job
**Loại project**: Web API service & Database SQL migrations
**Mục tiêu hiệu năng**: Thời gian phản hồi đăng nhập/xác thực < 200ms
**Ràng buộc**: Loại bỏ 100% dependency tới Oracle; tuân thủ quy ước `flex-database/docs/convention.md`.

---

## Kiểm tra constitution

*GATE: Phải đạt trước Phase 0 research. Kiểm tra lại sau Phase 1 design.*

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| I. Điều phối workspace | Pass | Pass | Code sản phẩm nằm đúng trong repo `flex-auth-service` và `flex-database`. |
| II. Spec trước code | Pass | Pass | Spec đã được phê duyệt, thiết kế tuân thủ WHY/WHAT trong spec. |
| III. Tooling không phụ thuộc agent | Pass | Pass | Dùng chuẩn quy ước workspace chung. |
| IV. Bootstrap có thể tái lập | Pass | Pass | Không làm hỏng môi trường phát triển hiện tại. |
| V. Thay đổi phẫu thuật & đơn giản | Pass | Pass | Chỉ tập trung migrate datastore Oracle -> PostgreSQL, không thêm bớt feature ngoài scope. |

---

## Câu hỏi kỹ thuật cần research

- **TQ-001**: [ĐÃ GIẢI QUYẾT] Có cần script migrate dữ liệu cũ từ Oracle không?
  - *Kết luận*: Không. Chưa có dữ liệu production thật.
- **TQ-002**: [ĐÃ GIẢI QUYẾT] Dùng EF Core PostgreSQL Provider nào và cấu hình ra sao?
  - *Kết luận*: Dùng `Npgsql.EntityFrameworkCore.PostgreSQL` v9.0.3, thay `.UseOracle(...)` bằng `.UseNpgsql(...)`.
- **TQ-003**: [ĐÃ GIẢI QUYẾT] Bắt lỗi trùng lặp tin nhắn deduplication trong `InboxStore.cs` thế nào?
  - *Kết luận*: Bắt `PostgresException` với `SqlState == "23505"` (`UniqueViolation`).

---

## Thiết kế tổng quan

**Luồng chính**:
1. Khởi tạo database PostgreSQL `aspnetidentity` và các bảng thông qua Liquibase script trong `flex-database`.
2. `flex-auth-service` đọc `DefaultConnection` string từ `appsettings.json` khi ứng dụng start.
3. `EntityFrameworkCoreExtensions` đăng ký `IdentityDbContext` với provider Npgsql (`options.UseNpgsql(...)`).
4. EF Core thực hiện các câu lệnh SQL trên PostgreSQL với schema tương thích chuẩn (trường `boolean` native, `text` thay cho `CLOB`).
5. Khi nhận tin nhắn trùng lặp trong Messaging Inbox, `InboxStore` bắt lỗi `PostgresException` (SqlState 23505) và ghi log deduplication.

**Component/module tham gia**:
- `flex-database/aspnetidentity`: Quản lý migration SQL-first bằng Liquibase cho DB `aspnetidentity`.
- `Flex.Infrastructures`: Quản lý EF Core DbContext, Entity Configurations, Provider extension và Inbox/Outbox store.
- `Flex.Auth`: API Host, nạp configuration settings và đăng ký infrastructure services.

**Điểm mở rộng/thay đổi chính**:
- Loại bỏ Oracle SDK & Oracle EF Core provider.
- Tích hợp Npgsql EF Core provider.
- Cập nhật connection string và quy ước mapping kiểu dữ liệu sang PostgreSQL.

---

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|------------|----------------------|---------------------|--------------|-------------|----------|
| US-001 / FR-001 | P1 | Đủ rõ | Tạo Liquibase master changelog & changeset cho DB `aspnetidentity` | `flex-database/aspnetidentity/changelog/` | Không áp dụng | Tất cả 11 bảng DB | Liquibase migration run |
| US-001 / FR-002 | P1 | Đủ rõ | Đảm bảo các UNIQUE Index (`NORMALIZED_USER_NAME`, `NORMALIZED_NAME`, `CODE`, `UQ_INBOX_DEDUP`) | `flex-database/aspnetidentity/changelog/` | Không áp dụng | Bảng `USERS`, `ROLES`, `PERMISSIONS`, `INBOX_MESSAGES` | Integration test DB constraints |
| US-002 / FR-003 | P1 | Đủ rõ | Thay Oracle EF Core provider bằng Npgsql trong DbContext | `flex-auth-service/src/Flex.Infrastructures/` | Không áp dụng | `IdentityDbContext` | Unit & Integration test repository |
| US-002 / FR-004 | P1 | Đủ rõ | Xóa OracleWallet, xóa Oracle packages, cập nhật appsettings.json connection string | `flex-auth-service/src/Flex.Auth/`, `Flex.Infrastructures.csproj` | Không áp dụng | Không áp dụng | App Startup check & Build verify |
| SEC-001 | P1 | Đủ rõ | Giữ nguyên thuật toán băm mật khẩu `IPasswordHasher<User>` hiện tại | `Flex.Auth/Extensions/ServiceExtensions.cs` | Không áp dụng | `USERS.PASSWORD_HASH` | Auth Login e2e test |
| BR-001 | P1 | Đủ rõ | Giữ nguyên toàn bộ API request/response & business flows | `Flex.Auth/Controllers/`, `Services/` | OpenAPI / REST API | Dữ liệu identity | cURL Quickstart verification |

---

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---------|------------------|--------------------------|---------------|
| Database/Migration | Đổi DB engine từ Oracle sang PostgreSQL | Không có dữ liệu cũ cần migrate | Chạy Liquibase changelog trên PostgreSQL sạch |
| API/Contract | Không thay đổi | Tương thích 100% | Chạy regression test toàn bộ endpoint `/api/v1/auth/*` |
| Permission/Security | Không thay đổi | Bảo toàn cơ chế mã hóa mật khẩu & JWT | Test login/register |
| Logging/Audit | Xóa log liên quan đến Oracle Wallet | Không ảnh hưởng Serilog | Kiểm tra log startup |
| UI/UX | Không áp dụng | Không áp dụng | Manual check |
| Job/Worker/Integration | Inbox/Outbox messaging cập nhật sang PostgreSQL | Đảm bảo deduplication inbox chạy đúng trên Postgres | Test gửi tin nhắn trùng lặp qua InboxStore |

---

## API/Contract Detail

**Có thay đổi contract không**: Không áp dụng (Giữ nguyên toàn bộ API endpoints hiện có).

---

## Permission Matrix

**Có thay đổi phân quyền không**: Không áp dụng (Giữ nguyên mô hình permission hiện có).

---

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Có (Tạo mới hoàn toàn schema PostgreSQL cho database `aspnetidentity`).

**Migration**:
- Quản lý qua Liquibase SQL-first trong repo `flex-database`.
- Tệp master: `flex-database/aspnetidentity/changelog/db.changelog-master.xml`.
- Changeset ban đầu: `flex-database/aspnetidentity/changelog/releases/1.0.0/01-init-schema.sql`.

**Backfill/Cleanup**: Không áp dụng (Chưa có dữ liệu thật).

**Tương thích dữ liệu cũ**: Không áp dụng.

**Rủi ro dữ liệu**: Không áp dụng.

**Cách xác minh**: Thực thi Liquibase migration và verify schema qua query tool/pgAdmin.

---

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| DEC-001 | `Npgsql.EntityFrameworkCore.PostgreSQL` 9.0.3 | Chuẩn .NET 9 EF Core provider cho PostgreSQL | Oracle EF Core | Cần bỏ Oracle theo chiến lược hệ thống |
| DEC-002 | Liquibase SQL-first trong `flex-database` | Tuân thủ quy ước quản lý DB tập trung của Flex | EF Core Code-First Migrations | Phá vỡ quy ước `flex-database/docs/convention.md` |
| DEC-003 | Kiểu `boolean` native và `text` | Chuẩn PostgreSQL, tối ưu lưu trữ | Kiểu `CHAR(1)` và `CLOB` | Định dạng đặc thù Oracle |
| DEC-004 | Catch `PostgresException` (SqlState 23505) | Đúng kiểu exception ném ra bởi Npgsql khi vi phạm Unique | Catch `OracleException` (ORA-00001) | Code Oracle không chạy trên Npgsql |

---

## Chiến lược kiểm thử

**Unit test**:
- Test `InboxStore` mock `IdentityDbContext` và kiểm tra xử lý exception trùng lặp.
- Test `EntityFrameworkCoreExtensions` nạp cấu hình connection string.

**Integration test**:
- Test kết nối DB PostgreSQL thật.
- Test CRUD trên các bảng `USERS`, `ROLES`, `INBOX_MESSAGES`, `OUTBOX_MESSAGES`.

**Contract test**: Không áp dụng.

**Permission/security test**:
- Verify thuật toán băm mật khẩu `PasswordHasher<User>` tạo hash và verify password trên PostgreSQL.

**E2E/manual test**:
- Thực hiện trọn vẹn kịch bản trong [quickstart.md](file:///C:/Workspace/Project/flex-workstation/specs/000009-auth-postgres-migration/quickstart.md) (Register -> Login -> Deduplication check).

**Regression test**:
- Test các endpoint đăng nhập, đăng ký, lấy thông tin user hiện có.

---

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/000009-auth-postgres-migration/
├── spec.md              # Đặc tả tính năng
├── plan.md              # File kế hoạch triển khai này
├── research.md          # Kết quả nghiên cứu kỹ thuật Phase 0
├── data-model.md        # Mô hình dữ liệu PostgreSQL Phase 1
└── quickstart.md        # Hướng dẫn kiểm thử xác minh Phase 1
```

### Source code sẽ tác động

```text
# Repository: flex-auth-service
flex-auth-service/
├── src/
│   ├── Flex.Auth/
│   │   ├── appsettings.json
│   │   └── appsettings.Development.json
│   └── Flex.Infrastructures/
│       ├── EntityFrameworkCore/
│       │   ├── EntityFrameworkCoreExtensions.cs
│       │   └── [XÓA] OracleWalletConfiguration.cs
│       ├── Messaging/Inbox/
│       │   └── InboxStore.cs
│       ├── Persistence/Configurations/
│       │   ├── UserConfiguration.cs
│       │   ├── InboxMessageConfiguration.cs
│       │   ├── OutboxMessageConfiguration.cs
│       │   └── ...
│       └── Flex.Infrastructures.csproj

# Repository: flex-database
flex-database/
└── aspnetidentity/
    └── changelog/
        ├── db.changelog-master.xml
        └── releases/
            └── 1.0.0/
                └── 01-init-schema.sql
```

**Quyết định cấu trúc**: Phân chia rõ ràng giữa repo mã nguồn ứng dụng (`flex-auth-service`) và repo quản lý migration database (`flex-database`).

---

## Rollout & Rollback

**Kế hoạch rollout**:
1. Chạy Liquibase migration trên PostgreSQL để tạo database & schema `aspnetidentity`.
2. Triển khai ứng dụng `flex-auth-service` phiên bản mới (đã chuyển sang Npgsql).

**Tương thích ngược**: Không áp dụng (chưa có consumer/dữ liệu cũ).

**Feature flag/config**: Dùng connection string `DefaultConnection` trong `appsettings.json`.

**Thực thi migration/backfill khi rollout**: Chạy Liquibase migration trước khi khởi động app service.

**Rollback code/config**: Nếu có sự cố, redeploy phiên bản `flex-auth-service` cũ kèm cấu hình Oracle (nếu DB Oracle vẫn tạm giữ).

**Rollback dữ liệu/migration**: Drop database `aspnetidentity` trên PostgreSQL nếu cần làm lại.

**Điều kiện kích hoạt rollback**: Service không thể kết nối DB hoặc gặp lỗi runtime không xác định trong quá trình authentication.

---

## Observability & Debug

**Log cần có**:
- Log startup: `LogInformation("Configured IdentityDbContext with PostgreSQL provider.")`
- Log Inbox deduplication: `LogDebug("Duplicate message {MessageId} for {Handler} detected by UNIQUE constraint")`

**Dữ liệu không được log**:
- Plaintext password, JWT Secret Key, Private Credentials.

**Metric cần theo dõi**:
- Latency database query, HTTP Request duration `/api/v1/auth/login`.

**Trace/Correlation**:
- Giữ nguyên `CorrelationIdHandler` để trace request qua các service.

**Cách kiểm tra sau release**:
- Kiểm tra log startup ứng dụng.
- Chạy health check endpoint và quickstart test.

---

## Theo dõi độ phức tạp

> KHÔNG CÓ VI PHẠM CONSTITUTION. Thiết kế giữ nguyên các ranh giới hiện có và đơn giản hóa hệ thống bằng cách loại bỏ Oracle Wallet phức tạp.

---

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật chặn thiết kế/task generation đã được resolve trong research hoặc ghi rủi ro rõ ràng.
- [x] Thiết kế tổng quan đã mô tả luồng chính, component/module tham gia, điểm thay đổi và boundary nếu có.
- [x] Các tình huống idempotency/concurrency/retry đã được đánh giá hoặc ghi `Không áp dụng`.
- [x] Mỗi `US`/`FR` P1/P2 hoặc FR ảnh hưởng code/data/API/permission có mapping sang module/path, API/contract, data/entity và kiểm thử.
- [x] Tác động tới database, API contract, permission, logging/audit và integration đã được đánh giá hoặc ghi `Không áp dụng`.
- [x] Các contract/API/event thay đổi đã có consumer bị ảnh hưởng và cách kiểm tra compatibility.
- [x] Dữ liệu/migration/backfill/compatibility đã rõ hoặc ghi `Không áp dụng`.
- [x] Quyết định kỹ thuật chính đã có lý do chọn và phương án bị loại.
- [x] Chiến lược kiểm thử đã bao phủ unit, integration, contract, permission/security, E2E/manual và regression khi liên quan.
- [x] Rollout, rollback code/config, rollback dữ liệu/migration, feature flag/config và backward compatibility đã rõ hoặc ghi `Không áp dụng`.
- [x] Observability/debug plan có log field, dữ liệu không được log, metric/trace và cách kiểm tra sau release.
- [x] Không còn cây thư mục mẫu/generic; toàn bộ path trong cấu trúc source code là path thật trong repository.
- [x] Constitution gate không còn blocker trước khi chuyển sang `/speckit-tasks`.
