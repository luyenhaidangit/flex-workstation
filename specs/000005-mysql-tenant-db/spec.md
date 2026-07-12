# Đặc tả tính năng: Triển khai DB MySQL cho các Tenant

**Branch**: `000005-mysql-tenant-db`
**Ngày tạo**: 2026-07-12
**Trạng thái**: Bản nháp
**Người phụ trách**: Luyện Hải Đăng
**Stakeholder xác nhận**: Luyện Hải Đăng
**Đầu vào**: Mô tả người dùng: "000005 Triển khai db mysql cho các tenant"

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 0. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

Khi một tenant mới được tạo trong hệ thống, dữ liệu của họ cần được lưu trữ trong một cơ sở dữ liệu độc lập với các tenant khác. Hiện tại chưa có quy trình tự động để khởi tạo và cấu hình cơ sở dữ liệu MySQL riêng cho từng tenant, dẫn đến thao tác thủ công, dễ sai sót và không scale được khi số lượng tenant tăng.

**Tổng quan tính năng**:

Tính năng này cho phép hệ thống tự động khởi tạo cơ sở dữ liệu MySQL riêng biệt cho mỗi tenant khi họ được đăng ký vào nền tảng. Mỗi tenant có database độc lập, thông tin xác thực riêng, và dữ liệu không bị trộn lẫn với tenant khác. Mục tiêu là đảm bảo cô lập dữ liệu, bảo mật và khả năng vận hành ổn định khi số lượng tenant tăng lên.

---

## 1. Mục tiêu

- **MT-001**: Mỗi tenant được cung cấp cơ sở dữ liệu MySQL riêng, độc lập với các tenant khác ngay khi được kích hoạt.
- **MT-002**: Quản trị viên có thể kiểm tra trạng thái database của từng tenant mà không cần thao tác thủ công trên máy chủ.
- **MT-003**: Quy trình khởi tạo database tenant có thể lặp lại, tái tạo và không phụ thuộc vào thao tác con người.

---

## 2. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Tự động khởi tạo một MySQL database riêng cho tenant khi tenant được tạo mới (hoặc khi quản trị viên kích hoạt thủ công).
- **MVP-002**: Tạo user MySQL riêng với thông tin xác thực an toàn cho từng tenant; thông tin xác thực được lưu trữ an toàn và có thể truy xuất bởi ứng dụng của tenant đó.
- **MVP-003**: MVP chỉ áp dụng cho môi trường vận hành nội bộ (không bao gồm multi-region hay cloud-managed DB); chỉ hỗ trợ khởi tạo mới, chưa hỗ trợ migration dữ liệu hiện có.

---

## 3. Người dùng & Bối cảnh

**Người dùng chính**: Quản trị viên hệ thống (System Administrator) và hệ thống tự động (automation pipeline trong quy trình onboarding tenant).

**Bối cảnh sử dụng**: Khi một tenant mới được đăng ký và cần được kích hoạt để sử dụng dịch vụ; quản trị viên cần đảm bảo tenant có đầy đủ hạ tầng dữ liệu trước khi tenant bắt đầu sử dụng.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Quản trị viên / Kỹ thuật (đối với người vận hành); Hệ thống tự động (đối với pipeline).

---

## 4. Kịch bản người dùng *(bắt buộc)*

### US-001 — Khởi tạo database khi onboard tenant mới (Ưu tiên: P1)

Quản trị viên đăng ký một tenant mới lên hệ thống. Hệ thống tự động (hoặc theo yêu cầu của quản trị viên) tạo một MySQL database riêng cho tenant đó, tạo user MySQL với thông tin xác thực, và lưu thông tin kết nối an toàn để ứng dụng của tenant có thể sử dụng ngay.

**Lý do ưu tiên**: Đây là luồng cốt lõi — không có database, tenant không thể hoạt động. Mọi tính năng khác phụ thuộc vào bước này.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003, FR-004

**Test độc lập**: Tạo một tenant test trong môi trường staging, xác minh database được tạo, user được tạo, thông tin kết nối được lưu và có thể kết nối thành công.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** hệ thống chưa có database cho tenant X, **Khi** tenant X được đăng ký hoặc quản trị viên kích hoạt tạo database, **Thì** một MySQL database có tên duy nhất được tạo thành công cho tenant X.
2. **AC-002**: **Cho trước** database của tenant X đã được tạo, **Khi** hệ thống hoàn tất khởi tạo, **Thì** thông tin xác thực kết nối (host, port, database name, user, password) được lưu trữ an toàn và chỉ có ứng dụng của tenant X được phép truy cập.
3. **AC-003**: **Cho trước** thông tin kết nối đã được lưu, **Khi** ứng dụng của tenant X dùng thông tin đó để kết nối, **Thì** kết nối thành công và tenant X không thể truy cập dữ liệu của tenant khác.

---

### US-002 — Quản trị viên kiểm tra trạng thái database của tenant (Ưu tiên: P2)

Quản trị viên cần kiểm tra database của một tenant cụ thể có đang hoạt động không, để hỗ trợ debug hoặc vận hành.

**Lý do ưu tiên**: Cần thiết cho vận hành nhưng không chặn tenant sử dụng dịch vụ.

**Liên quan yêu cầu**: FR-005

**Test độc lập**: Sau khi tạo database cho tenant test, quản trị viên truy vấn trạng thái và nhận được thông tin trạng thái chính xác (tồn tại / không tồn tại / lỗi kết nối).

**Acceptance Criteria**:

1. **AC-004**: **Cho trước** database của tenant Y đã được tạo, **Khi** quản trị viên kiểm tra trạng thái, **Thì** hệ thống trả về thông tin xác nhận database đang hoạt động bình thường.
2. **AC-005**: **Cho trước** tenant Z chưa có database, **Khi** quản trị viên kiểm tra trạng thái, **Thì** hệ thống trả về thông tin rõ ràng rằng database chưa được khởi tạo.

---

### US-003 — Xử lý lỗi khi khởi tạo database thất bại (Ưu tiên: P2)

Trong quá trình tự động khởi tạo, nếu xảy ra lỗi (máy chủ DB không sẵn sàng, tên bị trùng, thiếu quyền), hệ thống phải thông báo rõ ràng và không để tenant ở trạng thái không nhất quán.

**Lý do ưu tiên**: Đảm bảo tính nhất quán dữ liệu và hỗ trợ quản trị viên xử lý sự cố.

**Liên quan yêu cầu**: FR-006, FR-007

**Test độc lập**: Mô phỏng lỗi trong quá trình tạo database (ví dụ: máy chủ DB offline), xác minh hệ thống ghi nhận lỗi, rollback trạng thái và không để database hay user nửa vời tồn tại.

**Acceptance Criteria**:

1. **AC-006**: **Cho trước** quá trình khởi tạo database thất bại giữa chừng, **Khi** lỗi xảy ra, **Thì** hệ thống rollback hoặc dọn sạch các resource đã tạo một phần, và tenant không ở trạng thái "đã tạo một phần".
2. **AC-007**: **Cho trước** khởi tạo thất bại, **Khi** quản trị viên kiểm tra, **Thì** lỗi được ghi lại đủ thông tin để tái hiện và xử lý.

---

## 5. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Tenant mới được tạo nhưng chưa có database — hệ thống hiển thị trạng thái "Chưa khởi tạo".
- **Dữ liệu không hợp lệ**: Tên tenant không hợp lệ hoặc xung đột với tenant đã có — hệ thống từ chối và báo lỗi rõ ràng trước khi thực hiện.
- **Không có quyền**: Người gọi không có quyền khởi tạo database — hệ thống từ chối với thông báo quyền không đủ.
- **Lỗi hệ thống**: Máy chủ MySQL không sẵn sàng — hệ thống ghi lỗi, không tạo resource nửa vời, tenant giữ trạng thái "Chưa khởi tạo".
- **Timeout**: Nếu quá trình khởi tạo vượt thời gian cho phép — hệ thống timeout, rollback, ghi log và cảnh báo quản trị viên.
- **Dữ liệu bị thay đổi bởi người khác**: Không áp dụng (mỗi database thuộc về một tenant duy nhất).
- **Người dùng thao tác lặp lại**: Nếu quản trị viên cố tạo lại database cho tenant đã có — hệ thống từ chối với thông báo database đã tồn tại (không tạo trùng).
- **Trường hợp biên khác**: Tenant bị xóa — database của tenant bị xóa (hoặc lưu trữ tùy chính sách) cần được xác định trong câu hỏi mở.

---

## 6. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI tạo một MySQL database có định danh duy nhất cho mỗi tenant khi được yêu cầu.  
  **Liên quan**: US-001, AC-001
- **FR-002** `[P1]`: Hệ thống PHẢI tạo một user MySQL riêng biệt với thông tin xác thực mạnh cho mỗi tenant, và lưu thông tin xác thực đó ở vị trí an toàn.  
  **Liên quan**: US-001, AC-002
- **FR-003** `[P1]`: Hệ thống PHẢI đảm bảo user MySQL của tenant chỉ có quyền truy cập đúng database của tenant đó, không có quyền trên database của tenant khác.  
  **Liên quan**: US-001, AC-003
- **FR-004** `[P1]`: Hệ thống KHÔNG ĐƯỢC tạo trùng database hoặc user cho một tenant đã có database.  
  **Liên quan**: US-001, AC-003; Trạng thái lặp lại
- **FR-005** `[P2]`: Hệ thống PHẢI cho phép quản trị viên kiểm tra trạng thái database của một tenant cụ thể (tồn tại / không tồn tại / lỗi kết nối).  
  **Liên quan**: US-002, AC-004, AC-005
- **FR-006** `[P2]`: Khi quá trình khởi tạo thất bại, hệ thống PHẢI rollback hoặc dọn sạch các resource đã tạo một phần để tenant không ở trạng thái không nhất quán.  
  **Liên quan**: US-003, AC-006
- **FR-007** `[P2]`: Hệ thống PHẢI ghi log sự kiện khởi tạo (thành công và thất bại) với đủ thông tin để quản trị viên kiểm tra và tái hiện lỗi.  
  **Liên quan**: US-003, AC-007

---

## 7. Quy tắc nghiệp vụ

- **BR-001**: Mỗi tenant có đúng một database MySQL; không cho phép một tenant có nhiều database trong MVP.
- **BR-002**: Định danh database và user MySQL của tenant PHẢI được sinh từ định danh tenant (ví dụ: ID hoặc slug) theo quy tắc nhất quán — không dùng tên tự đặt tùy ý.
- **BR-003**: Thông tin xác thực (password) của MySQL user tenant PHẢI được sinh ngẫu nhiên, đủ mạnh và không được lưu dưới dạng plain text trong bất kỳ artifact nào.
- **BR-004**: Việc xóa database của tenant (nếu tenant bị hủy) PHẢI được xác nhận bởi quản trị viên có thẩm quyền — không tự động xóa dữ liệu.

**Luồng trạng thái**:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| Chưa khởi tạo | Khởi tạo database | Đang khởi tạo | Quản trị viên có quyền, tenant hợp lệ |
| Đang khởi tạo | Khởi tạo thành công | Hoạt động | Tất cả resource tạo đủ |
| Đang khởi tạo | Khởi tạo thất bại | Chưa khởi tạo | Lỗi xảy ra, đã rollback/dọn dẹp |
| Hoạt động | Kiểm tra trạng thái | Hoạt động | Không đổi trạng thái |
| Hoạt động | Xóa (thủ công) | Đã xóa | Quản trị viên có thẩm quyền xác nhận |

---

## 8. Thực thể dữ liệu

- **Tenant**: Đại diện cho một khách hàng/tổ chức sử dụng nền tảng; có định danh duy nhất; là đối tượng sở hữu database.
- **TenantDatabase**: Đại diện cho thông tin cơ sở dữ liệu MySQL được cấp phát cho một tenant — bao gồm tên database, thông tin xác thực (ở dạng tham chiếu an toàn), trạng thái, thời điểm tạo. Quan hệ 1-1 với Tenant.

---

## 9. Phân quyền & Bảo mật

**Ai được xem**:
- Quản trị viên hệ thống được xem trạng thái database của bất kỳ tenant nào.
- Ứng dụng của tenant được xem thông tin kết nối của chính mình (không xem tenant khác).

**Ai được thao tác**:
- Quản trị viên hệ thống được khởi tạo, kiểm tra và yêu cầu xóa database tenant.
- Hệ thống tự động (automation pipeline) được khởi tạo database khi có sự kiện onboard tenant.

**Ai không được phép**:
- Tenant không được xem hay thao tác trực tiếp trên database của tenant khác.
- Tenant không được tự khởi tạo hay xóa database của chính mình qua giao diện quản trị.

**Dữ liệu nhạy cảm**:
- Có. Thông tin xác thực MySQL (username, password, connection string) là dữ liệu nhạy cảm — không được ghi vào log, không được lưu plain text.

- **SEC-001**: Hệ thống PHẢI kiểm tra quyền quản trị viên trước khi cho phép khởi tạo hoặc xóa database tenant.
- **SEC-002**: Hệ thống KHÔNG ĐƯỢC cho phép ứng dụng của tenant A truy cập database của tenant B dưới bất kỳ hình thức nào.
- **SEC-003**: Thông tin xác thực MySQL của tenant PHẢI được mã hóa hoặc lưu trong hệ thống quản lý secret — không xuất hiện plain text trong log, config file, hay API response.

---

## 10. Audit & Lịch sử thay đổi

**Có cần audit không**: Có

Hệ thống PHẢI ghi nhận:

- Ai thực hiện (quản trị viên hoặc pipeline tự động)
- Thao tác gì (khởi tạo / xóa / kiểm tra trạng thái)
- Thời điểm thực hiện
- Tenant nào bị ảnh hưởng
- Kết quả (thành công / thất bại + lý do nếu thất bại)

---

## 11. Yêu cầu phi chức năng

- **NFR-001**: Quá trình khởi tạo database cho một tenant hoàn tất trong vòng 30 giây trong điều kiện bình thường.
- **NFR-002**: Tính năng không làm gián đoạn hoạt động của các tenant đang có database hiện hữu.
- **NFR-003**: Quy trình khởi tạo có thể chạy lại an toàn (idempotent về trạng thái cuối) — nếu chạy lại trên tenant đã có database, hệ thống phát hiện và không tạo trùng.

---

## 12. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: 100% tenant mới được onboard có database MySQL hoạt động trong vòng 30 giây kể từ khi yêu cầu khởi tạo.
- **SC-002**: Không có sự cố cô lập dữ liệu — không có trường hợp ứng dụng của tenant A truy cập được dữ liệu của tenant B.
- **SC-003**: Quản trị viên có thể kiểm tra trạng thái database của bất kỳ tenant nào trong dưới 5 giây, không cần SSH vào máy chủ.
- **SC-004**: Thao tác khởi tạo thất bại không để lại resource nửa vời (database hoặc user MySQL orphan) trong 100% trường hợp kiểm thử.

---

## 13. Giả định & Ràng buộc

**Giả định**:
- Hệ thống MySQL đã được cài đặt và đang chạy trong môi trường mục tiêu; tính năng này không bao gồm việc cài đặt MySQL.
- Có một tài khoản MySQL quản trị (với đủ quyền để tạo database và user) đã được cấu hình sẵn và lưu an toàn trong hệ thống.
- Mỗi tenant có định danh duy nhất (ID hoặc slug) được tạo trước bước khởi tạo database.
- Môi trường MVP là single-region, single MySQL instance.

**Ràng buộc**:
- PHẢI dùng MySQL (không phải MariaDB hay PostgreSQL) vì đây là yêu cầu của hệ thống hiện tại.
- Thông tin xác thực PHẢI được lưu trong hệ thống quản lý secret hiện có (không lưu trong database ứng dụng dưới dạng plain text).

---

## 14. Ngoài phạm vi

- Cài đặt và cấu hình ban đầu của MySQL server.
- Migration dữ liệu từ hệ thống cũ sang database tenant mới.
- Hỗ trợ multi-region hoặc cloud-managed MySQL (RDS, CloudSQL, v.v.).
- Backup và restore tự động cho database tenant.
- Cho phép tenant tự quản lý (tạo/xóa) database của mình qua self-service UI.
- Schema migration hoặc seed dữ liệu ban đầu cho từng tenant (đây là bước riêng sau khi database đã tạo).

---

## 15. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| MySQL admin credential bị lộ trong quá trình tự động hóa | Trung | Cao | Dùng hệ thống quản lý secret, không hardcode trong script hay config |
| Tên database/user bị xung đột nếu quy tắc đặt tên không đủ duy nhất | Thấp | Trung | Dùng ID tenant (UUID hoặc unique slug) làm cơ sở đặt tên, kiểm tra trùng trước khi tạo |
| Quá trình khởi tạo chạy song song cho nhiều tenant cùng lúc gây race condition | Thấp | Trung | Thiết kế để các thao tác tạo database là độc lập nhau; kiểm tra trong plan kỹ thuật |
| Thông tin kết nối không đến được ứng dụng của tenant kịp thời | Trung | Cao | Thiết kế luồng đồng bộ: database ready trước khi thông báo onboard hoàn tất |

---

## 16. Phụ thuộc

- Phụ thuộc vào hệ thống quản lý secret hiện có để lưu trữ MySQL admin credential và thông tin xác thực từng tenant.
- Phụ thuộc vào tài khoản MySQL admin đã được cấu hình sẵn trong môi trường mục tiêu.

---

## 17. Câu hỏi mở

Không còn câu hỏi mở chặn plan. Các quyết định đã chốt:

- **Trigger**: Quản trị viên kích hoạt thủ công (MVP). Tích hợp tự động event-driven để sau.
- **Chính sách xóa database khi tenant bị hủy**: Ngoài phạm vi MVP, sẽ xác định sau khi có nghiệp vụ rõ hơn.

---

## 18. Điều kiện sẵn sàng để lập plan kỹ thuật

- [x] Vấn đề cần giải quyết đã rõ.
- [x] MVP đã được xác định.
- [x] Luồng P1 có Acceptance Criteria đầy đủ.
- [x] Yêu cầu chức năng chính đã có ID.
- [x] Quy tắc nghiệp vụ quan trọng đã được ghi nhận.
- [x] Phân quyền/bảo mật đã rõ hoặc được đánh dấu là câu hỏi mở.
- [x] Ngoài phạm vi đã rõ.
- [x] Các câu hỏi mở quan trọng đã được trả lời hoặc được chấp nhận là rủi ro.
