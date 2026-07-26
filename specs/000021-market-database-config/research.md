# Nghiên cứu kỹ thuật: Chuyển cấu hình danh sách market và schedule từ hardcode JSON sang CSDL

**Feature**: `000021-market-database-config`  
**Ngày**: 2026-07-26  

---

## 1. Nghiên cứu & Quyết định thiết kế CSDL (Database Schema)

### Vấn đề / Yêu cầu
Cần lưu trữ danh sách thị trường (`HOSE`, `HNX`, `UPCOM`, `DERIVATIVES`) và tất cả các thuộc tính thời lượng phiên giao dịch (`has_ato`, `has_plo`, `pre_open_duration_seconds`, `ato_duration_seconds`, `continuous_duration_seconds`, `intermission_duration_seconds`, `continuous2_duration_seconds`, `atc_duration_seconds`, `plo_duration_seconds`) trong CSDL thay vì `appsettings.json`. Yêu cầu gộp chung thông tin thị trường và cấu hình phiên vào cùng **1 bảng duy nhất**.

### Quyết định kỹ thuật [DEC-001]
Tạo bảng `exchange_markets` trong CSDL PostgreSQL (`flex-database/securities`).

- **Lý do chọn**: Gộp chung toàn bộ thông tin thị trường và tham số phiên giúp thiết kế CSDL đơn giản, tránh việc phải JOIN 2 bảng trong các truy vấn tần suất cao của vòng lặp phiên giao dịch (`SessionWorker`).
- **Phương án bị loại**: Tách 2 bảng `markets` và `market_schedules`.
- **Lý do loại**: Tăng độ phức tạp truy vấn không cần thiết khi quan hệ giữa thị trường và cấu hình lịch phiên ở hiện tại là 1-1.

---

## 2. Nghiên cứu & Quyết định Caching & Performance trong `flex-exchange-service`

### Vấn đề / Yêu cầu
`SessionWorker` chạy vòng lặp kiểm tra trạng thái phiên liên tục. Nếu mỗi chu kỳ vòng lặp đều đọc CSDL trực tiếp sẽ tạo tải không cần thiết lên CSDL.

### Quyết định kỹ thuật [DEC-002]
Sử dụng **In-Memory Caching (`IMemoryCache`)** bọc ngoài `MarketRepository` trong `flex-exchange-service` với thời gian hết hạn (expiration) ngắn (hoặc nạp snapshot khi khởi động phiên).

- **Lý do chọn**: Giúp truy vấn danh sách thị trường và cấu hình phiên có độ trễ siêu thấp (<1ms) từ bộ nhớ RAM, đồng thời đảm bảo khi phiên giao dịch mới bắt đầu, dịch vụ sẽ đọc cấu hình mới nhất từ CSDL.
- **Quy tắc runtime**: Thay đổi cấu hình thị trường trong CSDL khi phiên đang chạy sẽ chỉ áp dụng ở chu kỳ/phiên tiếp theo (đúng theo quy tắc `BR-004`).

---

## 3. Nghiên cứu & Quyết định Tương thích ngược & Fallback

### Vấn đề / Yêu cầu
Đảm bảo khi ứng dụng nâng cấp, nếu CSDL chưa kịp chạy Migration hoặc kết nối CSDL tạm thời lỗi lúc ứng dụng boot up, ứng dụng không bị crash đột ngột.

### Quyết định kỹ thuật [DEC-003]
Cơ chế **Database First với Fallback về Options**: `MarketRepository` ưu tiên đọc dữ liệu từ CSDL `exchange_markets`. Nếu CSDL trống hoặc không thể truy vấn, hệ thống ghi log cảnh báo và fallback về `TradingSessionOptions` trong `appsettings.json`.

- **Lý do chọn**: Đảm bảo tính sẵn sàng (High Availability) cho `flex-exchange-service`.
