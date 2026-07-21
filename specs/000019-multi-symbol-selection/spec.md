# Đặc tả tính năng: Tùy chọn mã chứng khoán và lưu trạng thái hiển thị trên Market Board

**Branch**: `000019-multi-symbol-selection`  
**Ngày tạo**: 2026-07-21  
**Trạng thái**: Bản nháp  
**Người phụ trách**: Luyện Hải Đăng  
**Stakeholder xác nhận**: Luyện Hải Đăng  
**Đầu vào**: Hỗ trợ xem nhiều mã chứng khoán trên Market Board và tự động khôi phục mã chứng khoán đã chọn sau khi người dùng làm mới (reload) trang.

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

Hiện tại, Market Board của hệ thống đang cố định mã chứng khoán `FXS` (hardcode). Người dùng không thể chuyển sang xem Sổ lệnh và lịch sử giao dịch của các mã chứng khoán khác. Đồng thời, mỗi khi làm mới trang (reload), giao diện lại bị khóa cố định vào một mã đơn lẻ, gây gián đoạn trải nghiệm theo dõi thị trường của nhà đầu tư.

**Tổng quan tính năng**:

Tính năng này cho phép người dùng tùy chọn mã chứng khoán cần xem trên giao diện Market Board từ danh sách các mã đang giao dịch. Đồng thời, hệ thống tự động ghi nhớ mã chứng khoán mà người dùng chọn gần nhất để khôi phục chính xác trạng thái hiển thị khi người dùng tải lại trang hoặc quay lại ứng dụng.

---

## 2. Mục tiêu

- **MT-001**: Cho phép nhà đầu tư dễ dàng chuyển đổi xem thông tin Sổ lệnh và giao dịch của nhiều mã chứng khoán.
- **MT-002**: Tự động lưu trữ và khôi phục lựa chọn mã chứng khoán của người dùng qua các lần làm mới (reload) hoặc truy cập lại trang.
- **MT-003**: Đảm bảo luồng đặt lệnh và hủy lệnh áp dụng đúng theo mã chứng khoán đang được chọn trên màn hình.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Hiển thị danh sách các mã chứng khoán sẵn có để người dùng lựa chọn trên Market Board.
- **MVP-002**: Tải dữ liệu Sổ lệnh (Order Book), Băng khớp lệnh (Trade Tape) và thông tin phiên tương ứng với mã chứng khoán được chọn.
- **MVP-003**: Ghi nhớ mã chứng khoán được chọn gần nhất vào bộ nhớ trình duyệt của người dùng và tự động tải lại mã này khi làm mới trang.
- **MVP-004**: Đặt lệnh và hủy lệnh khớp đúng theo mã chứng khoán đang chọn.

---

## 4. Người dùng & Bối cảnh

**Người dùng chính**: Nhà đầu tư, người theo dõi thị trường chứng khoán HNX, người vận hành hệ thống.

**Bối cảnh sử dụng**: Khi theo dõi bảng điện, đặt lệnh mua/bán cổ phiếu, hoặc chuyển đổi giữa các mã cổ phiếu khác nhau trong phiên giao dịch.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Người dùng nghiệp vụ chứng khoán.

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Chuyển đổi mã chứng khoán trên Market Board (Ưu tiên: P1)

Nhà đầu tư muốn chọn một mã chứng khoán khác từ danh sách để xem Sổ lệnh (bids/asks) và các giao dịch khớp lệnh thực tế của mã đó.

**Lý do ưu tiên**: Đây là tính năng cốt lõi cho phép hỗ trợ đa mã chứng khoán thay vì cố định một mã.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003

**Test độc lập**: Mở giao diện, thay đổi mã chứng khoán từ danh sách và kiểm tra Sổ lệnh cùng lịch sử khớp lệnh cập nhật tương ứng theo mã mới.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** người dùng đang ở màn hình Market Board, **Khi** người dùng chọn một mã chứng khoán mới từ bộ chọn (ví dụ chọn `HNX`), **Thì** Sổ lệnh và danh sách khớp lệnh lập tức cập nhật dữ liệu của mã `HNX`.
2. **AC-002**: **Cho trước** người dùng chọn mã chứng khoán mới, **Khi** người dùng thực hiện đặt lệnh MUA hoặc BÁN, **Thì** lệnh mới được gửi đi với đúng mã chứng khoán đã chọn.

---

### US-002 — Khôi phục mã chứng khoán đã chọn sau khi làm mới trang (Ưu tiên: P1)

Nhà đầu tư đã chọn xem mã chứng khoán (ví dụ `VND`), khi F5 / làm mới trang hoặc mở lại trình duyệt, màn hình vẫn hiển thị mã `VND` thay vì bị reset về mã mặc định.

**Lý do ưu tiên**: Giữ trải nghiệm liền mạch cho người dùng, không bắt người dùng phải chọn lại mã mỗi lần chuyển trang hay làm mới.

**Liên quan yêu cầu**: FR-004, FR-005

**Test độc lập**: Chọn mã chứng khoán bất kỳ, nhấn F5 / reload trang, xác minh mã chứng khoán hiển thị và dữ liệu được tải ra đúng như trước khi làm mới.

**Acceptance Criteria**:

1. **AC-003**: **Cho trước** người dùng đã chọn mã chứng khoán `VND`, **Khi** người dùng bấm F5 / làm mới trang, **Thì** mã chứng khoán `VND` vẫn được giữ nguyên và dữ liệu Sổ lệnh của `VND` tự động được tải.
2. **AC-004**: **Cho trước** người dùng lần đầu truy cập và chưa có lịch sử chọn mã, **Khi** mở trang, **Thì** hệ thống chọn mã mặc định đầu tiên khả dụng trong danh sách.

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Nếu mã chứng khoán chưa có lệnh nào trong Sổ lệnh, hiển thị bảng Sổ lệnh rỗng với thông báo phù hợp.
- **Dữ liệu không hợp lệ**: Nếu mã đã lưu trước đó không còn tồn tại hoặc bị dừng giao dịch, hệ thống tự động quay về mã mặc định hợp lệ đầu tiên.
- **Không có quyền**: Không áp dụng.
- **Lỗi hệ thống**: Nếu không tải được dữ liệu mã chứng khoán, hiển thị thông báo lỗi và cho phép người dùng bấm thử lại.
- **Timeout**: Giữ nguyên mã chứng khoán đã chọn và cho phép thử tải lại dữ liệu.
- **Dữ liệu bị thay đổi bởi người khác**: Khi mã được chọn thay đổi, dữ liệu Sổ lệnh tự động cập nhật phản ánh đúng trạng thái mới nhất.
- **Người dùng thao tác lặp lại**: Thao tác chuyển đổi mã chứng khoán nhiều lần liên tiếp diễn ra mượt mà, request sau cùng sẽ phản ánh kết quả trên màn hình.
- **Trường hợp biên khác**: Không áp dụng.

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI cung cấp bộ chọn danh sách các mã chứng khoán khả dụng trên giao diện Market Board.  
  **Liên quan**: US-001, AC-001
- **FR-002** `[P1]`: Hệ thống PHẢI tải và hiển thị Sổ lệnh (Order Book) và Băng khớp lệnh (Trade Tape) tương ứng với mã chứng khoán đang được chọn.  
  **Liên quan**: US-001, AC-001
- **FR-003** `[P1]`: Hệ thống PHẢI đính kèm đúng mã chứng khoán đang được chọn khi người dùng đặt lệnh mới.  
  **Liên quan**: US-001, AC-002
- **FR-004** `[P1]`: Hệ thống PHẢI tự động ghi nhớ mã chứng khoán được người dùng chọn gần nhất vào bộ nhớ cục bộ trên thiết bị/trình duyệt của người dùng.  
  **Liên quan**: US-002, AC-003
- **FR-005** `[P1]`: Hệ thống PHẢI tự động đọc và khôi phục mã chứng khoán đã lưu khi khởi tạo giao diện Market Board.  
  **Liên quan**: US-002, AC-003, AC-004
- **FR-006** `[P2]`: Hệ thống PHẢI có cơ chế xử lý dự phòng quay về mã mặc định nếu mã đã lưu không hợp lệ hoặc không tìm thấy.  
  **Liên quan**: US-002, AC-004

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Lệnh đặt phải gắn đúng mã chứng khoán đang chọn và thuộc về một mã chứng khoán đang ở trạng thái hoạt động (`ACTIVE`).
- **BR-002**: Việc lưu trữ lựa chọn mã chứng khoán của người dùng mang tính cá nhân hóa trên từng trình duyệt/thiết bị.
- **BR-003**: Khi đổi mã chứng khoán, toàn bộ dữ liệu Sổ lệnh và Lịch sử giao dịch hiển thị trên giao diện phải làm sạch và nạp lại theo mã mới.

---

## 9. Thực thể dữ liệu

- **Danh sách mã chứng khoán (Instruments)**: Danh sách các mã chứng khoán được phép giao dịch (mã symbol, tên công ty, trạng thái).
- **Lựa chọn gần nhất (Selected Symbol State)**: Thông tin mã chứng khoán được chọn gần nhất của người dùng.

---

## 10. Phân quyền & Bảo mật

**Ai được xem**: Tất cả người dùng truy cập giao diện Market Board đều được chọn và xem các mã chứng khoán.

**Ai được thao tác**: Người dùng được phép chuyển đổi mã chứng khoán và đặt lệnh theo quyền khả dụng.

**Ai không được phép**: Không áp dụng.

**Dữ liệu nhạy cảm**: Không có.

- **SEC-001**: Hệ thống PHẢI kiểm tra tính hợp lệ của mã chứng khoán trước khi chấp nhận đặt lệnh.
- **SEC-002**: Hệ thống KHÔNG ĐƯỢC để thao tác lưu mã trên trình duyệt gây lỗi bảo mật hay lộ thông tin người dùng khác.

---

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Không áp dụng đối với việc chuyển đổi xem mã trên giao diện. Các giao dịch đặt/hủy lệnh vẫn được audit theo quy định của hệ thống Exchange.

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: Việc chuyển đổi giữa các mã chứng khoán trên giao diện phản hồi trong dưới 1 giây trong điều kiện mạng bình thường.
- **NFR-002**: Việc khôi phục mã chứng khoán đã lưu khi làm mới trang không làm chậm thời gian tải trang ban đầu.
- **NFR-003**: Ghi nhớ lựa chọn mã tương thích với tất cả trình duyệt hiện đại được hỗ trợ.

---

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: 100% lần làm mới trang (reload) sau khi chọn mã chứng khoán sẽ giữ nguyên mã chứng khoán đã chọn và tải đúng dữ liệu tương ứng.
- **SC-002**: Người dùng có thể chọn và xem thông tin Sổ lệnh của bất kỳ mã chứng khoán nào khả dụng trong hệ thống mà không gặp lỗi.
- **SC-003**: 100% lệnh đặt sau khi chuyển đổi mã được gửi đi chính xác với mã chứng khoán đang hiển thị.

---

## 14. Giả định & Ràng buộc

**Giả định**:
- Trình duyệt người dùng hỗ trợ bộ nhớ cục bộ (localStorage) để lưu mã đã chọn.
- Hệ thống có danh sách các mã chứng khoán hợp lệ được cung cấp từ Backend.

**Ràng buộc**:
- Không thay đổi cấu trúc dữ liệu lệnh và giao dịch cốt lõi của Exchange.

---

## 15. Ngoài phạm vi

- Quản lý danh mục đầu tư hay yêu thích (Watchlist) nhiều mã cùng lúc trên nhiều màn hình (Dashboard đa cửa sổ).
- Lưu trữ lựa chọn mã lên Server Database theo tài khoản đăng nhập ở v1.

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Mã đã lưu bị xóa hoặc không hợp lệ khi Backend thay đổi danh mục | Thấp | Thấp | Tự động chuyển về mã mặc định hợp lệ đầu tiên nếu mã cũ không tồn tại |

---

## 17. Phụ thuộc

- Backend cung cấp danh sách các mã chứng khoán hợp lệ và API truy vấn Sổ lệnh/Giao dịch theo mã chứng khoán.

---

## 18. Câu hỏi mở

- Không có.

---

## Clarifications

---

## 19. Điều kiện sẵn sàng để lập plan kỹ thuật

- [x] Vấn đề cần giải quyết đã rõ.
- [x] MVP đã được xác định.
- [x] Luồng P1 có Acceptance Criteria đầy đủ.
- [x] Yêu cầu chức năng chính đã có ID.
- [x] Quy tắc nghiệp vụ quan trọng đã được ghi nhận.
- [x] Phân quyền/bảo mật đã rõ.
- [x] Ngoài phạm vi đã rõ.
- [x] Các câu hỏi mở quan trọng đã được trả lời.
