# Nghiên cứu kỹ thuật: Migrate datastore flex-auth-service từ Oracle sang PostgreSQL

**Branch**: `000009-auth-postgres-migration` | **Ngày**: 2026-07-27 | **Đặc tả**: [spec.md](file:///C:/Workspace/Project/flex-workstation/specs/000009-auth-postgres-migration/spec.md)

---

## 1. Quyết định kỹ thuật

### Quyết định 1: Thư viện EF Core PostgreSQL Provider
- **Quyết định**: Sử dụng `Npgsql.EntityFrameworkCore.PostgreSQL` phiên bản 9.0.x (tương thích `.NET 9` / `EF Core 9.0.11`).
- **Lý do chọn**: `flex-auth-service` đang chạy `.NET 9.0` (`net9.0`). Thư viện `Npgsql` là ORM provider chính thức, hiệu năng cao và chuẩn cho PostgreSQL trong hệ sinh thái .NET.
- **Phương án đã loại**:
  - Giữ lại `Oracle.EntityFrameworkCore`: Loại bỏ hoàn toàn theo MT-001 / FR-003 / FR-004.
  - Sử dụng Dapper/SQL thuần: Loại bỏ vì `flex-auth-service` đang dùng EF Core DbContext và ASP.NET Core Identity abstractions, việc chuyển sang Dapper gây rework tầng Repository không cần thiết.

### Quyết định 2: Cấu hình Liquibase Migration trong `flex-database`
- **Quyết định**: Tạo cấu trúc Liquibase SQL-first changelog cho database `aspnetidentity` tại `flex-database/aspnetidentity/changelog/db.changelog-master.xml` và các release changeset trong `flex-database/aspnetidentity/changelog/releases/1.0.0/`. Tuân thủ tuyệt đối `flex-database/docs/convention.md`.
- **Lý do chọn**: Đảm bảo đúng ràng buộc kỹ thuật tại Mục 13 & 16 của `spec.md` về quản lý schema tập trung bằng Liquibase trong hệ thống Flex.
- **Phương án đã loại**:
  - EF Core Migrations (`dotnet ef migrations`): Loại bỏ vì hệ thống Flex dùng Liquibase SQL-first quản lý DB schema tập trung qua `flex-database`, không dùng EF Core auto-migrations để tránh schema drift giữa các môi trường.

### Quyết định 3: Chuyển đổi kiểu dữ liệu và EF Core Configuration
- **Quyết định**:
  - Thay thế kiểu dữ liệu Oracle `CLOB` trong `InboxMessageConfiguration.cs` và `OutboxMessageConfiguration.cs` bằng `text`.
  - Cập nhật các trường boolean (`EMAIL_CONFIRMED`, `PHONE_NUMBER_CONFIRMED`, `TWO_FACTOR_ENABLED`, `LOCKOUT_ENABLED`) từ `CHAR(1)` (`BoolToCharConverter`) sang kiểu native `boolean` của PostgreSQL.
  - Xóa bỏ `OracleWalletConfiguration.cs` và phương thức khởi tạo connection từ Oracle Wallet trong `EntityFrameworkCoreExtensions.cs`.
- **Lý do chọn**: PostgreSQL hỗ trợ native `boolean` và `text`, tối ưu hiệu năng storage và index. Đồng thời loại bỏ hoàn toàn các cấu hình Oracle đặc thù.
- **Phương án đã loại**:
  - Giữ `CHAR(1)` cho boolean: Dù chạy được nhưng không chuẩn theo quy ước PostgreSQL của `flex-database/docs/convention.md`.

### Quyết định 4: Xử lý ngoại lệ trùng lặp UNIQUE constraint trong `InboxStore.cs`
- **Quyết định**: Thay thế việc kiểm tra `OracleException` (`ORA-00001`) bằng kiểm tra `Npgsql.PostgresException` với `SqlState == "23505"` (`PostgresErrorCodes.UniqueViolation`).
- **Lý do chọn**: `InboxStore` thực hiện atomic deduplication bằng cách bắt lỗi UNIQUE constraint violation khi ghi record. Khi đổi provider sang Npgsql, exception ném ra là `Npgsql.PostgresException`.
- **Phương án đã loại**:
  - Bắt exception chung `DbUpdateException` không kiểm tra inner exception: Loại bỏ vì có thể che giấu các lỗi DB khác (timeout, connection loss, check constraint).

---

## 2. Tóm tắt giải quyết điểm chưa chắc chắn (NEEDS CLARIFICATION)

| TQ ID | Nội dung | Kết luận / Hướng xử lý |
|-------|----------|------------------------|
| TQ-001 | Có cần migration/backfill dữ liệu cũ không? | Không. Theo giả định mục 13 của spec, chưa có dữ liệu thật trên Oracle cần bảo toàn. Database PostgreSQL mới được khởi tạo từ đầu bằng Liquibase. |
| TQ-002 | Thay đổi provider DbContext thế nào trong `flex-auth-service`? | Thay `UseOracle(...)` bằng `UseNpgsql(...)` trong `EntityFrameworkCoreExtensions.cs`, đọc `DefaultConnection` string từ `appsettings.json`. |
| TQ-003 | Thay đổi exception handling tại đâu? | Sửa `IsUniqueConstraintViolation` trong `InboxStore.cs` từ `OracleException` (code 1) sang `PostgresException` (SqlState 23505). |
