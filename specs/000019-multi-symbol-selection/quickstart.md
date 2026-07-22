# Quickstart Verification: Tùy chọn Mã chứng khoán & Khôi phục Trạng thái

Hướng dẫn này mô tả các bước xác minh luồng tùy chọn mã chứng khoán (Multi-symbol) và ghi nhớ mã đã chọn khi reload trang end-to-end.

---

## Điều kiện chuẩn bị (Prerequisites)

1. **Database PostgreSQL** đã được chạy Liquibase changeset seed thành công các mã chứng khoán (`FXS`, `HNX`, `VND`).
2. **Backend API (`flex-exchange-service`)** chạy tại `http://localhost:5266`.
3. **Frontend Angular (`flex-microfrontend`)** chạy tại `http://localhost:4200`.

---

## 🧪 Kịch bản kiểm thử nhanh (Verification Steps)

### Kịch bản 1: Kiểm tra Danh sách mã chứng khoán và chuyển đổi (US-001)

1. Mở trình duyệt và truy cập: `http://localhost:4200/exchange`.
2. Kiểm tra ô Dropdown **Mã chứng khoán**: Hiển thị danh sách các mã `FXS`, `HNX`, `VND`.
3. Chọn mã `HNX` từ Dropdown.
4. **Kỳ vọng**:
   - Giao diện Sổ lệnh (Bids/Asks) và Băng khớp lệnh (Trade Tape) làm sạch và cập nhật dữ liệu của mã `HNX`.
   - Đường dẫn URL trên thanh địa chỉ tự động chuyển thành `http://localhost:4200/exchange?symbol=HNX`.

---

### Kịch bản 2: Kiểm tra Khôi phục mã sau khi Reload trang (US-002)

1. Đang ở màn hình mã `HNX` (`http://localhost:4200/exchange?symbol=HNX`).
2. Bấm phím `F5` hoặc nút Reload trên trình duyệt.
3. **Kỳ vọng**:
   - Giao diện tải lại thành công.
   - Dropdown mã chứng khoán vẫn giữ nguyên lựa chọn `HNX`.
   - Dữ liệu Sổ lệnh hiển thị đúng của mã `HNX`.

---

### Kịch bản 3: Kiểm tra đặt lệnh đúng theo mã chứng khoán đang chọn (AC-002)

1. Chọn mã `VND` trên Dropdown.
2. Nhập lệnh MUA: Giá `30`, Khối lượng `500`.
3. Bấm **Đặt lệnh**.
4. **Kỳ vọng**: Lệnh được đặt thành công cho mã `VND` và Sổ lệnh của mã `VND` xuất hiện khối lượng dư mua mới.

---

### Kịch bản 4: Kiểm tra chia sẻ link trực tiếp (URL Query Param)

1. Mở một tab mới trên trình duyệt và dán link: `http://localhost:4200/exchange?symbol=FXS`.
2. **Kỳ vọng**: Giao diện tự động mở ngay mã `FXS` mà không phụ thuộc vào `localStorage` của tab trước đó.
