# Đặc tả tính năng: Trang Publish Kiểm Thử Tích Hợp Instagram

**Branch**: `000024-instagram-publish`  
**Ngày tạo**: 2026-07-30  
**Trạng thái**: Bản nháp  
**Người phụ trách**: Admin  
**Stakeholder xác nhận**: Admin  
**Đầu vào**: Tạo trang hiển thị tại đường dẫn `/publish` cho phép người dùng giao diện frontend thử nghiệm luồng xuất bản bài đăng (đăng ảnh/video/bài viết) lên Instagram.

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

Hiện tại đội ngũ phát triển giao diện (FE) chưa có một trang dedicated tại đường dẫn URL `/publish` để mô phỏng, thao tác và kiểm thử các tính năng liên quan đến việc xuất bản nội dung lên Instagram (đăng bài, tải media, cấu hình caption, xem trước bài đăng và theo dõi trạng thái xuất bản). Việc thiếu trang kiểm thử chuyên biệt gây khó khăn cho QA và lập trình viên FE trong quá trình xác minh tương tác người dùng.

**Tổng quan tính năng**:

Tính năng cung cấp trang kiểm thử `/publish` hiển thị giao diện tạo bài đăng Instagram. Trang này cho phép người dùng FE chuẩn bị nội dung (ảnh/video, dòng trạng thái caption, hastag), xem trước bài đăng trực quan (Preview) và thực thi/mô phỏng thao tác "Đăng bài" (Publish) lên Instagram cũng như xem trạng thái phản hồi.

---

## 2. Mục tiêu

- **MT-001**: Cung cấp giao diện truy cập được tại URL `/publish` phục vụ thao tác kiểm thử xuất bản Instagram.
- **MT-002**: Cho phép người dùng nhập/tải nội dung media, nhập caption và xem trước giao diện bài đăng mô phỏng trên Instagram.
- **MT-003**: Cung cấp phản hồi rõ ràng về trạng thái gửi/đăng bài (đang xử lý, thành công, thất bại) giúp đội ngũ FE/QA dễ dàng kiểm tra.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Truy cập thành công vào URL `/publish` hiển thị đúng giao diện kiểm thử xuất bản.
- **MVP-002**: Form nhập thông tin bài đăng bao gồm chọn/tải file media (hình ảnh), nhập text caption, và nút bấm "Đăng lên Instagram".
- **MVP-003**: Khu vực xem trước bài đăng (Post Preview) cập nhật thời gian thực theo nội dung người dùng nhập.
- **MVP-004**: Khu vực hiển thị bảng nhật ký/trạng thái (Log/Status Panel) ghi lại thông báo phản hồi sau khi bấm đăng bài.

---

## 4. Người dùng & Bối cảnh

**Người dùng chính**: Lập trình viên Frontend (FE Developer), Tester / QA.

**Bối cảnh sử dụng**: Khi cần phát triển, kiểm thử giao diện và xác minh các luồng đăng bài Instagram từ ứng dụng web.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Kỹ thuật / Kiểm thử.

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Truy cập trang Publish và xem trước bài đăng (Ưu tiên: P1)

Là Tester / FE Developer, tôi muốn truy cập vào `/publish` và xem trước giao diện bài đăng Instagram dựa trên nội dung tôi nhập, để đảm bảo bài viết hiển thị đẹp mắt trước khi xuất bản.

**Lý do ưu tiên**: Luồng chính để xác minh giao diện người dùng.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003

**Test độc lập**: Điều hướng đến đường dẫn `/publish`, nhập caption và đính kèm ảnh, kiểm tra vùng Preview có cập nhật thông tin tương ứng hay không.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** người dùng truy cập đường dẫn `/publish`, **Khi** trang tải xong, **Thì** hệ thống hiển thị form soạn thảo nội dung và vùng xem trước bài đăng (Preview).
2. **AC-002**: **Cho trước** người dùng đang ở trang `/publish`, **Khi** nhập dòng chữ caption và chọn ảnh, **Thì** vùng Preview cập nhật hình ảnh và văn bản theo đúng dữ liệu vừa nhập.

---

### US-002 — Thực hiện xuất bản và nhận thông báo trạng thái (Ưu tiên: P1)

Là Tester / FE Developer, tôi muốn bấm nút "Đăng lên Instagram" và thấy rõ thông báo trạng thái phản hồi, để biết thao tác đã thành công hay xảy ra lỗi.

**Lý do ưu tiên**: Đảm bảo phản hồi trực quan đối với hành động của người dùng.

**Liên quan yêu cầu**: FR-004, FR-005

**Test độc lập**: Nhập đầy đủ thông tin bài đăng trên trang `/publish`, nhấn "Đăng lên Instagram" và quan sát bảng thông báo trạng thái.

**Acceptance Criteria**:

1. **AC-003**: **Cho trước** bài đăng đã có đủ ảnh và caption hợp lệ, **Khi** người dùng nhấn nút "Đăng lên Instagram", **Thì** hệ thống chuyển nút sang trạng thái "Đang đăng..." và hiển thị kết quả phản hồi (thành công/lỗi) tại Bảng trạng thái.

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Vùng Preview hiển thị trạng thái chờ (placeholder) kèm hướng dẫn "Nhập nội dung để xem trước".
- **Dữ liệu không hợp lệ**: Hệ thống hiển thị cảnh báo nếu người dùng nhấn đăng bài mà chưa chọn ảnh hoặc chưa nhập caption.
- **Không có quyền**: Cảnh báo người dùng nếu chưa kết nối/xác thực tài khoản Instagram.
- **Lỗi hệ thống**: Bảng trạng thái hiển thị thông tin lỗi chi tiết cùng gợi ý thử lại.
- **Timeout**: Hiển thị thông báo quá hạn phản hồi sau khoảng thời gian chờ quy định.
- **Dữ liệu bị thay đổi bởi người khác**: Không áp dụng.
- **Người dùng thao tác lặp lại**: Nút đăng bài tự động vô hiệu hóa (disable) trong lúc đang xử lý để tránh gửi yêu cầu trùng lặp.
- **Trường hợp biên khác**: Chọn file media không đúng định dạng hình ảnh/video được hỗ trợ -> hiển thị thông báo lỗi file không hợp lệ.

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI định tuyến và hiển thị trang kiểm thử khi người dùng truy cập URL `/publish`.  
  **Liên quan**: US-001, AC-001
- **FR-002** `[P1]`: Trang PHẢI cung cấp form nhập liệu gồm: khu vực chọn/tải ảnh/video, trường nhập caption văn bản.  
  **Liên quan**: US-001, AC-001, AC-002
- **FR-003** `[P1]`: Trang PHẢI hiển thị vùng xem trước bài đăng (Post Preview) mô phỏng chính xác khung bài viết Instagram.  
  **Liên quan**: US-001, AC-002
- **FR-004** `[P1]`: Trang PHẢI cung cấp nút hành động "Đăng lên Instagram" và tự động khóa nút khi yêu cầu đang thực thi.  
  **Liên quan**: US-002, AC-003
- **FR-005** `[P1]`: Trang PHẢI có bảng hiển thị nhật ký/trạng thái kết quả xuất bản (Log/Status Panel).  
  **Liên quan**: US-002, AC-003

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Bài đăng bắt buộc phải có ít nhất 1 tệp hình ảnh/video hợp lệ trước khi cho phép kích hoạt hành động đăng bài.
- **BR-002**: Độ dài caption tối đa tuân thủ theo quy định nghiệp vụ của Instagram (không quá 2.200 ký tự).
- **BR-003**: Trong quá trình gửi dữ liệu xuất bản, không cho phép chỉnh sửa lại nội dung form để đảm bảo tính toàn vẹn dữ liệu gửi đi.

---

## 9. Thực thể dữ liệu

- **Bài đăng kiểm thử (Test Instagram Post)**: Đại diện cho dữ liệu nội dung bài đăng gồm: Tệp media (URL hoặc Blob), văn bản caption, danh sách hashtag, thời gian tạo, và trạng thái xuất bản (Nháp, Đang đăng, Thành công, Lỗi).

---

## 10. Phân quyền & Bảo mật

**Ai được xem**: Lập trình viên, Tester, và Quản trị viên trong môi trường phát triển/kiểm thử.

**Ai được thao tác**: Người dùng có quyền truy cập môi trường test frontend.

**Ai không được phép**: Người dùng vãng lai chưa xác thực trên môi trường Production (nếu trang được đưa lên prod thì cần feature flag hoặc phân quyền).

**Dữ liệu nhạy cảm**: Không chứa thông tin cá nhân nhạy cảm ngoài thông tin cấu hình tài khoản kiểm thử Instagram.

- **SEC-001**: Hệ thống PHẢI đảm bảo các thông số cấu hình Instagram test không bị rò rỉ công khai.

---

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Không áp dụng (đây là trang test chức năng ở FE).

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: Vùng Preview PHẢI phản hồi tức thì (dưới 100ms) khi người dùng gõ nội dung caption hoặc chọn tệp ảnh.
- **NFR-002**: Trang `/publish` PHẢI hiển thị tương thích tốt trên giao diện máy tính (Desktop) và các độ phân giải màn hình phổ biến.

---

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: Người dùng điều hướng thành công vào đường dẫn `/publish` và nhìn thấy đầy đủ các thành phần kiểm thử trong dưới 2 giây.
- **SC-002**: 100% các thao tác nhập caption, chọn ảnh được cập nhật tương ứng trên vùng xem trước Preview.
- **SC-003**: Nút bấm đăng bài hiển thị phản hồi trạng thái rõ ràng sau khi thực hiện thao tác xuất bản.

---

## 14. Giả định & Ràng buộc

**Giả định**:
- Ứng dụng FE có cơ chế routing hỗ trợ khai báo đường dẫn `/publish`.
- Người dùng thực hiện kiểm thử trên trình duyệt hiện đại có hỗ trợ tải file ảnh.

**Ràng buộc**:
- Trang `/publish` trong phiên bản MVP tập trung vào giao diện kiểm thử bài đăng dạng ảnh đơn và bài viết tiêu chuẩn.

---

## 15. Ngoài phạm vi

- Đăng bài dạng Reel/Story nâng cao có chỉnh sửa âm thanh phức tạp.
- Lập lịch đăng bài tự động theo thời gian (Scheduling) trong bản MVP kiểm thử này.

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Người dùng chọn file media dung lượng quá lớn làm đơ trình duyệt | Trung bình | Trung bình | Thêm kiểm tra giới hạn dung lượng file phía client trước khi xử lý |

---

## 17. Phụ thuộc

- Phụ thuộc vào hệ thống routing sẵn có của FE để đăng ký đường dẫn `/publish`.

---

## 18. Câu hỏi mở

Không có câu hỏi mở cần làm rõ thêm ở mức nghiệp vụ.

---

## Clarifications

*(Chưa có phiên làm rõ nào)*

---

## 19. Điều kiện sẵn sàng để lập plan kỹ thuật

- [x] Vấn đề cần giải quyết đã rõ.
- [x] MVP đã được xác định.
- [x] Luồng P1 có Acceptance Criteria đầy đủ.
- [x] Yêu cầu chức năng chính đã có ID.
- [x] Quy tắc nghiệp vụ quan trọng đã được ghi nhận.
- [x] Phân quyền/bảo mật đã rõ hoặc được đánh dấu là câu hỏi mở.
- [x] Ngoài phạm vi đã rõ.
- [x] Các câu hỏi mở quan trọng đã được trả lời hoặc được chấp nhận là rủi ro.
