# Đặc tả tính năng: Nền tảng AI Agent đa tenant — MVP

**Branch**: `000008-agent-platform-mvp`
**Ngày tạo**: 2026-07-12
**Trạng thái**: Bản nháp
**Người phụ trách**: Luyện Hải Đăng
**Stakeholder xác nhận**: Luyện Hải Đăng
**Đầu vào**: Mô tả người dùng: "Mong muốn triển khai hệ thống như tài liệu phân tích docs/architecture/agent-platform-architecture.md tại MVP này"

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

Phạm vi MVP bám theo mục 7 của tài liệu `docs/architecture/agent-platform-architecture.md`: tenant provisioning, Agent Studio, knowledge upload, test chat, publish web widget, runtime RAG, version/rollback, RBAC, audit và usage cơ bản.

---

## 0. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

Doanh nghiệp muốn có "nhân viên AI" tư vấn/hỗ trợ khách hàng trên website của mình nhưng hiện chưa có công cụ nào để: tự tạo agent, nạp tri thức riêng của doanh nghiệp, chạy thử trước khi công bố, và phát hành lên website một cách an toàn. Nếu không có nền tảng chung, mỗi doanh nghiệp phải tự xây chatbot riêng — tốn kém, không kiểm soát được dữ liệu và không có cách ly giữa các doanh nghiệp.

Tài liệu phân tích kiến trúc đã xác định định vị sản phẩm là **nền tảng AI Agent đa tenant** (không chỉ là chatbot đơn lẻ). MVP này là bước hiện thực hóa đầu tiên của định vị đó.

**Tổng quan tính năng**:

Xây dựng phiên bản MVP của nền tảng: mỗi doanh nghiệp (tenant) có không gian làm việc riêng với dữ liệu được cách ly hoàn toàn; trong đó chủ tenant tạo agent, nạp tri thức từ tài liệu, chạy thử hội thoại, phát hành agent lên web widget cho khách truy cập chat trực tiếp, và có thể rollback về phiên bản trước khi cần. Toàn bộ thao tác quan trọng đều được phân quyền và ghi audit.

---

## 1. Mục tiêu

- **MT-001**: Một tenant mới có thể đi hết hành trình "khởi tạo → tạo agent → nạp tri thức → chạy thử → phát hành" mà không cần can thiệp kỹ thuật thủ công vào hệ thống.
- **MT-002**: Khách truy cập website của tenant chat được với agent đã phát hành và nhận câu trả lời dựa trên tri thức riêng của tenant đó.
- **MT-003**: Dữ liệu (tri thức, hội thoại, cấu hình) của tenant này không bao giờ xuất hiện trong câu trả lời hoặc màn hình quản trị của tenant khác.
- **MT-004**: Mọi thao tác phát hành, rollback, thay đổi cấu hình agent và tri thức đều truy vết được: ai làm, làm gì, khi nào.

---

## 2. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Khởi tạo tenant mới với vùng dữ liệu riêng (tenant provisioning) và đăng ký tenant vào danh bạ trung tâm.
- **MVP-002**: Agent Studio: tạo/sửa agent ở trạng thái nháp — tên, persona, hướng dẫn trả lời, lời chào.
- **MVP-003**: Nạp tri thức: upload tài liệu (PDF, DOCX, TXT) làm nguồn tri thức cho agent; xem danh sách, xóa nguồn tri thức.
- **MVP-004**: Chạy thử (test chat): hội thoại thử với agent nháp dùng tri thức đã nạp, trước khi phát hành.
- **MVP-005**: Phát hành agent lên web widget nhúng vào website của tenant; khách truy cập chat realtime với câu trả lời hiển thị dần (streaming).
- **MVP-006**: Quản lý phiên bản: mỗi lần phát hành tạo một phiên bản bất biến; rollback về phiên bản đã phát hành trước đó.
- **MVP-007**: RBAC cơ bản trong tenant: phân biệt quyền giữa chủ tenant, người biên tập và người chỉ xem.
- **MVP-008**: Audit: ghi nhận bất biến các thao tác phát hành, rollback, thay đổi cấu hình agent, upload/xóa tri thức.
- **MVP-009**: Usage cơ bản: đếm số hội thoại và mức tiêu thụ theo tenant để theo dõi.
- **MVP-010**: Giới hạn MVP: chỉ một kênh phát hành là web widget; không có Zalo/Facebook, không có tool/workflow nghiệp vụ, không có hóa đơn/thanh toán.

---

## 3. Người dùng & Bối cảnh

**Người dùng chính**:

- **Quản trị viên nền tảng**: vận hành nền tảng, khởi tạo tenant, theo dõi sức khỏe hệ thống.
- **Chủ tenant**: chủ doanh nghiệp/người được ủy quyền — tạo agent, nạp tri thức, phát hành, quản lý thành viên.
- **Thành viên tenant**: người biên tập nội dung agent/tri thức hoặc người chỉ xem, theo vai trò được cấp.
- **Khách truy cập**: khách trên website của tenant, chat với agent qua web widget, không cần tài khoản.

**Bối cảnh sử dụng**: Chủ tenant làm việc trên ứng dụng quản trị web để xây dựng và phát hành agent. Khách truy cập dùng widget chat trên website của tenant vào bất kỳ lúc nào.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Chủ tenant và thành viên là người dùng nghiệp vụ, không chuyên kỹ thuật. Khách truy cập là người dùng phổ thông. Quản trị viên nền tảng là kỹ thuật.

---

## 4. Kịch bản người dùng *(bắt buộc)*

### US-001 — Khởi tạo tenant mới (Ưu tiên: P1)

Quản trị viên nền tảng tạo một tenant mới cho doanh nghiệp đăng ký sử dụng. Hệ thống tạo vùng dữ liệu riêng cho tenant, đăng ký tenant vào danh bạ trung tâm và tạo tài khoản chủ tenant đầu tiên. Sau đó chủ tenant đăng nhập được vào không gian làm việc của mình.

**Lý do ưu tiên**: Mọi kịch bản khác đều cần tenant tồn tại trước; đây là nền móng của mô hình đa tenant.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003

**Test độc lập**: Tạo tenant mới, xác nhận chủ tenant đăng nhập được vào không gian làm việc trống của riêng mình và không thấy dữ liệu của tenant khác.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** một yêu cầu tạo tenant hợp lệ, **Khi** quản trị viên nền tảng khởi tạo tenant, **Thì** tenant có vùng dữ liệu riêng, xuất hiện trong danh bạ tenant với trạng thái hoạt động, và chủ tenant nhận được quyền truy cập.
2. **AC-002**: **Cho trước** một tenant đã tồn tại, **Khi** khởi tạo lại với cùng định danh, **Thì** hệ thống từ chối và báo tenant đã tồn tại, không tạo trùng vùng dữ liệu.
3. **AC-003**: **Cho trước** quá trình khởi tạo bị lỗi giữa chừng, **Khi** hệ thống ghi nhận lỗi, **Thì** không để lại vùng dữ liệu mồ côi và tenant được đánh dấu trạng thái lỗi để xử lý lại.

---

### US-002 — Tạo và cấu hình agent (Ưu tiên: P1)

Chủ tenant (hoặc người biên tập) vào Agent Studio tạo một agent mới: đặt tên, mô tả persona, viết hướng dẫn trả lời và lời chào. Agent ở trạng thái nháp, có thể sửa nhiều lần trước khi phát hành.

**Lý do ưu tiên**: Agent là sản phẩm trung tâm; không có agent thì không có gì để nạp tri thức hay phát hành.

**Liên quan yêu cầu**: FR-004, FR-005

**Test độc lập**: Tạo agent nháp trong một tenant, sửa cấu hình, xác nhận thay đổi được lưu và agent chỉ hiển thị trong tenant đó.

**Acceptance Criteria**:

1. **AC-004**: **Cho trước** chủ tenant đã đăng nhập, **Khi** tạo agent mới với tên và hướng dẫn trả lời, **Thì** agent xuất hiện trong danh sách agent của tenant ở trạng thái nháp.
2. **AC-005**: **Cho trước** một agent nháp, **Khi** sửa persona/hướng dẫn và lưu, **Thì** nội dung mới được giữ lại và hiển thị đúng khi mở lại.

---

### US-003 — Nạp tri thức cho agent (Ưu tiên: P1)

Người biên tập upload tài liệu của doanh nghiệp (bảng giá, chính sách, giới thiệu sản phẩm…) làm nguồn tri thức cho agent. Hệ thống xử lý tài liệu ở nền; người dùng thấy trạng thái xử lý (đang xử lý / sẵn sàng / lỗi) và có thể xóa nguồn tri thức không còn dùng.

**Lý do ưu tiên**: Giá trị cốt lõi của agent là trả lời theo tri thức riêng của doanh nghiệp, không phải kiến thức chung.

**Liên quan yêu cầu**: FR-006, FR-007, FR-008

**Test độc lập**: Upload một tài liệu, chờ trạng thái sẵn sàng, chạy thử hỏi nội dung trong tài liệu và nhận câu trả lời dựa trên tài liệu đó.

**Acceptance Criteria**:

1. **AC-006**: **Cho trước** một agent nháp, **Khi** upload tài liệu định dạng được hỗ trợ, **Thì** tài liệu xuất hiện trong danh sách nguồn tri thức với trạng thái "đang xử lý" rồi chuyển sang "sẵn sàng".
2. **AC-007**: **Cho trước** tài liệu định dạng không hỗ trợ hoặc vượt giới hạn dung lượng, **Khi** upload, **Thì** hệ thống từ chối với thông báo lý do rõ ràng.
3. **AC-008**: **Cho trước** một nguồn tri thức đã sẵn sàng, **Khi** người biên tập xóa nguồn đó, **Thì** agent không còn dùng nội dung của nguồn đó để trả lời nữa.

---

### US-004 — Chạy thử agent (Ưu tiên: P1)

Trước khi phát hành, người biên tập mở màn hình chạy thử, chat với agent nháp như một khách hàng. Câu trả lời dùng đúng cấu hình nháp và tri thức đã nạp, giúp đánh giá chất lượng trước khi công bố.

**Lý do ưu tiên**: Đúng luồng nghiệp vụ "huấn luyện → chạy thử → phát hành"; tránh phát hành agent trả lời sai cho khách thật.

**Liên quan yêu cầu**: FR-009, FR-010

**Test độc lập**: Mở test chat với agent nháp, gửi câu hỏi thuộc tri thức đã nạp và câu hỏi ngoài tri thức, đối chiếu hành vi trả lời.

**Acceptance Criteria**:

1. **AC-009**: **Cho trước** agent nháp có tri thức sẵn sàng, **Khi** người biên tập gửi câu hỏi trong phạm vi tri thức, **Thì** agent trả lời dựa trên tri thức của chính tenant đó.
2. **AC-010**: **Cho trước** phiên chạy thử, **Khi** hội thoại diễn ra, **Thì** hội thoại thử không xuất hiện lẫn vào hội thoại của khách thật.

---

### US-005 — Phát hành agent lên web widget (Ưu tiên: P1)

Chủ tenant bấm "Phát hành". Hệ thống tạo một phiên bản bất biến của agent và cung cấp đoạn mã nhúng widget. Tenant gắn widget vào website của mình; khách truy cập chat với agent và thấy câu trả lời hiển thị dần theo thời gian thực.

**Lý do ưu tiên**: Đây là điểm tạo giá trị cuối cùng của toàn bộ hành trình — agent phục vụ khách thật.

**Liên quan yêu cầu**: FR-011, FR-012, FR-013, FR-014

**Test độc lập**: Phát hành agent, nhúng widget vào một trang web thử, chat từ vai khách truy cập và nhận câu trả lời đúng tri thức tenant.

**Acceptance Criteria**:

1. **AC-011**: **Cho trước** agent nháp đạt yêu cầu, **Khi** chủ tenant phát hành, **Thì** hệ thống tạo phiên bản mới, ở trạng thái riêng tư mặc định (chỉ tenant sở hữu dùng được) và cung cấp mã nhúng widget.
2. **AC-012**: **Cho trước** widget đã nhúng, **Khi** khách truy cập gửi tin nhắn, **Thì** khách nhận phản hồi hiển thị dần, dựa trên đúng phiên bản đã phát hành (không phải bản nháp đang sửa dở).
3. **AC-013**: **Cho trước** agent đã phát hành và bản nháp đang được sửa tiếp, **Khi** khách chat qua widget, **Thì** thay đổi ở bản nháp không ảnh hưởng câu trả lời cho khách cho tới lần phát hành kế tiếp.

---

### US-006 — Quản lý phiên bản và rollback (Ưu tiên: P2)

Sau khi phát hành phiên bản mới, chủ tenant phát hiện agent trả lời kém hơn trước. Chủ tenant xem danh sách phiên bản đã phát hành và rollback về phiên bản trước; khách truy cập ngay lập tức được phục vụ bởi phiên bản cũ ổn định.

**Lý do ưu tiên**: An toàn vận hành khi phát hành hỏng; là yêu cầu bắt buộc của tài liệu kiến trúc nhưng chỉ có giá trị sau khi luồng phát hành (P1) hoạt động.

**Liên quan yêu cầu**: FR-015, FR-016

**Test độc lập**: Phát hành 2 phiên bản có nội dung trả lời khác nhau, rollback về phiên bản 1, xác nhận widget trả lời theo phiên bản 1.

**Acceptance Criteria**:

1. **AC-014**: **Cho trước** agent có từ 2 phiên bản phát hành trở lên, **Khi** chủ tenant rollback về phiên bản trước, **Thì** khách truy cập được phục vụ bởi phiên bản đó mà không cần thao tác gì thêm phía website tenant.
2. **AC-015**: **Cho trước** thao tác rollback, **Khi** hoàn tất, **Thì** hệ thống ghi audit ai rollback, từ phiên bản nào về phiên bản nào, vào lúc nào.

---

### US-007 — Phân quyền thành viên trong tenant (Ưu tiên: P2)

Chủ tenant mời thành viên vào không gian làm việc và gán vai trò: người biên tập (tạo/sửa agent và tri thức) hoặc người xem (chỉ xem). Chỉ chủ tenant được phát hành, rollback và quản lý thành viên.

**Lý do ưu tiên**: Cần thiết khi tenant có nhiều người dùng; không chặn giá trị của luồng P1 (một người dùng duy nhất).

**Liên quan yêu cầu**: FR-017, FR-018

**Test độc lập**: Tạo thành viên vai trò người xem, xác nhận không sửa được agent và không thấy nút phát hành; thành viên biên tập sửa được nhưng không phát hành được.

**Acceptance Criteria**:

1. **AC-016**: **Cho trước** thành viên vai trò người xem, **Khi** cố sửa agent hoặc tri thức, **Thì** hệ thống từ chối và giải thích không đủ quyền.
2. **AC-017**: **Cho trước** thành viên vai trò biên tập, **Khi** cố phát hành hoặc rollback, **Thì** hệ thống từ chối; chỉ chủ tenant thực hiện được.

---

### US-008 — Theo dõi mức sử dụng (Ưu tiên: P3)

Chủ tenant xem thống kê cơ bản: số hội thoại, số tin nhắn và mức tiêu thụ theo thời gian, để nắm được agent được dùng nhiều hay ít. Quản trị viên nền tảng xem được mức sử dụng của từng tenant.

**Lý do ưu tiên**: Cần cho vận hành và chuẩn bị tính phí sau này, nhưng không chặn giá trị của các luồng trên.

**Liên quan yêu cầu**: FR-019

**Test độc lập**: Thực hiện một số hội thoại qua widget, mở màn hình usage, đối chiếu số liệu tăng đúng.

**Acceptance Criteria**:

1. **AC-018**: **Cho trước** các hội thoại đã diễn ra qua widget, **Khi** chủ tenant xem usage, **Thì** số hội thoại và tin nhắn phản ánh đúng hoạt động của chính tenant mình, không lẫn tenant khác.

---

## 5. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Tenant mới chưa có agent → hiển thị trạng thái trống với hướng dẫn tạo agent đầu tiên. Agent chưa có tri thức → chạy thử vẫn được nhưng có cảnh báo agent chưa được nạp tri thức.
- **Dữ liệu không hợp lệ**: Tài liệu sai định dạng/quá dung lượng bị từ chối kèm lý do. Tên agent trống hoặc trùng trong cùng tenant bị từ chối khi lưu.
- **Không có quyền**: Thao tác ngoài vai trò được cấp bị từ chối với thông báo không đủ quyền; không lộ dữ liệu ngoài phạm vi.
- **Lỗi hệ thống**: Nếu dịch vụ trả lời AI gặp sự cố, khách truy cập nhận thông báo lịch sự rằng agent tạm thời không phản hồi được; hội thoại không bị mất.
- **Timeout**: Câu trả lời quá thời gian chờ → hiển thị thông báo thử lại; hệ thống không tính đó là câu trả lời hoàn chỉnh trong usage.
- **Dữ liệu bị thay đổi bởi người khác**: Hai người biên tập cùng sửa một agent nháp → người lưu sau được cảnh báo nội dung đã thay đổi để tránh ghi đè âm thầm.
- **Người dùng thao tác lặp lại**: Bấm phát hành nhiều lần liên tiếp không tạo nhiều phiên bản trùng lặp cho cùng một nội dung nháp chưa đổi. Khởi tạo lại tenant đã tồn tại bị từ chối (AC-002). Upload lại cùng tài liệu tạo bản ghi nguồn tri thức mới thay thế theo lựa chọn của người dùng.
- **Trường hợp biên khác**: Xử lý tài liệu thất bại ở nền → nguồn tri thức đánh dấu trạng thái lỗi kèm lý do, người dùng có thể xóa hoặc thử lại; agent bị xóa nguồn tri thức duy nhất vẫn trả lời được ở mức lời chào/hướng dẫn chung.

---

## 6. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI cho phép quản trị viên nền tảng khởi tạo tenant mới với vùng dữ liệu riêng và ghi vào danh bạ tenant trung tâm.
  **Liên quan**: US-001, AC-001
- **FR-002** `[P1]`: Hệ thống KHÔNG ĐƯỢC tạo trùng tenant với cùng định danh; khởi tạo lỗi giữa chừng PHẢI không để lại vùng dữ liệu mồ côi.
  **Liên quan**: US-001, AC-002, AC-003
- **FR-003** `[P1]`: Hệ thống PHẢI tạo tài khoản chủ tenant đầu tiên khi khởi tạo tenant và cho phép người này đăng nhập vào đúng không gian làm việc của tenant mình.
  **Liên quan**: US-001, AC-001
- **FR-004** `[P1]`: Người dùng có quyền biên tập PHẢI tạo được agent ở trạng thái nháp với tên, persona, hướng dẫn trả lời và lời chào.
  **Liên quan**: US-002, AC-004
- **FR-005** `[P1]`: Hệ thống PHẢI cho phép sửa agent nháp nhiều lần và lưu lại nội dung mới nhất.
  **Liên quan**: US-002, AC-005
- **FR-006** `[P1]`: Người dùng có quyền biên tập PHẢI upload được tài liệu (tối thiểu PDF, DOCX, TXT) làm nguồn tri thức cho agent, và thấy trạng thái xử lý của từng nguồn.
  **Liên quan**: US-003, AC-006
- **FR-007** `[P1]`: Hệ thống PHẢI từ chối tài liệu sai định dạng hoặc vượt giới hạn dung lượng với thông báo lý do.
  **Liên quan**: US-003, AC-007
- **FR-008** `[P1]`: Người dùng có quyền biên tập PHẢI xóa được nguồn tri thức; sau khi xóa, agent KHÔNG ĐƯỢC tiếp tục trả lời dựa trên nguồn đó.
  **Liên quan**: US-003, AC-008
- **FR-009** `[P1]`: Người dùng có quyền biên tập PHẢI chạy thử hội thoại với agent nháp, dùng đúng cấu hình nháp và tri thức đã sẵn sàng.
  **Liên quan**: US-004, AC-009
- **FR-010** `[P1]`: Hệ thống PHẢI tách hội thoại chạy thử khỏi hội thoại của khách thật.
  **Liên quan**: US-004, AC-010
- **FR-011** `[P1]`: Chủ tenant PHẢI phát hành được agent; mỗi lần phát hành tạo một phiên bản bất biến, mặc định ở phạm vi riêng tư của tenant sở hữu.
  **Liên quan**: US-005, AC-011
- **FR-012** `[P1]`: Hệ thống PHẢI cung cấp mã nhúng web widget cho agent đã phát hành để tenant gắn vào website của mình.
  **Liên quan**: US-005, AC-011
- **FR-013** `[P1]`: Khách truy cập PHẢI chat được với agent qua widget không cần tài khoản, nhận câu trả lời hiển thị dần theo thời gian thực.
  **Liên quan**: US-005, AC-012
- **FR-014** `[P1]`: Câu trả lời cho khách PHẢI dựa trên phiên bản đã phát hành; thay đổi bản nháp KHÔNG ĐƯỢC ảnh hưởng khách cho tới lần phát hành kế tiếp.
  **Liên quan**: US-005, AC-013
- **FR-015** `[P2]`: Chủ tenant PHẢI xem được danh sách phiên bản đã phát hành và rollback về một phiên bản trước đó.
  **Liên quan**: US-006, AC-014
- **FR-016** `[P2]`: Rollback PHẢI có hiệu lực với khách truy cập mà tenant không phải sửa lại mã nhúng widget.
  **Liên quan**: US-006, AC-014
- **FR-017** `[P2]`: Chủ tenant PHẢI quản lý được thành viên và gán vai trò (chủ tenant, biên tập, xem) trong tenant của mình.
  **Liên quan**: US-007, AC-016, AC-017
- **FR-018** `[P2]`: Hệ thống PHẢI chặn thao tác vượt vai trò: người xem không sửa được, người biên tập không phát hành/rollback được.
  **Liên quan**: US-007, AC-016, AC-017
- **FR-019** `[P3]`: Hệ thống PHẢI thống kê số hội thoại, số tin nhắn và mức tiêu thụ theo tenant; chủ tenant chỉ xem được số liệu của tenant mình.
  **Liên quan**: US-008, AC-018
- **FR-020** `[P1]`: Hệ thống KHÔNG ĐƯỢC dùng tri thức, cấu hình hoặc hội thoại của tenant khác trong bất kỳ câu trả lời hoặc màn hình nào của một tenant.
  **Liên quan**: US-003, US-004, US-005, AC-009, AC-012
- **FR-021** `[P1]`: Hệ thống PHẢI ghi audit bất biến cho các thao tác: phát hành, rollback, thay đổi cấu hình agent, upload/xóa tri thức, thay đổi vai trò thành viên.
  **Liên quan**: US-005, US-006, US-007, AC-015

---

## 7. Quy tắc nghiệp vụ

- **BR-001**: Agent phát hành mặc định là riêng tư — chỉ tenant sở hữu sử dụng được; MVP không có chia sẻ agent giữa các tenant.
- **BR-002**: Phiên bản đã phát hành là bất biến: không sửa nội dung phiên bản, chỉ tạo phiên bản mới hoặc rollback.
- **BR-003**: Chỉ chủ tenant được phát hành, rollback và quản lý thành viên; người biên tập chỉ thao tác trên bản nháp và tri thức.
- **BR-004**: Danh tính tenant của mỗi yêu cầu do hệ thống xác định từ phiên đăng nhập hoặc nguồn phát hành widget; KHÔNG ĐƯỢC tin định danh tenant do phía client tự khai.
- **BR-005**: Tri thức chỉ phục vụ agent trong cùng tenant sở hữu; xóa nguồn tri thức có hiệu lực với mọi câu trả lời sau đó.
- **BR-006**: Bản ghi audit không được sửa hoặc xóa bởi bất kỳ người dùng nào, kể cả chủ tenant.

**Luồng trạng thái nếu có**:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| (chưa có) | Tạo agent | Nháp | Người dùng có quyền biên tập |
| Nháp | Phát hành | Đã phát hành (phiên bản N) | Chỉ chủ tenant |
| Đã phát hành (N) | Sửa tiếp bản nháp | Nháp mới trên nền N | Không ảnh hưởng khách |
| Đã phát hành (N) | Phát hành lại | Đã phát hành (N+1) | Chỉ chủ tenant |
| Đã phát hành (N+1) | Rollback | Phục vụ bằng phiên bản N | Chỉ chủ tenant, ghi audit |
| Đã phát hành | Gỡ phát hành | Ngừng phục vụ khách | Chỉ chủ tenant, widget báo agent tạm ngưng |

---

## 8. Thực thể dữ liệu

- **Tenant**: Doanh nghiệp sử dụng nền tảng; có định danh duy nhất, trạng thái hoạt động, vùng dữ liệu riêng và gói/hạn mức sử dụng.
- **Thành viên & vai trò**: Người dùng thuộc một tenant với vai trò chủ tenant / biên tập / xem; quyết định quyền thao tác.
- **Agent**: Nhân viên AI của tenant; có tên, persona, hướng dẫn trả lời, lời chào; luôn thuộc đúng một tenant.
- **Phiên bản agent**: Bản chụp bất biến của agent tại thời điểm phát hành; có số phiên bản, trạng thái phục vụ và phạm vi hiển thị (mặc định riêng tư).
- **Nguồn tri thức**: Tài liệu được nạp cho agent; có trạng thái xử lý (đang xử lý / sẵn sàng / lỗi) và thuộc đúng một tenant.
- **Hội thoại**: Phiên chat giữa một khách truy cập (hoặc người chạy thử) và một agent; gồm các tin nhắn hai chiều, có đánh dấu là hội thoại thử hay thật.
- **Bản ghi audit**: Sự kiện bất biến ghi ai làm gì, khi nào, trên đối tượng nào.
- **Chỉ số sử dụng**: Số hội thoại, tin nhắn và mức tiêu thụ tổng hợp theo tenant và theo thời gian.

---

## 9. Phân quyền & Bảo mật

**Ai được xem**:
- Chủ tenant, người biên tập, người xem: dữ liệu thuộc tenant của mình (agent, tri thức, hội thoại, usage).
- Quản trị viên nền tảng: danh bạ tenant, trạng thái provisioning, usage tổng hợp theo tenant.

**Ai được thao tác**:
- Chủ tenant: mọi thao tác trong tenant, gồm phát hành, rollback, quản lý thành viên.
- Người biên tập: tạo/sửa agent nháp, upload/xóa tri thức, chạy thử.
- Quản trị viên nền tảng: khởi tạo/tạm ngưng tenant.
- Khách truy cập: chỉ chat qua widget với agent đã phát hành.

**Ai không được phép**:
- Mọi người dùng của tenant A: xem hoặc thao tác trên bất kỳ dữ liệu nào của tenant B.
- Người xem: mọi thao tác thay đổi dữ liệu.
- Khách truy cập: mọi truy cập ngoài hội thoại của chính mình.

**Dữ liệu nhạy cảm**:
- Có. Tri thức nội bộ doanh nghiệp (bảng giá, chính sách…), nội dung hội thoại với khách, thông tin thành viên. Các khóa/bí mật tích hợp không được hiển thị cho người dùng và không nằm trong dữ liệu tenant thông thường.

- **SEC-001**: Hệ thống PHẢI kiểm tra quyền theo vai trò và theo tenant trước khi cho phép mọi thao tác.
- **SEC-002**: Hệ thống KHÔNG ĐƯỢC cho người dùng truy cập dữ liệu ngoài tenant của mình trong mọi luồng, kể cả luồng trả lời của agent (tri thức dùng để trả lời phải thuộc đúng tenant).
- **SEC-003**: Hệ thống KHÔNG ĐƯỢC để nội dung tri thức tự thay đổi quy tắc trả lời hoặc quyền của agent (chống prompt injection từ tài liệu được nạp).
- **SEC-004**: Widget công khai PHẢI có giới hạn tần suất sử dụng để chống lạm dụng từ khách vãng lai.

---

## 10. Audit & Lịch sử thay đổi

**Có cần audit không**: Có

Hệ thống PHẢI ghi nhận (bất biến, không sửa/xóa được):

- Ai thực hiện (người dùng, vai trò, tenant)
- Thao tác gì: phát hành, rollback, gỡ phát hành, tạo/sửa agent, upload/xóa tri thức, thay đổi vai trò thành viên, khởi tạo/tạm ngưng tenant
- Thời điểm thực hiện
- Đối tượng và phiên bản liên quan (ví dụ rollback từ phiên bản nào về phiên bản nào)
- Kết quả (thành công/thất bại) đối với thao tác provisioning

Nội dung audit KHÔNG ĐƯỢC chứa bí mật (mật khẩu, khóa truy cập).

---

## 11. Yêu cầu phi chức năng

- **NFR-001**: Khách truy cập thấy phần phản hồi đầu tiên của agent trong vòng 5 giây ở điều kiện tải thông thường; phần còn lại hiển thị dần.
- **NFR-002**: Cách ly dữ liệu tenant là tuyệt đối: không có kịch bản nghiệp vụ nào cho phép đọc chéo dữ liệu giữa tenant trong MVP.
- **NFR-003**: MVP PHẢI vận hành được trên hạ tầng hiện có của môi trường phát triển Flex mà không làm gián đoạn các dịch vụ đang chạy.
- **NFR-004**: Hệ thống phục vụ tối thiểu 20 hội thoại đồng thời qua widget trong MVP mà không suy giảm trải nghiệm rõ rệt.
- **NFR-005**: Tài liệu tri thức thông thường (≤ 10 MB) sẵn sàng phục vụ trả lời trong vòng 10 phút kể từ khi upload.

---

## 12. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: Một chủ tenant mới hoàn thành hành trình "tạo agent → nạp tri thức → chạy thử → phát hành" trong dưới 30 phút mà không cần hỗ trợ kỹ thuật.
- **SC-002**: Khách truy cập nhận được phần trả lời đầu tiên trong dưới 5 giây ở 95% lượt hỏi trong điều kiện tải thông thường.
- **SC-003**: 100% bài kiểm tra cách ly xuyên tenant (hỏi agent tenant A về tri thức tenant B, truy cập chéo màn hình quản trị) đều bị chặn hoặc không lộ dữ liệu.
- **SC-004**: Rollback có hiệu lực với khách truy cập trong dưới 1 phút kể từ khi chủ tenant xác nhận.
- **SC-005**: 100% thao tác phát hành, rollback, thay đổi cấu hình agent, upload/xóa tri thức và thay đổi vai trò có bản ghi audit đối chiếu được.
- **SC-006**: Tenant mới sẵn sàng làm việc trong dưới 10 phút kể từ khi quản trị viên nền tảng khởi tạo.

---

## 13. Giả định & Ràng buộc

**Giả định**:
- Ở MVP, quản trị viên nền tảng và chủ tenant có thể là cùng một người (dự án vận hành bởi một người); mô hình vai trò vẫn tách bạch để mở rộng sau.
- Kênh phát hành duy nhất của MVP là web widget; khách truy cập dùng trình duyệt hiện đại có kết nối internet ổn định.
- Ngôn ngữ hội thoại chính là tiếng Việt.
- Nền tảng dùng dịch vụ mô hình AI bên ngoài để sinh câu trả lời; chất lượng câu trả lời phụ thuộc một phần vào dịch vụ này.
- Hạ tầng dữ liệu nền (vùng dữ liệu riêng cho tenant và danh bạ tenant trung tâm) đã có sẵn từ tính năng `000005-mysql-tenant-db` và được tái sử dụng.

**Ràng buộc**:
- PHẢI tuân theo mô hình chia miền dữ liệu của tài liệu kiến trúc: dữ liệu vận hành riêng theo tenant; danh bạ và bản phát hành ở vùng dùng chung có gắn định danh tenant; file gốc ở kho lưu trữ đối tượng.
- Code sản phẩm PHẢI nằm trong các repo con của workspace (theo nguyên tắc I của constitution); workstation chỉ chứa spec/plan/tài liệu.
- MVP KHÔNG mở rộng sang Zalo/Facebook, tool nghiệp vụ, workflow tự động hay thanh toán — các phần này thuộc giai đoạn sau theo tài liệu kiến trúc.

---

## 14. Ngoài phạm vi

- Kênh Zalo, Facebook Messenger và mọi kênh ngoài web widget.
- Tool & workflow nghiệp vụ (tạo đơn, gửi mail, tra cứu CRM/ERP…).
- Chợ agent mẫu / chia sẻ agent giữa các tenant (visibility PUBLIC hoặc chia sẻ chọn lọc).
- Hóa đơn, thanh toán, gói cước tự động (MVP chỉ đếm usage).
- Handoff hội thoại sang nhân viên thật.
- Đánh giá tự động chất lượng câu trả lời (evaluation nâng cao trong Test Lab).
- OCR ảnh/scan phức tạp; MVP chỉ xử lý tài liệu văn bản thông dụng.
- Ứng dụng di động cho quản trị.

---

## 15. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Rò rỉ dữ liệu xuyên tenant qua luồng trả lời của agent | Trung | Cao | Kiểm thử cách ly là điều kiện chấp nhận bắt buộc (SC-003); mọi luồng trả lời chỉ dùng tri thức đúng tenant (FR-020, SEC-002) |
| Chất lượng câu trả lời từ tri thức chưa đạt kỳ vọng người dùng | Cao | Trung | Luồng chạy thử trước phát hành (US-004); rollback nhanh (US-006) |
| Tri thức chứa nội dung điều khiển làm agent vượt quyền (prompt injection) | Trung | Cao | SEC-003 là yêu cầu bắt buộc; kiểm thử với tài liệu chứa chỉ thị độc hại |
| Chi phí dịch vụ mô hình AI vượt dự kiến khi mở widget công khai | Trung | Trung | Giới hạn tần suất widget (SEC-004) và theo dõi usage theo tenant (FR-019) |
| Phạm vi MVP phình to (thêm kênh, thêm tool) | Cao | Trung | Mục 14 chốt ngoài phạm vi; mọi mở rộng phải qua spec mới |

---

## 16. Phụ thuộc

- Hạ tầng vùng dữ liệu riêng theo tenant và danh bạ tenant từ tính năng `000005-mysql-tenant-db` (đã hoàn thành và kiểm chứng thành công trên môi trường chạy thật — xác nhận bởi stakeholder ngày 2026-07-12).
- Dịch vụ mô hình AI bên ngoài (nhà cung cấp LLM) để sinh câu trả lời — cần tài khoản/khóa truy cập hợp lệ khi triển khai.
- Môi trường hạ tầng phát triển hiện có của workspace Flex (`flex-environment`) đang hoạt động.

---

## 17. Câu hỏi mở

Không còn câu hỏi mở chặn plan kỹ thuật. Các điểm chưa chắc chắn đã được chốt bằng giả định tại mục 13 (một người vận hành ở MVP, kênh duy nhất là web widget, tiếng Việt là ngôn ngữ chính, tái sử dụng hạ tầng 000005); nếu giả định thay đổi, spec này PHẢI được cập nhật trước khi tiếp tục.

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
