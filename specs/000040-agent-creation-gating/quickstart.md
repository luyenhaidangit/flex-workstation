# Quickstart validation: Phân tách trạng thái tạo và cấu hình Agent

## Phạm vi

Hướng dẫn này xác minh UI Angular, route và hành vi gọi API hiện có sau implementation. Không yêu cầu migration hoặc backend draft mới.

## Chuẩn bị

1. Đứng tại thư mục `flex-microfrontend`.
2. Cài dependencies nếu môi trường chưa có:

   ```powershell
   npm install
   ```

3. Đảm bảo frontend có thể gọi Agent API hiện tại và người dùng đăng nhập có quyền quản lý Agent.

## Kiểm tra tự động

```powershell
npm run lint
npm run test -- --watch=false --browsers=ChromeHeadless
npm run build
```

Kết quả mong đợi: lint, unit test và build hoàn tất không lỗi.

## Manual smoke test

### 1. Trạng thái chưa tạo

1. Mở `/agents/create`.
2. Xác nhận tiêu đề là “Tạo Agent mới”; không có dòng “Cập nhật lúc”.
3. Xác nhận step 1 active; step 2-5 có lock icon và không chuyển bước.
4. Hover/focus/click step khóa; xác nhận thấy:

   ```text
   Vui lòng tạo Agent trước để tiếp tục cấu hình.
   ```

5. Xác nhận `Hội thoại`, `Báo cáo hoạt động` và input chat không thao tác được.
6. Mở Network tab, click step khóa và xác nhận không có POST `/api/v1/agents`.

### 2. Validation và tạo Agent

1. Click “Tạo Agent và tiếp tục” khi form invalid; xác nhận validation hiển thị và không có POST.
2. Nhập tên hợp lệ, click lại nút.
3. Xác nhận có một POST `/api/v1/agents` với status inactive theo contract hiện có.
4. Khi response có `id`, xác nhận điều hướng tới `/agents/{id}/settings`, hiển thị “Bản nháp” và stepper được mở khóa.

### 3. Lưu và tiếp tục

1. Ở Agent draft, thay đổi thông tin chung.
2. Click “Lưu và tiếp tục”.
3. Xác nhận validation chạy trước; với dữ liệu hợp lệ có một PUT `/api/v1/agents/{id}` và không chuyển status sang active.
4. Xác nhận người dùng chuyển sang bước cấu hình tiếp theo.

### 4. Regression

1. Mở Agent đã phát hành qua route detail/edit hiện có.
2. Xác nhận route cũ vẫn hoạt động và action “Lưu và phát hành lại” giữ hành vi hiện có.
3. Kiểm tra cancel khi form dirty, toggle channel và danh sách Agent không bị ảnh hưởng.

