# Research: Thiết kế Kỹ thuật Tùy chọn Mã Chứng khoán (Multi-symbol) & Lưu Trạng thái

## Phạm vi nghiên cứu

1. **`flex-microfrontend` (Angular Frontend)**:
   - Cơ chế quản lý state lựa chọn mã chứng khoán (symbol state).
   - Phối hợp giữa Angular Router Query Parameter (`?symbol=...`) và `localStorage`.
   - UI Component Dropdown chọn mã chứng khoán & tự động reload Sổ lệnh / Băng khớp lệnh.

2. **`flex-exchange-service` (ASP.NET Core Backend)**:
   - API `GET /api/instruments`: Trả về danh sách các mã chứng khoán ở trạng thái `ACTIVE`.
   - Cập nhật API `GET /api/orderbook?symbol={symbol}` và `GET /api/trades?symbol={symbol}`.
   - Quản lý đa Sổ lệnh (`MatchingEngine`) trong `ExchangeService` theo `symbol`.

3. **`flex-database` (PostgreSQL / Liquibase)**:
   - Seed thêm mã chứng khoán mẫu (ví dụ: `HNX`, `VND`, `ACB`) vào bảng `exchange_instruments`.

---

## Các quyết định kỹ thuật (Technical Decisions)

### TQ-001 — Thứ tự ưu tiên và cơ chế lưu trữ mã chứng khoán ở Frontend

**Quyết định**:
Khởi tạo mã chứng khoán khi load trang theo đúng thứ tự ưu tiên 3 bước:
1. **URL Query Parameter**: Kiểm tra param `?symbol=XYZ` trên đường dẫn URL.
2. **`localStorage`**: Nếu không có trên URL, đọc mã đã chọn gần nhất trong `localStorage.getItem('flex_selected_symbol')`.
3. **Mã mặc định**: Nếu cả hai đều không có hoặc không hợp lệ, lấy mã `ACTIVE` đầu tiên trả về từ API `GET /api/instruments` (fallback mặc định `FXS`).

Khi người dùng chọn mã mới trên giao diện:
- Cập nhật Angular Router Query Param `?symbol=NEW_SYMBOL` (không reload lại toàn bộ SPA page).
- Lưu mã mới vào `localStorage.setItem('flex_selected_symbol', 'NEW_SYMBOL')`.

**Lý do chọn**:
- Đảm bảo tính linh hoạt: Vừa hỗ trợ lưu bookmark/chia sẻ URL trực tiếp cho người khác, vừa giữ trải nghiệm cá nhân hóa khi F5/reload trang mà không mất state.

---

### TQ-002 — Thiết kế API Backend hỗ trợ đa mã chứng khoán (Multi-symbol Contracts)

**Quyết định**:
- **Bổ sung API `GET /api/instruments`**: Trả về `IReadOnlyList<InstrumentView>` gồm các mã đang có trạng thái `ACTIVE`.
- **Cập nhật `GET /api/orderbook`**: Cho phép truyền `[FromQuery] string? symbol`. Nếu `symbol` rỗng, mặc định lấy `FXS` để bảo đảm tương thích ngược (Backward Compatibility).
- **Cập nhật `GET /api/trades`**: Cho phép truyền `[FromQuery] string? symbol`. Nếu `symbol` rỗng, mặc định lấy `FXS`.
- **`POST /api/orders`**: Request payload đã có trường `symbol`. Backend sẽ validate xem `symbol` này có tồn tại và đang `ACTIVE` trong `exchange_instruments` không trước khi nhận lệnh.

**Lý do chọn**:
- Giữ tương thích ngược 100% với các client cũ (nếu không truyền `symbol` thì tự động fallback về `FXS`).
- Tuân thủ chuẩn RESTful API đơn giản và dễ kiểm thử.

---

### TQ-003 — Quản lý nhiều Sổ lệnh (Multi MatchingEngine) trong Backend Service

**Quyết định**:
Trong `ExchangeService`, thay thế biến đơn `MatchingEngine` bằng bộ quản lý thread-safe `ConcurrentDictionary<string, MatchingEngine>` với key là mã `symbol` (đã viết hoa / normalized).

Khi nhận request đặt lệnh hoặc lấy sổ lệnh:
- Tìm `MatchingEngine` tương ứng trong dictionary theo `symbol`.
- Nếu chưa có, tự động tạo mới hoặc load trạng thái của `symbol` đó từ Database.

**Lý do chọn**:
- Đảm bảo tính độc lập tuyệt đối giữa các Sổ lệnh của từng mã chứng khoán. Khớp lệnh mã `HNX` không làm ảnh hưởng hay tranh chấp lock với mã `FXS`.

---

## Kết luận

Giải pháp thiết kế đảm bảo đáp ứng đầy đủ tất cả các yêu cầu trong `spec.md`, đồng thời duy trì tính tương thích ngược và giữ kiến trúc đơn giản, sạch sẽ (Phẫu thuật & Đơn giản theo Constitution).
