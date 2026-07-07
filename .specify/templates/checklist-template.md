# Checklist [LOẠI CHECKLIST]: [TÊN TÍNH NĂNG]

**Mục đích**: [Mô tả ngắn gọn phạm vi checklist này kiểm tra]
**Ngày tạo**: [DATE]
**Tính năng**: [Link tới spec.md hoặc tài liệu liên quan]

**Ghi chú**: Checklist này được sinh bởi lệnh `/speckit-checklist` dựa trên bối cảnh và yêu cầu của tính năng.

<!--
  ============================================================================
  QUY TẮC NGÔN NGỮ

  Nội dung người dùng đọc và review PHẢI dùng tiếng Việt có dấu. Giữ nguyên
  các định danh kỹ thuật như command, file path, package, API, framework,
  Markdown checkbox, mã `CHK###`, marker `[Gap]`, `[Spec §X]`, `[Ambiguity]`,
  `[Conflict]`, `[Assumption]`.

  Checklist kiểm tra chất lượng requirement, không kiểm thử implementation.
  Mỗi item nên hỏi liệu requirement đã đầy đủ, rõ ràng, nhất quán, đo được
  và bao phủ đủ tình huống hay chưa.

  Các item bên dưới chỉ là VÍ DỤ MINH HỌA.

  Lệnh /speckit-checklist PHẢI thay thế chúng bằng item thực tế dựa trên:
  - Yêu cầu checklist cụ thể của người dùng
  - Requirement trong spec.md
  - Bối cảnh kỹ thuật trong plan.md
  - Chi tiết triển khai trong tasks.md

  KHÔNG giữ các item ví dụ này trong checklist sinh ra.
  ============================================================================
-->

## [Nhóm kiểm tra 1]

- [ ] CHK001 Requirement liên quan đã được mô tả đầy đủ cho tình huống chính chưa? [Completeness, Spec §X]
- [ ] CHK002 Thuật ngữ dễ gây hiểu nhầm đã được định nghĩa bằng tiêu chí rõ ràng chưa? [Clarity]
- [ ] CHK003 Các requirement trong cùng phạm vi có nhất quán với nhau không? [Consistency]

## [Nhóm kiểm tra 2]

- [ ] CHK004 Tiêu chí chấp nhận có thể đo lường hoặc xác minh khách quan không? [Measurability]
- [ ] CHK005 Các trường hợp biên quan trọng đã được nêu trong requirement chưa? [Coverage, Gap]
- [ ] CHK006 Giả định hoặc phụ thuộc bên ngoài đã được ghi rõ và kiểm chứng chưa? [Assumption]

## Ghi chú

- Đánh dấu item đã hoàn thành bằng `[x]`
- Thêm nhận xét hoặc phát hiện trực tiếp bên dưới item liên quan
- Liên kết tới tài liệu hoặc artifact liên quan khi cần
- Item được đánh số tuần tự để dễ tham chiếu
