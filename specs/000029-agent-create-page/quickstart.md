# Hướng dẫn chạy & Kiểm thử (Quickstart & Validation Guide)

## 1. Yêu cầu môi trường

- Node.js 14+ / 16+
- Angular CLI
- Project `flex-microfrontend` đang chạy ở `http://localhost:4200`

---

## 2. Các bước chạy thử nghiệm

1. Mở terminal tại thư mục `c:\Workspace\Project\flex-workstation\flex-microfrontend`.
2. Khởi động ứng dụng local:
   ```bash
   npm run start
   ```
3. Mở trình duyệt tại địa chỉ `http://localhost:4200/agents`.

---

## 3. Kịch bản kiểm thử (Validation Scenarios)

### Kịch bản 1: Mở trang mới từ nút Thêm mới
1. Tại trang `/agents`, bấm nút **+ Thêm mới**.
2. **Kỳ vọng**: Trình duyệt chuyển sang URL `http://localhost:4200/agents/create` (không mở popup dialog như trước). Trang hiển thị layout Stepper 7 bước bên trái và form "Thiết lập thông tin chung" ở giữa.

### Kịch bản 2: Kiểm tra Form Bước 1 & Cập nhật Live Card Header
1. Nhập Tên agent (ví dụ: `Mai Hương`), Vai trò (`Nhân viên AI tư vấn...`).
2. Chọn Cấp thực hiện (Cấp tỉnh), chọn Cơ quan thực hiện.
3. Nhập nội dung Chỉ dẫn cho Agent.
4. **Kỳ vọng**: Card tóm tắt Agent ở góc trên bên trái tự động cập nhật Tên và Vai trò vừa nhập theo real-time.

### Kịch bản 3: Chuyển bước & Validation
1. Để trống Tên agent, bấm nút **Tiếp tục**.
2. **Kỳ vọng**: Đèn báo lỗi xuất hiện ở trường Tên agent, hệ thống giữ nguyên người dùng ở Bước 1.
3. Nhập đầy đủ thông tin bắt buộc và bấm **Tiếp tục**.
4. **Kỳ vọng**: Chuyển sang Bước 2 ("Thêm thủ tục hành chính..."), trên Stepper bước 1 hiển thị mốc xanh đã hoàn thành, bước 2 được active.

### Kịch bản 4: Hủy thao tác & Cảnh báo
1. Nhập dở thông tin, bấm nút **Hủy** (hoặc nút **X** ở góc phải).
2. **Kỳ vọng**: Hiển thị popup cảnh báo xác nhận dữ liệu chưa lưu. Bấm **Đồng ý**, trình duyệt chuyển quay lại `/agents`.
