# Đặc tả tính năng: Tích hợp chat AI tại màn Agent

**Branch**: `[000033-ai-chat-integration]`  
**Ngày tạo**: 2026-08-11  
**Trạng thái**: Bản nháp  
**Người phụ trách**: Luyện Hải Đăng  
**Stakeholder xác nhận**: Luyện Hải Đăng  
**Đầu vào**: Thay cuộc hội thoại giả lập giữa hai người tại màn Agent bằng cuộc trò chuyện thực tế giữa người dùng và AI Agent được cấu hình trên màn, để kiểm tra phản hồi của Agent.

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

Khung “Xem trước và kiểm tra” trên màn cấu hình Agent hiện hiển thị trao đổi giữa hai người, nên không phản ánh khả năng trả lời của AI Agent. Người cấu hình không thể xác minh trực tiếp Agent có phản hồi câu hỏi theo thông tin và chỉ dẫn đã thiết lập hay không, dẫn đến phải trao đổi thủ công giữa FE và BE để kiểm tra.

**Tổng quan tính năng**:

Khung xem trước sẽ cho phép người được chọn gửi câu hỏi đến AI Agent đang được cấu hình trên màn và hiển thị câu trả lời của Agent trong cùng cuộc hội thoại. Tính năng phục vụ người cấu hình Agent kiểm tra nhanh hành vi trả lời trước khi phát hành, thay vì mô phỏng chat người với người.

---

## 2. Mục tiêu

- **MT-001**: Cho phép người cấu hình nhận được phản hồi của AI Agent cho một câu hỏi ngay trên màn hiện tại.
- **MT-002**: Giúp xác minh Agent hiểu và phản hồi theo cấu hình hiện hành trước khi phát hành.
- **MT-003**: Loại bỏ nhu cầu giả lập phản hồi bằng cuộc trò chuyện giữa hai người trong khung xem trước.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Người dùng được chọn tại khung xem trước có thể nhập và gửi một câu hỏi đến AI Agent đang được cấu hình trên màn.
- **MVP-002**: Khung hội thoại hiển thị câu hỏi của người dùng, trạng thái chờ phản hồi và câu trả lời hoặc lỗi trả về từ AI Agent.
- **MVP-003**: Chỉ áp dụng cho việc xem trước/kiểm tra Agent tại màn hiện tại; không bao gồm quản lý hội thoại khách hàng đa kênh hay thay thế các màn hội thoại vận hành khác.

---

## 4. Người dùng & Bối cảnh

**Người dùng chính**: Quản trị viên hoặc nhân viên nghiệp vụ có quyền cấu hình và kiểm tra AI Agent.

**Bối cảnh sử dụng**: Người dùng đang tạo hoặc chỉnh sửa một AI Agent, đã nhập thông tin và chỉ dẫn cần thiết, và muốn thử một hoặc nhiều câu hỏi đại diện trước khi lưu/phát hành.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Người dùng nghiệp vụ và quản trị viên.

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Gửi câu hỏi để nhận trả lời từ AI Agent (Ưu tiên: P1)

Người cấu hình chọn người gửi thử nghiệm, nhập câu hỏi vào khung xem trước và gửi. Hệ thống đưa câu hỏi vào cuộc hội thoại của người dùng, sau đó hiển thị phản hồi do AI Agent đang cấu hình tạo ra.

**Lý do ưu tiên**: Đây là giá trị cốt lõi, giúp người dùng kiểm tra trực tiếp Agent thay vì xem một cuộc chat giả lập.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003, FR-004

**Test độc lập**: Với một Agent có thể sử dụng được và người gửi thử nghiệm hợp lệ, gửi một câu hỏi ngắn và kiểm tra câu hỏi cùng câu trả lời AI xuất hiện đúng vai trò trong khung hội thoại.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** người dùng có quyền kiểm tra Agent và Agent sẵn sàng trả lời, **Khi** người dùng gửi một câu hỏi không rỗng, **Thì** câu hỏi được hiển thị là tin nhắn của người dùng và hệ thống yêu cầu AI Agent trả lời.
2. **AC-002**: **Cho trước** AI Agent đang xử lý câu hỏi, **Khi** chưa có kết quả cuối cùng, **Thì** khung hội thoại thể hiện rõ trạng thái đang chờ và ngăn gửi trùng câu hỏi đó.
3. **AC-003**: **Cho trước** AI Agent trả lời thành công, **Khi** nhận được phản hồi, **Thì** phản hồi hiển thị là tin nhắn của Agent trong cùng cuộc hội thoại.
4. **AC-004**: **Cho trước** cuộc hội thoại đã có các tin nhắn, **Khi** người dùng gửi câu hỏi tiếp theo, **Thì** hệ thống tiếp tục hiển thị câu hỏi và phản hồi theo đúng thứ tự thời gian.

---

### US-002 — Nhận biết Agent chưa sẵn sàng hoặc xảy ra lỗi (Ưu tiên: P2)

Người cấu hình cố gắng gửi câu hỏi khi Agent chưa kết nối/sẵn sàng hoặc khi không thể nhận phản hồi. Hệ thống thông báo tình trạng dễ hiểu, bảo toàn các tin nhắn trước đó và cho phép người dùng thử lại khi điều kiện đã được khắc phục.

**Lý do ưu tiên**: Trạng thái trong ảnh hiện tại có thể là “Chưa kết nối Agent Service”; người dùng cần hiểu vì sao không thể kiểm tra Agent thay vì nhầm với chat người-người.

**Liên quan yêu cầu**: FR-005, FR-006, FR-007

**Test độc lập**: Đặt Agent vào trạng thái không sẵn sàng hoặc mô phỏng lỗi khi gửi câu hỏi; kiểm tra có thông báo rõ ràng, không sinh câu trả lời giả và có thể gửi lại sau đó.

**Acceptance Criteria**:

1. **AC-005**: **Cho trước** Agent chưa sẵn sàng để trả lời, **Khi** người dùng mở hoặc gửi tin nhắn trong khung xem trước, **Thì** hệ thống hiển thị lý do/trạng thái rõ ràng và không tạo phản hồi giả lập.
2. **AC-006**: **Cho trước** việc nhận phản hồi thất bại hoặc quá thời gian chờ, **Khi** hệ thống xác định lỗi, **Thì** hệ thống thông báo lỗi thân thiện, giữ nguyên lịch sử cuộc hội thoại và cho phép người dùng gửi lại.

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Khi chưa có tin nhắn, khung hội thoại hiển thị trạng thái trống hướng dẫn người dùng gửi câu hỏi đầu tiên.
- **Dữ liệu không hợp lệ**: Không gửi tin nhắn rỗng hoặc chỉ gồm khoảng trắng; hiển thị nhắc người dùng nhập câu hỏi hợp lệ.
- **Không có quyền**: Người không có quyền kiểm tra Agent không được gửi câu hỏi và nhận thông báo quyền truy cập phù hợp.
- **Lỗi hệ thống**: Hiển thị thông báo không thể nhận phản hồi từ Agent, không tạo tin nhắn trả lời giả và giữ lịch sử hiện có.
- **Timeout**: Thông báo Agent chưa phản hồi trong thời gian chờ; người dùng có thể thử gửi lại.
- **Dữ liệu bị thay đổi bởi người khác**: Không áp dụng trong phạm vi cuộc kiểm tra tức thời.
- **Người dùng thao tác lặp lại**: Trong khi một câu hỏi đang chờ phản hồi, hệ thống không gửi lặp lại cùng thao tác; sau khi hoàn tất hoặc lỗi, người dùng có thể gửi câu hỏi mới hoặc thử lại.
- **Trường hợp biên khác**: Nếu câu trả lời không có nội dung hiển thị được, hệ thống xử lý như một lỗi phản hồi và không hiển thị câu trả lời trống như phản hồi thành công.

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI thay luồng phản hồi giả lập giữa hai người trong khung xem trước bằng luồng người dùng gửi câu hỏi và AI Agent trả lời.  
  **Liên quan**: US-001, AC-001, AC-003
- **FR-002** `[P1]`: Hệ thống PHẢI gửi câu hỏi từ người dùng được chọn đến AI Agent đang được cấu hình trên màn hiện tại.  
  **Liên quan**: US-001, AC-001
- **FR-003** `[P1]`: Hệ thống PHẢI hiển thị câu hỏi của người dùng và câu trả lời của AI Agent với vai trò người gửi phân biệt rõ ràng, theo thứ tự cuộc hội thoại.  
  **Liên quan**: US-001, AC-003, AC-004
- **FR-004** `[P1]`: Hệ thống PHẢI hiển thị trạng thái đang chờ trong khi AI Agent xử lý câu hỏi và không cho phép gửi trùng thao tác đang chờ.  
  **Liên quan**: US-001, AC-002
- **FR-005** `[P2]`: Hệ thống PHẢI hiển thị trạng thái Agent chưa sẵn sàng/kết nối và không cho phép người dùng hiểu nhầm rằng đã có phản hồi AI.  
  **Liên quan**: US-002, AC-005
- **FR-006** `[P2]`: Hệ thống PHẢI thông báo lỗi hoặc quá thời gian chờ bằng ngôn ngữ dễ hiểu, giữ lại lịch sử hội thoại đã hiển thị và cho phép thử lại.  
  **Liên quan**: US-002, AC-006
- **FR-007** `[P2]`: Hệ thống KHÔNG ĐƯỢC hiển thị tin nhắn của người dùng khác hoặc phản hồi được tạo sẵn như là câu trả lời mới từ AI Agent.  
  **Liên quan**: US-002, AC-005

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Mỗi tin nhắn gửi từ khung xem trước được coi là câu hỏi của người được chọn tại thời điểm gửi, không phải tin nhắn của một người dùng thứ hai.
- **BR-002**: Chỉ một yêu cầu trả lời được ở trạng thái chờ trong một cuộc xem trước tại một thời điểm.
- **BR-003**: Chỉ phản hồi được trả về từ AI Agent đang được kiểm tra mới được hiển thị với vai trò Agent; hệ thống không được thay thế bằng phản hồi giả lập khi không nhận được kết quả.
- **BR-004**: Khi Agent chưa sẵn sàng, người dùng phải nhận biết được trạng thái trước hoặc ngay khi thực hiện thao tác gửi.

**Luồng trạng thái nếu có**:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| Sẵn sàng gửi | Người dùng gửi câu hỏi hợp lệ | Đang chờ phản hồi | Agent sẵn sàng |
| Đang chờ phản hồi | Nhận phản hồi hợp lệ | Sẵn sàng gửi | Phản hồi có nội dung |
| Đang chờ phản hồi | Lỗi hoặc quá thời gian chờ | Sẵn sàng gửi | Có thông báo lỗi |
| Agent chưa sẵn sàng | Người dùng gửi câu hỏi | Agent chưa sẵn sàng | Không tạo phản hồi AI |

---

## 9. Thực thể dữ liệu

- **Phiên xem trước hội thoại**: Ngữ cảnh các tin nhắn được hiển thị trong một lần người dùng kiểm tra AI Agent trên màn hiện tại.
- **Tin nhắn xem trước**: Nội dung câu hỏi hoặc phản hồi, vai trò người gửi, thời điểm hiển thị và trạng thái xử lý; thuộc một phiên xem trước hội thoại.
- **Trạng thái sẵn sàng của Agent**: Trạng thái nghiệp vụ cho biết AI Agent có thể nhận và trả lời câu hỏi kiểm tra hay không.

---

## 10. Phân quyền & Bảo mật

**Ai được xem**:
- Người có quyền truy cập màn cấu hình Agent và quyền xem trước/kiểm tra Agent tương ứng.

**Ai được thao tác**:
- Người có quyền kiểm tra Agent được chọn người gửi thử nghiệm và gửi câu hỏi trong khung xem trước.

**Ai không được phép**:
- Người không có quyền truy cập hoặc kiểm tra Agent không được gửi câu hỏi, xem phản hồi hoặc mạo danh người được chọn ngoài phạm vi quyền của họ.

**Dữ liệu nhạy cảm**:
- Có. Câu hỏi và phản hồi có thể chứa thông tin nghiệp vụ hoặc dữ liệu khách hàng; chỉ hiển thị trong phạm vi quyền của người kiểm tra và không dùng dữ liệu đó làm tin nhắn giả lập cho người khác.

- **SEC-001**: Hệ thống PHẢI kiểm tra quyền trước khi cho phép người dùng xem hoặc gửi câu hỏi kiểm tra đến Agent.
- **SEC-002**: Hệ thống KHÔNG ĐƯỢC cho người dùng truy cập dữ liệu hội thoại hoặc phản hồi ngoài phạm vi Agent và quyền được cấp.

---

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Không áp dụng cho MVP. Lịch sử hiển thị phục vụ phiên xem trước hiện tại; yêu cầu lưu audit lâu dài sẽ được xác định ở feature riêng nếu nghiệp vụ yêu cầu.

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: Trong điều kiện Agent sẵn sàng và tải thông thường, ít nhất 95% câu hỏi kiểm tra hiển thị phản hồi hoặc trạng thái lỗi rõ ràng trong vòng 15 giây sau khi người dùng gửi.
- **NFR-002**: Tính năng không làm gián đoạn các thao tác cấu hình, lưu nháp hoặc phát hành Agent hiện có.
- **NFR-003**: Khung xem trước hoạt động trên các trình duyệt đang được tổ chức hỗ trợ.

---

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: 100% lần gửi câu hỏi hợp lệ trong khung xem trước tạo ra đúng một trạng thái kết quả nhìn thấy được: câu trả lời từ Agent hoặc thông báo không thể trả lời.
- **SC-002**: Ít nhất 95% câu hỏi kiểm tra với Agent sẵn sàng nhận được phản hồi hoặc trạng thái lỗi rõ ràng trong vòng 15 giây.
- **SC-003**: Người dùng có quyền kiểm tra hoàn thành việc gửi câu hỏi và nhận biết kết quả trong lần thử đầu tiên với tỷ lệ ít nhất 90% trong kịch bản kiểm thử chấp nhận.

---

## 14. Giả định & Ràng buộc

**Giả định**:
- AI Agent có một trạng thái sẵn sàng có thể xác định được để nhận câu hỏi kiểm tra.
- Người dùng hiện tại đã được xác thực và danh sách người gửi thử nghiệm chỉ hiển thị các lựa chọn hợp lệ theo quyền.
- Phiên bản đầu tiên chỉ cần giữ cuộc hội thoại trong phiên xem trước hiện tại, không yêu cầu truy xuất lại sau khi rời màn.

**Ràng buộc**:
- Phải giữ nguyên mục đích kiểm tra trên màn hiện tại và không biến thành màn quản lý hội thoại khách hàng.
- Không được tạo hoặc hiển thị phản hồi giả lập thay cho phản hồi thực tế của AI Agent.

---

## 15. Ngoài phạm vi

- Lưu trữ, tìm kiếm hoặc phân tích dài hạn lịch sử hội thoại xem trước.
- Chat đa kênh với khách hàng thực tế, chuyển tiếp cho nhân viên, phân công hội thoại hoặc quản lý ticket.
- Tạo mới, huấn luyện, thay đổi kiến thức hoặc tự động phát hành AI Agent từ khung hội thoại.
- Hỗ trợ tệp đính kèm, ghi âm, hoặc các loại nội dung ngoài văn bản trong MVP.

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Agent chưa kết nối hoặc không sẵn sàng tại thời điểm kiểm tra | Trung | Cao | Hiển thị trạng thái rõ ràng, không tạo phản hồi giả và cho phép thử lại khi Agent sẵn sàng. |
| Phản hồi chậm hoặc lỗi khiến người dùng gửi lặp | Trung | Trung | Thể hiện trạng thái chờ, chỉ cho phép một yêu cầu đang xử lý và cung cấp thao tác thử lại sau lỗi. |
| Nội dung kiểm tra chứa dữ liệu nhạy cảm | Thấp | Cao | Áp dụng quyền xem/gửi theo Agent và không hiển thị hội thoại ngoài phạm vi được cấp quyền. |

---

## 17. Phụ thuộc

- AI Agent phải có khả năng nhận câu hỏi kiểm tra và trả về phản hồi/trạng thái lỗi cho màn hiện tại.
- Cơ chế xác thực và phân quyền hiện có phải xác định được người được phép kiểm tra từng Agent.
- Trạng thái kết nối/sẵn sàng của Agent phải được cung cấp để người dùng nhận biết khi không thể thực hiện kiểm tra.

---

## 18. Câu hỏi mở

Không có câu hỏi mở chặn lập plan. Các giả định phạm vi của MVP được ghi tại §14.

---

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
