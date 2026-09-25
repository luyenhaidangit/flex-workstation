# Đặc tả tính năng: Trang Publish Chat với AI Agent

**Branch**: `000042-publish-chat-page`  
**Ngày tạo**: 2026-09-17  
**Trạng thái**: Bản nháp  
**Người phụ trách**: Luyện Hải Đăng  
**Stakeholder xác nhận**: Luyện Hải Đăng  
**Đầu vào**: Xây dựng một trang/địa chỉ riêng trong hệ thống hiện tại để người dùng trò chuyện trực tiếp với AI Agent theo giao diện dạng hội thoại (kiểu ChatGPT); phiên bản đầu tiên chỉ cần chat hoạt động được, chưa cần lưu trữ tin nhắn.

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

Hệ thống hiện đã có khung xem trước chat AI Agent nhúng trong màn cấu hình Agent (`specs/000033-ai-chat-integration`), nhưng đó chỉ là một khung nhỏ gắn liền với màn cấu hình, không phải một trang/địa chỉ độc lập. Người dùng chưa có nơi trò chuyện với AI Agent theo trải nghiệm hội thoại đầy đủ, quen thuộc (dạng như ChatGPT) mà không bị ràng buộc vào ngữ cảnh màn cấu hình. Việc thiếu một địa chỉ chat riêng khiến hệ thống chưa có nền tảng để sau này mở rộng thành trang chat chính thức được "phát hành" cho người dùng sử dụng Agent.

**Tổng quan tính năng**:

Xây dựng một trang mới, có địa chỉ (route) riêng trong hệ thống hiện tại, với giao diện hội thoại toàn màn hình tương tự ChatGPT (khung nhập tin nhắn + khu vực hiển thị hội thoại). Trang cho phép người dùng trò chuyện nhiều lượt với AI Agent và nhận phản hồi thực tế từ model nền của Agent đó. Phiên bản đầu tiên chỉ tập trung vào việc chat hoạt động được; chưa triển khai lưu trữ tin nhắn hay lịch sử hội thoại.

---

## 2. Mục tiêu

- **MT-001**: Người dùng có một trang riêng, đầy đủ màn hình để trò chuyện trực tiếp với AI Agent, độc lập với khung xem trước nhỏ trong màn cấu hình (`specs/000033`).
- **MT-002**: Cuộc trò chuyện trên trang phản ánh đúng phản hồi thực tế từ model nền của Agent, không mô phỏng hay giả lập.
- **MT-003**: Cấu trúc trang cho phép mở rộng sau này (lưu lịch sử, chia sẻ công khai, đa Agent) mà không phải thiết kế lại từ đầu.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Một trang/địa chỉ mới trong hệ thống, hiển thị giao diện hội thoại dạng ChatGPT: khung nhập tin nhắn và khu vực hiển thị tin nhắn phân biệt rõ vai trò người gửi (người dùng/Agent).
- **MVP-002**: Người dùng gửi được nhiều lượt tin nhắn liên tiếp trong một phiên và nhận phản hồi thực tế từ model nền của AI Agent gắn với trang.
- **MVP-003**: Giới hạn MVP — không lưu trữ tin nhắn vào cơ sở dữ liệu, không khôi phục lịch sử sau khi tải lại/rời trang; chưa hỗ trợ đính kèm tệp, chưa tạo mã nhúng/widget để gắn ra ngoài hệ thống, chưa xử lý chia sẻ trang công khai.

---

## 4. Người dùng & Bối cảnh

**Người dùng chính**: [CẦN LÀM RÕ: Đối tượng sử dụng trang chat này — người dùng nội bộ đã đăng nhập hệ thống, hay bất kỳ ai có địa chỉ trang kể cả không cần đăng nhập? Xem chi tiết tại §18.]

**Bối cảnh sử dụng**: Người dùng muốn trò chuyện trực tiếp, nhiều lượt với một AI Agent cụ thể trong một không gian đầy đủ, thay vì khung xem trước nhỏ gắn với màn cấu hình.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Người dùng nghiệp vụ / Quản trị viên.

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Trò chuyện nhiều lượt với AI Agent trên trang riêng (Ưu tiên: P1)

Người dùng mở trang chat, nhập câu hỏi và gửi. Hệ thống hiển thị câu hỏi trong khu vực hội thoại, gửi yêu cầu đến model nền của AI Agent, sau đó hiển thị phản hồi. Người dùng tiếp tục gửi các lượt hỏi tiếp theo trong cùng phiên và nhận phản hồi tương ứng theo đúng ngữ cảnh hội thoại.

**Lý do ưu tiên**: Đây là giá trị cốt lõi của tính năng — cho phép chat thực sự với AI Agent qua một địa chỉ riêng, độc lập với khung xem trước hiện có.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003, FR-004

**Test độc lập**: Mở trang với một Agent khả dụng, gửi liên tiếp 2 câu hỏi khác nhau, xác nhận cả hai lượt hỏi-đáp hiển thị đúng vai trò và đúng thứ tự thời gian.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** Agent khả dụng, **Khi** người dùng nhập và gửi một câu hỏi không rỗng, **Thì** câu hỏi hiển thị là tin nhắn của người dùng và hệ thống gửi yêu cầu đến model nền của Agent.
2. **AC-002**: **Cho trước** một câu hỏi đang chờ phản hồi, **Khi** chưa có kết quả, **Thì** trang hiển thị trạng thái đang xử lý và không cho gửi trùng câu hỏi đó.
3. **AC-003**: **Cho trước** Agent trả lời thành công, **Khi** nhận được phản hồi, **Thì** phản hồi hiển thị là tin nhắn của Agent, tiếp nối đúng thứ tự hội thoại.
4. **AC-004**: **Cho trước** cuộc trò chuyện trong phiên đã có nhiều lượt, **Khi** người dùng tải lại hoặc rời trang, **Thì** lịch sử hội thoại không được khôi phục lại (vì MVP không lưu trữ).

---

### US-002 — Nhận biết khi Agent không sẵn sàng hoặc xảy ra lỗi (Ưu tiên: P2)

Người dùng gửi câu hỏi trong lúc AI Agent chưa sẵn sàng hoặc khi gọi model nền xảy ra lỗi/timeout. Hệ thống thông báo rõ ràng, giữ nguyên các tin nhắn đã có trong phiên hiện tại và cho phép người dùng thử gửi lại.

**Lý do ưu tiên**: Tránh người dùng hiểu nhầm hệ thống bị treo hoặc mất phản hồi khi Agent không thể trả lời.

**Liên quan yêu cầu**: FR-005, FR-006

**Test độc lập**: Mô phỏng Agent lỗi hoặc model không phản hồi, gửi một câu hỏi và xác nhận thông báo lỗi hiển thị rõ ràng, lịch sử phiên vẫn còn, có thể gửi lại.

**Acceptance Criteria**:

1. **AC-005**: **Cho trước** model nền không phản hồi được (lỗi hoặc quá thời gian chờ), **Khi** hệ thống xác định lỗi, **Thì** trang hiển thị thông báo lỗi thân thiện, giữ nguyên các tin nhắn trước đó trong phiên và cho phép người dùng gửi lại.

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Khi mới mở trang, phiên chưa có tin nhắn nào; khu vực hội thoại hiển thị trạng thái trống, mời người dùng bắt đầu.
- **Dữ liệu không hợp lệ**: Không gửi tin nhắn rỗng hoặc chỉ gồm khoảng trắng; nhắc người dùng nhập nội dung hợp lệ.
- **Không có quyền**: [CẦN LÀM RÕ: phụ thuộc câu trả lời cho §18 — nếu trang yêu cầu đăng nhập, người dùng không đủ quyền nhận thông báo từ chối truy cập phù hợp.]
- **Lỗi hệ thống**: Hiển thị thông báo không thể nhận phản hồi từ Agent, không tạo phản hồi giả lập, giữ nguyên tin nhắn hiện có trong phiên.
- **Timeout**: Thông báo Agent chưa phản hồi trong thời gian chờ; người dùng có thể thử gửi lại.
- **Dữ liệu bị thay đổi bởi người khác**: Không áp dụng — MVP không lưu trữ và không chia sẻ phiên giữa nhiều người dùng.
- **Người dùng thao tác lặp lại**: Trong khi một câu hỏi đang chờ phản hồi, hệ thống không cho gửi câu hỏi mới cho tới khi có kết quả hoặc lỗi.
- **Trường hợp biên khác**: Nếu phản hồi từ model không có nội dung hiển thị được, xử lý như một lỗi phản hồi, không hiển thị như câu trả lời thành công rỗng.

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI cung cấp một trang/địa chỉ riêng trong hệ thống hiện tại, hiển thị giao diện hội thoại dạng ChatGPT (khung nhập tin nhắn + khu vực hiển thị hội thoại) để chat với AI Agent.  
  **Liên quan**: US-001, AC-001
- **FR-002** `[P1]`: Hệ thống PHẢI gửi nội dung người dùng nhập đến model nền của AI Agent gắn với trang và trả về phản hồi thực tế của model đó.  
  **Liên quan**: US-001, AC-001, AC-003
- **FR-003** `[P1]`: Hệ thống PHẢI hiển thị tin nhắn người dùng và phản hồi Agent theo đúng vai trò người gửi và đúng thứ tự thời gian trong cùng một phiên trò chuyện.  
  **Liên quan**: US-001, AC-003, AC-004
- **FR-004** `[P1]`: Hệ thống PHẢI hỗ trợ nhiều lượt hỏi-đáp liên tiếp trong cùng một phiên, không giới hạn ở một lượt duy nhất.  
  **Liên quan**: US-001, AC-001
- **FR-005** `[P2]`: Hệ thống PHẢI hiển thị trạng thái đang xử lý trong khi chờ phản hồi và không cho gửi trùng câu hỏi khi đang chờ kết quả.  
  **Liên quan**: US-001, AC-002
- **FR-006** `[P2]`: Hệ thống PHẢI thông báo lỗi rõ ràng khi model nền không phản hồi được hoặc quá thời gian chờ, đồng thời giữ nguyên các tin nhắn đã hiển thị trong phiên.  
  **Liên quan**: US-002, AC-005
- **FR-007** `[P1]`: Hệ thống KHÔNG ĐƯỢC lưu trữ nội dung tin nhắn vào cơ sở dữ liệu hoặc khôi phục lịch sử sau khi tải lại/rời trang trong phạm vi MVP này.  
  **Liên quan**: US-001, AC-004

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Mỗi phiên trò chuyện trên trang chỉ tồn tại trong phạm vi phiên làm việc hiện tại của trình duyệt, không đồng bộ giữa nhiều thiết bị/tab.
- **BR-002**: Chỉ một câu hỏi được ở trạng thái chờ phản hồi tại một thời điểm trong cùng một phiên.
- **BR-003**: Chỉ phản hồi thực tế từ model nền của Agent gắn với trang mới được hiển thị với vai trò Agent; hệ thống không được thay thế bằng phản hồi mô phỏng/giả lập khi không nhận được kết quả.

**Luồng trạng thái nếu có**:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| Sẵn sàng gửi | Người dùng gửi câu hỏi hợp lệ | Đang chờ phản hồi | Agent sẵn sàng |
| Đang chờ phản hồi | Nhận phản hồi hợp lệ | Sẵn sàng gửi | Phản hồi có nội dung |
| Đang chờ phản hồi | Lỗi hoặc quá thời gian chờ | Sẵn sàng gửi | Có thông báo lỗi |

---

## 9. Thực thể dữ liệu

- **Phiên chat publish**: Ngữ cảnh tạm thời chứa các tin nhắn trao đổi trong một lần người dùng mở trang chat; tồn tại trong bộ nhớ của phiên làm việc, không được lưu trữ lâu dài.
- **Tin nhắn chat**: Nội dung câu hỏi hoặc phản hồi, vai trò người gửi (người dùng/Agent), thời điểm hiển thị, trạng thái xử lý; thuộc một phiên chat publish.
- **AI Agent**: Agent hiện có trong danh mục hệ thống (`specs/000026-agent-catalog`), được gắn với trang chat để cung cấp phản hồi.

---

## 10. Phân quyền & Bảo mật

**Ai được xem**:
- [CẦN LÀM RÕ: xem §18 — phụ thuộc vào việc trang là nội bộ hay công khai.]

**Ai được thao tác**:
- [CẦN LÀM RÕ: xem §18 — cùng câu hỏi về đối tượng truy cập.]

**Ai không được phép**:
- Người dùng không thỏa điều kiện truy cập được xác định tại §18 không được xem hoặc gửi tin nhắn trên trang.

**Dữ liệu nhạy cảm**:
- Có. Nội dung câu hỏi/phản hồi có thể chứa thông tin nghiệp vụ; chỉ hiển thị trong phạm vi phiên của người đang thao tác, không chia sẻ giữa các phiên khác nhau.

- **SEC-001**: Hệ thống PHẢI áp dụng nhất quán điều kiện truy cập trang chat (theo kết quả làm rõ tại §18) trước khi cho phép gửi/nhận tin nhắn.
- **SEC-002**: Hệ thống KHÔNG ĐƯỢC cho người dùng truy cập nội dung phiên chat của người dùng khác.

---

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Không áp dụng cho MVP — trang không lưu trữ dữ liệu nên không có gì để ghi nhận audit.

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: Trong điều kiện Agent sẵn sàng và tải thông thường, ít nhất 95% lượt gửi câu hỏi nhận được phản hồi hoặc thông báo lỗi rõ ràng trong vòng 15 giây.
- **NFR-002**: Tính năng không làm gián đoạn khung xem trước hiện có tại màn cấu hình Agent (`specs/000033-ai-chat-integration`) hay luồng phát hành kênh hiện có (`specs/000028-agent-publish-channels`).
- **NFR-003**: Trang hoạt động trên các trình duyệt đang được tổ chức hỗ trợ.

---

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: 100% lượt gửi câu hỏi hợp lệ tạo ra đúng một kết quả nhìn thấy được: phản hồi từ Agent hoặc thông báo lỗi rõ ràng.
- **SC-002**: Ít nhất 95% lượt hỏi với Agent sẵn sàng nhận được phản hồi hoặc thông báo lỗi trong vòng 15 giây.
- **SC-003**: Người dùng thực hiện được tối thiểu 3 lượt hỏi-đáp liên tiếp trong một phiên mà không gặp lỗi giao diện hay mất tin nhắn trước đó.

---

## 14. Giả định & Ràng buộc

**Giả định**:
- Model nền tái sử dụng lớp truy cập AI provider-agnostic đã có từ `specs/000032-ai-chat-basics`.
- Trang chat này là một tính năng độc lập, đầy đủ màn hình, khác với khung xem trước nhỏ đã có tại `specs/000033-ai-chat-integration`; hai tính năng có thể dùng chung cơ chế gọi Agent nhưng khác nhau về vị trí và giao diện hiển thị.
- Agent dùng cho trang chat phải ở trạng thái hoạt động và có model nền hợp lệ để phản hồi.

**Ràng buộc**:
- MVP không triển khai lưu trữ tin nhắn, không tạo mã nhúng/widget để nhúng ra site ngoài hệ thống, không quản lý phiên đa thiết bị.

---

## 15. Ngoài phạm vi

- Lưu trữ, tìm kiếm hoặc khôi phục lịch sử hội thoại sau khi rời/tải lại trang.
- Tạo mã nhúng (embed code) hoặc widget để gắn trang chat vào website/kênh bên ngoài.
- Quản lý hội thoại khách hàng đa kênh, chuyển tiếp nhân viên, gán ticket.
- Hỗ trợ tệp đính kèm, ghi âm hoặc nội dung ngoài văn bản.
- Chia sẻ công khai trang chat ra ngoài hệ thống hiện tại (nếu có nhu cầu, sẽ là feature riêng).

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Model nền không phản hồi kịp hoặc lỗi provider | Trung | Cao | Hiển thị lỗi rõ ràng, cho phép thử lại, không mất tin nhắn đã có trong phiên. |
| Chưa rõ đối tượng truy cập (nội bộ hay công khai) dẫn đến sai phạm vi bảo mật khi lập plan | Trung | Cao | Làm rõ tại `$speckit-clarify` trước khi chuyển sang plan kỹ thuật. |
| Nhầm lẫn phạm vi với khung xem trước đã có ở `specs/000033` | Thấp | Trung | Nêu rõ ranh giới hai tính năng tại mục Giả định. |

---

## 17. Phụ thuộc

- AI Agent và lớp truy cập model nền hiện có (`specs/000032-ai-chat-basics`, `specs/000033-ai-chat-integration`) phải sẵn sàng nhận câu hỏi và trả phản hồi.
- Cơ chế xác thực/phân quyền hiện có của hệ thống (nếu kết quả làm rõ tại §18 yêu cầu đăng nhập) phải xác định được người dùng hợp lệ.
- Danh mục Agent hiện có (`specs/000026-agent-catalog`) để xác định Agent nào được gắn với trang chat.

---

## 18. Câu hỏi mở

- [CẦN LÀM RÕ: Đối tượng được phép truy cập trang chat này là ai — chỉ người dùng nội bộ đã đăng nhập vào hệ thống hiện tại, hay bất kỳ ai có địa chỉ trang (kể cả người dùng bên ngoài, không cần đăng nhập)? Quyết định này ảnh hưởng trực tiếp đến scope, cơ chế xác thực và yêu cầu bảo mật.]
- [CẦN LÀM RÕ: Trang chat gắn với Agent nào — mỗi Agent có một địa chỉ chat riêng (ví dụ gắn theo Agent đã chọn từ danh mục), hay có một địa chỉ chung và người dùng tự chọn Agent trên trang? Quyết định này ảnh hưởng đến cấu trúc địa chỉ và luồng chọn Agent.]

---

## Clarifications

---

## 19. Điều kiện sẵn sàng để lập plan kỹ thuật

- [x] Vấn đề cần giải quyết đã rõ.
- [x] MVP đã được xác định.
- [x] Luồng P1 có Acceptance Criteria đầy đủ.
- [x] Yêu cầu chức năng chính đã có ID.
- [x] Quy tắc nghiệp vụ quan trọng đã được ghi nhận.
- [ ] Phân quyền/bảo mật đã rõ hoặc được đánh dấu là câu hỏi mở. *(Đã đánh dấu câu hỏi mở tại §18, chưa có câu trả lời)*
- [x] Ngoài phạm vi đã rõ.
- [ ] Các câu hỏi mở quan trọng đã được trả lời hoặc được chấp nhận là rủi ro. *(Đang chờ `$speckit-clarify`)*

---

## 20. Đánh giá tác động tài liệu nghiệp vụ

- **Trạng thái**: CHƯA ĐÁNH GIÁ
- **Căn cứ**: [Section/spec fact chứng minh có hoặc không có tác động đáng kể]
- **Tài liệu đã cập nhật**: [Path tài liệu hiện hữu, hoặc "Không áp dụng"]
