# Data Model: Tùy chọn mã chứng khoán & Lưu trạng thái

## 1. Thực thể Database (PostgreSQL)

### `exchange_instruments`
Bảng lưu trữ thông tin các mã chứng khoán được phép giao dịch trên hệ thống.

| Cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `instrument_id` | `BIGINT` | `PRIMARY KEY`, Auto Increment | ID định danh mã chứng khoán |
| `symbol` | `VARCHAR(20)` | `NOT NULL`, `UNIQUE` | Mã chứng khoán (VD: `FXS`, `HNX`, `VND`, `ACB`) |
| `market` | `VARCHAR(20)` | `NOT NULL` | Phân đoạn thị trường (VD: `HNX`) |
| `status` | `VARCHAR(20)` | `NOT NULL` | Trạng thái (`ACTIVE`, `INACTIVE`, `SUSPENDED`) |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, Default `NOW()` | Thời điểm tạo bản ghi |

**Mẫu dữ liệu Seed (Liquibase)**:
- `FXS` | `HNX` | `ACTIVE`
- `HNX` | `HNX` | `ACTIVE`
- `VND` | `HNX` | `ACTIVE`

---

## 2. Thực thể Client State (Frontend App State)

### `SelectedSymbolState`
Trạng thái mã chứng khoán đang được chọn trên giao diện Frontend Angular.

```typescript
export interface SelectedSymbolState {
  symbol: string;         // Mã chứng khoán hiện tại (VD: 'HNX')
  source: 'url' | 'storage' | 'default'; // Nguồn khôi phục mã
}
```

**Quy tắc khôi phục (Recovery Rule)**:
1. Đọc từ URL parameter: `?symbol=HNX`
2. Đọc từ `localStorage`: `flex_selected_symbol`
3. Fallback: Mã `ACTIVE` đầu tiên từ API `GET /api/instruments`

---

## 3. Cấu trúc Dữ liệu API Models (Backend DTOs)

### `InstrumentView`
DTO trả về cho Frontend hiển thị danh sách Dropdown.

```csharp
public sealed record InstrumentView(
    long InstrumentId,
    string Symbol,
    string Market,
    string Status
);
```
