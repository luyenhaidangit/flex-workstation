# Danh sách Task triển khai: Trang Publish Kiểm Thử Tích Hợp Instagram

**Branch**: `000024-instagram-publish` | **Đặc tả**: [spec.md](./spec.md) | **Kế hoạch**: [plan.md](./plan.md)

---

## Phase 1: Setup

- [x] T001 Tạo thư mục component `publish` tại `flex-microfrontend/src/app/pages/publish/`

---

## Phase 2: Foundational (Khai báo Router & Module)

- [x] T002 Đăng ký route `/publish` trong routing module `flex-microfrontend/src/app/pages/pages-routing.module.ts` (hoặc `app-routing.module.ts`)

---

## Phase 3: User Story 1 - Soạn thảo & Xem trước Instagram Post (P1)

- [x] T003 [P] [US1] Định nghĩa TypeScript interface cho bài đăng, OAuth token và log entry tại `flex-microfrontend/src/app/pages/publish/publish.types.ts`
- [x] T004 [US1] Xây dựng HTML layout Form soạn thảo, Live Post Preview và Log Panel tại `flex-microfrontend/src/app/pages/publish/publish.component.html`
- [x] T005 [P] [US1] Thiết kế SCSS cho khung mô phỏng Instagram Post, Form controls và Log Viewer tại `flex-microfrontend/src/app/pages/publish/publish.component.scss`
- [x] T006 [US1] Viết logic Angular Component xử lý Data Binding cho Live Preview và Tải ảnh/Video tại `flex-microfrontend/src/app/pages/publish/publish.component.ts`

---

## Phase 4: User Story 2 - Xuất bản & OAuth Instagram Direct Login (P1)

- [x] T007 [US2] Viết logic xử lý Direct Instagram Login OAuth Redirect/Callback (`?code=...`) và Đăng bài (Mock & Live API) tại `flex-microfrontend/src/app/pages/publish/publish.component.ts`
- [x] T008 [US2] Cập nhật bảng Log Viewer hiển thị realtime thông báo kết quả đăng bài tại `flex-microfrontend/src/app/pages/publish/publish.component.html`

---

## Phase 5: Polish & Integration

- [x] T009 Khai báo `PublishComponent` trong Angular Module `flex-microfrontend/src/app/pages/publish/publish.module.ts`
- [x] T010 Khởi chạy FE server và xác minh kiểm thử giao diện trang `/publish`
