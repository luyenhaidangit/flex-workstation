# Hướng dẫn kiểm thử & Xác minh (Quickstart Guide)

**Feature**: `000021-market-database-config`  

---

## 1. Chuẩn bị CSDL (Database Setup)

Chạy migration SQL trong `flex-database` để tạo bảng và chèn dữ liệu mẫu 4 thị trường:

```bash
# Thực thi migration script trên Postgres/MySQL
psql -U postgres -d exchange -f flex-database/hnx/changelog/releases/1.0.0.1/001-create-exchange-markets.sql
```

Xác minh bảng đã được tạo:
```sql
SELECT market_code, market_name, status, has_ato, has_plo FROM exchange_markets;
```

---

## 2. Khởi chạy `flex-exchange-service`

Chạy dịch vụ `flex-exchange-service`:

```bash
cd flex-exchange-service/src/Flex.Exchange.Api
dotnet run
```

Quan sát log khởi động:
* Khởi tạo `SessionWorker` và load danh sách thị trường `HOSE`, `HNX`, `UPCOM`, `DERIVATIVES` từ CSDL.

---

## 3. Kiểm tra API Endpoints

### 3.1 Truy vấn danh sách thị trường
Gửi request HTTP:
```http
GET http://localhost:5000/api/v1/markets
```
Xác nhận phản hồi 200 OK chứa danh sách 4 thị trường.

### 3.2 Kiểm tra cập nhật trạng thái `inactive`
Chạy câu lệnh SQL:
```sql
UPDATE exchange_markets SET status = 'inactive' WHERE market_code = 'DERIVATIVES';
```
Gọi lại `GET http://localhost:5000/api/v1/markets` hoặc quan sát `SessionWorker` phiên tiếp theo:
* Thị trường `DERIVATIVES` không còn xuất hiện trong danh sách thị trường được khởi tạo phiên tự động.
