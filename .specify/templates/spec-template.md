# Đặc tả tính năng: [TÊN TÍNH NĂNG]

**Branch**: `[NNNNNN-ten-tinh-nang]`  
**Ngày tạo**: [NGÀY]  
**Chế độ Spec**: [Full / Compact]  
**Trạng thái**: Bản nháp  
**Ngày reconcile cuối**: Chưa reconcile  
**Người phụ trách**: {{GIT_USER_NAME}}  
**Stakeholder xác nhận**: {{GIT_USER_NAME}}  
**Đầu vào**: [Tóm tắt mong muốn người dùng trong 1-2 câu]

<!-- Lifecycle Trạng thái: Bản nháp (/speckit-specify) -> Đang triển khai (/speckit-implement) -> Hoàn thành (/speckit-converge sau khi 0 gap + Reconcile + Final Specialist Review pass; hoặc sửa tay: Đã thay thế bởi <feature-id>). Spec chỉ mô tả WHY + WHAT; HOW thuộc plan.md. Giữ đủ các đề mục §1–§20; mục không liên quan ghi "Không áp dụng — <lý do ngắn>". -->

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết kỹ thuật (HOW) thuộc về `plan.md`.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:
[Vấn đề hiện tại, tác động nghiệp vụ/người dùng và lý do cần làm lúc này — viết cho người không chuyên kỹ thuật.]

**Tổng quan tính năng**:
[Mô tả ngắn 2–4 câu: cái gì, tại sao, cho ai.]

---

## 2. Mục tiêu

- **MT-001**: [Kết quả cụ thể, đo lường được cho người dùng/nghiệp vụ]
- **MT-002**: [Kết quả cụ thể thứ 2 — nếu có]

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: [Khả năng tối thiểu 1 tạo ra giá trị]
- **MVP-002**: [Khả năng tối thiểu 2 / giới hạn phạm vi rõ ràng của v1]

---

## 4. Người dùng & Bối cảnh

- **Người dùng chính**: [Vai trò cụ thể]
- **Bối cảnh sử dụng**: [Khi nào, ở điều kiện nào cần tính năng này]
- **Mức độ am hiểu hệ thống/nghiệp vụ**: [Không chuyên / Người dùng nghiệp vụ / Quản trị viên / Kỹ thuật]

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — [Tiêu đề ngắn] (Ưu tiên: P1)

[Hành trình người dùng bằng ngôn ngữ đời thường — có thể test và mang lại giá trị độc lập.]

- **Lý do ưu tiên**: [Giá trị cốt lõi]
- **Liên quan yêu cầu**: FR-001, FR-002
- **Test độc lập**: [Cách xác minh kịch bản này độc lập]

**Acceptance Criteria**:
1. **AC-001**: **Cho trước** [trạng thái đầu], **Khi** [hành động], **Thì** [kết quả mong đợi]
2. **AC-002**: **Cho trước** [trạng thái đầu], **Khi** [hành động], **Thì** [kết quả mong đợi]

<!-- Chỉ thêm US-002 (P2), US-003 (P3)... khi tính năng thực sự có kịch bản độc lập tiếp theo. -->

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: [Mô tả hoặc "Không áp dụng"]
- **Dữ liệu không hợp lệ**: [Mô tả hoặc "Không áp dụng"]
- **Không có quyền**: [Mô tả hoặc "Không áp dụng"]
- **Lỗi hệ thống / Timeout**: [Mô tả hoặc "Không áp dụng"]
- **Xung đột / Thao tác lặp lại**: [Mô tả đồng thời/nhấn lặp hoặc "Không áp dụng"]
- **Trường hợp biên khác**: [Mô tả hoặc "Không áp dụng"]

---

## 7. Yêu cầu chức năng *(bắt buộc)*

<!-- Mỗi FR phải kiểm thử được, dùng PHẢI / KHÔNG ĐƯỢC và trace về US/AC. -->

- **FR-001** `[P1]`: Hệ thống PHẢI [khả năng cụ thể]. *(Liên quan: US-001, AC-001)*
- **FR-002** `[P1]`: Hệ thống KHÔNG ĐƯỢC [ràng buộc quan trọng]. *(Liên quan: US-001, AC-002)*

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: [Quy tắc nghiệp vụ bắt buộc — điều kiện, trạng thái, trùng lặp, từ chối...]

**Luồng trạng thái** *(ghi "Không áp dụng" nếu không có máy trạng thái)*:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| [A hoặc "Không áp dụng"] | [Hành động] | [B] | [Điều kiện] |

---

## 9. Thực thể dữ liệu

<!-- Chỉ nêu ý nghĩa nghiệp vụ và quan hệ; không ghi bảng DB, kiểu cột hay payload API. -->

- **[Thực thể 1]**: [Ý nghĩa nghiệp vụ, thuộc tính chính và quan hệ — hoặc ghi "Không áp dụng — lý do ngắn"]

---

## 10. Phân quyền & Bảo mật

- **Ai được xem / thao tác**: [Vai trò được xem, tạo, sửa, xóa, duyệt]
- **Ai bị chặn**: [Vai trò/phạm vi không được phép]
- **Dữ liệu nhạy cảm**: [Có/Không — mô tả mức nghiệp vụ]
- **SEC-001**: Hệ thống PHẢI kiểm tra quyền và phạm vi dữ liệu trước khi thực hiện thao tác.

---

## 11. Audit & Lịch sử thay đổi

- **Có cần audit không**: [Có / Không áp dụng — nêu lý do ngắn. Nếu Có: ghi rõ Ai, Thao tác gì, Thời điểm, Dữ liệu trước/sau, Lý do.]

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: [Chỉ ghi điều kiện chấp nhận đo lường được từ nghiệp vụ/hệ thống hiện có, hoặc ghi "Không áp dụng — dùng chuẩn mặc định hệ thống"]

---

## 13. Tiêu chí thành công *(bắt buộc)*

<!-- Đo lường được, không phụ thuộc công nghệ (không nêu framework/DB/API latency nội bộ). -->

- **SC-001**: [Chỉ số kết quả người dùng/nghiệp vụ cụ thể]

---

## 14. Giả định & Ràng buộc

- **Giả định**: [Điều đang mặc định là đúng]
- **Ràng buộc**: [Điều kiện cố định từ nghiệp vụ hoặc hệ thống hiện hữu]

---

## 15. Ngoài phạm vi

- [Hạng mục/kịch bản chủ đích không làm trong phiên bản này để chống scope creep]

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp giảm thiểu |
|--------|----------|----------|----------------------|
| [Mô tả hoặc "Không áp dụng"] | Cao/Trung/Thấp | Cao/Trung/Thấp | [Biện pháp] |

---

## 17. Phụ thuộc

- [Phụ thuộc nghiệp vụ/hệ thống hiện có hoặc quyết định từ stakeholder — hoặc "Không áp dụng"]

---

## 18. Câu hỏi mở

<!-- Tối đa 3 marker [CẦN LÀM RÕ: ...] cho các điểm chặn scope, bảo mật, dữ liệu hoặc UX chính. Ghi "Không có" nếu đã rõ. -->

- [Không có — hoặc `[CẦN LÀM RÕ: câu hỏi cụ thể]`]

---

## Clarifications

<!-- Do /speckit-clarify quản lý (`### Session YYYY-MM-DD` -> `- Q: ... → A: ...`). Khi trả lời xong mục ở §18, thay marker bằng `[ĐÃ LÀM RÕ → Clarifications / Session YYYY-MM-DD]`. -->

---

## 19. Điều kiện sẵn sàng để lập plan kỹ thuật

<!-- Chi tiết 16 tiêu chí chất lượng được chấm tại checklists/requirements.md (tránh lặp lại tại đây). -->

- [ ] Quality gate tại `checklists/requirements.md` đạt `Pass` hoặc `Pass có điều kiện`.
- [ ] Mọi câu hỏi mở chặn phạm vi/dữ liệu/bảo mật tại §18 đã được giải quyết hoặc ghi nhận ngoại lệ.
- [ ] Đánh giá tác động tài liệu nghiệp vụ (§20) đã hoàn tất (không còn `CHƯA ĐÁNH GIÁ`).

---

## 20. Đánh giá tác động tài liệu nghiệp vụ

<!-- Gate bắt buộc do /speckit-docbiz cập nhật sau lần sửa cuối của spec.md và trước /speckit-plan. -->

- **Trạng thái**: CHƯA ĐÁNH GIÁ
- **Căn cứ**: [Section/spec fact chứng minh có hoặc không có tác động nghiệp vụ đáng kể]
- **Tài liệu đã cập nhật**: [Path tài liệu hiện hữu, hoặc "Không áp dụng"]
