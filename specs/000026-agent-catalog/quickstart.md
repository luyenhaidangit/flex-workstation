# Quickstart & Hướng dẫn kiểm thử: Danh mục Agent

**Feature**: `000026-agent-catalog` | **Ngày**: 2026-08-01

Tài liệu này hướng dẫn cách chạy, xác minh và kiểm thử tính năng Danh mục Agent v1 end-to-end.

---

## 1. Yêu cầu tiên quyết & Môi trường

- .NET SDK 9.0+
- Node.js 18+ & Angular CLI (cho `flex-microfrontend`)
- PostgreSQL instance (`flexdb`) đang hoạt động (connection string trong `flex-agent-service/src/Flex.Agent.Api/appsettings.Development.json`)

---

## 2. Các bước thiết lập & Khởi chạy

### Bước 1: Migration Cơ sở dữ liệu

Chạy migration EF Core để tạo bảng `agents` trong PostgreSQL:

```bash
cd flex-agent-service
dotnet ef database update --project src/Flex.Agent.Infrastructures --startup-project src/Flex.Agent.Api
```

### Bước 2: Chạy Backend API (`flex-agent-service`)

```bash
cd flex-agent-service
dotnet run --project src/Flex.Agent.Api
```

API sẽ khởi chạy tại: `http://localhost:5000` (hoặc port được cấu hình).

### Bước 3: Chạy Frontend App (`flex-microfrontend`)

```bash
cd flex-microfrontend
npm install
npm run start
```

Mở trình duyệt truy cập: `http://localhost:4200/agents`.

---

## 3. Kịch bản xác minh (Validation Scenarios)

### Kịch bản 1: Đăng nhập & Truy cập Danh mục Agent (FR-007, SEC-003)

1. Mở trình duyệt truy cập `/agents` khi chưa đăng nhập.
2. **Kỳ vọng**: Hệ thống chuyển hướng sang màn hình đăng nhập hoặc từ chối truy cập.
3. Thực hiện đăng nhập tài khoản Quản trị viên.
4. Truy cập lại màn hình `/agents`.
5. **Kỳ vọng**: Màn hình Danh mục Agent hiển thị thành công.

### Kịch bản 2: Xem danh sách rỗng (AC-005)

1. Với database chưa có Agent nào, mở `/agents`.
2. **Kỳ vọng**: Giao diện hiển thị trạng thái rỗng rõ ràng ("Chưa có Agent nào trong danh mục. Bấm nút 'Tạo Agent mới' để bắt đầu.").

### Kịch bản 3: Tạo Agent thành công (AC-001, US-001)

1. Bấm nút **"Tạo Agent mới"**.
2. Nhập Tên: `"Sales Assistant Bot"`, Mô tả: `"Bot hỗ trợ tư vấn bán hàng"`.
3. Bấm **"Lưu"**.
4. **Kỳ vọng**: Agent mới được thêm vào danh sách và xuất hiện ngay lập tức trên UI với đúng tên và trạng thái `'active'`.

### Kịch bản 4: Kiểm tra Validation khi tạo (AC-002, AC-003, AC-010)

1. **Tên trống**: Nhập Tên trống hoặc khoảng trắng $\rightarrow$ **Kỳ vọng**: Nút Lưu bị vô hiệu hóa hoặc hệ thống báo lỗi `"Tên Agent không được để trống"`.
2. **Tên vượt quá 100 ký tự**: Nhập tên 101 ký tự $\rightarrow$ **Kỳ vọng**: Hệ thống từ chối và báo lỗi độ dài tên.
3. **Trùng tên**: Tạo agent mới có tên `"Sales Assistant Bot"` $\rightarrow$ **Kỳ vọng**: Backend trả về lỗi 409 Conflict `"Tên Agent đã tồn tại"`.
4. **Phân biệt chữ hoa/thường**: Tạo agent mới có tên `"sales assistant bot"` $\rightarrow$ **Kỳ vọng**: Tạo thành công (BR-001 cho phép trùng tên khác hoa/thường).

### Kịch bản 5: Xem chi tiết & Sửa Agent (AC-004, AC-006, AC-007)

1. Bấm vào nút **"Sửa"** trên Agent `"Sales Assistant Bot"`.
2. Đổi tên thành `"Sales Assistant Bot v2"`.
3. Bấm **"Lưu"**.
4. **Kỳ vọng**: Tên trên danh sách và màn chi tiết cập nhật ngay lập tức thành `"Sales Assistant Bot v2"`.

### Kịch bản 6: Xóa Agent với Popup xác nhận (AC-008, AC-009)

1. Bấm nút **"Xóa"** trên Agent `"Sales Assistant Bot v2"`.
2. **Kỳ vọng**: Màn hình hiển thị popup cảnh báo xác nhận xóa.
3. Bấm **"Hủy"** $\rightarrow$ Agent vẫn còn trong danh sách.
4. Bấm **"Xác nhận xóa"** $\rightarrow$ Agent biến mất khỏi danh sách vĩnh viễn.

---

## 4. Chạy Automated Tests

### Unit Tests Backend (`flex-agent-service`)

```bash
cd flex-agent-service
dotnet test tests/Flex.Agent.UnitTests
```

### Integration Tests Backend (`flex-agent-service`)

```bash
cd flex-agent-service
dotnet test tests/Flex.Agent.IntegrationTests
```
