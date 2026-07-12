# Đặc tả tính năng: Chuẩn hóa requirements template

**Branch**: `000007-requirements-template`
**Ngày tạo**: 2026-07-12
**Trạng thái**: Bản nháp
**Người phụ trách**: Luyện Hải Đăng
**Stakeholder xác nhận**: Luyện Hải Đăng
**Đầu vào**: Cập nhật, cải tiến bộ requirements-template.md

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 0. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

Khi tạo feature mới, `$speckit-specify` sinh `checklists/requirements.md` theo nội dung cố định trong skill thay vì theo template checklist của workspace. Artifact sinh ra thiếu cấu trúc review, mã item, mức độ nghiêm trọng, trạng thái từng item và kết luận chuyển bước; đồng thời vai trò của nó dễ bị nhầm với checklist tùy biến do `$speckit-checklist` tạo.

**Tổng quan tính năng**:

Chuẩn hóa một requirements template dành riêng cho quality gate của spec. Người soạn và reviewer nhận được một checklist nhất quán, có thể truy vết và hỗ trợ quyết định chuyển từ spec sang bước tiếp theo, trong khi checklist theo domain vẫn độc lập.

---

## 1. Mục tiêu

- **MT-001**: Mọi feature mới có requirements checklist nhất quán với quy ước template của workspace.
- **MT-002**: Reviewer xác định được trạng thái, mức độ và bằng chứng của từng tiêu chí chất lượng spec.
- **MT-003**: Phân biệt rõ quality gate bắt buộc của spec với checklist tùy biến theo domain.

---

## 2. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Có requirements template riêng để sinh `checklists/requirements.md` cho feature mới.
- **MVP-002**: Checklist có metadata review, item định danh duy nhất, trạng thái, severity, tham chiếu và kết luận chuyển bước.
- **MVP-003**: Checklist kiểm các tiêu chí chất lượng spec cốt lõi và ghi nhận kết quả đánh giá thay vì chỉ đánh dấu hoàn tất hình thức.

---

## 3. Người dùng & Bối cảnh

**Người dùng chính**: Người soạn spec và reviewer Speckit.

**Bối cảnh sử dụng**: Ngay sau khi tạo hoặc cập nhật spec, trước khi chuyển sang `$speckit-clarify` hoặc `$speckit-plan`.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Kỹ thuật.

---

## 4. Kịch bản người dùng *(bắt buộc)*

### US-001 — Đánh giá chất lượng spec (Ưu tiên: P1)

Người soạn tạo feature mới và nhận requirements checklist đã có cấu trúc chuẩn. Họ biết tiêu chí nào pass, fail hoặc không áp dụng, cùng căn cứ liên quan trong spec.

**Lý do ưu tiên**: Đây là giá trị chính để checklist thực sự là quality gate.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003

**Test độc lập**: Tạo một feature mới và kiểm tra requirements checklist có đủ metadata, item định danh, trạng thái và tham chiếu.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** một spec mới, **Khi** requirements checklist được tạo, **Thì** mỗi tiêu chí kiểm tra có mã duy nhất, severity và trạng thái đánh giá.
2. **AC-002**: **Cho trước** một tiêu chí không đạt, **Khi** reviewer ghi nhận kết quả, **Thì** checklist thể hiện phát hiện, ảnh hưởng, đề xuất và tham chiếu phù hợp.

---

### US-002 — Quyết định chuyển bước (Ưu tiên: P1)

Reviewer xem kết quả tổng hợp của requirements checklist để biết feature có được chuyển sang bước làm rõ hoặc lập plan hay không.

**Lý do ưu tiên**: Không có kết luận rõ ràng thì checklist không ngăn được spec chưa đủ điều kiện.

**Liên quan yêu cầu**: FR-004, FR-005

**Test độc lập**: Đánh giá một checklist có item Blocker fail và xác nhận kết luận yêu cầu cập nhật spec trước khi chuyển bước.

**Acceptance Criteria**:

1. **AC-003**: **Cho trước** có item Blocker fail, **Khi** tổng hợp checklist, **Thì** kết quả là Fail và không cho phép chuyển bước.
2. **AC-004**: **Cho trước** không còn item Blocker hoặc High fail, **Khi** tổng hợp checklist, **Thì** checklist nêu rõ bước tiếp theo được phép thực hiện.

---

## 5. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Nếu chưa có spec, requirements checklist không được tạo hoặc đánh giá.
- **Dữ liệu không hợp lệ**: Item thiếu mã, trạng thái hoặc nội dung kiểm tra cụ thể phải được coi là chưa hợp lệ.
- **Không có quyền**: Không áp dụng; quyền thao tác theo quy tắc repository hiện có.
- **Lỗi hệ thống**: Không được ghi nhận checklist là Pass nếu không đánh giá được spec.
- **Timeout**: Không áp dụng.
- **Dữ liệu bị thay đổi bởi người khác**: Lần review phải ghi rõ trạng thái và thời điểm để tránh nhầm lẫn kết quả cũ.
- **Người dùng thao tác lặp lại**: Sinh lại checklist không được tạo mã item trùng trong cùng checklist.
- **Trường hợp biên khác**: Checklist domain do `$speckit-checklist` tạo không bị thay thế bởi requirements checklist.

---

## 6. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI có requirements template riêng cho quality gate của `spec.md`. **Liên quan**: US-001, AC-001
- **FR-002** `[P1]`: Requirements checklist PHẢI ghi metadata về mục đích, artifact được kiểm, lần review, người review và trạng thái review. **Liên quan**: US-001, AC-001
- **FR-003** `[P1]`: Mỗi item PHẢI có mã duy nhất, severity, trạng thái và tham chiếu hoặc marker gap phù hợp. **Liên quan**: US-001, AC-001, AC-002
- **FR-004** `[P1]`: Checklist PHẢI tổng hợp kết quả Pass, Fail và Không áp dụng, đồng thời nêu điều kiện chuyển bước tiếp theo. **Liên quan**: US-002, AC-003, AC-004
- **FR-005** `[P2]`: Hệ thống PHẢI giữ checklist tùy biến theo domain là artifact độc lập với requirements checklist. **Liên quan**: US-001, AC-001

---

## 7. Quy tắc nghiệp vụ

- **BR-001**: Item Blocker fail chặn chuyển sang bước tiếp theo, trừ khi có ngoại lệ được phê duyệt.
- **BR-002**: Mỗi item chỉ kiểm một vấn đề chất lượng của requirement, không kiểm hành vi implementation.
- **BR-003**: Checklist quality gate của spec không thay thế checklist tùy biến cho security, UX hoặc domain khác.

**Luồng trạng thái nếu có**:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| Chưa review | Đánh giá item | Pass / Fail / Không áp dụng | Có bằng chứng hoặc lý do phù hợp |
| Fail | Cập nhật spec và đánh giá lại | Pass / Fail | Phát hiện được xử lý hoặc có ngoại lệ |
| Pass | Tổng hợp gate | Được chuyển bước | Không có Blocker hoặc High fail |

---

## 8. Thực thể dữ liệu

- **Requirements checklist**: Artifact ghi nhận đánh giá chất lượng của một `spec.md`.
- **Checklist item**: Tiêu chí đánh giá có mã, severity, trạng thái và tham chiếu.
- **Ngoại lệ review**: Chấp thuận có chủ đích cho một item chưa đạt, có người phê duyệt và rủi ro được chấp nhận.

---

## 9. Phân quyền & Bảo mật

**Ai được xem**:
- Thành viên tham gia soạn, review hoặc lập plan cho feature.

**Ai được thao tác**:
- Người soạn spec và reviewer được giao.

**Ai không được phép**:
- Không có quy tắc phân quyền riêng ngoài repository hiện có.

**Dữ liệu nhạy cảm**:
- Không; checklist không được ghi secret hoặc thông tin xác thực.

- **SEC-001**: Hệ thống KHÔNG ĐƯỢC đưa secret, mật khẩu, khóa API hoặc connection string vào checklist.

---

## 10. Audit & Lịch sử thay đổi

**Có cần audit không**: Có, ở mức metadata lần review và ngoại lệ được phê duyệt.

Nếu có, hệ thống PHẢI ghi nhận:

- Người review
- Lần review
- Trạng thái và kết luận
- Ngoại lệ được phê duyệt nếu có

---

## 11. Yêu cầu phi chức năng

- **NFR-001**: Toàn bộ nội dung người đọc trong requirements template phải dùng tiếng Việt có dấu.
- **NFR-002**: Requirements checklist phải giữ Markdown hợp lệ và dễ đọc trong Markdown preview.

---

## 12. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: 100% requirements checklist tạo sau thay đổi có metadata, mã item, severity, trạng thái và kết luận chuyển bước.
- **SC-002**: 100% item Blocker fail được thể hiện là chặn chuyển bước, trừ khi có ngoại lệ được ghi nhận.
- **SC-003**: Người review xác định được artifact chính, kết quả tổng hợp và hành động tiếp theo trong không quá 1 phút.

---

## 13. Giả định & Ràng buộc

**Giả định**:
- `requirements.md` tiếp tục là tên artifact quality gate mặc định của spec.
- Checklist tùy biến vẫn được tạo qua `$speckit-checklist` với tên theo domain.

**Ràng buộc**:
- Không tự động sửa hoặc chuyển đổi requirements checklist đã tồn tại.
- Thay đổi template/runtime phải cập nhật tài liệu Speckit liên quan.

---

## 14. Ngoài phạm vi

- Thay đổi nội dung nghiệp vụ trong các `spec.md` hiện có.
- Tạo hoặc thay thế checklist theo domain như security, UX hoặc release.
- Tự động phê duyệt ngoại lệ review.

---

## 15. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Checklist mới quá dài khiến review hình thức | Trung | Trung | Ưu tiên item có rủi ro và traceability rõ ràng |
| Nhầm lẫn với checklist domain | Trung | Trung | Ghi rõ mục đích và ranh giới artifact |
| Artifact cũ không đồng nhất với template mới | Cao | Thấp | Không tự động migrate; chỉ áp dụng cho feature mới |

---

## 16. Phụ thuộc

- Quy ước checklist và traceability hiện hành trong workspace.
- Tài liệu hướng dẫn bảo trì template Speckit.

---

## 17. Câu hỏi mở

- Không có câu hỏi mở blocker. Quyết định chi tiết về danh sách item và cấu trúc template thuộc bước lập plan.

---

## 18. Điều kiện sẵn sàng để lập plan kỹ thuật

- [x] Vấn đề cần giải quyết đã rõ.
- [x] MVP đã được xác định.
- [x] Luồng P1 có Acceptance Criteria đầy đủ.
- [x] Yêu cầu chức năng chính đã có ID.
- [x] Quy tắc nghiệp vụ quan trọng đã được ghi nhận.
- [x] Phân quyền/bảo mật đã rõ hoặc được đánh dấu là câu hỏi mở.
- [x] Ngoài phạm vi đã rõ.
- [x] Các câu hỏi mở quan trọng đã được trả lời hoặc được chấp nhận là rủi ro.
