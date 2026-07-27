# Hướng dẫn xác minh nhanh (Quickstart Guide): Migrate flex-auth-service sang PostgreSQL

**Branch**: `000009-auth-postgres-migration` | **Ngày**: 2026-07-27 | **Đặc tả**: [spec.md](file:///C:/Workspace/Project/flex-workstation/specs/000009-auth-postgres-migration/spec.md)

---

## 1. Mục đích

Tài liệu này hướng dẫn chạy và kiểm thử kiểm chứng end-to-end việc chuyển đổi datastore của `flex-auth-service` từ Oracle sang PostgreSQL.

---

## 2. Tiền đề & Môi trường

1. PostgreSQL Server đã sẵn sàng (đại diện qua môi trường `flex-environment` hoặc local PostgreSQL Docker instance).
2. Liquibase CLI hoặc script Liquibase migration trong `flex-database`.
3. SDK `.NET 9.0` để build và chạy `flex-auth-service`.

---

## 3. Các bước thực thi xác minh

### Bước 1: Chạy Liquibase Migration khởi tạo DB PostgreSQL
Mở terminal tại `flex-database`:
```bash
# Chạy migration cho database aspnetidentity
cd flex-database
# Thực thi script migration Liquibase tạo schema aspnetidentity trên PostgreSQL
```

### Bước 2: Cập nhật cấu hình kết nối trong `flex-auth-service`
Kiểm tra file `flex-auth-service/src/Flex.Auth/appsettings.json` (hoặc `appsettings.Development.json`):
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=aspnetidentity;Username=postgres;Password=your_password"
  }
}
```
*Lưu ý*: Xác nhận không còn phần cấu hình `"OracleWallet"` trong `appsettings.json`.

### Bước 3: Build và chạy `flex-auth-service`
```bash
cd flex-auth-service/src/Flex.Auth
dotnet build
dotnet run
```
**Kỳ vọng**: Service khởi tạo thành công, kết nối PostgreSQL mà không báo lỗi connection hay Oracle Wallet.

### Bước 4: Kiểm thử luồng xác thực (Authentication Flow)

#### 4.1 Đăng ký tài khoản mới (Register)
```bash
curl -X POST "http://localhost:5000/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "userName": "testuser",
    "email": "testuser@flex.local",
    "password": "Password123!",
    "fullName": "Test User"
  }'
```
**Kỳ vọng**: Phản hồi `200 OK` hoặc `201 Created`. Kiểm tra database PostgreSQL tại bảng `USERS` có chứa thông tin user mới.

#### 4.2 Đăng nhập (Login)
```bash
curl -X POST "http://localhost:5000/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "userName": "testuser",
    "password": "Password123!"
  }'
```
**Kỳ vọng**: Phản hồi `200 OK` chứa JWT token và thông tin xác thực. Bảng `LOGIN_HISTORIES` ghi nhận 1 bản ghi đăng nhập thành công.

#### 4.3 Đăng nhập sai mật khẩu (Validation & History)
```bash
curl -X POST "http://localhost:5000/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "userName": "testuser",
    "password": "WrongPassword!"
  }'
```
**Kỳ vọng**: Phản hồi `401 Unauthorized` hoặc `400 Bad Request`. Bảng `LOGIN_HISTORIES` ghi nhận thất bại.

---

## 4. Bảng tiêu chí nghiệm thu nhanh

| Kịch bản | Kết quả mong đợi | Trạng thái xác minh |
|----------|------------------|---------------------|
| Khởi động Service | Không còn dependency Oracle, kết nối PostgreSQL thành công | [ ] Pending |
| Registration | Lưu user vào PostgreSQL table `USERS` | [ ] Pending |
| Authentication | Đăng nhập thành công, phát hành JWT token | [ ] Pending |
| Login History | Ghi lịch sử đăng nhập vào PostgreSQL table `LOGIN_HISTORIES` | [ ] Pending |
| Deduplication Inbox | `InboxStore` bắt đúng `PostgresException` (23505) khi trùng message | [ ] Pending |
