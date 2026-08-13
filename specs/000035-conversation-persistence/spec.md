# Đặc tả tính năng: Lưu trữ và tích hợp hội thoại

**Branch**: `000035-conversation-persistence`  
**Ngày tạo**: 2026-08-13  
**Trạng thái**: Bản nháp  
**Người phụ trách**: Luyện Hải Đăng  
**Stakeholder xác nhận**: Luyện Hải Đăng  
**Đầu vào**: Xây dựng nền tảng lưu trữ hội thoại và message để FE/BE dùng chung, bảo đảm lịch sử có thứ tự ổn định, phân biệt đúng vai trò nội dung với tác nhân tạo message, và hỗ trợ các luồng user–AI hiện có.

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW như database cụ thể, schema SQL, API route, transaction, framework và repo migration sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

Các luồng chat AI hiện có mới xử lý hội thoại trong phiên hoặc mô phỏng trên màn hình, chưa có nguồn dữ liệu bền vững và thống nhất cho FE, BE, realtime và các xử lý tiếp theo. Nếu mỗi luồng tự suy luận người gửi hoặc tự ghép lịch sử, message có thể sai thứ tự, mất ngữ cảnh, trùng khi gửi lại hoặc làm lệch trạng thái hội thoại.

**Tổng quan tính năng**:

Tính năng cung cấp khả năng tạo, xem và tiếp tục một conversation; lưu từng message với thứ tự, role và actor rõ ràng; đồng thời cung cấp dữ liệu nhất quán để FE hiển thị và BE xử lý. Một message do người dùng, AI Agent, human agent, system hoặc tool tạo đều dùng cùng mô hình nghiệp vụ, không tạo các loại lịch sử tách rời theo tác nhân.

---

## 2. Mục tiêu

- **MT-001**: Người dùng có thể mở lại và tiếp tục một conversation mà không mất lịch sử đã ghi nhận.
- **MT-002**: FE và BE diễn giải thống nhất thứ tự, vai trò và tác nhân của từng message.
- **MT-003**: Hệ thống duy trì lịch sử không trùng thứ tự trong trường hợp có nhiều yêu cầu gửi đồng thời hoặc gửi lại.
- **MT-004**: Nền tảng hỗ trợ mở rộng thông tin theo provider/channel/AI mà không làm thay đổi các thuộc tính cốt lõi của message.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Tạo conversation thuộc một tenant và gắn với người tạo.
- **MVP-002**: Lưu message văn bản trong conversation với thứ tự tăng dần, trạng thái xử lý, thời điểm tạo và thông tin tác nhân.
- **MVP-003**: Phân biệt `role` (`system`, `user`, `assistant`, `tool`) với `actor_type` (`end_user`, `ai_agent`, `human_agent`, `system`, `tool`, `automation`).
- **MVP-004**: FE có thể tải danh sách conversation, mở chi tiết lịch sử và gửi message mới; BE trả về cùng một mô hình dữ liệu cho các thao tác này.
- **MVP-005**: Hỗ trợ message assistant do AI Agent tạo trong cùng conversation với message user, không tạo bảng/lịch sử riêng cho AI.
- **MVP-006**: Bảo toàn thứ tự và trạng thái khi message được tạo đồng thời, bị lỗi hoặc được gửi lại.

---

## 4. Người dùng & Bối cảnh

**Người dùng chính**: Người dùng nghiệp vụ đã xác thực đang trao đổi với AI Agent; human agent hoặc hệ thống có quyền tham gia conversation.

**Bối cảnh sử dụng**: Người dùng mở một conversation cũ, đọc các message gần nhất, gửi câu hỏi tiếp theo và nhận phản hồi từ AI Agent hoặc tác nhân phù hợp.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Người dùng nghiệp vụ; quản trị viên và kỹ thuật viên cần đọc dữ liệu để vận hành, hỗ trợ hoặc tích hợp.

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Mở và tiếp tục conversation (Ưu tiên: P1)

Người dùng xem danh sách conversation được phép truy cập, mở một conversation và gửi message mới. Hệ thống hiển thị lịch sử theo đúng thứ tự và bổ sung message mới vào cuối conversation.

**Lý do ưu tiên**: Đây là luồng cốt lõi tạo giá trị trực tiếp cho người dùng và là nền để tích hợp các luồng AI.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003, FR-004, FR-005

**Test độc lập**: Tạo conversation, thêm hai message, tải lại lịch sử, gửi message thứ ba và xác nhận thứ tự cùng nội dung được giữ nguyên.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** người dùng có quyền và chưa có conversation cần dùng, **Khi** người dùng bắt đầu cuộc trao đổi, **Thì** hệ thống tạo một conversation thuộc đúng tenant và gắn người tạo.
2. **AC-002**: **Cho trước** conversation có lịch sử, **Khi** người dùng mở conversation, **Thì** FE hiển thị các message theo thứ tự từ cũ đến mới và thể hiện đúng trạng thái của từng message.
3. **AC-003**: **Cho trước** conversation hợp lệ và nội dung message không rỗng, **Khi** người dùng gửi message, **Thì** message được ghi nhận một lần và xuất hiện trong lịch sử với thứ tự tiếp theo.
4. **AC-004**: **Cho trước** có nhiều conversation được phép truy cập, **Khi** người dùng xem danh sách, **Thì** danh sách thể hiện tiêu đề/trạng thái và hoạt động gần nhất để người dùng chọn đúng conversation.

### US-002 — Nhận phản hồi từ AI Agent và nhận diện tác nhân (Ưu tiên: P1)

Người dùng gửi message và nhận phản hồi AI trong cùng conversation. FE hiển thị rõ message là của user hay assistant; dữ liệu phía sau vẫn xác định được tác nhân thực sự tạo message.

**Lý do ưu tiên**: Phân biệt `role` và `actor_type` là điều kiện để lịch sử đúng nghiệp vụ, audit và mở rộng human agent/tool sau này.

**Liên quan yêu cầu**: FR-006, FR-007

**Test độc lập**: Tạo một message user và một message AI Agent, tải lịch sử và xác nhận mỗi message có role, actor type và actor tương ứng.

**Acceptance Criteria**:

1. **AC-005**: **Cho trước** AI Agent trả lời thành công, **Khi** phản hồi được ghi nhận, **Thì** phản hồi nằm trong cùng conversation và được nhận diện là assistant do ai_agent tạo.
2. **AC-006**: **Cho trước** message do system, tool hoặc human agent tạo, **Khi** FE nhận lịch sử, **Thì** FE không suy luận tác nhân chỉ từ role mà hiển thị theo thông tin tác nhân được cung cấp.

### US-003 — Khôi phục và xử lý lỗi khi tải/gửi (Ưu tiên: P2)

Người dùng gặp lỗi khi tải lịch sử hoặc gửi message nhưng vẫn biết trạng thái và có thể thử lại mà không tạo bản ghi trùng hoặc làm mất lịch sử đã có.

**Lý do ưu tiên**: Hội thoại là dữ liệu liên tục; lỗi mạng, timeout và retry không được làm hỏng thứ tự hoặc trải nghiệm.

**Liên quan yêu cầu**: FR-008, FR-009

**Test độc lập**: Mô phỏng lỗi tải, timeout và gửi lại cùng một thao tác; xác nhận thông báo rõ ràng, lịch sử cũ còn nguyên và không có message trùng.

**Acceptance Criteria**:

1. **AC-007**: **Cho trước** tải lịch sử thất bại, **Khi** FE nhận lỗi, **Thì** FE giữ trạng thái hiện có, thông báo có thể hành động và cho phép tải lại.
2. **AC-008**: **Cho trước** yêu cầu gửi bị timeout hoặc retry, **Khi** hệ thống hoàn tất xử lý, **Thì** một thao tác nghiệp vụ chỉ tạo tối đa một message tương ứng và không làm trùng sequence.

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Conversation mới hiển thị trạng thái trống và hướng dẫn gửi message đầu tiên.
- **Dữ liệu không hợp lệ**: Message rỗng hoặc chỉ gồm khoảng trắng bị từ chối; conversation không bị cập nhật như đã có message mới.
- **Không có quyền**: Người dùng không thuộc phạm vi tenant/conversation không được xem hoặc gửi message.
- **Lỗi hệ thống**: Hiển thị lỗi dễ hiểu, không tiết lộ chi tiết nội bộ và không hiển thị message chưa được ghi nhận như đã hoàn tất.
- **Timeout**: Cho biết thao tác chưa xác định kết quả và cung cấp cách kiểm tra/tải lại trước khi gửi lại.
- **Dữ liệu bị thay đổi bởi người khác**: Khi lịch sử đã có message mới, FE phải tải hoặc hợp nhất dữ liệu để không ghi đè message của tác nhân khác.
- **Người dùng thao tác lặp lại**: Retry cùng một thao tác không được tạo message trùng hoặc nhảy sai thứ tự.
- **Trường hợp biên khác**: Message lỗi/cancelled vẫn được thể hiện trạng thái phù hợp nếu đã được ghi nhận; không coi là phản hồi thành công.

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI tạo và quản lý conversation theo tenant và người tạo.  
  **Liên quan**: US-001, AC-001
- **FR-002** `[P1]`: Hệ thống PHẢI cho người dùng có quyền tải danh sách và lịch sử message của conversation.  
  **Liên quan**: US-001, AC-002, AC-004
- **FR-003** `[P1]`: Hệ thống PHẢI lưu mỗi message trong đúng một conversation và cung cấp thứ tự ổn định trong conversation đó.  
  **Liên quan**: US-001, AC-003
- **FR-004** `[P1]`: Hệ thống PHẢI cập nhật thông tin hoạt động gần nhất của conversation sau khi message được ghi nhận thành công.  
  **Liên quan**: US-001, AC-004
- **FR-005** `[P1]`: Hệ thống PHẢI cho FE gửi message mới và nhận kết quả theo mô hình dữ liệu thống nhất với BE.  
  **Liên quan**: US-001, AC-003
- **FR-006** `[P1]`: Mỗi message PHẢI cung cấp độc lập `role` và `actor_type`; `actor_id` PHẢI được cung cấp khi tác nhân có danh tính cần truy vết.  
  **Liên quan**: US-002, AC-005, AC-006
- **FR-007** `[P1]`: Hệ thống PHẢI dùng cùng mô hình message cho user, AI Agent, human agent, system, tool và automation; không được yêu cầu FE suy luận tác nhân từ cờ boolean hoặc nhãn hiển thị.  
  **Liên quan**: US-002, AC-006
- **FR-008** `[P1]`: Hệ thống PHẢI bảo toàn tính duy nhất và thứ tự message khi có yêu cầu đồng thời hoặc retry.  
  **Liên quan**: US-003, AC-008
- **FR-009** `[P2]`: Hệ thống PHẢI trả trạng thái pending/completed/failed/cancelled phù hợp với vòng đời message và cho phép FE phân biệt message chưa hoàn tất với message thành công.  
  **Liên quan**: US-003, AC-007, AC-008
- **FR-010** `[P2]`: Hệ thống PHẢI cho phép lưu thông tin mở rộng không ổn định theo ngữ cảnh AI/provider/channel mà không làm thay đổi các thuộc tính cốt lõi của message.  
  **Liên quan**: MT-004

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Conversation và message luôn thuộc cùng một tenant; không được dùng message của tenant khác để tạo lịch sử.
- **BR-002**: `role` mô tả vai trò của message trong ngữ cảnh xử lý; `actor_type` mô tả tác nhân thực sự tạo message. Hai khái niệm không được thay thế cho nhau.
- **BR-003**: Thứ tự message là thứ tự nghiệp vụ trong conversation; timestamp chỉ mô tả thời điểm và không thay thế thứ tự này.
- **BR-004**: Source of truth của lịch sử là các message đã ghi nhận. Thông tin message cuối cùng trên conversation chỉ là dữ liệu phục vụ hiển thị danh sách và truy vấn nhanh.
- **BR-005**: Message assistant do AI Agent tạo vẫn thuộc conversation chung và không được lưu thành một loại lịch sử riêng.
- **BR-006**: Metadata chỉ chứa thông tin mở rộng theo ngữ cảnh; các thuộc tính cần dùng chung cho nghiệp vụ, quyền hoặc sắp xếp phải được thể hiện rõ trong mô hình cốt lõi.

**Luồng trạng thái nếu có**:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| Chưa có conversation | Người dùng bắt đầu trao đổi | Đang hoạt động | Người dùng có quyền |
| Đang hoạt động | Gửi message hợp lệ | Đang hoạt động | Message được ghi nhận |
| Đang hoạt động | AI/human agent đang xử lý | Đang chờ phản hồi | Có yêu cầu xử lý đang mở |
| Đang chờ phản hồi | Nhận phản hồi hợp lệ | Đang hoạt động | Message assistant được ghi nhận |
| Đang chờ phản hồi | Lỗi hoặc huỷ | Đang hoạt động | Message lỗi/cancelled được xử lý phù hợp |

---

## 9. Thực thể dữ liệu

- **Conversation**: Một chuỗi trao đổi thuộc tenant, có người tạo, tiêu đề/trạng thái và thông tin hoạt động gần nhất.
- **Message**: Một đơn vị nội dung trong conversation, có thứ tự, role, actor type, tác nhân tùy chọn, nội dung, trạng thái và thông tin mở rộng.
- **Actor**: Danh tính hoặc loại tác nhân tạo message, có thể là end user, AI Agent, human agent, system, tool hoặc automation.
- **Metadata**: Thông tin mở rộng theo provider, channel, model hoặc ngữ cảnh xử lý; không thay thế dữ liệu cốt lõi.

Quan hệ nghiệp vụ: Một conversation có nhiều message; mỗi message thuộc đúng một conversation và một tenant.

---

## 10. Phân quyền & Bảo mật

**Ai được xem**:
- Người dùng đã xác thực có quyền trên tenant và conversation tương ứng.
- Các thành phần xử lý nội bộ được cấp quyền cho conversation theo vai trò nghiệp vụ.

**Ai được thao tác**:
- Người dùng có quyền được tạo conversation và gửi message.
- AI Agent, human agent, system hoặc tool chỉ được tạo message trong phạm vi được giao.

**Ai không được phép**:
- Không được đọc, tạo hoặc sửa conversation/message ngoài tenant hoặc phạm vi quyền.
- FE không được coi `conversation_id` hoặc `actor_id` do client cung cấp là bằng chứng quyền truy cập.

**Dữ liệu nhạy cảm**:
- Có. Nội dung hội thoại có thể chứa thông tin cá nhân, nghiệp vụ hoặc dữ liệu khách hàng; dữ liệu chỉ được trả về cho chủ thể có quyền và không được đưa nguyên văn vào lỗi vận hành.

- **SEC-001**: Hệ thống PHẢI kiểm tra tenant và quyền conversation trước mọi thao tác đọc/ghi.
- **SEC-002**: Hệ thống PHẢI kiểm soát việc message được tạo nhân danh actor nào; client không được tự ý mạo danh actor không thuộc quyền.
- **SEC-003**: Log, lỗi và dữ liệu mở rộng KHÔNG ĐƯỢC làm lộ nội dung nhạy cảm hoặc thông tin xác thực.

---

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Có ở mức lịch sử message. Message đã ghi nhận phải giữ được tác nhân, thời điểm, trạng thái và thứ tự để phục vụ truy vết nghiệp vụ. Cơ chế lưu audit kỹ thuật chi tiết và chính sách retention thuộc plan.

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: Trong điều kiện tải thông thường, ít nhất 95% thao tác mở conversation hiển thị được danh sách/lịch sử hoặc lỗi rõ ràng trong vòng 2 giây.
- **NFR-002**: Ít nhất 99,9% message đã được xác nhận thành công không bị mất, nhân đôi hoặc đổi thứ tự sau khi tải lại lịch sử.
- **NFR-003**: FE có thể hiển thị lịch sử tăng dần theo message mà không cần biết chi tiết hệ thống lưu trữ phía BE.
- **NFR-004**: Mô hình dữ liệu cho phép bổ sung tác nhân và metadata mới mà không phá vỡ các luồng FE/BE hiện có.

---

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: 100% message hợp lệ được tải lại theo đúng thứ tự nghiệp vụ trong conversation.
- **SC-002**: 100% message user và AI Agent trong kịch bản MVP được FE nhận diện đúng role và actor type.
- **SC-003**: Ít nhất 95% người dùng thử nghiệm có thể mở conversation, đọc message gần nhất và gửi message tiếp theo mà không cần làm mới thủ công.
- **SC-004**: Trong kiểm thử đồng thời và retry, không có conversation nào xuất hiện hai message cùng thứ tự hoặc một thao tác nghiệp vụ tạo bản ghi trùng.

---

## 14. Giả định & Ràng buộc

**Giả định**:
- Người dùng và tenant đã có cơ chế xác thực, định danh và phân quyền được dùng lại.
- MVP ưu tiên message văn bản; các loại content khác chỉ được mở rộng khi có yêu cầu riêng.
- Tích hợp FE/BE cần hỗ trợ lịch sử bền vững cho chat AI runtime, không biến feature này thành hệ thống quản lý ticket đa kênh.

**Ràng buộc**:
- Không được dùng `is_bot`, `sender_type` hoặc nhãn giao diện làm nguồn duy nhất để xác định tác nhân.
- Không được hy sinh tính nhất quán lịch sử để đổi lấy việc ghi message nhanh hơn.
- Quyết định database đích, repo migration và API contract chi tiết phải được xác định ở plan theo Constitution VI.

---

## 15. Ngoài phạm vi

- Streaming token, đính kèm file, voice message và rich content ngoài text.
- Tìm kiếm toàn văn, phân tích sentiment, analytics hoặc RAG index riêng.
- Quản lý ticket, assignment, SLA, chuyển conversation đa kênh hoặc customer profile.
- Xóa/sửa message theo chính sách retention phức tạp; chỉ xử lý trạng thái và retry cần cho MVP.
- Chọn model/provider hoặc cấu hình system prompt của AI Agent.

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Chọn sai database/repo migration giữa các sub-repo | Trung | Cao | Xác định trong plan dựa trên system map và tiền lệ trước khi tạo migration. |
| Retry hoặc request đồng thời tạo message trùng/thứ tự sai | Trung | Cao | Đặt quy tắc duy nhất/thứ tự ở cấp conversation và kiểm thử đồng thời trong plan. |
| FE/BE hiểu khác role và actor type | Trung | Cao | Dùng contract có hai thuộc tính độc lập và kiểm thử consumer. |
| Metadata phát triển thành nơi chứa dữ liệu cốt lõi | Trung | Trung | Giữ thuộc tính dùng chung trong mô hình cốt lõi, review metadata theo từng extension. |
| Nội dung hội thoại bị lộ qua log hoặc lỗi | Thấp | Cao | Giới hạn quyền, che dữ liệu nhạy cảm và kiểm tra log/error contract. |

---

## 17. Phụ thuộc

- Cơ chế xác thực, tenant context và phân quyền conversation hiện có.
- AI Agent runtime có thể tạo phản hồi gắn với conversation và actor tương ứng.
- FE và BE thống nhất contract message/conversation trước khi triển khai.
- Quyết định về database đích và repo chứa migration trong plan kỹ thuật.

---

## 18. Câu hỏi mở

Không có câu hỏi mở chặn lập plan. Các quyết định kỹ thuật về database/repo migration, API/realtime transport, pagination và retention phải được phân tích trong plan; nếu system map không đủ bằng chứng thì plan phải tạo câu hỏi kỹ thuật trước khi sinh tasks.

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
