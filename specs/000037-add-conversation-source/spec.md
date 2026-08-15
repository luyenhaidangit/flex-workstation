# Đặc tả tính năng: Phân loại nguồn hội thoại

**Branch**: `[000037-add-conversation-source]`  
**Ngày tạo**: 2026-08-15  
**Trạng thái**: Bản nháp  
**Người phụ trách**: Luyện Hải Đăng  
**Stakeholder xác nhận**: Luyện Hải Đăng  
**Đầu vào**: Bổ sung thông tin `conversation_source` để nhận biết conversation được khởi tạo từ luồng vận hành thực tế, màn hình cấu hình Agent, playground hoặc API.

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

Conversation hiện chưa cho biết nó bắt đầu từ đâu. Vì vậy, đội vận hành và phát triển không thể phân biệt hội thoại thật của end-user với thao tác thử Agent trên màn cấu hình, playground hoặc cuộc gọi API; dữ liệu đánh giá và xử lý sự cố có thể bị trộn lẫn.

**Tổng quan tính năng**:

Mỗi conversation mới được gán một nguồn khởi tạo chuẩn để có thể lọc, thống kê và diễn giải đúng mục đích của hội thoại. Việc phân loại này phục vụ vận hành và phân tích, không thay thế vai trò, tác nhân hay nội dung message.

## 2. Mục tiêu

- **MT-001**: Phân biệt chính xác nguồn khởi tạo của mọi conversation mới thuộc các luồng được hỗ trợ.
- **MT-002**: Giúp đội vận hành loại trừ dữ liệu test khi đánh giá hội thoại Production.
- **MT-003**: Tạo nền tảng nhất quán để bổ sung nguồn hội thoại trong tương lai mà không làm đổi nghĩa các nguồn hiện có.

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Ghi nhận một nguồn khởi tạo chuẩn cho từng conversation mới.
- **MVP-002**: Hỗ trợ bốn nguồn: `Production = 1`, `Preview = 2`, `Playground = 3`, `Api = 4`.
- **MVP-003**: Cung cấp nguồn đã ghi nhận trong dữ liệu conversation cho các chủ thể được phép sử dụng dữ liệu đó.
- **MVP-004**: Giữ nguyên khả năng đọc và tiếp tục conversation lịch sử khi chưa có thông tin nguồn đáng tin cậy.

## 4. Người dùng & Bối cảnh

**Người dùng chính**: End-user trò chuyện với Agent; quản trị viên cấu hình Agent; nhân sự vận hành, hỗ trợ và kỹ thuật tích hợp qua API.

**Bối cảnh sử dụng**: Người dùng hoặc hệ thống bắt đầu một hội thoại từ một trong các điểm vào được hỗ trợ; đội vận hành cần xác định chính xác hội thoại đó phục vụ mục đích thật hay kiểm thử.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Người dùng nghiệp vụ, quản trị viên và kỹ thuật viên.

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Phân loại hội thoại khi khởi tạo (Ưu tiên: P1)

End-user, quản trị viên hoặc ứng dụng tích hợp bắt đầu conversation từ một điểm vào hợp lệ. Hệ thống ghi nhận đúng nguồn khởi tạo ngay từ lúc conversation được tạo.

**Lý do ưu tiên**: Đây là điều kiện cốt lõi để dữ liệu hội thoại không bị trộn lẫn giữa vận hành thật và kiểm thử.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003

**Test độc lập**: Khởi tạo một conversation từ từng nguồn hỗ trợ và xác nhận nguồn trả về tương ứng.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** end-user bắt đầu hội thoại qua luồng vận hành thực tế, **Khi** conversation được tạo, **Thì** nguồn là `Production`.
2. **AC-002**: **Cho trước** quản trị viên thử Agent ngay trên màn cấu hình, **Khi** conversation được tạo, **Thì** nguồn là `Preview`.
3. **AC-003**: **Cho trước** conversation được khởi tạo qua playground hoặc API, **Khi** conversation được tạo, **Thì** nguồn lần lượt là `Playground` hoặc `Api`.

### US-002 — Diễn giải dữ liệu hội thoại theo nguồn (Ưu tiên: P2)

Nhân sự được cấp quyền xem dữ liệu conversation có thể nhận biết nguồn đã ghi nhận để không nhầm dữ liệu test với dữ liệu Production.

**Lý do ưu tiên**: Giá trị nghiệp vụ của phân loại chỉ đạt được khi nguồn được cung cấp nhất quán cho các luồng đọc conversation có quyền.

**Liên quan yêu cầu**: FR-004, FR-005

**Test độc lập**: Mở dữ liệu của các conversation có nguồn khác nhau và xác nhận từng conversation hiển thị hoặc cung cấp đúng nguồn đã được ghi nhận.

**Acceptance Criteria**:

1. **AC-004**: **Cho trước** người dùng có quyền xem conversation, **Khi** họ tải dữ liệu conversation, **Thì** nguồn đã ghi nhận được cung cấp cùng conversation.
2. **AC-005**: **Cho trước** conversation lịch sử không có bằng chứng về nguồn, **Khi** người dùng có quyền tải conversation đó, **Thì** lịch sử vẫn đọc được và không bị gán nhầm một trong bốn nguồn.

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Không áp dụng; nguồn được xác định khi một conversation mới được tạo.
- **Dữ liệu không hợp lệ**: Conversation mới không được nhận một nguồn ngoài bốn nguồn chuẩn.
- **Không có quyền**: Người dùng không có quyền trên conversation không được xem nguồn hoặc nội dung của conversation đó.
- **Lỗi hệ thống**: Nếu không thể ghi nhận nguồn khi tạo conversation, thao tác tạo không được báo là hoàn tất.
- **Timeout**: Khi kết quả tạo conversation chưa xác định, việc thử lại không được tạo conversation trùng hoặc nguồn mâu thuẫn.
- **Dữ liệu bị thay đổi bởi người khác**: Không áp dụng; nguồn khởi tạo là thuộc tính lịch sử của conversation.
- **Người dùng thao tác lặp lại**: Lặp lại cùng một thao tác tạo chỉ được dẫn đến một conversation với một nguồn nhất quán.
- **Trường hợp biên khác**: Conversation lịch sử chưa có nguồn đáng tin cậy được nhận diện là chưa phân loại, không tự suy đoán là `Production`, `Preview`, `Playground` hoặc `Api`.

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI ghi nhận `conversation_source` khi tạo mỗi conversation mới.  
  **Liên quan**: US-001, AC-001, AC-002, AC-003
- **FR-002** `[P1]`: `conversation_source` PHẢI chỉ nhận một trong các giá trị chuẩn: `Production = 1`, `Preview = 2`, `Playground = 3`, `Api = 4`.  
  **Liên quan**: US-001, AC-001, AC-002, AC-003
- **FR-003** `[P1]`: Hệ thống PHẢI gán nguồn theo điểm vào tạo conversation và KHÔNG ĐƯỢC suy luận nguồn từ `role`, `actor_type`, nội dung message hoặc nhãn hiển thị.  
  **Liên quan**: US-001, AC-001, AC-002, AC-003
- **FR-004** `[P2]`: Hệ thống PHẢI cung cấp nguồn đã ghi nhận khi trả dữ liệu conversation cho chủ thể có quyền xem conversation.  
  **Liên quan**: US-002, AC-004
- **FR-005** `[P1]`: Nguồn khởi tạo của conversation đã được ghi nhận PHẢI được giữ nguyên trong suốt vòng đời conversation.  
  **Liên quan**: US-001, AC-001, AC-002, AC-003
- **FR-006** `[P1]`: Hệ thống KHÔNG ĐƯỢC gán hồi tố một trong bốn nguồn cho conversation lịch sử nếu không có bằng chứng đáng tin cậy về điểm vào đã tạo conversation đó.  
  **Liên quan**: US-002, AC-005

## 8. Quy tắc nghiệp vụ

- **BR-001**: `conversation_source` mô tả nơi hoặc cách conversation được khởi tạo, không mô tả người gửi message, kênh giao tiếp hay trạng thái xử lý.
- **BR-002**: `Production` chỉ dành cho hội thoại thật với end-user; không dùng cho thao tác test hoặc đánh giá Agent.
- **BR-003**: `Preview` chỉ dành cho thao tác test trực tiếp trên màn cấu hình Agent.
- **BR-004**: `Playground` dành cho màn test độc lập khi luồng này được cung cấp.
- **BR-005**: `Api` dành cho conversation được khởi tạo qua API.
- **BR-006**: Giá trị nguồn đã gán là bất biến; điểm vào tiếp tục conversation không làm thay đổi nguồn ban đầu.
- **BR-007**: Conversation lịch sử không có bằng chứng về điểm vào được giữ trạng thái chưa phân loại thay vì bị suy đoán nguồn.

**Luồng trạng thái nếu có**:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| Chưa có conversation | Khởi tạo từ điểm vào hợp lệ | Conversation có nguồn | Điểm vào xác định được một trong bốn nguồn chuẩn |
| Conversation có nguồn | Tiếp tục trao đổi | Conversation có cùng nguồn | Conversation còn hợp lệ và người dùng có quyền |

## 9. Thực thể dữ liệu

- **Conversation**: Chuỗi trao đổi thuộc tenant; ngoài thông tin hiện có, mang nguồn khởi tạo để phân biệt mục đích của cuộc trao đổi.
- **Conversation source**: Phân loại chuẩn của điểm vào tạo conversation gồm `Production`, `Preview`, `Playground` và `Api`.

Quan hệ nghiệp vụ: Một conversation có tối đa một nguồn khởi tạo; một nguồn có thể áp dụng cho nhiều conversation.

## 10. Phân quyền & Bảo mật

**Ai được xem**:
- Chủ thể đã được cấp quyền xem conversation tương ứng.

**Ai được thao tác**:
- Chỉ các điểm vào được hệ thống công nhận mới được tạo conversation với nguồn tương ứng.

**Ai không được phép**:
- Client không được tự nhận hoặc sửa nguồn không tương ứng với điểm vào đã xác thực.
- Chủ thể không có quyền không được biết nguồn hay nội dung conversation.

**Dữ liệu nhạy cảm**:
- Có. Nguồn có thể cho biết ngữ cảnh vận hành hoặc kiểm thử; được bảo vệ cùng phạm vi quyền của conversation, trong khi nội dung conversation vẫn là dữ liệu nhạy cảm theo chính sách hiện có.

- **SEC-001**: Hệ thống PHẢI kiểm tra quyền conversation trước khi cung cấp nguồn.
- **SEC-002**: Hệ thống PHẢI xác thực điểm vào trước khi gán nguồn; dữ liệu do client tự khai không phải bằng chứng duy nhất.

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Có. Cần truy vết nguồn đã gán tại thời điểm tạo conversation; vì nguồn là bất biến nên không có luồng sửa nguồn trong phạm vi tính năng.

## 12. Yêu cầu phi chức năng

- **NFR-001**: Trong kiểm thử các điểm vào được hỗ trợ, 100% conversation mới có nguồn phù hợp với điểm vào khởi tạo.
- **NFR-002**: Việc bổ sung nguồn không làm gián đoạn khả năng đọc hoặc tiếp tục conversation lịch sử.
- **NFR-003**: Ít nhất 95% thao tác xem conversation hợp lệ nhận được dữ liệu conversation, gồm nguồn nếu đã được ghi nhận, hoặc thông báo lỗi rõ ràng trong vòng 2 giây ở điều kiện tải thông thường.

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: 100% conversation mới được tạo trong bốn luồng hỗ trợ được phân loại đúng nguồn trong kiểm thử chấp nhận.
- **SC-002**: 100% conversation đã có nguồn khi được tải bởi chủ thể có quyền đều cung cấp cùng nguồn đã ghi nhận lúc tạo.
- **SC-003**: 100% conversation lịch sử được kiểm thử vẫn xem và tiếp tục được mà không bị gán sai một nguồn mới.
- **SC-004**: Đội vận hành có thể tách chính xác 100% mẫu conversation Production và test đã được phân loại trong kiểm thử nghiệm thu.

## 14. Giả định & Ràng buộc

**Giả định**:
- Bốn điểm vào được mô tả có thể được nhận diện tin cậy tại thời điểm tạo conversation.
- Conversation lịch sử không có bằng chứng nguồn sẽ tiếp tục được hỗ trợ ở trạng thái chưa phân loại; không tự xem là `Production`.
- `Playground` được nhận diện trong mô hình ngay từ MVP dù màn test độc lập có thể được cung cấp sau.

**Ràng buộc**:
- Bốn mã nguồn và ý nghĩa nghiệp vụ đã nêu phải ổn định trong phạm vi feature này.
- Không thay đổi hoặc hợp nhất các khái niệm `role`, `actor_type`, kênh, hay trạng thái message.

## 15. Ngoài phạm vi

- Thiết kế hoặc xây dựng màn hình playground mới.
- Thay đổi nội dung, role, actor hoặc thứ tự message.
- Phân tích chất lượng Agent, báo cáo, dashboard, chi phí hoặc chính sách retention theo nguồn.
- Tự động suy đoán hay sửa nguồn của conversation lịch sử.
- Bổ sung nguồn thứ năm hoặc cấu hình nguồn tùy biến.

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Điểm vào gán sai nguồn | Trung | Cao | Xác định rõ điểm vào và kiểm thử chấp nhận cho từng nguồn. |
| Client giả mạo nguồn | Trung | Cao | Chỉ tin nguồn được xác thực từ điểm vào hợp lệ. |
| Conversation lịch sử bị suy đoán sai | Trung | Trung | Không hồi tố khi không có bằng chứng. |
| Dữ liệu test bị dùng như Production do consumer bỏ qua nguồn | Trung | Cao | Cung cấp nguồn nhất quán và kiểm thử các luồng sử dụng dữ liệu. |

## 17. Phụ thuộc

- Mô hình conversation và các điểm vào tạo conversation hiện có.
- Cơ chế tenant context, xác thực và phân quyền conversation.
- Thống nhất contract dữ liệu conversation giữa các consumer trước khi triển khai.

## 18. Câu hỏi mở

Không có câu hỏi mở chặn lập plan. Việc xác định vị trí thay đổi dữ liệu, migration và contract cụ thể thuộc plan kỹ thuật theo Constitution VI.

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
