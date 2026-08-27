# Đặc tả tính năng: Kết nối kênh Instagram và Facebook qua Meta

**Branch**: `000041-meta-channel-connections`  
**Ngày tạo**: 2026-08-26  
**Trạng thái**: Bản nháp  
**Người phụ trách**: Luyện Hải Đăng  
**Stakeholder xác nhận**: Luyện Hải Đăng  
**Đầu vào**: Xây dựng luồng kết nối Instagram và Facebook với khả năng dùng chung các năng lực xác thực và khám phá tài khoản của Meta, đồng thời giữ ranh giới rõ giữa nghiệp vụ và implementation. MVP tập trung vào khởi tạo, callback, khám phá, hoàn tất và ngắt kết nối.

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

Người dùng chưa có một luồng thống nhất để kết nối các tài khoản Instagram và Facebook mà agent được phép quản lý. Việc thiếu một quy trình rõ ràng cho xác thực, chọn tài khoản, hoàn tất và ngắt kết nối làm tăng công sức hỗ trợ, khó kiểm soát quyền truy cập và khiến việc bổ sung kênh mới về sau dễ tạo hành vi không nhất quán.

**Tổng quan tính năng**:

Tính năng cung cấp vòng đời kết nối cho Instagram và Facebook thông qua Meta. Người dùng có thể bắt đầu kết nối, hoàn tất xác thực tại nhà cung cấp, xem các tài khoản/trang được phát hiện, chọn tài khoản cần liên kết với agent và ngắt kết nối khi không còn nhu cầu. Quy trình phải đủ rõ để có thể mở rộng sang phương thức kết nối hoặc kênh khác mà không làm thay đổi trải nghiệm hiện có.

---

## 2. Mục tiêu

- **MT-001**: Cho phép người dùng hoàn tất kết nối một tài khoản Instagram hoặc Facebook hợp lệ với đúng agent.
- **MT-002**: Bảo đảm người dùng chỉ nhìn thấy và lựa chọn các tài khoản/trang mà họ có quyền quản lý.
- **MT-003**: Tạo vòng đời kết nối có thể truy vết, xử lý lỗi và mở rộng thêm phương thức kết nối trong các phiên bản sau.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Bắt đầu và tiếp tục luồng xác thực cho Instagram và Facebook thông qua Meta.
- **MVP-002**: Nhận kết quả xác thực, khám phá các tài khoản/trang hợp lệ, cho phép chọn một tài khoản và hoàn tất liên kết với agent.
- **MVP-003**: Cho phép ngắt kết nối, từ chối tài khoản không hợp lệ hoặc không có quyền, và giữ trạng thái kết nối nhất quán khi luồng thất bại hoặc được lặp lại.
- **MVP-004**: Lưu thông tin kết nối và tham chiếu thông tin xác thực theo cách không làm lộ credential cho người dùng cuối.

---

## 4. Người dùng & Bối cảnh

**Người dùng chính**: Người dùng đã đăng nhập và có quyền cấu hình agent; quản trị viên hỗ trợ kết nối kênh.

**Bối cảnh sử dụng**: Người dùng cấu hình một agent và cần liên kết agent đó với tài khoản Instagram hoặc Facebook đang được họ quản lý.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Người dùng nghiệp vụ; quản trị viên có thể hỗ trợ các trường hợp lỗi hoặc thu hồi kết nối.

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Kết nối tài khoản Instagram (Ưu tiên: P1)

Người dùng chọn kết nối Instagram cho một agent, hoàn tất xác thực với Meta, xem các tài khoản Instagram được phát hiện từ các trang họ quản lý, chọn một tài khoản và xác nhận kết nối.

**Lý do ưu tiên**: Đây là luồng chính để agent có thể sử dụng Instagram và là nhu cầu được nêu rõ trong đề xuất.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003, FR-004, FR-005

**Test độc lập**: Dùng một agent và tài khoản Meta có ít nhất một trang liên kết với Instagram hợp lệ; kiểm tra từ lúc bắt đầu đến khi kết nối hoàn tất.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** người dùng có quyền cấu hình agent, **Khi** họ bắt đầu kết nối Instagram, **Thì** hệ thống tạo một phiên kết nối gắn với agent và chuyển người dùng đến bước xác thực Meta.
2. **AC-002**: **Cho trước** xác thực Meta thành công, **Khi** hệ thống nhận callback hợp lệ, **Thì** hệ thống hiển thị các tài khoản Instagram mà người dùng có quyền quản lý cùng thông tin nhận diện cần thiết.
3. **AC-003**: **Cho trước** có ít nhất một tài khoản hợp lệ, **Khi** người dùng chọn một tài khoản và xác nhận, **Thì** tài khoản được liên kết với đúng agent và trạng thái kết nối chuyển sang hoàn tất.
4. **AC-004**: **Cho trước** callback hoặc tài khoản được chọn không hợp lệ, **Khi** hệ thống xử lý kết quả, **Thì** kết nối không được hoàn tất và người dùng nhận được hướng dẫn có thể thực hiện lại.

### US-002 — Kết nối trang Facebook (Ưu tiên: P1)

Người dùng chọn kết nối Facebook cho một agent, hoàn tất xác thực với Meta, xem các trang Facebook họ quản lý, chọn một trang và xác nhận kết nối.

**Lý do ưu tiên**: Facebook là kênh được yêu cầu cùng với Instagram và dùng chung quá trình xác thực nhưng có bước lựa chọn tài nguyên riêng.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003, FR-004, FR-005

**Test độc lập**: Dùng một agent và tài khoản Meta có ít nhất một trang Facebook được quản lý; kiểm tra từ lúc bắt đầu đến khi kết nối hoàn tất.

**Acceptance Criteria**:

1. **AC-005**: **Cho trước** người dùng có quyền cấu hình agent, **Khi** họ bắt đầu kết nối Facebook, **Thì** hệ thống tạo một phiên kết nối gắn với agent và chuyển người dùng đến bước xác thực Meta.
2. **AC-006**: **Cho trước** xác thực Meta thành công, **Khi** hệ thống nhận callback hợp lệ, **Thì** hệ thống hiển thị các trang Facebook người dùng có quyền quản lý.
3. **AC-007**: **Cho trước** người dùng chọn một trang hợp lệ, **Khi** họ xác nhận, **Thì** trang được liên kết với đúng agent và trạng thái kết nối chuyển sang hoàn tất.

### US-003 — Ngắt kết nối kênh (Ưu tiên: P2)

Người dùng xem một kết nối hiện có của agent và yêu cầu ngắt kết nối để agent không tiếp tục sử dụng liên kết đó.

**Lý do ưu tiên**: Người dùng cần quyền kiểm soát vòng đời kết nối và khả năng thu hồi khi đổi tài khoản hoặc không còn sử dụng kênh.

**Liên quan yêu cầu**: FR-006, FR-007

**Test độc lập**: Dùng agent đã có kết nối hoàn tất; thực hiện ngắt kết nối và xác nhận trạng thái sau thao tác.

**Acceptance Criteria**:

1. **AC-008**: **Cho trước** người dùng có quyền quản lý kết nối, **Khi** họ yêu cầu ngắt kết nối, **Thì** hệ thống đánh dấu kết nối đã ngắt, dọn dẹp tham chiếu credential cục bộ và không cho phép dùng kết nối đó cho thao tác mới.
2. **AC-009**: **Cho trước** kết nối đã ngắt, **Khi** người dùng gửi lại yêu cầu ngắt kết nối, **Thì** hệ thống không tạo thêm thay đổi và hiển thị trạng thái hiện tại.

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Hiển thị trạng thái không tìm thấy tài khoản/trang hợp lệ và hướng dẫn kiểm tra quyền quản lý hoặc thử tài khoản khác.
- **Dữ liệu không hợp lệ**: Callback, phiên hoặc tài khoản không hợp lệ không được phép hoàn tất kết nối; phiên chuyển sang thất bại có thể thử lại theo chính sách phiên.
- **Không có quyền**: Từ chối thao tác và không hiển thị hoặc lưu tài nguyên ngoài phạm vi quyền của người dùng.
- **Lỗi hệ thống**: Giữ kết nối chưa hoàn tất, thông báo lỗi thân thiện và cho phép thử lại mà không tạo kết nối trùng.
- **Timeout**: Phiên đang xử lý được đánh dấu không hoàn tất; người dùng có thể bắt đầu lại một phiên mới.
- **Dữ liệu bị thay đổi bởi người khác**: Khi tài khoản/trang không còn khả dụng hoặc quyền đã bị thu hồi, hệ thống không hoàn tất kết nối và yêu cầu người dùng xác thực lại.
- **Người dùng thao tác lặp lại**: Các yêu cầu lặp lại không tạo thêm kết nối hoặc phiên hoàn tất trùng cho cùng tài khoản và agent.
- **Trường hợp biên khác**: Nếu một tài khoản đã liên kết với agent, hệ thống hiển thị kết nối hiện có và không tạo bản ghi hoạt động thứ hai.

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI cho phép người dùng có quyền bắt đầu luồng kết nối Instagram hoặc Facebook cho một agent.  
  **Liên quan**: US-001, US-002, AC-001, AC-005
- **FR-002** `[P1]`: Hệ thống PHẢI duy trì phiên kết nối để liên kết callback xác thực với đúng agent, kênh và phương thức kết nối đã chọn.  
  **Liên quan**: US-001, US-002, AC-001, AC-005, AC-004
- **FR-003** `[P1]`: Hệ thống PHẢI khám phá và hiển thị các tài khoản Instagram hoặc trang Facebook mà người dùng có quyền quản lý sau khi xác thực thành công.  
  **Liên quan**: US-001, US-002, AC-002, AC-006
- **FR-004** `[P1]`: Hệ thống PHẢI cho phép người dùng chọn một tài khoản/trang hợp lệ để liên kết với agent.  
  **Liên quan**: US-001, US-002, AC-003, AC-007
- **FR-005** `[P1]`: Hệ thống PHẢI hoàn tất kết nối với thông tin nhận diện của tài khoản/trang và trạng thái kết nối có thể truy vấn được.  
  **Liên quan**: US-001, US-002, AC-003, AC-007
- **FR-006** `[P2]`: Hệ thống PHẢI cho phép người dùng có quyền ngắt kết nối một liên kết đã hoàn tất.  
  **Liên quan**: US-003, AC-008
- **FR-007** `[P2]`: Hệ thống PHẢI xử lý yêu cầu ngắt kết nối lặp lại theo cách an toàn, không tạo thay đổi hoặc lỗi nghiệp vụ mới.  
  **Liên quan**: US-003, AC-009
- **FR-008** `[P1]`: Hệ thống KHÔNG ĐƯỢC hoàn tất kết nối nếu callback, phiên, tài khoản hoặc quyền truy cập không hợp lệ.  
  **Liên quan**: US-001, US-002, AC-004
- **FR-009** `[P1]`: Hệ thống KHÔNG ĐƯỢC tạo kết nối hoạt động trùng cho cùng agent, kênh và tài khoản/trang.  
  **Liên quan**: US-001, US-002, US-003
- **FR-010** `[P1]`: Hệ thống PHẢI tách thông tin xác thực khỏi dữ liệu hiển thị cho người dùng và chỉ lưu tham chiếu cần thiết cho việc sử dụng kết nối.  
  **Liên quan**: US-001, US-002, AC-003, AC-007

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Chỉ người dùng có quyền cấu hình agent mới được bắt đầu, hoàn tất hoặc ngắt kết nối của agent đó.
- **BR-002**: Một phiên kết nối chỉ được dùng cho đúng agent, kênh và phương thức đã khởi tạo; callback không khớp phiên bị từ chối.
- **BR-003**: Chỉ tài khoản/trang được nhà cung cấp xác nhận người dùng có quyền quản lý mới đủ điều kiện liên kết.
- **BR-004**: Một agent không được có nhiều kết nối hoạt động trùng tới cùng tài khoản/trang trên cùng kênh.
- **BR-005**: Ngắt kết nối phải vô hiệu hóa việc sử dụng liên kết và dọn dẹp tham chiếu credential cục bộ theo chính sách lưu trữ.
- **BR-006**: Phương thức kết nối được lưu cùng phiên để callback được xử lý bởi đúng quy trình; phương thức mới không được làm thay đổi hành vi của phương thức hiện có.

**Luồng trạng thái nếu có**:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| Chưa bắt đầu | Bắt đầu kết nối | Đang chờ xác thực | Người dùng có quyền |
| Đang chờ xác thực | Callback hợp lệ | Đã khám phá | Xác thực thành công |
| Đang chờ xác thực | Callback lỗi/hết hạn | Thất bại | Không thể xác thực hoặc phiên không hợp lệ |
| Đã khám phá | Chọn tài khoản/trang hợp lệ | Hoàn tất | Tài khoản/trang chưa bị liên kết trùng |
| Đã khám phá | Không có tài khoản/trang hợp lệ | Thất bại | Không có tài nguyên đủ điều kiện |
| Hoàn tất | Ngắt kết nối | Đã ngắt kết nối | Người dùng có quyền |

---

## 9. Thực thể dữ liệu

- **Agent**: Agent nhận liên kết kênh; một agent có thể có nhiều kết nối thuộc các kênh khác nhau.
- **Integration Connection Session**: Phiên tạm thời theo dõi một lần người dùng bắt đầu xác thực, khám phá và hoàn tất kết nối.
- **Channel Connection**: Liên kết đã hoàn tất giữa agent và tài khoản/trang bên ngoài, cùng trạng thái vòng đời.
- **External Account**: Tài khoản Instagram hoặc trang Facebook được người dùng lựa chọn từ các tài nguyên họ quản lý.
- **Credential Reference**: Tham chiếu nội bộ đến thông tin cho phép hệ thống sử dụng kết nối; không phải dữ liệu hiển thị cho người dùng.

---

## 10. Phân quyền & Bảo mật

**Ai được xem**:
- Người dùng có quyền xem/cấu hình agent được xem trạng thái và thông tin nhận diện của các kết nối thuộc agent đó.

**Ai được thao tác**:
- Người dùng có quyền cấu hình agent được bắt đầu, hoàn tất và ngắt kết nối.
- Quản trị viên được hỗ trợ xử lý hoặc thu hồi kết nối theo quyền quản trị hiện có.

**Ai không được phép**:
- Người dùng không có quyền trên agent không được xem, tạo, hoàn tất hoặc ngắt kết nối của agent đó.
- Không người dùng nào được xem credential hoặc tài nguyên ngoài phạm vi được nhà cung cấp cấp quyền.

**Dữ liệu nhạy cảm**:
- Có. Thông tin xác thực và tham chiếu credential là dữ liệu nhạy cảm; chỉ hệ thống được ủy quyền mới được sử dụng và không được đưa vào dữ liệu hiển thị, log hoặc audit không cần thiết.

- **SEC-001**: Hệ thống PHẢI kiểm tra quyền trước khi cho phép thao tác.
- **SEC-002**: Hệ thống KHÔNG ĐƯỢC cho người dùng truy cập dữ liệu ngoài phạm vi được cấp quyền.
- **SEC-003**: Hệ thống PHẢI bảo vệ credential trong toàn bộ vòng đời kết nối và thu hồi tham chiếu khi ngắt kết nối.

---

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Có.

Hệ thống PHẢI ghi nhận:

- Ai bắt đầu, hoàn tất hoặc ngắt kết nối.
- Kênh, tài khoản/trang và agent bị tác động.
- Thời điểm, kết quả và lý do thất bại nếu có.
- Không ghi credential hoặc giá trị bí mật vào audit.

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: Trong điều kiện tải thông thường, người dùng nhận được phản hồi cho mỗi bước nội bộ của luồng kết nối trong vòng 3 giây, không tính thời gian người dùng tương tác với trang xác thực bên ngoài.
- **NFR-002**: Việc kết nối lỗi hoặc hết hạn không được làm thay đổi các kết nối hoàn tất trước đó của cùng agent.
- **NFR-003**: Thông báo lỗi phải đủ rõ để người dùng biết có thể thử lại, kiểm tra quyền hay liên hệ quản trị viên.
- **NFR-004**: Luồng kết nối phải hoạt động trên các trình duyệt đang được ứng dụng hỗ trợ.

---

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: Ít nhất 95% luồng kết nối hợp lệ hoàn tất mà không cần thao tác hỗ trợ thủ công.
- **SC-002**: Người dùng hoàn tất một luồng kết nối thành công trong dưới 5 phút, không tính thời gian chờ xét duyệt bên ngoài nếu có.
- **SC-003**: 100% callback không hợp lệ hoặc tài nguyên ngoài quyền bị từ chối và không tạo kết nối hoạt động.
- **SC-004**: 100% yêu cầu ngắt kết nối hợp lệ làm cho liên kết không còn được phép dùng cho thao tác mới.
- **SC-005**: Không phát sinh kết nối hoạt động trùng trong các lần người dùng lặp lại cùng một thao tác.

---

## 14. Giả định & Ràng buộc

**Giả định**:
- Người dùng đã đăng nhập và hệ thống đã có cơ chế phân quyền agent.
- Người dùng có tài khoản Meta và đã cấp các quyền cần thiết cho tài nguyên họ muốn kết nối.
- Việc gửi tin nhắn, webhook và các thao tác vận hành kênh sẽ được xác định ở feature khác.
- MVP có thể hỗ trợ thêm phương thức kết nối Instagram trong tương lai mà không thay đổi dữ liệu kết nối đã hoàn tất.

**Ràng buộc**:
- PHẢI tuân thủ quyền truy cập và giới hạn do Meta áp dụng.
- Không được lưu credential trực tiếp trong dữ liệu hiển thị hoặc tài liệu nghiệp vụ.
- Không được làm hỏng các kết nối hoặc luồng agent hiện có.

---

## 15. Ngoài phạm vi

- Gửi và nhận tin nhắn Instagram/Facebook.
- Webhook, đồng bộ sự kiện thời gian thực và xử lý hội thoại.
- Đăng bài, quảng cáo, phân tích số liệu hoặc quản trị nội dung trên các kênh.
- Kết nối Zalo, TikTok, Telegram hoặc nhà cung cấp khác.
- Chi tiết triển khai như framework, API endpoint, cấu trúc project, DI, database schema và cơ chế lưu secret.

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Chính sách hoặc quyền Meta thay đổi | Trung | Cao | Theo dõi quyền được cấp, hiển thị lỗi có hướng dẫn và cô lập phụ thuộc nhà cung cấp trong một ranh giới rõ ràng |
| Người dùng mất quyền quản lý trang/tài khoản sau khi kết nối | Trung | Cao | Kiểm tra quyền khi hoàn tất và khi sử dụng; đánh dấu kết nối cần xác thực lại khi quyền bị thu hồi |
| Callback bị gửi lại hoặc phiên bị giả mạo | Thấp | Cao | Gắn phiên với agent và phương thức, từ chối callback không khớp và bảo đảm thao tác lặp có tính idempotent |
| Credential bị lộ qua log hoặc dữ liệu hiển thị | Thấp | Cao | Chỉ dùng tham chiếu nội bộ, loại bỏ secret khỏi log/audit và kiểm tra trong review bảo mật |

---

## 17. Phụ thuộc

- Ứng dụng Meta và các quyền sản phẩm cần thiết cho Instagram/Facebook phải được cấu hình và được nhà cung cấp cho phép.
- Hệ thống xác thực và phân quyền agent hiện có phải xác định được người dùng có quyền cấu hình agent.
- Hệ thống lưu trữ kết nối/credential hiện có hoặc quyết định nghiệp vụ tương ứng phải sẵn sàng trước khi hoàn tất kết nối.
- Stakeholder cần xác nhận chính sách lưu trữ và thu hồi tham chiếu credential trước khi release production.

---

## 18. Câu hỏi mở

- Không có câu hỏi mở chặn phạm vi MVP. Các quyết định kỹ thuật về giao thức, cấu trúc module, persistence và DI thuộc `plan.md`.

## Clarifications

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

---

## 20. Đánh giá tác động tài liệu nghiệp vụ

- **Trạng thái**: CÓ CẬP NHẬT
- **Căn cứ**: Sections 1, 3, 4, 5, 8, 9, 10 và 15 bổ sung luồng đầu-cuối kết nối Instagram/Facebook qua Meta, vai trò của người quản lý, thực thể kết nối, quy tắc quyền/thu hồi và phạm vi vận hành kênh.
- **Tài liệu đã cập nhật**: `docs/business/13-meta-channel-connections.md` và `docs/business/business-docs-index.md`.
- **Tài liệu đã xem xét nhưng không chỉnh sửa**: `docs/business/06-instagram-business.md` vẫn là tài liệu chi tiết cho nghiệp vụ phát hành và xử lý DM Instagram; `docs/business/07-agent-service-restructure.md` vẫn là tài liệu tái cấu trúc kỹ thuật, không mở rộng vì feature này không thay đổi ý nghĩa của hai tài liệu đó.
