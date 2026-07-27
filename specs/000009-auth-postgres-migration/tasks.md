# Tasks: Migrate datastore flex-auth-service từ Oracle sang PostgreSQL

**Đầu vào**: Design documents từ `/specs/000009-auth-postgres-migration/`
**Điều kiện tiên quyết**: [spec.md](file:///C:/Workspace/Project/flex-workstation/specs/000009-auth-postgres-migration/spec.md), [plan.md](file:///C:/Workspace/Project/flex-workstation/specs/000009-auth-postgres-migration/plan.md), [research.md](file:///C:/Workspace/Project/flex-workstation/specs/000009-auth-postgres-migration/research.md), [data-model.md](file:///C:/Workspace/Project/flex-workstation/specs/000009-auth-postgres-migration/data-model.md), [quickstart.md](file:///C:/Workspace/Project/flex-workstation/specs/000009-auth-postgres-migration/quickstart.md)

---

## Phase 1: Setup (Shared Infrastructure)

**Mục đích**: Khởi tạo thư mục và khai báo package dependency cho PostgreSQL.

- [x] T001 Thêm package reference `Npgsql.EntityFrameworkCore.PostgreSQL` version `9.0.3`, xóa `Oracle.EntityFrameworkCore` và `Oracle.ManagedDataAccess.Core` trong `flex-auth-service/src/Flex.Infrastructures/Flex.Infrastructures.csproj`
- [x] T002 Tạo thư mục chứa changelog Liquibase cho database `aspnetidentity` tại `flex-database/aspnetidentity/changelog/releases/1.0.0/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Mục đích**: Thiết lập cấu trúc master changelog Liquibase trước khi viết script khởi tạo database schema.

- [x] T003 Tạo file master changelog Liquibase cho database `aspnetidentity` tại `flex-database/aspnetidentity/changelog/db.changelog-master.xml`
- [x] T004 Tạo release changelog file cho phiên bản 1.0.0 tại `flex-database/aspnetidentity/changelog/releases/1.0.0/changelog.xml` (phụ thuộc T003)

---

## Phase 3: User Story 1 - Tạo PostgreSQL database mới cho flex-auth-service (Priority: P1)

**Goal**: Khởi tạo schema PostgreSQL hoàn chỉnh cho database `aspnetidentity` gồm 11 bảng, indexes và constraints tuân thủ `flex-database/docs/convention.md`.

**Independent Test**:
1. Thực thi script migration Liquibase trên database PostgreSQL `aspnetidentity`.
2. Kiểm tra 11 bảng (`USERS`, `ROLES`, `USER_ROLES`, `ROLE_CLAIMS`, `USER_CLAIMS`, `USER_LOGINS`, `USER_TOKENS`, `PERMISSIONS`, `LOGIN_HISTORIES`, `OUTBOX_MESSAGES`, `INBOX_MESSAGES`) cùng các UNIQUE Index (`UX_USERS_NORMALIZED_USER_NAME`, `UX_ROLES_NORMALIZED_NAME`, `UX_PERMISSIONS_CODE`, `UQ_INBOX_DEDUP`) được khởi tạo chính xác.

### Implementation for User Story 1

- [x] T005 [P] [US1] Viết tệp migration SQL Liquibase `01-init-schema.sql` khởi tạo 11 bảng DB (`USERS`, `ROLES`, `USER_ROLES`, `ROLE_CLAIMS`, `USER_CLAIMS`, `USER_LOGINS`, `USER_TOKENS`, `PERMISSIONS`, `LOGIN_HISTORIES`, `OUTBOX_MESSAGES`, `INBOX_MESSAGES`) với kiểu dữ liệu PostgreSQL native (`boolean`, `text`, `TIMESTAMPTZ`, `UUID`) tại `flex-database/aspnetidentity/changelog/releases/1.0.0/01-init-schema.sql`
- [x] T006 [P] [US1] Viết tệp rollback SQL `01-rollback-schema.sql` cho schema `aspnetidentity` tại `flex-database/aspnetidentity/changelog/releases/1.0.0/01-rollback-schema.sql`
- [x] T007 [US1] Thực thi command validate Liquibase migration để xác minh việc tạo schema `aspnetidentity` trên PostgreSQL (phụ thuộc T004, T005)

**Definition of Done**:
- Script migration SQL Liquibase được tạo và validate thành công.
- Database PostgreSQL `aspnetidentity` được tạo đầy đủ cấu trúc bảng và index.
- Chạy thử nghiệm thành công mà không báo lỗi syntax SQL.

---

## Phase 4: User Story 2 - Vận hành flex-auth-service hoàn toàn trên PostgreSQL (Priority: P1)

**Goal**: Migrate toàn bộ code tầng data access (EF Core Extensions, Configurations, Stores, Connection Settings) của `flex-auth-service` từ Oracle sang PostgreSQL, xóa 100% dependency tới Oracle.

**Independent Test**:
1. Khởi động `flex-auth-service` kết nối tới PostgreSQL `aspnetidentity`.
2. Thực hiện đăng ký tài khoản mới (`POST /api/v1/auth/register`) -> dữ liệu lưu vào bảng `USERS`.
3. Thực hiện đăng nhập (`POST /api/v1/auth/login`) -> đăng nhập thành công, trả về JWT Token và ghi 1 bản ghi vào bảng `LOGIN_HISTORIES`.
4. Bắt đúng exception deduplication tin nhắn `PostgresException` (23505) khi `InboxStore` xử lý tin nhắn trùng lặp.

### Implementation for User Story 2

- [x] T008 [US2] Xóa file `OracleWalletConfiguration.cs` tại `flex-auth-service/src/Flex.Infrastructures/EntityFrameworkCore/OracleWalletConfiguration.cs`
- [x] T009 [US2] Cập nhật `EntityFrameworkCoreExtensions.cs` tại `flex-auth-service/src/Flex.Infrastructures/EntityFrameworkCore/EntityFrameworkCoreExtensions.cs` loại bỏ tham chiếu `Oracle.ManagedDataAccess.Client`, xóa logic nạp Oracle Wallet và thay `options.UseOracle(...)` bằng `options.UseNpgsql(...)` đọc `DefaultConnection` (phụ thuộc T001, T008)
- [x] T010 [P] [US2] Cập nhật `UserConfiguration.cs` tại `flex-auth-service/src/Flex.Infrastructures/Persistence/Configurations/UserConfiguration.cs` loại bỏ `BoolToCharConverter` và `.HasColumnType("CHAR(1)")`, chuyển sang mapping boolean native PostgreSQL
- [x] T011 [P] [US2] Cập nhật `InboxMessageConfiguration.cs` tại `flex-auth-service/src/Flex.Infrastructures/Persistence/Configurations/InboxMessageConfiguration.cs` thay `.HasColumnType("CLOB")` bằng `.HasColumnType("text")`
- [x] T012 [P] [US2] Cập nhật `OutboxMessageConfiguration.cs` tại `flex-auth-service/src/Flex.Infrastructures/Persistence/Configurations/OutboxMessageConfiguration.cs` thay `.HasColumnType("CLOB")` bằng `.HasColumnType("text")`
- [x] T013 [US2] Cập nhật `InboxStore.cs` tại `flex-auth-service/src/Flex.Infrastructures/Messaging/Inbox/InboxStore.cs` thay việc kiểm tra `OracleException` (`ORA-00001`) bằng `Npgsql.PostgresException` với `SqlState == "23505"` (phụ thuộc T001)
- [x] T014 [P] [US2] Cập nhật `appsettings.json` tại `flex-auth-service/src/Flex.Auth/appsettings.json` xóa section `OracleWallet` và khai báo connection string `DefaultConnection` trỏ tới PostgreSQL `aspnetidentity`
- [x] T015 [P] [US2] Cập nhật `appsettings.Development.json` tại `flex-auth-service/src/Flex.Auth/appsettings.Development.json` xóa section `OracleWallet` và khai báo connection string `DefaultConnection` trỏ tới PostgreSQL `aspnetidentity`

**Definition of Done**:
- 100% code C# không còn tham chiếu tới `Oracle.ManagedDataAccess` hay `Oracle.EntityFrameworkCore`.
- Ứng dụng khởi động thành công và kết nối tới PostgreSQL `aspnetidentity`.
- Luồng đăng ký, đăng nhập và xử lý inbox deduplication hoạt động chính xác trên PostgreSQL.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Mục đích**: Kiểm tra toàn bộ giải pháp, biên dịch solution và xác minh quickstart test end-to-end.

- [x] T016 [P] Kiểm tra toàn bộ codebase `flex-auth-service` bằng lệnh tìm kiếm pattern `Oracle` để đảm bảo không còn bất kỳ Oracle reference nào dư thừa
- [x] T017 Biển dịch lại toàn bộ solution bằng command `dotnet build flex-auth-service/Flex.Auth.sln`
- [x] T018 Thực hiện xác minh các kịch bản test end-to-end theo hướng dẫn tại `specs/000009-auth-postgres-migration/quickstart.md`

---

## Validation Commands

- **Build solution**: `dotnet build flex-auth-service/Flex.Auth.sln`
- **Kiểm tra Oracle reference**: `rtk grep "Oracle" flex-auth-service/src`
- **Xác minh Quickstart**: Theo các lệnh `curl` trong `specs/000009-auth-postgres-migration/quickstart.md`

---

## Traceability Matrix

| Source | Covered by tasks |
|--------|------------------|
| US-001 | T005, T006, T007 |
| US-002 | T008, T009, T010, T011, T012, T013, T014, T015 |
| FR-001 | T005, T007 |
| FR-002 | T005, T010 |
| FR-003 | T001, T009, T010, T011, T012, T013 |
| FR-004 | T008, T009, T014, T015, T016 |
| AC-001 | T005, T007 |
| AC-002 | T009, T013, T018 |
| AC-003 | T008, T014, T015, T016 |
| SEC-001 | T009, T018 |
| BR-001 | T009, T010, T018 |
| NFR-001 | T017, T018 |

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Không có dependency, thực hiện ngay.
- **Foundational (Phase 2)**: Phụ thuộc Phase 1 completion, CHẶN User Story 1 & 2.
- **User Story 1 (Phase 3)**: Phụ thuộc Phase 2 completion.
- **User Story 2 (Phase 4)**: Phụ thuộc Phase 1 & Phase 2 completion (có thể tiến hành song song với US1 nếu DB PostgreSQL đã sẵn sàng).
- **Polish (Final Phase)**: Phụ thuộc tất cả task trong US1 & US2 hoàn tất.

### Parallel Opportunities

- **Phase 1**: `T001` và `T002` khác repo/file, có thể thực hiện song song.
- **Phase 3 (US1)**: `T005` (`01-init-schema.sql`) và `T006` (`01-rollback-schema.sql`) có thể thực hiện song song.
- **Phase 4 (US2)**: `T010` (`UserConfiguration.cs`), `T011` (`InboxMessageConfiguration.cs`), `T012` (`OutboxMessageConfiguration.cs`), `T014` (`appsettings.json`), `T015` (`appsettings.Development.json`) là các file độc lập, có thể sửa song song.

---

## Checklist chất lượng trước khi implement

- [x] Không còn task ví dụ hoặc placeholder `[Entity]`, `[endpoint]`, `[file]` trong output cuối.
- [x] Không còn `TXXX`, `Phase N` hoặc phase user story không tồn tại trong `spec.md`.
- [x] Toàn bộ task được đánh số tuần tự từ `T001` đến `T018`.
- [x] Mỗi task có file path cụ thể hoặc command cụ thể.
- [x] Task sửa file có sẵn đã nêu rõ class, method, section hoặc config key cần sửa.
- [x] Task phụ thuộc task khác đã ghi rõ dependency task ID.
- [x] Mỗi user story có Independent Test cụ thể và Definition of Done cụ thể.
- [x] Traceability Matrix đã map source quan trọng sang task ID thực tế.
- [x] Task `[P]` không sửa cùng file và không phụ thuộc nhau.
