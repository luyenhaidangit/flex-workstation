# Đặc tả tính năng: Chat AI cơ bản

**Branch**: `000032-ai-chat-basics`  
**Ngày tạo**: 2026-08-11  
**Trạng thái**: Bản nháp  
**Người phụ trách**: Luyện Hải Đăng  
**Stakeholder xác nhận**: Luyện Hải Đăng  
**Đầu vào**: Cung cấp luồng chat AI tối thiểu để người dùng yêu cầu tóm tắt một hội thoại và nhận lại bản tóm tắt, đồng thời bảo đảm trải nghiệm nghiệp vụ không bị phụ thuộc vào nhà cung cấp mô hình AI.

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

Hệ thống chưa có luồng AI thống nhất để người dùng gửi yêu cầu ngôn ngữ tự nhiên và nhận kết quả. Khi các khu vực nghiệp vụ kết nối trực tiếp đến từng dịch vụ mô hình, việc thay đổi nhà cung cấp có thể làm gián đoạn hoặc làm thay đổi hành vi của các luồng đang dùng AI.

**Tổng quan tính năng**:

Tính năng cung cấp một điểm truy cập chat AI cơ bản cho FLEX Agent. Người dùng gửi nội dung hội thoại cùng yêu cầu tóm tắt và nhận về bản tóm tắt dễ đọc. Luồng đầu tiên tạo nền tảng để các nhu cầu AI sau này dùng chung trải nghiệm, không buộc người dùng hay luồng nghiệp vụ phải thay đổi khi dịch vụ mô hình nền được thay thế.

---

## 2. Mục tiêu

- **MT-001**: Cho phép người dùng hoàn thành yêu cầu tóm tắt một hội thoại bằng một lần gửi yêu cầu.
- **MT-002**: Cung cấp phản hồi rõ ràng khi yêu cầu không thể được xử lý.
- **MT-003**: Giữ nguyên hành vi người dùng của luồng tóm tắt khi thay đổi dịch vụ mô hình AI nền.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Người dùng đã đăng nhập có thể gửi nội dung hội thoại và yêu cầu tóm tắt qua một điểm truy cập AI.
- **MVP-002**: Hệ thống trả về một bản tóm tắt văn bản hoặc thông báo lỗi có thể hành động.
- **MVP-003**: Chỉ hỗ trợ một tác vụ AI là tóm tắt hội thoại; không lưu hội thoại hay lịch sử kết quả trong MVP.

---

## 4. Người dùng & Bối cảnh

**Người dùng chính**: Người dùng đã đăng nhập của FLEX Agent cần nắm nhanh nội dung một hội thoại.

**Bối cảnh sử dụng**: Người dùng có một đoạn hội thoại sẵn có và muốn rút gọn các ý chính trước khi tiếp tục công việc.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Người dùng nghiệp vụ.

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Tóm tắt hội thoại (Ưu tiên: P1)

Người dùng đã đăng nhập gửi nội dung của một hội thoại kèm yêu cầu tóm tắt. Hệ thống xử lý yêu cầu và trả về phần tóm tắt để người dùng có thể đọc ngay.

**Lý do ưu tiên**: Đây là giá trị cốt lõi và là luồng AI đầu tiên cần hoạt động trọn vẹn.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003, FR-004

**Test độc lập**: Gửi một hội thoại hợp lệ bằng người dùng có quyền và xác nhận nhận được một bản tóm tắt tương ứng.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** người dùng đã đăng nhập và nội dung hội thoại không rỗng, **Khi** người dùng yêu cầu tóm tắt, **Thì** hệ thống trả về một bản tóm tắt văn bản cho chính yêu cầu đó.
2. **AC-002**: **Cho trước** yêu cầu tóm tắt đang được gửi, **Khi** dịch vụ AI không thể hoàn thành, **Thì** hệ thống thông báo lỗi rõ ràng và không trả về một bản tóm tắt bị hiểu là hoàn tất.

### US-002 — Nhận phản hồi khi dữ liệu đầu vào không hợp lệ (Ưu tiên: P2)

Người dùng gửi yêu cầu tóm tắt nhưng không cung cấp nội dung hội thoại hợp lệ. Hệ thống chỉ ra rằng người dùng cần bổ sung nội dung trước khi thử lại.

**Lý do ưu tiên**: Phản hồi sớm giúp người dùng tự sửa yêu cầu thay vì chờ xử lý thất bại.

**Liên quan yêu cầu**: FR-005

**Test độc lập**: Gửi yêu cầu thiếu nội dung hội thoại và xác nhận nhận được thông báo hướng dẫn, không có kết quả tóm tắt.

**Acceptance Criteria**:

1. **AC-003**: **Cho trước** người dùng đã đăng nhập, **Khi** gửi yêu cầu tóm tắt có nội dung hội thoại rỗng hoặc chỉ gồm khoảng trắng, **Thì** hệ thống từ chối yêu cầu và nêu rõ nội dung cần được cung cấp.

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Yêu cầu không có nội dung hội thoại bị từ chối với thông báo hướng dẫn.
- **Dữ liệu không hợp lệ**: Nội dung chỉ gồm khoảng trắng bị xem là không hợp lệ và không được xử lý.
- **Không có quyền**: Người chưa được xác thực không được dùng luồng chat AI.
- **Lỗi hệ thống**: Hiển thị thông báo không thể hoàn thành yêu cầu tại thời điểm hiện tại, không tiết lộ thông tin nội bộ.
- **Timeout**: Hiển thị thông báo yêu cầu hết thời gian chờ và cho phép người dùng gửi lại.
- **Dữ liệu bị thay đổi bởi người khác**: Không áp dụng vì MVP xử lý nội dung do người dùng cung cấp trong từng yêu cầu.
- **Người dùng thao tác lặp lại**: Mỗi lần gửi là một yêu cầu tóm tắt độc lập; hệ thống không gộp hay ghi đè kết quả của lần khác.
- **Trường hợp biên khác**: Nếu kết quả AI trống, hệ thống xem yêu cầu là chưa hoàn tất và phản hồi lỗi có thể hành động.

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI cho người dùng đã đăng nhập gửi một yêu cầu tóm tắt kèm nội dung hội thoại.  
  **Liên quan**: US-001, AC-001
- **FR-002** `[P1]`: Hệ thống PHẢI trả về một bản tóm tắt văn bản cho yêu cầu hợp lệ được xử lý thành công.  
  **Liên quan**: US-001, AC-001
- **FR-003** `[P1]`: Hệ thống PHẢI trả về trạng thái lỗi rõ ràng khi không thể hoàn thành yêu cầu tóm tắt.  
  **Liên quan**: US-001, AC-002
- **FR-004** `[P1]`: Hệ thống KHÔNG ĐƯỢC làm thay đổi trải nghiệm gửi yêu cầu và nhận kết quả của người dùng khi dịch vụ mô hình AI nền được thay thế.  
  **Liên quan**: US-001, AC-001
- **FR-005** `[P2]`: Hệ thống PHẢI từ chối yêu cầu thiếu nội dung hội thoại và hướng dẫn người dùng bổ sung nội dung.  
  **Liên quan**: US-002, AC-003

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Một yêu cầu tóm tắt chỉ được xử lý khi có nội dung hội thoại không rỗng sau khi loại bỏ khoảng trắng đầu và cuối.
- **BR-002**: Kết quả chỉ được xem là thành công khi có nội dung tóm tắt văn bản không rỗng.
- **BR-003**: Mỗi yêu cầu tóm tắt là độc lập; MVP không lưu hoặc dùng lại ngữ cảnh từ yêu cầu trước.

**Luồng trạng thái nếu có**:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| Chờ gửi | Người dùng gửi yêu cầu hợp lệ | Đang xử lý | Người dùng đã đăng nhập và có nội dung hội thoại |
| Đang xử lý | Có bản tóm tắt hợp lệ | Hoàn tất | Kết quả tóm tắt không rỗng |
| Đang xử lý | Không thể xử lý | Thất bại | Có lỗi hoặc hết thời gian chờ |
| Thất bại | Người dùng gửi lại | Đang xử lý | Yêu cầu mới hợp lệ |

---

## 9. Thực thể dữ liệu

- **Yêu cầu tóm tắt**: Nội dung hội thoại và chỉ dẫn tóm tắt do người dùng gửi trong một lần tương tác.
- **Kết quả tóm tắt**: Bản tóm tắt hoặc trạng thái thất bại tương ứng với một yêu cầu tóm tắt.

---

## 10. Phân quyền & Bảo mật

**Ai được xem**:
- Người dùng đã đăng nhập chỉ được xem kết quả của yêu cầu do chính họ gửi trong phiên tương tác hiện tại.

**Ai được thao tác**:
- Người dùng đã đăng nhập được gửi yêu cầu tóm tắt.

**Ai không được phép**:
- Người chưa được xác thực không được gửi yêu cầu hoặc nhận kết quả chat AI.

**Dữ liệu nhạy cảm**:
- Có. Nội dung hội thoại có thể chứa thông tin nghiệp vụ hoặc cá nhân; thông báo lỗi không được tiết lộ dữ liệu này hay chi tiết vận hành nội bộ.

- **SEC-001**: Hệ thống PHẢI kiểm tra quyền trước khi cho phép gửi yêu cầu tóm tắt.
- **SEC-002**: Hệ thống KHÔNG ĐƯỢC cho người dùng truy cập kết quả hoặc nội dung ngoài phạm vi yêu cầu của họ.

---

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Không áp dụng cho MVP vì không có thao tác quản trị, phê duyệt hoặc thay đổi dữ liệu lưu trữ.

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: Trong điều kiện tải thông thường, ít nhất 95% yêu cầu tóm tắt hoàn tất hoặc trả về trạng thái lỗi rõ ràng trong vòng 30 giây.
- **NFR-002**: Tính năng không làm gián đoạn các luồng nghiệp vụ không sử dụng AI hiện có.
- **NFR-003**: Thông báo lỗi không chứa nội dung hội thoại, thông tin xác thực hoặc chi tiết nội bộ của dịch vụ mô hình.

---

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: Ít nhất 95% yêu cầu tóm tắt hợp lệ trong điều kiện tải thông thường trả về kết quả hoặc trạng thái lỗi rõ ràng trong vòng 30 giây.
- **SC-002**: 100% yêu cầu thiếu nội dung hội thoại bị từ chối trước khi tạo kết quả tóm tắt.
- **SC-003**: Người dùng có thể hoàn thành luồng gửi yêu cầu và đọc kết quả tóm tắt trong một lần tương tác, không cần chọn hoặc hiểu dịch vụ mô hình nền.

---

## 14. Giả định & Ràng buộc

**Giả định**:
- Người dùng đã có cơ chế đăng nhập hợp lệ của hệ thống.
- Người dùng cung cấp nội dung hội thoại mà họ được phép xử lý.
- MVP chỉ cần kết quả văn bản bằng ngôn ngữ phù hợp với nội dung đầu vào.

**Ràng buộc**:
- Phạm vi chỉ bao gồm tóm tắt hội thoại qua một luồng chat AI cơ bản.
- Hành vi nghiệp vụ phải giữ ổn định khi thay đổi dịch vụ mô hình AI nền.

---

## 15. Ngoài phạm vi

- Lưu trữ, tìm kiếm hoặc quản lý lịch sử hội thoại và kết quả tóm tắt.
- Chat nhiều lượt, streaming kết quả, tải tệp đính kèm và tạo tác vụ AI khác.
- Quản trị mô hình AI, cấu hình nhà cung cấp, đánh giá chất lượng mô hình hoặc chuyển đổi nhà cung cấp trong giao diện người dùng.

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Dịch vụ mô hình phản hồi chậm hoặc không sẵn sàng | Trung | Cao | Trả trạng thái lỗi hoặc hết thời gian chờ rõ ràng để người dùng có thể thử lại |
| Nội dung đầu vào chứa dữ liệu nhạy cảm | Trung | Cao | Kiểm soát truy cập và không đưa dữ liệu nhạy cảm vào thông báo lỗi |
| Bản tóm tắt không đáp ứng kỳ vọng người dùng | Trung | Trung | Giới hạn MVP ở luồng đơn giản và thu thập phản hồi trước khi mở rộng tác vụ |

---

## 17. Phụ thuộc

- Phụ thuộc vào cơ chế xác thực hiện có để xác định người dùng được phép sử dụng tính năng.
- Phụ thuộc vào một dịch vụ mô hình AI sẵn sàng xử lý yêu cầu tóm tắt trong môi trường triển khai.

---

## 18. Câu hỏi mở

Không có câu hỏi mở chặn lập plan. Các quyết định về nhà cung cấp mô hình, giao diện kỹ thuật và cấu trúc ứng dụng thuộc plan kỹ thuật.

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
