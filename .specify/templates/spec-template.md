# Đặc tả tính năng: [TÊN TÍNH NĂNG]

**Branch**: `[NNNNNN-ten-tinh-nang]`

**Ngày tạo**: [NGÀY]

**Trạng thái**: Bản nháp

**Người phụ trách**: [Tên người viết/owner]

**Stakeholder xác nhận**: [PO/BA/Khách hàng/Team liên quan]

**Đầu vào**: Mô tả người dùng: "$ARGUMENTS"

---

## Nguyên tắc phạm vi

<!--
  Spec này chỉ mô tả WHY và WHAT:
  - WHY: vấn đề cần giải quyết, lý do cần làm, giá trị mong đợi.
  - WHAT: hành vi, kết quả, phạm vi, điều kiện chấp nhận ở góc nhìn người dùng/nghiệp vụ.
  - HOW thuộc về plan kỹ thuật: kiến trúc, framework, database, API, schema, implementation.

  Chỉ đưa ràng buộc kỹ thuật vào spec nếu đó là điều kiện bắt buộc từ nghiệp vụ
  hoặc từ hệ thống hiện có và ảnh hưởng trực tiếp đến phạm vi/chấp nhận tính năng.
-->

[Xác nhận ngắn: đặc tả này tập trung vào WHY/WHAT; mọi HOW sẽ được xử lý trong plan kỹ thuật.]

---

## 0. Bối cảnh & vấn đề

<!--
  Bắt đầu từ vấn đề thật trước khi mô tả tính năng.
  Trả lời: Hiện tại người dùng gặp vấn đề gì? Hậu quả là gì? Vì sao cần làm bây giờ?
  Sau đó mô tả ngắn gọn tính năng là gì và ai được hưởng lợi.
  Viết cho người đọc không có kỹ thuật hiểu được.
  Không mô tả cách triển khai kỹ thuật ở đây.
-->

**Vấn đề cần giải quyết**:

[Mô tả vấn đề hiện tại, tác động đến người dùng/nghiệp vụ, và lý do cần xử lý trong thời điểm này.]

**Tổng quan tính năng**:

[Mô tả tổng quan tính năng trong 2-4 câu. Trả lời: Cái gì? Tại sao? Cho ai?]

---

## 1. Mục tiêu

<!--
  Liệt kê các mục tiêu cụ thể, có thể đo lường.
  Không phải tính năng — mà là kết quả mong muốn.
-->

- **MT-001**: [Mục tiêu 1 — kết quả cụ thể cho người dùng]
- **MT-002**: [Mục tiêu 2 — kết quả cụ thể cho hệ thống hoặc nghiệp vụ]
- **MT-003**: [Mục tiêu 3 — nếu có]

---

## 2. Phạm vi MVP

<!--
  Xác định phiên bản đầu tiên cần tối thiểu những gì để tạo giá trị.
  Chỉ liệt kê phần PHẢI có trong v1/MVP; phần chưa cần đưa sang "Ngoài phạm vi".
  Mục này giúp tránh spec phình to và giúp task generation tập trung.
-->

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: [Khả năng tối thiểu 1 cần có để người dùng nhận được giá trị]
- **MVP-002**: [Khả năng tối thiểu 2 cần có để luồng chính hoàn chỉnh]
- **MVP-003**: [Giới hạn rõ ràng của MVP, ví dụ: chỉ áp dụng cho nhóm người dùng/phạm vi nghiệp vụ X]

---

## 3. Người dùng & Bối cảnh

<!--
  Ai sẽ dùng tính năng này? Trong hoàn cảnh nào?
  Không cần nhiều persona — chỉ những người dùng thực sự liên quan.
-->

**Người dùng chính**: [Vai trò, ví dụ: "Nhân viên kế toán", "Quản trị viên hệ thống"]

**Bối cảnh sử dụng**: [Khi nào, ở đâu, điều kiện gì người dùng cần tính năng này]

**Trình độ kỹ thuật**: [Mức độ am hiểu công nghệ của người dùng]

---

## 4. Kịch bản người dùng *(bắt buộc)*

<!--
  Ưu tiên theo thứ tự quan trọng. Mỗi kịch bản phải:
  - Có thể test độc lập
  - Mang lại giá trị độc lập nếu chỉ implement mình nó (MVP)
  - Liên kết rõ với các yêu cầu chức năng để dễ trace khi test và sinh task
-->

### US-001 — [Tiêu đề ngắn] (Ưu tiên: P1)

[Mô tả hành trình người dùng bằng ngôn ngữ đời thường]

**Lý do ưu tiên**: [Giải thích giá trị và lý do có mức ưu tiên này]

**Liên quan yêu cầu**: FR-001, FR-002

**Test độc lập**: [Mô tả cách test kịch bản này mà không cần kịch bản khác]

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** [trạng thái ban đầu], **Khi** [hành động], **Thì** [kết quả mong đợi]
2. **AC-002**: **Cho trước** [trạng thái ban đầu], **Khi** [hành động], **Thì** [kết quả mong đợi]

---

### US-002 — [Tiêu đề ngắn] (Ưu tiên: P2)

[Mô tả hành trình người dùng bằng ngôn ngữ đời thường]

**Lý do ưu tiên**: [Giải thích giá trị]

**Liên quan yêu cầu**: FR-003

**Test độc lập**: [Mô tả cách test độc lập]

**Acceptance Criteria**:

1. **AC-003**: **Cho trước** [trạng thái ban đầu], **Khi** [hành động], **Thì** [kết quả mong đợi]

---

## 5. Trạng thái dữ liệu, lỗi & thao tác lặp

<!--
  Mô tả phản ứng mong đợi của hệ thống ở các trạng thái phổ biến.
  Tập trung vào kết quả người dùng/nghiệp vụ nhìn thấy, không mô tả implementation.
  Bỏ dòng không liên quan, nhưng không bỏ qua trạng thái có thể xảy ra trong luồng chính.
-->

- **Không có dữ liệu**: [Người dùng thấy gì hoặc có thể làm gì khi chưa có dữ liệu phù hợp]
- **Dữ liệu không hợp lệ**: [Hệ thống báo gì, chặn gì, và người dùng sửa thế nào]
- **Không có quyền**: [Hệ thống phản hồi thế nào khi người dùng không đủ quyền]
- **Lỗi hệ thống**: [Thông báo/kết quả mong đợi khi hệ thống không xử lý được yêu cầu]
- **Timeout**: [Hệ thống phản hồi thế nào khi xử lý quá thời gian cho phép]
- **Dữ liệu bị thay đổi bởi người khác**: [Hệ thống xử lý thế nào khi dữ liệu không còn như lúc người dùng bắt đầu thao tác]
- **Người dùng thao tác lặp lại**: [Hệ thống xử lý thế nào khi người dùng gửi lại cùng một thao tác]
- **Trường hợp biên khác**: [Điều kiện biên quan trọng riêng của tính năng]

---

## 6. Yêu cầu chức năng *(bắt buộc)*

<!--
  Mỗi yêu cầu phải:
  - Có thể test được và không mơ hồ
  - Tập trung vào WHAT (cái gì), không phải HOW (cách nào)
  - Dùng PHẢI/KHÔNG ĐƯỢC thay vì "nên"
-->

- **FR-001**: Hệ thống PHẢI [khả năng cụ thể]
- **FR-002**: Hệ thống PHẢI [khả năng cụ thể]
- **FR-003**: Người dùng PHẢI có thể [tương tác chính]
- **FR-004**: Hệ thống KHÔNG ĐƯỢC [ràng buộc quan trọng]
- **FR-005**: Hệ thống PHẢI [yêu cầu dữ liệu hoặc hành vi]

---

## 7. Quy tắc nghiệp vụ

<!--
  Ghi các quy tắc nghiệp vụ bắt buộc, đặc biệt là quyền, trạng thái, trùng lặp,
  điều kiện chuyển bước, điều kiện khóa/sửa/xóa, và lý do bắt buộc khi từ chối.
  Đây là rule nghiệp vụ, không phải mô tả implementation.
-->

- **BR-001**: [Quy tắc nghiệp vụ bắt buộc 1]
- **BR-002**: [Quy tắc nghiệp vụ bắt buộc 2]
- **BR-003**: [Quy tắc nghiệp vụ bắt buộc 3]

---

## 8. Yêu cầu phi chức năng

<!--
  Hiệu năng, bảo mật, khả dụng, v.v.
  Phải có thể đo lường — không dùng từ mơ hồ như "nhanh", "ổn định".
  Chỉ ghi yêu cầu phi chức năng vào spec khi đó là điều kiện chấp nhận từ nghiệp vụ
  hoặc ràng buộc bắt buộc của hệ thống hiện có. Chi tiết triển khai thuộc plan kỹ thuật.
  Bỏ section này nếu không có yêu cầu phi chức năng rõ ràng.
-->

- **NFR-001**: [Yêu cầu hiệu năng, ví dụ: "Người dùng thấy kết quả trong vòng 2 giây với kết nối 4G"]
- **NFR-002**: [Yêu cầu bảo mật/nghiệp vụ, ví dụ: "Người dùng không có quyền KHÔNG ĐƯỢC xem dữ liệu nhạy cảm"]
- **NFR-003**: [Yêu cầu khả dụng, ví dụ: "Tính năng hoạt động trên các trình duyệt đang được tổ chức hỗ trợ"]

---

## 9. Thực thể dữ liệu

<!--
  Bao gồm section này nếu tính năng liên quan đến dữ liệu.
  Mô tả thực thể nghiệp vụ và quan hệ — không phải schema, table, field type, index, hoặc API payload.
  Bỏ section này nếu không liên quan.
-->

- **[Thực thể 1]**: [Nó đại diện cho gì, thuộc tính quan trọng không có chi tiết kỹ thuật]
- **[Thực thể 2]**: [Nó đại diện cho gì, quan hệ với thực thể khác]

---

## 10. Tiêu chí thành công *(bắt buộc)*

<!--
  Mỗi tiêu chí phải:
  - Đo lường được: có số liệu cụ thể (thời gian, tỷ lệ, số lượng)
  - Không phụ thuộc công nghệ: không đề cập framework, database, API
  - Tập trung vào người dùng: kết quả từ góc nhìn người dùng/nghiệp vụ

  Tốt: "Người dùng hoàn thành đăng ký trong dưới 3 phút"
  Không tốt: "API response time dưới 200ms" (chi tiết kỹ thuật)
-->

- **SC-001**: [Chỉ số đo lường, ví dụ: "Người dùng hoàn thành luồng chính trong dưới 3 phút"]
- **SC-002**: [Chỉ số đo lường, ví dụ: "90% người dùng hoàn thành task chính trong lần thử đầu tiên"]
- **SC-003**: [Chỉ số nghiệp vụ, ví dụ: "Giảm 50% ticket hỗ trợ liên quan đến [vấn đề X]"]

---

## 11. Giả định & Ràng buộc

<!--
  Liệt kê những gì đang được giả định là đúng.
  Và những ràng buộc cố định không thể thay đổi.
  Nếu ràng buộc là kỹ thuật, chỉ đưa vào khi đó là điều kiện bắt buộc từ nghiệp vụ
  hoặc hệ thống hiện có; còn lại để plan kỹ thuật quyết định.
-->

**Giả định**:
- [Giả định về người dùng, ví dụ: "Người dùng có kết nối internet ổn định"]
- [Giả định về phạm vi, ví dụ: "Hệ thống xác thực hiện tại sẽ được tái sử dụng"]
- [Giả định về môi trường, ví dụ: "Mobile không nằm trong phạm vi v1"]

**Ràng buộc**:
- [Ràng buộc cố định, ví dụ: "PHẢI tương thích với hệ thống kế thừa X"]
- [Ràng buộc thời gian hoặc nguồn lực nếu có]

---

## 12. Ngoài phạm vi

<!--
  Liệt kê rõ ràng những gì KHÔNG thuộc tính năng này.
  Giúp tránh scope creep và làm rõ ranh giới.
-->

- [Tính năng/trường hợp không thuộc phạm vi này]
- [Tính năng/trường hợp không thuộc phạm vi này]

---

## 13. Rủi ro

<!--
  Những rủi ro có thể ảnh hưởng đến việc deliver tính năng.
  Bỏ section này nếu không có rủi ro đáng kể.
-->

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| [Mô tả rủi ro] | Cao/Trung/Thấp | Cao/Trung/Thấp | [Cách giảm thiểu] |

---

## 14. Phụ thuộc

<!--
  Tính năng này phụ thuộc vào gì để hoạt động?
  Chỉ ghi service/API/team nếu đó là phụ thuộc bắt buộc từ nghiệp vụ hoặc hệ thống hiện có.
  Không dùng section này để thiết kế tích hợp kỹ thuật; phần đó thuộc plan kỹ thuật.
  Bỏ section này nếu không có phụ thuộc rõ ràng.
-->

- [Phụ thuộc vào hệ thống hiện có hoặc quyết định nghiệp vụ X để có Y]
- [Cần quyết định từ stakeholder về Z trước khi bắt đầu]

---

## 15. Câu hỏi mở

<!--
  Những điều chưa rõ cần làm rõ trước khi plan kỹ thuật.
  Tối đa 3 câu hỏi — đặt câu hỏi có tác động lớn nhất.
  Dùng [CẦN LÀM RÕ: câu hỏi cụ thể] trong spec nếu chưa có câu trả lời.
-->

- [CẦN LÀM RÕ: Câu hỏi 1 — tác động đến phạm vi hoặc UX]
- [CẦN LÀM RÕ: Câu hỏi 2 — tác động đến bảo mật hoặc dữ liệu]
