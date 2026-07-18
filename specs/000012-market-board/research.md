# Nghiên cứu MVP 3 — Bảng điện thị trường demo

## R1 — Biên triển khai giao diện

**Decision**: Triển khai bảng điện trong `flex-microfrontend` bằng một feature module lazy-loaded tại route công khai `/exchange`.

**Rationale**: Đây là repository frontend hiện có, dùng Angular 16, NgModule và SCSS. Route hiện tại nằm dưới `AuthGuard`, trong khi spec yêu cầu demo chưa có đăng nhập; route riêng ngoài nhánh được bảo vệ giữ đúng phạm vi mà không làm thay đổi authentication hiện hữu.

**Alternatives considered**:
- Tạo một ứng dụng frontend mới: loại vì làm tăng chi phí deploy và không cần thiết cho một màn hình demo.
- Đặt trong `pages`: loại vì toàn bộ nhánh này đang yêu cầu đăng nhập.

## R2 — Nguồn dữ liệu thị trường

**Decision**: Dùng trực tiếp các endpoint đã có của `flex-exchange-service`: `GET /api/orderbook`, `GET /api/trades`, `GET /api/orders/{orderId}`, `POST /api/orders` và `DELETE /api/orders/{orderId}`.

**Rationale**: MVP 02 đã cung cấp snapshot, trade tape, trạng thái lệnh và command place/cancel. MVP 3 chỉ trình bày và điều phối dữ liệu, không tạo nguồn tính giá hoặc matching thứ hai.

**Alternatives considered**:
- Thêm endpoint tổng hợp mới: loại vì chưa có nhu cầu nghiệp vụ và làm tăng contract/backend scope.
- Đọc event stream để tự dựng order book ở browser: loại vì dễ lệch với snapshot authoritative của Exchange.

## R3 — Cơ chế cập nhật

**Decision**: Polling có chu kỳ cấu hình được, mặc định 2 giây; dừng khi component bị hủy và không làm mất dữ liệu cuối cùng khi một lần gọi thất bại.

**Rationale**: Spec cho phép polling và MVP chưa yêu cầu realtime push. Chu kỳ 2 giây đáp ứng NFR-002 tối đa 3 giây trong điều kiện bình thường, đồng thời đơn giản hơn SignalR/WebSocket.

**Alternatives considered**:
- SignalR/WebSocket: loại khỏi MVP vì cần thêm server contract, lifecycle và vận hành realtime.
- Chỉ cập nhật sau thao tác form: loại vì không phản ánh được lệnh đối ứng từ phiên khác.

## R4 — Tích hợp URL và browser

**Decision**: Thêm `exchangeApiBaseUrl` vào environment của Angular; client dùng URL này cho các request Exchange. Cấu hình dev trỏ tới profile HTTP `http://localhost:5266`, production để giá trị deploy cung cấp.

**Rationale**: `apiBaseUrl` hiện có phục vụ backend khác và interceptor tự gắn bearer token cho URL đó. URL riêng giúp bảng điện demo không phụ thuộc gateway/auth và tránh hard-code endpoint trong component.

**Alternatives considered**:
- Dùng URL tương đối qua `apiBaseUrl`: loại vì không bảo đảm gateway đã route Exchange.
- Hard-code port trong service: loại vì không phù hợp nhiều môi trường.

## R5 — Contract và lỗi

**Decision**: Giữ nguyên JSON contract MVP 02, ánh xạ các enum `Buy/Sell` và reject reason bằng typed frontend models; hiển thị `ProblemDetails` hoặc reason nghiệp vụ bằng thông báo an toàn.

**Rationale**: Đây là thay đổi additive ở consumer; không cần breaking change. UI cần phân biệt lỗi validation, rejection nghiệp vụ, timeout và lỗi kết nối để không báo thành công giả.

**Alternatives considered**:
- Parse response thành `any`: loại vì làm mất kiểm tra compile-time và dễ lỗi khi API thay đổi.
- Thay đổi response backend chỉ để phù hợp UI: loại vì contract hiện tại đã đủ dữ liệu.

## R6 — Bảo mật và tài khoản demo

**Decision**: Route công khai chỉ cho phép chọn hai broker demo từ cấu hình frontend; không nhận broker tùy ý từ người dùng và không lưu token/secret.

**Rationale**: Spec loại trừ auth thật nhưng vẫn yêu cầu không thao tác ngoài phạm vi demo. Backend tiếp tục là nguồn xác nhận cuối cùng; UI không được coi dữ liệu form là quyền sở hữu.

**Alternatives considered**:
- Tích hợp JWT/Keycloak ngay trong MVP 3: loại vì nằm ngoài phạm vi và sẽ gắn chặt demo với auth chưa được triển khai.

## R7 — Không có thay đổi dữ liệu bền vững

**Decision**: Không migration, backfill, database hoặc local persistence riêng cho bảng điện. Refresh đọc lại trạng thái từ Exchange.

**Rationale**: Exchange MVP 02 đang giữ state trong process và spec yêu cầu refresh không mất dữ liệu đã được Exchange xác nhận, không yêu cầu UI lưu dữ liệu nghiệp vụ.

**Alternatives considered**:
- Lưu order/trade vào browser storage: loại vì có thể hiển thị stale data và tạo nguồn sự thật thứ hai.
