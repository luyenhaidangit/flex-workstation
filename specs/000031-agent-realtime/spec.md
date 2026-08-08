# Đặc tả tính năng: Demo realtime cho Agent Service

**Branch**: `000031-agent-realtime`  
**Ngày tạo**: 2026-08-08  
**Trạng thái**: Bản nháp  
**Người phụ trách**: Luyện Hải Đăng  
**Stakeholder xác nhận**: Luyện Hải Đăng  
**Đầu vào**: Dựng một demo realtime tối thiểu để kiểm chứng việc FE gửi tin nhắn cho Agent Service, BE nhận và ghi log, đồng thời BE có thao tác test phát thông báo để FE nhận và hiển thị cảnh báo.

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

Chưa có luồng kiểm chứng đơn giản cho khả năng giao tiếp hai chiều realtime giữa màn hình chat Agent và Agent Service. Vì vậy, nhóm khó xác nhận FE gửi được dữ liệu đến BE, BE quan sát được dữ liệu qua log, và BE có thể chủ động đẩy thông báo ngược lại FE.

**Tổng quan tính năng**:

Tạo một demo dành cho người dùng nội bộ để chat thử với Agent Service qua kênh realtime. Tin nhắn người dùng gửi phải được BE nhận và ghi log; một thao tác test từ BE phải phát thông báo để FE nhận và hiển thị bằng cảnh báo trên màn hình. Demo không nhằm hoàn thiện chat production hay lưu lịch sử hội thoại.

---

## 2. Mục tiêu

- **MT-001**: Kiểm chứng người dùng có thể gửi một tin nhắn từ màn hình chat và nhận được xác nhận dữ liệu đã tới Agent Service.
- **MT-002**: Cho phép developer quan sát nội dung tin nhắn nhận được từ BE qua log trong quá trình chạy demo.
- **MT-003**: Kiểm chứng BE có thể chủ động phát một thông báo realtime và người dùng nhìn thấy ngay trên FE.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Kết nối màn hình chat Agent hiện có với Agent Service qua một kênh realtime cho phiên demo.
- **MVP-002**: Khi người dùng gửi tin nhắn, Agent Service nhận được nội dung và ghi log để kiểm tra.
- **MVP-003**: Cung cấp một thao tác test từ Agent Service để phát thông báo realtime; FE nhận thông báo và hiển thị `alert`.
- **MVP-004**: Có hướng dẫn ngắn để chạy hai phía và kiểm tra hai luồng trên môi trường local.

---

## 4. Người dùng & Bối cảnh

**Người dùng chính**: Developer hoặc người kiểm thử nội bộ.

**Bối cảnh sử dụng**: Khi cần xác minh nhanh kết nối realtime giữa màn hình chat Agent và Agent Service trong môi trường local.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Kỹ thuật.

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Gửi tin nhắn và quan sát BE nhận được (Ưu tiên: P1)

Là người kiểm thử, tôi muốn nhập và gửi một tin nhắn trên màn hình chat để xác nhận Agent Service nhận được nội dung và ghi log.

**Lý do ưu tiên**: Đây là luồng nền tảng để xác minh chiều FE → BE.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003

**Test độc lập**: Mở màn hình chat, gửi chuỗi nhận diện được, sau đó kiểm tra log của Agent Service có cùng nội dung và thông tin thời điểm nhận.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** màn hình chat đã kết nối, **Khi** người dùng gửi một tin nhắn không rỗng, **Thì** Agent Service nhận được tin nhắn trong cùng phiên demo.
2. **AC-002**: **Cho trước** Agent Service nhận được tin nhắn, **Thì** log hiển thị nội dung và thời điểm nhận mà không làm lộ thông tin nhạy cảm ngoài phạm vi demo.
3. **AC-003**: **Khi** gửi tin nhắn thất bại hoặc chưa kết nối, **Thì** FE hiển thị trạng thái lỗi phù hợp và người dùng biết cần thử lại.

### US-002 — Nhận thông báo chủ động từ BE (Ưu tiên: P1)

Là người kiểm thử, tôi muốn kích hoạt thao tác test trên Agent Service để xác nhận FE nhận được thông báo và hiển thị cảnh báo.

**Lý do ưu tiên**: Đây là bằng chứng cho chiều BE → FE.

**Liên quan yêu cầu**: FR-004, FR-005

**Test độc lập**: Khi FE đang mở và đã kết nối, gọi thao tác test của Agent Service; xác nhận trình duyệt hiển thị `alert` với nội dung thông báo được phát.

**Acceptance Criteria**:

1. **AC-004**: **Cho trước** FE đang kết nối, **Khi** thao tác test từ Agent Service được gọi, **Thì** FE nhận được một thông báo realtime.
2. **AC-005**: **Khi** FE nhận được thông báo test, **Thì** trình duyệt hiển thị `alert` chứa đúng nội dung thông báo.
3. **AC-006**: **Khi** chưa có FE kết nối, **Thì** thao tác test trả về kết quả cho biết không có phiên nhận đang hoạt động và không làm hỏng Agent Service.

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Tin nhắn rỗng không được gửi.
- **Dữ liệu không hợp lệ**: FE yêu cầu người dùng nhập nội dung trước khi gửi.
- **Không có quyền**: Chỉ người dùng nội bộ có quyền truy cập môi trường demo được sử dụng luồng này.
- **Lỗi hệ thống**: FE hiển thị lỗi kết nối; BE ghi log lỗi đủ để chẩn đoán.
- **Timeout**: FE thể hiện trạng thái chưa kết nối hoặc gửi thất bại để người dùng thử lại.
- **Dữ liệu bị thay đổi bởi người khác**: Không áp dụng; demo không có dữ liệu dùng chung cần đồng bộ.
- **Người dùng thao tác lặp lại**: Mỗi lần gửi tạo một sự kiện riêng; thao tác test lặp lại không được làm ứng dụng lỗi.
- **Trường hợp biên khác**: Khi reload hoặc mất kết nối, FE phải có thể kết nối lại khi phiên demo được mở lại.

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: FE PHẢI cho phép người dùng gửi một tin nhắn không rỗng trong phiên demo realtime.  
  **Liên quan**: US-001, AC-001
- **FR-002** `[P1]`: Agent Service PHẢI nhận được nội dung tin nhắn từ FE trong cùng phiên demo.  
  **Liên quan**: US-001, AC-001
- **FR-003** `[P1]`: Agent Service PHẢI ghi log nội dung tin nhắn và thời điểm nhận để developer kiểm tra.  
  **Liên quan**: US-001, AC-002
- **FR-004** `[P1]`: Agent Service PHẢI cung cấp một thao tác test để phát một thông báo đến các phiên FE đang kết nối.  
  **Liên quan**: US-002, AC-004, AC-006
- **FR-005** `[P1]`: FE PHẢI hiển thị `alert` khi nhận thông báo test từ Agent Service.  
  **Liên quan**: US-002, AC-005
- **FR-006** `[P2]`: Hệ thống PHẢI thể hiện trạng thái kết nối hoặc lỗi đủ để người kiểm thử biết luồng nào chưa hoạt động.

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Chỉ tin nhắn có nội dung sau khi loại bỏ khoảng trắng đầu/cuối mới được xem là hợp lệ để gửi.
- **BR-002**: Thông báo test chỉ có ý nghĩa trong phiên demo đang hoạt động; không yêu cầu lưu hoặc phát lại khi FE kết nối sau đó.
- **BR-003**: Demo chỉ phục vụ kiểm chứng, không được coi là lịch sử hội thoại hoặc phản hồi AI hoàn chỉnh.

---

## 9. Thực thể dữ liệu

- **Tin nhắn demo**: Nội dung người dùng gửi và thời điểm Agent Service nhận; chỉ cần tồn tại trong phạm vi log của phiên chạy.
- **Thông báo realtime**: Nội dung do thao tác test phát đến phiên FE đang kết nối.

---

## 10. Phân quyền & Bảo mật

**Ai được xem**:
- Developer hoặc người kiểm thử nội bộ trong môi trường local/demo.

**Ai được thao tác**:
- Người dùng nội bộ có quyền truy cập màn hình chat và thao tác test demo.

**Ai không được phép**:
- Người dùng bên ngoài phạm vi demo hoặc phiên không được xác thực theo cơ chế hiện có.

**Dữ liệu nhạy cảm**:
- Không sử dụng dữ liệu thật; nội dung test phải là dữ liệu giả lập và log không được chứa credential, token hoặc thông tin nhạy cảm.

- **SEC-001**: Hệ thống PHẢI áp dụng cơ chế xác thực/quyền hiện có của môi trường demo trước khi cho phép kết nối hoặc gọi thao tác test.
- **SEC-002**: Hệ thống KHÔNG ĐƯỢC ghi credential, token hoặc dữ liệu nhạy cảm vào log.

---

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Không áp dụng cho demo; log kỹ thuật phục vụ kiểm chứng là đủ.

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: Trong điều kiện local bình thường, thông báo test phải xuất hiện trên FE trong vòng 2 giây sau khi thao tác test hoàn tất.
- **NFR-002**: Demo không được làm gián đoạn các luồng chat Agent hiện có ngoài phạm vi màn hình/phiên được bật để thử nghiệm.
- **NFR-003**: Developer phải có thể xác định trạng thái kết nối, sự kiện gửi và lỗi từ giao diện hoặc log mà không cần công cụ quan sát bổ sung ngoài môi trường chạy local.

---

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: 100% lần gửi tin nhắn test hợp lệ trong kịch bản smoke test xuất hiện trong log của Agent Service.
- **SC-002**: 100% lần gọi thao tác test khi có FE đang kết nối làm FE hiển thị `alert` trong tối đa 2 giây.
- **SC-003**: Developer hoàn thành kiểm chứng cả hai chiều FE → BE và BE → FE trong một phiên local với tối đa 5 bước thao tác được hướng dẫn.

---

## 14. Giả định & Ràng buộc

**Giả định**:
- Agent Service và màn hình chat hiện có thể chạy đồng thời trong môi trường local.
- Người kiểm thử dùng dữ liệu giả lập và có quyền truy cập môi trường demo.
- Không cần lưu trữ bền vững hoặc phản hồi AI thật cho MVP.

**Ràng buộc**:
- Phải tận dụng Agent Service hiện có làm backend của demo.
- Phải giữ giao diện chat và design system hiện có của FE, chỉ bổ sung phần cần thiết cho kiểm chứng realtime.

---

## 15. Ngoài phạm vi

- Lưu lịch sử hội thoại bền vững, tìm kiếm hoặc phân trang tin nhắn.
- Streaming nội dung AI, typing indicator, read receipt hoặc trạng thái online production.
- Broadcast đa tenant, phân phối nhiều phòng chat hoặc cơ chế retry/durable delivery.
- Thay đổi nghiệp vụ Agent, authentication platform hoặc schema database.

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|---|---|---|---|
| FE và BE chạy khác origin hoặc khác cấu hình local khiến kết nối thất bại | Trung bình | Cao | Ghi rõ cấu hình chạy trong plan/quickstart và có smoke test kết nối |
| Log chứa nội dung test không phù hợp | Thấp | Trung bình | Chỉ dùng dữ liệu giả lập và loại trừ credential/token khỏi log |
| `alert` là cơ chế demo thô, không phù hợp production | Cao | Thấp | Ghi rõ đây là tín hiệu kiểm chứng, loại khỏi phạm vi production |

---

## 17. Phụ thuộc

- Agent Service hiện có và màn hình chat Agent trong `flex-microfrontend`.
- Quyền truy cập môi trường local/demo và khả năng chạy đồng thời hai repo.

---

## 18. Câu hỏi mở

- Không có. Chi tiết giao thức, đường dẫn thao tác test và cấu hình chạy sẽ được quyết định trong plan kỹ thuật.

---

## Clarifications

### Session 2026-08-08

- Q: Phạm vi demo có cần lưu lịch sử hội thoại hoặc tạo phản hồi AI thật không? → A: Không; chỉ cần kiểm chứng sự kiện FE → BE/log và BE → FE/alert.
- Q: Thao tác test từ BE có cần broadcast đến nhiều người dùng không? → A: Không; chỉ cần phiên FE đang kết nối trong môi trường demo.
- Q: Có cần thay đổi database không? → A: Không; demo chỉ dùng log và sự kiện trong phiên chạy.

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
