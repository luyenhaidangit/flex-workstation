# Đặc tả tính năng: Bảng điện thị trường demo

**Branch**: `000012-market-board`  
**Ngày tạo**: 2026-07-18  
**Trạng thái**: Bản nháp  
**Người phụ trách**: Luyện Hải Đăng  
**Stakeholder xác nhận**: Luyện Hải Đăng  
**Đầu vào**: Tạo một bảng điện demo để người dùng quan sát mã FXS và đặt/hủy lệnh qua giao diện trực quan.

---

## Nguyên tắc phạm vi

Đặc tả này chỉ mô tả WHY và WHAT. Cách triển khai kỹ thuật sẽ được xác định trong plan.

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

MVP 02 đã cung cấp Exchange API, nhưng người dùng vẫn phải đọc log hoặc tự gọi API để biết order book, giao dịch và trạng thái lệnh. Điều này khiến luồng demo khó quan sát, khó kiểm chứng và khó sử dụng bởi người không quen kỹ thuật.

**Tổng quan tính năng**:

Bảng điện demo hiển thị thị trường của một mã FXS trong một màn hình dễ đọc. Người xem có thể quan sát giá gần nhất, thanh khoản đang chờ và trade tape; hai tài khoản demo có thể đặt hoặc hủy lệnh để minh họa vòng đời giao dịch.

## 2. Mục tiêu

- **MT-001**: Người dùng không đọc log vẫn nhận biết được giá gần nhất, các mức giá mua/bán tốt nhất, khối lượng chờ và giao dịch mới.
- **MT-002**: Người dùng có thể hoàn thành một luồng đặt hoặc hủy lệnh demo mà không cần thao tác trực tiếp với API.
- **MT-003**: Kết quả trên bảng điện phản ánh dữ liệu Exchange sau khi làm mới và không bị mất khi tải lại trang.

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Một bảng điện cho duy nhất mã FXS, hiển thị giá gần nhất, năm mức mua tốt nhất, năm mức bán tốt nhất, khối lượng chờ và trade tape.
- **MVP-002**: Form chọn một trong hai tài khoản demo, chiều lệnh, giá và khối lượng; hiển thị kết quả chấp nhận hoặc từ chối.
- **MVP-003**: Cho phép hủy lệnh demo đang chờ và làm mới dữ liệu thị trường theo chu kỳ ngắn; không yêu cầu đăng nhập.

## 4. Người dùng & Bối cảnh

**Người dùng chính**: Người xem demo, QA hoặc developer cần quan sát hành vi matching.

**Bối cảnh sử dụng**: Truy cập bảng điện trong môi trường local/demo để theo dõi một mã FXS và tạo hai lệnh đối ứng.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Không chuyên đến người dùng kỹ thuật; không yêu cầu đọc log.

## 5. Kịch bản người dùng

### US-001 — Quan sát bảng điện (Ưu tiên: P1)

Người xem mở bảng điện và nhanh chóng nhận biết giá, các mức thanh khoản đang chờ và những giao dịch gần nhất của FXS.

**Lý do ưu tiên**: Đây là giá trị cốt lõi của MVP 03 và là cơ sở để kiểm chứng matching bằng mắt thường.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003

**Test độc lập**: Mở bảng điện với dữ liệu trống, dữ liệu có lệnh chờ và dữ liệu có trade; xác nhận các khu vực hiển thị và trạng thái làm mới.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** Exchange có dữ liệu của mã FXS, **Khi** người dùng mở bảng điện, **Thì** hệ thống hiển thị giá gần nhất, năm mức mua tốt nhất, năm mức bán tốt nhất, tổng khối lượng chờ và trade tape.
2. **AC-002**: **Cho trước** có lệnh hoặc giao dịch mới từ Exchange, **Khi** bảng điện làm mới, **Thì** dữ liệu hiển thị cập nhật và giữ đúng thứ tự giá, thời gian, khối lượng.
3. **AC-003**: **Cho trước** người dùng tải lại trang, **Khi** bảng điện mở lại, **Thì** dữ liệu được đọc lại từ Exchange và không phụ thuộc vào trạng thái hiển thị trước đó.

### US-002 — Đặt và hủy lệnh demo (Ưu tiên: P1)

Người dùng chọn một tài khoản demo, nhập chiều lệnh, giá và khối lượng, sau đó đặt hoặc hủy lệnh và nhận kết quả rõ ràng trên cùng màn hình.

**Lý do ưu tiên**: Cho phép tạo luồng demo khép kín và chứng minh bảng điện phản ánh đúng kết quả matching.

**Liên quan yêu cầu**: FR-004, FR-005, FR-006

**Test độc lập**: Đặt một lệnh chờ, đặt lệnh đối ứng, kiểm tra bảng điện/trade tape; sau đó hủy một lệnh còn chờ và kiểm tra trạng thái.

**Acceptance Criteria**:

1. **AC-004**: **Cho trước** người dùng chọn tài khoản demo và nhập dữ liệu hợp lệ, **Khi** gửi lệnh, **Thì** màn hình hiển thị kết quả chấp nhận hoặc lý do từ chối từ Exchange.
2. **AC-005**: **Cho trước** có lệnh demo còn chờ, **Khi** người dùng yêu cầu hủy, **Thì** màn hình hiển thị trạng thái hủy thành công hoặc lý do từ chối, không báo thành công giả.
3. **AC-006**: **Cho trước** hai lệnh đối ứng được chấp nhận, **Khi** Exchange khớp lệnh, **Thì** giá gần nhất, trade tape và order book trên bảng điện phản ánh giao dịch mới.

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Hiển thị trạng thái rõ ràng cho order book/trade tape trống; không hiển thị số liệu giả.
- **Dữ liệu không hợp lệ**: Chặn gửi form thiếu tài khoản, chiều, giá hoặc khối lượng; hiển thị lỗi tại trường liên quan.
- **Không có quyền**: Không áp dụng xác thực trong MVP; chỉ cho phép hai tài khoản demo được chọn sẵn.
- **Lỗi hệ thống**: Hiển thị thông báo thao tác thất bại và giữ dữ liệu cuối cùng còn hợp lệ nếu có.
- **Timeout**: Thông báo không lấy được dữ liệu mới, cho phép người dùng thử lại; không xóa dữ liệu đang xem.
- **Dữ liệu bị thay đổi bởi người khác**: Lần làm mới tiếp theo phải phản ánh dữ liệu mới từ Exchange.
- **Người dùng thao tác lặp lại**: Không tạo yêu cầu hủy trùng hoặc báo thành công nhiều lần cho cùng một thao tác.
- **Trường hợp biên khác**: Khi lệnh bị từ chối hoặc đã hoàn tất trước khi hủy, hiển thị đúng lý do nghiệp vụ từ Exchange.

## 7. Yêu cầu chức năng

- **FR-001** `[P1]`: Hệ thống PHẢI hiển thị dữ liệu thị trường của duy nhất mã FXS trên một bảng điện dễ đọc.  
  **Liên quan**: US-001, AC-001
- **FR-002** `[P1]`: Hệ thống PHẢI hiển thị tối đa năm mức mua tốt nhất, năm mức bán tốt nhất, khối lượng chờ và giá gần nhất theo dữ liệu Exchange.  
  **Liên quan**: US-001, AC-001, AC-002
- **FR-003** `[P1]`: Hệ thống PHẢI hiển thị trade tape theo thứ tự mới nhất và cập nhật lại dữ liệu thị trường trong phiên xem.  
  **Liên quan**: US-001, AC-002, AC-003
- **FR-004** `[P1]`: Người dùng PHẢI chọn được một trong hai tài khoản demo và nhập chiều lệnh, giá, khối lượng trước khi gửi.  
  **Liên quan**: US-002, AC-004
- **FR-005** `[P1]`: Hệ thống PHẢI hiển thị kết quả đặt/hủy lệnh cùng lý do nghiệp vụ khi Exchange từ chối.  
  **Liên quan**: US-002, AC-004, AC-005
- **FR-006** `[P1]`: Hệ thống PHẢI cập nhật bảng điện sau thao tác đặt/hủy hoặc sau khi có giao dịch mới.  
  **Liên quan**: US-002, AC-005, AC-006
- **FR-007** `[P1]`: Hệ thống KHÔNG ĐƯỢC yêu cầu người dùng đọc log hoặc nhập thủ công định danh kỹ thuật để hoàn thành luồng demo.  
  **Liên quan**: US-001, US-002

## 8. Quy tắc nghiệp vụ

- **BR-001**: MVP chỉ hiển thị và thao tác với mã FXS.
- **BR-002**: Chỉ hai tài khoản demo được chọn; người dùng không tự nhập tài khoản ngoài danh sách.
- **BR-003**: Bảng điện là bản trình bày dữ liệu Exchange; không tự tính giá, khối lượng hoặc trạng thái khác với kết quả Exchange.
- **BR-004**: Lệnh chỉ được coi là thành công khi Exchange xác nhận; mọi lý do từ chối phải được giữ nguyên ý nghĩa khi hiển thị.
- **BR-005**: Hủy chỉ áp dụng cho lệnh của đúng tài khoản demo còn ở trạng thái có thể hủy.

**Luồng trạng thái**:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| Chưa có lệnh | Gửi lệnh hợp lệ | Đã chấp nhận / Bị từ chối | Exchange trả kết quả |
| Đã chấp nhận, còn chờ | Hủy lệnh | Đã hủy / Từ chối hủy | Lệnh còn có thể hủy |
| Đã chấp nhận, còn chờ | Có lệnh đối ứng | Đã khớp một phần / Đã khớp | Theo kết quả matching |

## 9. Thực thể dữ liệu

- **Bảng điện**: Trình bày trạng thái thị trường hiện tại của mã FXS, gồm giá, mức giá, khối lượng và giao dịch gần nhất.
- **Tài khoản demo**: Một trong hai danh tính demo được dùng để đặt và hủy lệnh.
- **Lệnh**: Yêu cầu mua/bán và trạng thái do Exchange trả về.
- **Giao dịch**: Kết quả khớp lệnh được hiển thị trên trade tape.

## 10. Phân quyền & Bảo mật

**Ai được xem**:
- Người truy cập môi trường demo.

**Ai được thao tác**:
- Người truy cập môi trường demo, trong giới hạn hai tài khoản demo có sẵn.

**Ai không được phép**:
- Không áp dụng vai trò thật hoặc tài khoản ngoài danh sách demo trong MVP.

**Dữ liệu nhạy cảm**:
- Không có dữ liệu nhạy cảm trong phạm vi MVP; không hiển thị token, secret hoặc thông tin xác thực.

- **SEC-001**: Hệ thống PHẢI giới hạn thao tác vào hai tài khoản demo được định nghĩa cho môi trường demo.
- **SEC-002**: Hệ thống KHÔNG ĐƯỢC hiển thị token, secret, header xác thực hoặc thông tin nội bộ trong giao diện/lỗi người dùng.

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Không tạo audit riêng cho UI. Lịch sử lệnh và giao dịch do Exchange API cung cấp được dùng làm nguồn hiển thị.

## 12. Yêu cầu phi chức năng

- **NFR-001**: Trong điều kiện demo bình thường, người dùng nhận được phản hồi đặt/hủy lệnh trong tối đa 5 giây.
- **NFR-002**: Sau khi có dữ liệu mới, bảng điện hiển thị thay đổi trong tối đa 3 giây ở phiên demo bình thường.
- **NFR-003**: Tải lại trang không làm mất dữ liệu đã ghi nhận trên Exchange và không tạo lại lệnh ngoài ý muốn.
- **NFR-004**: Giao diện desktop phải sử dụng được bởi người không đọc log kỹ thuật; các trạng thái thành công, từ chối, lỗi và đang tải phải phân biệt được.

## 13. Tiêu chí thành công

- **SC-001**: Ít nhất 90% người dùng thử nghiệm nhận biết đúng lệnh đang chờ và giao dịch mới mà không mở log.
- **SC-002**: Người dùng hoàn thành luồng chọn tài khoản, đặt lệnh và đọc kết quả trong dưới 2 phút.
- **SC-003**: Hai lệnh đối ứng trong kịch bản demo làm thay đổi đúng giá gần nhất, trade tape và order book trong tối đa 5 giây.
- **SC-004**: Tải lại trang trong kịch bản demo vẫn hiển thị trạng thái khớp/hủy đã được Exchange xác nhận trong 100% lần kiểm thử.

## 14. Giả định & Ràng buộc

**Giả định**:
- Exchange API của MVP 02 đã sẵn sàng và trả về dữ liệu order book, trades, order status, place và cancel.
- Người dùng truy cập môi trường local/demo có kết nối tới Exchange.
- Chỉ cần một mã FXS và hai tài khoản demo trong MVP.

**Ràng buộc**:
- Không mở rộng sang đăng nhập thật, portfolio, số dư tiền/chứng khoán hoặc nhiều mã trong MVP.
- Không thay đổi quy tắc matching và không tạo nguồn dữ liệu giao dịch thứ hai ngoài Exchange.

## 15. Ngoài phạm vi

- Đăng nhập, phân quyền thật, tích hợp auth token hoặc Keycloak.
- Portfolio, số dư tiền/chứng khoán, settlement và quản lý tài khoản.
- Biểu đồ giá, lịch sử dài hạn, watchlist, nhiều mã và mobile/responsive hoàn chỉnh.
- Push realtime, notification hoặc cơ chế streaming thay cho việc làm mới dữ liệu trong MVP.

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|---|---|---|---|
| Dữ liệu Exchange thay đổi trong lúc người dùng đang xem | Trung | Trung | Hiển thị thời điểm cập nhật và làm mới lại sau thao tác |
| Người dùng gửi thao tác lặp do phản hồi chậm | Trung | Cao | Khóa thao tác đang xử lý và phản hồi theo kết quả thực tế |
| Giao diện hiển thị sai ý nghĩa trạng thái Exchange | Thấp | Cao | Dùng contract test và kiểm thử các kết quả accepted/rejected/cancelled |

## 17. Phụ thuộc

- Exchange API và matching engine của MVP 02.
- Hai tài khoản demo và cấu hình mã FXS cho môi trường demo.
- Quyết định giao diện tối thiểu của stakeholder trước khi lập plan chi tiết.

## 18. Câu hỏi mở

- Không có câu hỏi mở chặn phạm vi; các lựa chọn về giao diện chi tiết được quyết định trong plan nhưng không thay đổi luồng nghiệp vụ trên.

## 19. Điều kiện sẵn sàng để lập plan kỹ thuật

- [x] Vấn đề cần giải quyết đã rõ.
- [x] MVP đã được xác định.
- [x] Luồng P1 có Acceptance Criteria đầy đủ.
- [x] Yêu cầu chức năng chính đã có ID.
- [x] Quy tắc nghiệp vụ quan trọng đã được ghi nhận.
- [x] Phân quyền/bảo mật đã rõ trong phạm vi demo.
- [x] Ngoài phạm vi đã rõ.
- [x] Không còn câu hỏi mở chặn thiết kế.
