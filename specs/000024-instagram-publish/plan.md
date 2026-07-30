# Kế hoạch triển khai: Trang Publish Kiểm Thử Tích Hợp Instagram

**Branch**: `000024-instagram-publish` | **Ngày**: 2026-07-30 | **Đặc tả**: [spec.md](./spec.md)

**Đầu vào**: Đặc tả tính năng từ `/specs/000024-instagram-publish/spec.md`

## Tóm tắt

**Yêu cầu chính từ spec**: Tạo trang FE kiểm thử tại đường dẫn `/publish` tích hợp luồng Instagram Direct Login (Luồng 1), hỗ trợ xem trước bài viết (Live Post Preview), form nhập caption/media, nút bấm xuất bản bài đăng và bảng theo dõi log trạng thái.

**Hướng tiếp cận kỹ thuật dự kiến**:
- Tạo `PublishModule` / `PublishComponent` trong dự án Angular `flex-microfrontend`.
- Đăng ký router path `/publish` trong routing module.
- Xây dựng giao diện rich UI hiện đại (glassmorphism/dark/light aesthetic) cho trang `/publish`.
- Xử lý nhận OAuth query callback (`?code=...`), hỗ trợ chuyển đổi giữa `Mock Mode` (kiểm thử nhanh UI) và `Live API Mode` (gọi Meta Graph API thật).

**Kết quả sau research**: Đã thống nhất áp dụng Luồng 1 (Instagram Login for Business OAuth 2.0 direct). Xem chi tiết tại [research.md](./research.md).

## Phạm vi kỹ thuật

**Trong phạm vi**:
- Tạo Angular Component và Module tại `flex-microfrontend/src/app/pages/publish/`.
- Cập nhật routing `flex-microfrontend/src/app/app-routing.module.ts` (hoặc `pages-routing.module.ts`) khai báo `/publish`.
- Xây dựng UI Form: Media Upload/URL, Caption Editor, Post Live Preview, OAuth Login Bar, Log/Status Monitor.
- Logic Angular Service hoặc Component helper xử lý OAuth callback và API requests.

**Ngoài phạm vi kỹ thuật**:
- Thay đổi cấu trúc backend hay database.

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: TypeScript / Node.js
**Service/App liên quan**: `flex-microfrontend` (Angular application)
**Phụ thuộc chính**: Angular Reactive/Template Forms, RxJS, HttpClient
**Loại project**: Frontend Web Application (Angular SPA)
**Mục tiêu hiệu năng**: Phản hồi UI tức thì (<50ms khi gõ caption hoặc thay ảnh preview)
**Nền tảng chạy**: Browser / Web

## Kiểm tra constitution

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| Đơn giản là ưu tiên | Pass | Pass | Chỉ tập trung vào UI/UX kiểm thử trang `/publish` |
| Thay đổi phẫu thuật | Pass | Pass | Chỉ thêm component/route mới tại `flex-microfrontend` |

## Thiết kế tổng quan

**Luồng chính**:
1. Người dùng điều hướng tới `http://localhost:4200/publish`.
2. Trình duyệt render giao diện Publish Test Suite gồm 3 cột:
   - Form soạn thảo bài đăng (Caption, Media Picker, Post Button, Mode Switcher).
   - Card Live Post Preview (mô phỏng bài viết Instagram).
   - Log Viewer Panel (theo dõi tiến trình API/mock).
3. Nếu bấm "Đăng nhập Instagram": Chuyển hướng đến `https://www.instagram.com/oauth/authorize`. Khi đăng nhập xong, Instagram chuyển hướng về `/publish?code=...`, component lấy `code` ghi nhận token và sẵn sàng xuất bản.

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|------------|----------------------|---------------------|--------------|-------------|----------|
| US-001 / FR-001 | P1 | Đủ rõ | Khai báo route `/publish` trỏ tới `PublishComponent` | `flex-microfrontend/src/app/app-routing.module.ts` | Route path `/publish` | Không áp dụng | Manual / E2E |
| US-001 / FR-002 | P1 | Đủ rõ | Form soạn thảo caption và tải media | `flex-microfrontend/src/app/pages/publish/publish.component.ts` | Form binding | `PublishPostDraft` | Manual |
| US-001 / FR-003 | P1 | Đủ rõ | Thẻ HTML/CSS mô phỏng Instagram Post Preview | `flex-microfrontend/src/app/pages/publish/publish.component.html` | UI Binding | `PublishPostDraft` | Manual |
| US-002 / FR-004, FR-005 | P1 | Đủ rõ | Nút Đăng bài + Bảng Log Monitor | `flex-microfrontend/src/app/pages/publish/publish.component.ts` | Async API / Mock service | `PublishLogEntry` | Manual |

## Cấu trúc project

### Source code (`flex-microfrontend`)

```text
flex-microfrontend/
└── src/
    └── app/
        ├── app-routing.module.ts
        └── pages/
            └── publish/
                ├── publish.module.ts
                ├── publish-routing.module.ts
                ├── publish.component.ts
                ├── publish.component.html
                └── publish.component.scss
```

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoại phase đã rõ.
- [x] Thiết kế tổng quan đã mô tả luồng chính và component tham gia.
- [x] Trạng thái kiểm tra constitution đã đạt.
