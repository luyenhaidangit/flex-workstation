# Quickstart & Verification Guide: Instagram Publish Page `/publish`

## Hướng dẫn kiểm thử & Xác minh tính năng

### 1. Khởi chạy ứng dụng FE
```bash
cd flex-microfrontend
npm run start
```
Ứng dụng sẽ mở tại `http://localhost:4200/`.

### 2. Kịch bản kiểm thử (Test Scenarios)

#### Scenario 1: Kiểm thử giao diện & Live Preview bài đăng
1. Truy cập đường dẫn: `http://localhost:4200/publish`
2. Kiểm tra giao diện hiển thị 3 cột chính:
   - Form soạn thảo nội dung (nằm bên trái).
   - Khung xem trước Instagram Post Live Preview (nằm ở giữa).
   - Bảng nhật ký trạng thái Log Viewer (nằm bên phải/phía dưới).
3. Thao tác chọn ảnh từ máy tính hoặc nhập URL hình ảnh.
4. Gõ nội dung văn bản caption kèm hashtag trong ô soạn thảo.
5. **Kì vọng**: Khung Preview cập nhật tức thì hình ảnh và chữ hiển thị theo đúng dữ liệu đã nhập.

#### Scenario 2: Mô phỏng xuất bản bài đăng (Mock Publish Mode)
1. Giữ nguyên chế độ mặc định `Mock Mode`.
2. Bấm nút **"Đăng lên Instagram (Mock)"**.
3. **Kì vọng**:
   - Nút đăng bài đổi thành trạng thái "Đang xuất bản..." và bị disable.
   - Sau 1-2 giây, hiển thị thông báo thành công.
   - Bảng Log Viewer ghi lại chi tiết các bước mô phỏng (Tạo Media Container -> Kiểm tra Status -> Publish Media -> Thành công với Post ID mẫu).

#### Scenario 3: Đăng nhập thật và xuất bản qua Instagram Direct Login (Live API Mode)
1. Chuyển chế độ sang `Live API Mode`.
2. Bấm nút **"Đăng nhập Instagram Business"**. Trình duyệt sẽ mở trang OAuth authorize của Instagram.
3. Sau khi đồng ý cấp quyền, Instagram sẽ redirect lại về `http://localhost:4200/publish?code=...`.
4. Trang tự động lấy `code`, hiển thị Access Token / User Info và cho phép đăng bài thật lên tài khoản Instagram đã kết nối.
