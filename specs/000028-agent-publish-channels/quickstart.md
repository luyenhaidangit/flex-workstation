# Quickstart: Tab Thiết lập thông tin chung & Phát hành đa kênh cho Agent

**Feature**: `specs/000028-agent-publish-channels` | **Ngày**: 2026-08-05

Hướng dẫn xác minh tính năng end-to-end sau khi implement. Không lặp lại chi tiết API/data model — xem [contracts/agent-publish-channels-api.md](contracts/agent-publish-channels-api.md) và [data-model.md](data-model.md).

---

## Chuẩn bị

1. Migration `flex-database/agentdb/migrations/V1.2__create_table_agent_publish_locations.sql` đã chạy trên môi trường test (verify: `\d agent_publish_locations` trong `psql` thấy đúng cột và `UNIQUE(agent_id, location_code)`).
2. `flex-agent-service` (`Flex.Agent.Api`) đang chạy, có JWT token hợp lệ của quản trị viên (theo cơ chế đã có ở `specs/000026-agent-catalog`).
3. `flex-microfrontend` đang chạy, đã đăng nhập bằng tài khoản quản trị viên.
4. Có sẵn ít nhất 1 agent trong danh mục (tạo trước qua UI nếu chưa có).

---

## Kịch bản 1 — Tab mặc định & không phá vỡ luồng cũ (US-001)

1. Mở màn hình chi tiết/sửa một agent đã có.
2. **Kỳ vọng**: Modal hiển thị 2 tab — "Thiết lập thông tin chung" (đang active) và "Phát hành". Tab đầu chứa đúng tên/mô tả/trạng thái hiện có.
3. Sửa tên hoặc mô tả, bấm "Cập nhật".
4. **Kỳ vọng**: Lưu thành công, toast "Cập nhật Agent thành công.", hành vi giống hệt trước khi có tab (AC-001, AC-002).

## Kịch bản 2 — Tab Phát hành bị khóa khi tạo agent mới (US-001/FR-007)

1. Bấm "Thêm mới Agent".
2. **Kỳ vọng**: Tab "Phát hành" hiển thị ở trạng thái vô hiệu hóa/không bấm được cho tới khi tạo agent thành công (AC-003).

## Kịch bản 3 — Bật kênh Website và lưu chung với thông tin chung (US-002, FR-008)

1. Mở agent đã có (chưa từng bật kênh nào), chuyển sang tab "Phát hành".
2. **Kỳ vọng**: 5 kênh hiển thị đủ (Fanpage Facebook, Zalo OA, Website, Chatbot, Zalo cá nhân); chỉ công tắc Website bấm được, 4 kênh còn lại ở trạng thái vô hiệu hóa "chưa khả dụng" (AC-009, AC-010).
3. Bật công tắc Website. **Chưa** bấm "Lưu" — tải lại trang.
4. **Kỳ vọng**: Sau khi tải lại, kênh Website trở về trạng thái tắt (thay đổi chưa lưu bị mất — AC-008 đúng như thiết kế).
5. Lặp lại: bật công tắc Website, lần này bấm nút "Lưu" (nút chung dùng cho cả 2 tab).
6. **Kỳ vọng**: Toast lưu thành công. `GET /api/v1/agents/{id}` (hoặc mở lại modal) trả về `publishLocations: [{ locationCode: "website", isEnabled: true }]` (AC-004, AC-005).

## Kịch bản 4 — Tắt kênh đã bật (US-003)

1. Với agent ở Kịch bản 3 (Website đang bật), mở lại tab "Phát hành", tắt công tắc Website, bấm "Lưu".
2. **Kỳ vọng**: Toast lưu thành công. Mở lại tab "Phát hành" lần nữa, Website hiển thị tắt (AC-007).

## Kịch bản 5 — Chặn ghi kênh ngoài whitelist MVP (FR-009, validate tầng API)

1. Gọi trực tiếp `PUT /api/v1/agents/{id}` với `publishLocations: [{ "locationCode": "facebook_fanpage", "isEnabled": true }]` (dùng Postman/curl, không qua UI vì UI đã chặn ở client).
2. **Kỳ vọng**: HTTP 400, `ErrorResponse.code = "PUBLISH_LOCATION_NOT_AVAILABLE"`.

## Kịch bản 6 — Regression danh mục agent (SC-003)

1. Chạy lại 6 kịch bản quickstart của `specs/000026-agent-catalog/quickstart.md` (tạo, xem danh sách/chi tiết, sửa, xóa, validate tên trùng/độ dài).
2. **Kỳ vọng**: Toàn bộ vẫn pass không đổi hành vi, chỉ khác vị trí hiển thị (trong tab "Thiết lập thông tin chung" thay vì form phẳng).
