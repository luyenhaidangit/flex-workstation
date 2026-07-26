# Đặc tả tính năng: Chuyển cấu hình danh sách market và schedule từ hardcode JSON sang CSDL

**Branch**: `000021-market-database-config`  
**Ngày tạo**: 2026-07-26  
**Trạng thái**: Bản nháp  
**Người phụ trách**: Admin  
**Stakeholder xác nhận**: Admin  
**Đầu vào**: Chuyển cấu hình danh sách market và lịch phiên giao dịch từ hardcode JSON sang lưu trữ trực tiếp trong CSDL (gộp chung thông tin market và schedule trong cùng 1 thực thể/bảng, không tách bảng riêng).

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:
Hiện tại, danh sách các thị trường giao dịch (`HOSE`, `HNX`, `UPCOM`, `DERIVATIVES`) và cấu hình thời lượng các phiên giao dịch tương ứng (`PreOpen`, `ATO`, `Continuous`, `Intermission`, `ATC`, `PLO`) đang được cấu hình cố định trong file JSON (`appsettings.json`). Mỗi khi hệ thống cần bổ sung thị trường mới hoặc điều chỉnh thời gian/tính chất phiên, quản trị viên bắt buộc phải sửa file cấu hình và khởi động lại dịch vụ `flex-exchange-service`.

**Tổng quan tính năng**:
Chuyển toàn bộ việc quản lý danh sách thị trường và cấu hình lịch phiên giao dịch sang lưu trữ trong Cơ sở dữ liệu (CSDL). Toàn bộ thuộc tính thông tin thị trường và tham số lịch phiên được quản lý gộp trong cùng một thực thể `Market` duy nhất, giúp quản trị viên dễ dàng thêm/sửa/bật/tắt thị trường cũng như cấu hình phiên một cách linh hoạt mà không cần thay đổi file cấu hình hay khởi động lại dịch vụ.

---

## 2. Mục tiêu

- **MT-001**: Cho phép hệ thống quản lý danh sách thị trường và cấu hình phiên giao dịch linh hoạt thông qua CSDLThay vì hardcode JSON.
- **MT-002**: Giảm bớt sự phức tạp của mô hình dữ liệu bằng cách quản lý thuộc tính thị trường và tham số lịch phiên giao dịch trong cùng 1 thực thể/bảng duy nhất.
- **MT-003**: Cho phép dịch vụ giao dịch (`flex-exchange-service`) tự động cập nhật danh sách thị trường và lịch phiên từ CSDL.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Lưu trữ thông tin danh sách thị trường cùng các tham số cấu hình lịch phiên (`has_ato`, `has_plo`, thời lượng phiên...) trong CSDL.
- **MVP-002**: Dịch vụ `flex-exchange-service` đọc danh sách thị trường active và cấu hình lịch phiên trực tiếp từ CSDL để vận hành vòng lặp phiên giao dịch.
- **MVP-003**: Cung cấp giao diện/API đọc danh sách thị trường động phục vụ các dịch vụ liên quan và giao diện người dùng.

---

## 4. Người dùng & Bối cảnh

**Người dùng chính**: Quản trị viên hệ thống (System Administrator) và Dịch vụ giao dịch tự động (`flex-exchange-service`).

**Bối cảnh sử dụng**: 
- Dịch vụ giao dịch truy vấn danh sách thị trường và cấu hình phiên khi khởi chạy hoặc khi cần cập nhật trạng thái phiên.
- Quản trị viên điều chỉnh cấu hình thị trường/phiên trong CSDL khi có thay đổi quy định giao dịch.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Quản trị viên hệ thống & kỹ thuật.

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Dịch vụ khởi tạo phiên giao dịch từ CSDL (Ưu tiên: P1)

Dịch vụ `flex-exchange-service` khi khởi động sẽ đọc danh sách các thị trường đang hoạt động (active) và lịch trình phiên của từng thị trường từ CSDL để chạy vòng lặp quản lý phiên tự động.

**Lý do ưu tiên**: Luồng lõi giúp hệ thống loại bỏ hoàn toàn việc phụ thuộc vào JSON hardcode trong `appsettings.json`.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003

**Test độc lập**: Kiểm tra dịch vụ `flex-exchange-service` nạp đúng danh sách thị trường và khung giờ phiên từ CSDL khi khởi chạy.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** CSDL chứa danh sách thị trường `HOSE`, `HNX`, `UPCOM`, `DERIVATIVES` kèm cấu hình lịch phiên tương ứng, **Khi** dịch vụ khởi động, **Thì** dịch vụ nạp chính xác danh sách thị trường active và thiết lập lịch phiên tương ứng mà không đọc từ JSON hardcode.
2. **AC-002**: **Cho trước** CSDL có một thị trường bị đánh dấu `inactive`, **Khi** dịch vụ vận hành vòng lặp phiên, **Thì** thị trường `inactive` đó sẽ không được kích hoạt phiên giao dịch.

---

### US-002 — Truy vấn danh sách thị trường động (Ưu tiên: P2)

Người dùng hoặc các dịch vụ khác (API Gateway / Frontend / Microfrontend) có thể gửi yêu cầu lấy danh sách các thị trường giao dịch khả dụng hiện tại.

**Lý do ưu tiên**: Cung cấp dữ liệu động cho giao diện bảng điện và ứng dụng đặt lệnh.

**Liên quan yêu cầu**: FR-004

**Test độc lập**: Gọi API truy vấn thị trường và kiểm tra dữ liệu trả về từ CSDL.

**Acceptance Criteria**:

1. **AC-003**: **Cho trước** các thị trường đang `active` trong CSDL, **Khi** gửi yêu cầu lấy danh sách thị trường, **Thì** hệ thống trả về đầy đủ mã thị trường, tên thị trường và trạng thái hoạt động.

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Nếu CSDL chưa có thị trường nào active, dịch vụ ghi log cảnh báo và không mở phiên giao dịch nào.
- **Dữ liệu không hợp lệ**: Nếu thời lượng phiên trong CSDL <= 0, hệ thống cảnh báo dữ liệu cấu hình lỗi và bỏ qua thị trường đó.
- **Không có quyền**: Không áp dụng.
- **Lỗi hệ thống (CSDL ngắt kết nối)**: Dịch vụ sử dụng bộ nhớ đệm (cache) hoặc ghi nhận lỗi kết nối và thử lại.
- **Timeout**: Áp dụng cơ chế retry truy vấn CSDL.
- **Dữ liệu bị thay đổi bởi người khác**: Khi cấu hình thị trường trong CSDL thay đổi khi phiên đang chạy, cấu hình mới sẽ áp dụng ở chu kỳ/phiên tiếp theo.
- **Người dùng thao tác lặp lại**: Không áp dụng.

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI lưu trữ danh sách thị trường và đầy đủ các thông số lịch phiên giao dịch (bao gồm cờ phiên `has_ato`, `has_plo` và thời lượng từng giai đoạn phiên) trong cùng một thực thể/bảng CSDL.  
  **Liên quan**: US-001, AC-001
- **FR-002** `[P1]`: Dịch vụ `flex-exchange-service` PHẢI đọc danh sách thị trường và cấu hình phiên từ CSDL thay cho file hardcode JSON.  
  **Liên quan**: US-001, AC-001
- **FR-003** `[P1]`: Hệ thống PHẢI hỗ trợ bật/tắt (active/inactive) trạng thái của từng thị trường trong CSDL.  
  **Liên quan**: US-001, AC-002
- **FR-004** `[P2]`: Hệ thống PHẢI cung cấp API/hàm truy vấn lấy danh sách thị trường đang hoạt động.  
  **Liên quan**: US-002, AC-003
- **FR-005** `[P1]`: Hệ thống KHÔNG ĐƯỢC chia tách dữ liệu lịch phiên ra bảng riêng biệt nhằm giữ cho mô hình dữ liệu đơn giản và tối ưu truy vấn.  
  **Liên quan**: US-001, AC-001

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Mỗi thị trường có một mã duy nhất (`market_code`, ví dụ: `HOSE`, `HNX`, `UPCOM`, `DERIVATIVES`).
- **BR-002**: Chỉ các thị trường có trạng thái `active` mới được khởi tạo phiên giao dịch tự động.
- **BR-003**: Cấu hình thời lượng của từng giai đoạn phiên (PreOpen, ATO, Continuous, Intermission, Continuous2, ATC, PLO) thuộc về thuộc tính của thị trường đó.
- **BR-004**: Mọi thay đổi về cấu hình thời lượng phiên trong CSDL khi phiên giao dịch đang diễn ra sẽ chỉ có hiệu lực ở chu kỳ/phiên giao dịch tiếp theo để đảm bảo tính nhất quán.

---

## 9. Thực thể dữ liệu

- **Thị trường (`Market`)**: Đại diện cho một thị trường chứng khoán/giao dịch. Bao gồm các thuộc tính nghiệp vụ: Mã thị trường (`market_code`), Tên thị trường (`market_name`), Trạng thái (`status`), Cờ hỗ trợ phiên ATO (`has_ato`), Cờ hỗ trợ phiên PLO (`has_plo`), cùng thời lượng (tính bằng giây) cho từng giai đoạn phiên (`pre_open_duration_seconds`, `ato_duration_seconds`, `continuous_duration_seconds`, `intermission_duration_seconds`, `continuous2_duration_seconds`, `atc_duration_seconds`, `plo_duration_seconds`).

---

## 10. Phân quyền & Bảo mật

**Ai được xem**: Dịch vụ hệ thống và người dùng nghiệp vụ.

**Ai được thao tác**: Quản trị viên hệ thống (được quyền chỉnh sửa cấu hình thị trường trong CSDL).

**SEC-001**: Hệ thống PHẢI đảm bảo chỉ quản trị viên có thẩm quyền mới được chỉnh sửa dữ liệu cấu hình thị trường trong CSDL.

---

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Có. Ghi nhận thời gian cập nhật `updated_at` khi có thay đổi cấu hình thị trường hoặc phiên.

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: Việc truy vấn cấu hình thị trường từ CSDL không làm ảnh hưởng đến hiệu năng của vòng lặp khớp lệnh realtime (khuyến nghị sử dụng bộ nhớ đệm In-memory cache).
- **NFR-002**: Đảm bảo tính toàn vẹn dữ liệu khi dịch vụ đọc cấu hình thị trường từ CSDL.

---

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: 100% danh sách thị trường và cấu hình phiên được đọc từ CSDL thay vì hardcode trong JSON.
- **SC-002**: Khởi động `flex-exchange-service` thành công và nhận diện chính xác 4 thị trường cơ bản (`HNX`, `HOSE`, `UPCOM`, `DERIVATIVES`) từ CSDL.
- **SC-003**: Việc thêm mới hoặc ẩn một thị trường trong CSDL có hiệu lực mà không cần sửa file JSON cấu hình.

---

## 14. Giả định & Ràng buộc

**Giả định**:
- CSDL `flex-database` (PostgreSQL/MySQL) sẵn sàng để bổ sung bảng dữ liệu thị trường mới.

**Ràng buộc**:
- Không chia bảng `market_schedules` riêng mà gộp toàn bộ cấu hình lịch phiên vào bảng `markets`.

---

## 15. Ngoài phạm vi

- Xây dựng giao diện UI (Web Portal) cho Admin quản lý thị trường (trong MVP chỉ quản lý qua SQL/API).

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| CSDL ngắt kết nối khi khởi chạy làm dịch vụ không đọc được danh sách thị trường | Thấp | Cao | Sử dụng In-memory caching hoặc retry mechanism |

---

## 17. Phụ thuộc

- Bảng dữ liệu thị trường mới trong `flex-database`.

---

## 18. Câu hỏi mở

Không có.

---

## Clarifications

### Session 2026-07-26
- Q: Khi thay đổi cấu hình thời lượng/phiên của thị trường trong CSDL lúc phiên đang chạy, xử lý thế nào? → A: Áp dụng cấu hình mới ở chu kỳ/phiên giao dịch tiếp theo.

---

## 19. Điều kiện sẵn sàng để lập plan kỹ thuật

- [x] Vấn đề cần giải quyết đã rõ.
- [x] MVP đã được xác định.
- [x] Luồng P1 có Acceptance Criteria đầy đủ.
- [x] Yêu cầu chức năng chính đã có ID.
- [x] Quy tắc nghiệp vụ quan trọng đã được ghi nhận.
- [x] Phân quyền/bảo mật đã rõ.
- [x] Ngoài phạm vi đã rõ.
- [x] Không còn câu hỏi mở.
