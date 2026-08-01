# Data Model: Danh mục Agent (CRUD cơ bản)

**Feature**: `000026-agent-catalog` | **Ngày**: 2026-08-01

Tài liệu này mô tả chi tiết mô hình dữ liệu cho tính năng Danh mục Agent v1.

---

## 1. PostgreSQL `flexdb` — Control Plane Catalog

### Bảng `agents`

Bảng `agents` lưu trữ danh mục thông tin định danh cơ bản của từng Agent trong hệ thống.

```sql
CREATE TABLE IF NOT EXISTS agents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_agents_name UNIQUE (name)
);
```

#### Chi tiết các cột:

| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---------|--------------|-----------|-------|
| `id` | `UUID` | `PRIMARY KEY` | Khóa chính dạng UUID v4 tự động sinh |
| `name` | `VARCHAR(100)` | `NOT NULL, UNIQUE` | Tên của Agent. Phải duy nhất, phân biệt hoa/thường (BR-001), tối đa 100 ký tự |
| `description` | `VARCHAR(500)` | `NULL` | Mô tả chi tiết vai trò/chức năng Agent. Tùy chọn, tối đa 500 ký tự |
| `status` | `VARCHAR(20)` | `NOT NULL` | Trạng thái Agent. Giá trị v1 mặc định `'active'` |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL` | Thời điểm tạo bản ghi |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL` | Thời điểm cập nhật bản ghi gần nhất |

---

## 2. Quy tắc Validation Dữ liệu

1. **`name`**:
   - Bắt buộc (`NOT NULL`, không được để trống hoặc chỉ có khoảng trắng).
   - Độ dài: $1 \le \text{length}(name) \le 100$ ký tự (AC-010, BR-004).
   - Duy nhất: So sánh có phân biệt chữ hoa/chữ thường (Case-sensitive exact match). Ví dụ: `"Agent Sales"` và `"agent sales"` được phép tồn tại đồng thời (BR-001).

2. **`description`**:
   - Tùy chọn (`NULL` hoặc chuỗi rỗng).
   - Độ dài: $0 \le \text{length}(description) \le 500$ ký tự (AC-010, BR-004).

3. **`status`**:
   - Chuỗi định danh trạng thái: `'active'` (hoặc `'inactive'` nếu được vô hiệu hóa sau này). Ở v1 mặc định `'active'`.

---

## 3. Chuyển đổi trạng thái & Vòng đời dữ liệu

- **Tạo (Create)**: Chèn bản ghi mới vào `agents` với `id` sinh mới, `status = 'active'`, `created_at = updated_at = NOW()`.
- **Đọc (Read)**: Truy vấn tất cả hoặc theo `id`. Ở v1 quy mô nhỏ (<100 agent), lấy toàn bộ danh sách xếp theo `created_at DESC`.
- **Sửa (Update)**: Cập nhật `name`, `description`, và `updated_at = NOW()`. Kiểm tra không được trùng tên với `id` khác.
- **Xóa (Delete)**: Xóa vĩnh viễn bản ghi khỏi bảng `agents` sau khi người dùng xác nhận trên UI (BR-003).

---

## 4. DTO & Model Contracts

### AgentResponseDto
```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "name": "Customer Support Bot",
  "description": "Agent hỗ trợ giải đáp thắc mắc khách hàng 24/7",
  "status": "active",
  "createdAt": "2026-08-01T10:00:00Z",
  "updatedAt": "2026-08-01T10:00:00Z"
}
```

### CreateAgentRequestDto
```json
{
  "name": "Customer Support Bot",
  "description": "Agent hỗ trợ giải đáp thắc mắc khách hàng 24/7"
}
```

### UpdateAgentRequestDto
```json
{
  "name": "Customer Support Bot v2",
  "description": "Agent hỗ trợ giải đáp thắc mắc nâng cao"
}
```
