# Research: Instagram Business Direct Login & Publish Integration

## Quyết định kỹ thuật & Tích hợp Luồng 1 (Instagram Login for Business)

### 1. Luồng OAuth 2.0 & Token Exchange (Instagram Login for Business)

- **Decision**: Sử dụng luồng **Direct Instagram Login for Business** (`instagram.com/oauth/authorize`).
- **Rationale**:
  - Cho phép người dùng đăng nhập bằng trực tiếp tài khoản Instagram Professional (Business/Creator) mà không bắt buộc liên kết với Facebook Page.
  - Phù hợp với định hướng kiểm thử giao diện xuất bản trực tiếp của FE.
- **Tham số Authorization URL**:
  - URL authorization: `https://www.instagram.com/oauth/authorize` hoặc `https://api.instagram.com/oauth/authorize`
  - Parameters:
    - `client_id`: Instagram App ID / Meta App ID (`939518829176551`)
    - `redirect_uri`: `http://localhost:4200/publish` (hoặc domain frontend tương ứng)
    - `scope`: `instagram_business_basic,instagram_business_content_publish`
    - `response_type`: `code`

### 2. Thành phần FE trong `flex-microfrontend` (Angular)

- **Decision**: Tạo mới một Angular Module / Component tên `PublishComponent` nằm tại `flex-microfrontend/src/app/pages/publish/` và đăng ký route `/publish` trong `app-routing.module.ts` (hoặc `pages-routing.module.ts`).
- **Rationale**: Tuân thủ kiến trúc hiện tại của `flex-microfrontend`.
- **Giao diện bao gồm**:
  1. **Header / Auth Status Bar**:
     - Nút "Đăng nhập Instagram" (kích hoạt luồng OAuth) / Hiển thị thông tin tài khoản Instagram (Access Token / User Info) sau khi đăng nhập.
     - Xử lý nhận URL query parameter `?code=...` khi Instagram redirect quay về `/publish`.
  2. **Publish Form (Soạn thảo bài đăng)**:
     - Input chọn file Media (Hình ảnh / Video preview).
     - Textarea soạn caption (đếm ký tự, hỗ trợ emoji / hashtag).
     - Nút "Đăng lên Instagram" (Publish Now).
  3. **Live Post Preview (Mô phỏng Instagram Post)**:
     - Card hiển thị mô phỏng thiết kế bài đăng Instagram (Header có Avatar + Username, Khung hiển thị ảnh/video, khu vực caption, timestamp, các icon Like/Comment/Share).
  4. **Log & Response Viewer Panel**:
     - Bảng ghi nhận kết quả API (Request Payload, Status Code, Response Body JSON, Error detail) giúp FE / QA dễ dàng debug.

### 3. Phân tách Mock / Production API Mode

- **Decision**: Hỗ trợ 2 chế độ trong `PublishComponent`:
  - **Mock Mode**: Dùng để test UI/UX ngay lập tức mà không cần token thật từ Instagram App.
  - **Live API Mode**: Gửi request trực tiếp đến Meta Graph API (`https://graph.instagram.com/v19.0/me/media` & `me/media_publish`) nếu có Access Token hợp lệ.
