# Đặc tả tính năng: [TÊN TÍNH NĂNG]

**Branch**: `[NNNNNN-ten-tinh-nang]`

**Ngày tạo**: [NGÀY]

**Trạng thái**: Bản nháp

**Đầu vào**: Mô tả người dùng: "$ARGUMENTS"

---

## 0. Tổng quan

<!--
  Mô tả ngắn gọn tính năng là gì, tại sao cần làm, và ai được hưởng lợi.
  Viết cho người đọc không có kỹ thuật hiểu được.
-->

[Mô tả tổng quan tính năng trong 2-4 câu. Trả lời: Cái gì? Tại sao? Cho ai?]

---

## 1. Mục tiêu

<!--
  Liệt kê các mục tiêu cụ thể, có thể đo lường.
  Không phải tính năng — mà là kết quả mong muốn.
-->

- **MĐ-01**: [Mục tiêu 1 — kết quả cụ thể cho người dùng]
- **MĐ-02**: [Mục tiêu 2 — kết quả cụ thể cho hệ thống hoặc nghiệp vụ]
- **MĐ-03**: [Mục tiêu 3 — nếu có]

---

## 2. Người dùng & Bối cảnh

<!--
  Ai sẽ dùng tính năng này? Trong hoàn cảnh nào?
  Không cần nhiều persona — chỉ những người dùng thực sự liên quan.
-->

**Người dùng chính**: [Vai trò, ví dụ: "Nhân viên kế toán", "Quản trị viên hệ thống"]

**Bối cảnh sử dụng**: [Khi nào, ở đâu, điều kiện gì người dùng cần tính năng này]

**Trình độ kỹ thuật**: [Mức độ am hiểu công nghệ của người dùng]

---

## 3. Kịch bản người dùng *(bắt buộc)*

<!--
  Ưu tiên theo thứ tự quan trọng. Mỗi kịch bản phải:
  - Có thể test độc lập
  - Mang lại giá trị độc lập nếu chỉ implement mình nó (MVP)
-->

### Kịch bản 1 — [Tiêu đề ngắn] (Ưu tiên: P1)

[Mô tả hành trình người dùng bằng ngôn ngữ đời thường]

**Lý do ưu tiên**: [Giải thích giá trị và lý do có mức ưu tiên này]

**Test độc lập**: [Mô tả cách test kịch bản này mà không cần kịch bản khác]

**Acceptance Scenarios**:

1. **Cho trước** [trạng thái ban đầu], **Khi** [hành động], **Thì** [kết quả mong đợi]
2. **Cho trước** [trạng thái ban đầu], **Khi** [hành động], **Thì** [kết quả mong đợi]

---

### Kịch bản 2 — [Tiêu đề ngắn] (Ưu tiên: P2)

[Mô tả hành trình người dùng bằng ngôn ngữ đời thường]

**Lý do ưu tiên**: [Giải thích giá trị]

**Test độc lập**: [Mô tả cách test độc lập]

**Acceptance Scenarios**:

1. **Cho trước** [trạng thái ban đầu], **Khi** [hành động], **Thì** [kết quả mong đợi]

---

### Trường hợp biên

- Điều gì xảy ra khi [điều kiện biên]?
- Hệ thống xử lý thế nào khi [tình huống lỗi]?

---

## 4. Yêu cầu chức năng *(bắt buộc)*

<!--
  Mỗi yêu cầu phải:
  - Có thể test được và không mơ hồ
  - Tập trung vào WHAT (cái gì), không phải HOW (cách nào)
  - Dùng PHẢI/KHÔNG ĐƯỢC thay vì "nên"
-->

- **YC-001**: Hệ thống PHẢI [khả năng cụ thể]
- **YC-002**: Hệ thống PHẢI [khả năng cụ thể]
- **YC-003**: Người dùng PHẢI có thể [tương tác chính]
- **YC-004**: Hệ thống KHÔNG ĐƯỢC [ràng buộc quan trọng]
- **YC-005**: Hệ thống PHẢI [yêu cầu dữ liệu hoặc hành vi]

---

## 5. Yêu cầu phi chức năng

<!--
  Hiệu năng, bảo mật, khả dụng, v.v.
  Phải có thể đo lường — không dùng từ mơ hồ như "nhanh", "ổn định".
  Bỏ section này nếu không có yêu cầu phi chức năng rõ ràng.
-->

- **YCPCK-001**: [Yêu cầu hiệu năng, ví dụ: "Trang tải xong trong vòng 2 giây với kết nối 4G"]
- **YCPCK-002**: [Yêu cầu bảo mật, ví dụ: "Dữ liệu nhạy cảm PHẢI được mã hóa khi lưu trữ"]
- **YCPCK-003**: [Yêu cầu khả dụng, ví dụ: "Tính năng hoạt động trên Chrome, Firefox, Edge phiên bản mới nhất"]

---

## 6. Thực thể dữ liệu

<!--
  Bao gồm section này nếu tính năng liên quan đến dữ liệu.
  Mô tả thực thể và quan hệ — không phải schema kỹ thuật.
  Bỏ section này nếu không liên quan.
-->

- **[Thực thể 1]**: [Nó đại diện cho gì, thuộc tính quan trọng không có chi tiết kỹ thuật]
- **[Thực thể 2]**: [Nó đại diện cho gì, quan hệ với thực thể khác]

---

## 7. Tiêu chí thành công *(bắt buộc)*

<!--
  Mỗi tiêu chí phải:
  - Đo lường được: có số liệu cụ thể (thời gian, tỷ lệ, số lượng)
  - Không phụ thuộc công nghệ: không đề cập framework, database, API
  - Tập trung vào người dùng: kết quả từ góc nhìn người dùng/nghiệp vụ

  Tốt: "Người dùng hoàn thành đăng ký trong dưới 3 phút"
  Không tốt: "API response time dưới 200ms" (chi tiết kỹ thuật)
-->

- **TC-001**: [Chỉ số đo lường, ví dụ: "Người dùng hoàn thành luồng chính trong dưới 3 phút"]
- **TC-002**: [Chỉ số đo lường, ví dụ: "90% người dùng hoàn thành task chính trong lần thử đầu tiên"]
- **TC-003**: [Chỉ số nghiệp vụ, ví dụ: "Giảm 50% ticket hỗ trợ liên quan đến [vấn đề X]"]

---

## 8. Giả định & Ràng buộc

<!--
  Liệt kê những gì đang được giả định là đúng.
  Và những ràng buộc cố định không thể thay đổi.
-->

**Giả định**:
- [Giả định về người dùng, ví dụ: "Người dùng có kết nối internet ổn định"]
- [Giả định về phạm vi, ví dụ: "Hệ thống xác thực hiện tại sẽ được tái sử dụng"]
- [Giả định về môi trường, ví dụ: "Mobile không nằm trong phạm vi v1"]

**Ràng buộc**:
- [Ràng buộc cố định, ví dụ: "PHẢI tương thích với hệ thống kế thừa X"]
- [Ràng buộc thời gian hoặc nguồn lực nếu có]

---

## 9. Ngoài phạm vi

<!--
  Liệt kê rõ ràng những gì KHÔNG thuộc tính năng này.
  Giúp tránh scope creep và làm rõ ranh giới.
-->

- [Tính năng/trường hợp không thuộc phạm vi này]
- [Tính năng/trường hợp không thuộc phạm vi này]

---

## 10. Rủi ro

<!--
  Những rủi ro có thể ảnh hưởng đến việc deliver tính năng.
  Bỏ section này nếu không có rủi ro đáng kể.
-->

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| [Mô tả rủi ro] | Cao/Trung/Thấp | Cao/Trung/Thấp | [Cách giảm thiểu] |

---

## 11. Phụ thuộc

<!--
  Tính năng này phụ thuộc vào gì để hoạt động?
  Service, team, quyết định, tính năng khác.
  Bỏ section này nếu không có phụ thuộc rõ ràng.
-->

- [Phụ thuộc vào service/API/team X để có Y]
- [Cần quyết định từ stakeholder về Z trước khi bắt đầu]

---

## 12. Câu hỏi mở

<!--
  Những điều chưa rõ cần làm rõ trước khi plan kỹ thuật.
  Tối đa 3 câu hỏi — đặt câu hỏi có tác động lớn nhất.
  Dùng [CẦN LÀM RÕ: câu hỏi cụ thể] trong spec nếu chưa có câu trả lời.
-->

- [CẦN LÀM RÕ: Câu hỏi 1 — tác động đến phạm vi hoặc UX]
- [CẦN LÀM RÕ: Câu hỏi 2 — tác động đến bảo mật hoặc dữ liệu]
