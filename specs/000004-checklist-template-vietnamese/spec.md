# Đặc tả tính năng: Sửa template checklist Speckit sang tiếng Việt

**Branch**: `[000004-checklist-template-vietnamese]`

**Ngày tạo**: 2026-07-07

**Trạng thái**: Bản nháp

**Đầu vào**: Mô tả người dùng: "Hiện tại checklist của speckit gen ra đang tiếng anh, tôi cần review lại sử dụng với tiếng việt"

---

## 0. Tổng quan

Template sinh checklist của Speckit hiện vẫn chứa nội dung tiếng Anh, khiến checklist mới tạo ra không nhất quán với quy tắc làm việc của workspace là dùng tiếng Việt có dấu trong trả lời, tài liệu và ghi chú. Tính năng này tập trung sửa nội dung template/hướng dẫn sinh checklist để checklist mới được trình bày bằng tiếng Việt, dễ hiểu cho người dùng trong workspace Flex. Người hưởng lợi chính là người vận hành Speckit và người review tài liệu/tính năng.

---

## 1. Mục tiêu

- **MĐ-01**: 100% checklist mới sinh từ template đã sửa sử dụng tiếng Việt có dấu cho tiêu đề, mô tả, nhóm nội dung, ghi chú và item kiểm tra.
- **MĐ-02**: Người review có thể đọc và xác nhận checklist mà không cần dịch thủ công từ tiếng Anh sang tiếng Việt.
- **MĐ-03**: Checklist vẫn giữ đầy đủ ý nghĩa kiểm tra chất lượng, readiness và gate của luồng Speckit sau khi chuyển sang tiếng Việt.

---

## 2. Người dùng & Bối cảnh

**Người dùng chính**: Người vận hành Codex/Claude trong workspace Flex, người review spec/plan/tasks, và người chịu trách nhiệm kiểm tra chất lượng trước khi implement.

**Bối cảnh sử dụng**: Khi chạy các bước Speckit đọc template/hướng dẫn để sinh checklist hoặc dùng checklist làm điều kiện review trước các bước tiếp theo trong feature workflow.

**Trình độ kỹ thuật**: Có hiểu biết về workflow Speckit và tài liệu Markdown, nhưng không nên cần đọc tiếng Anh để hoàn thành việc review checklist.

---

## 3. Kịch bản người dùng *(bắt buộc)*

### Kịch bản 1 — Template sinh checklist tiếng Việt (Ưu tiên: P1)

Người dùng chạy bước Speckit có tạo checklist từ template đã được sửa. Sau khi hoàn tất, checklist mới hiển thị toàn bộ nội dung hướng dẫn và item kiểm tra bằng tiếng Việt có dấu, giữ nguyên định dạng dễ tick và dễ review.

**Lý do ưu tiên**: Đây là vấn đề trực tiếp người dùng báo cáo; nếu chưa đạt, checklist vẫn không phù hợp quy tắc ngôn ngữ của workspace.

**Test độc lập**: Tạo một checklist mới từ template đã sửa và đọc file kết quả để xác nhận không còn nội dung tiếng Anh ở phần người dùng cần review.

**Kịch bản chấp nhận**:

1. **Cho trước** workspace yêu cầu tài liệu tiếng Việt, **Khi** người dùng chạy bước Speckit sinh checklist từ template, **Thì** checklist được tạo với tiêu đề, mục đích, nhóm item, item kiểm tra và ghi chú bằng tiếng Việt có dấu.
2. **Cho trước** checklist đã được sinh ra, **Khi** người review mở checklist, **Thì** họ có thể hiểu từng item mà không cần dịch nội dung tiếng Anh.

---

### Kịch bản 2 — Checklist giữ nguyên giá trị quality gate (Ưu tiên: P2)

Người review dùng checklist tiếng Việt để xác nhận spec, plan hoặc artifact liên quan đã sẵn sàng cho bước tiếp theo. Nội dung tiếng Việt phải truyền đạt cùng tiêu chí kiểm tra như checklist trước đó.

**Lý do ưu tiên**: Việt hóa không được làm mất ý nghĩa kiểm tra hoặc làm checklist trở nên mơ hồ.

**Test độc lập**: So sánh checklist tiếng Việt với mục đích kiểm tra của workflow và xác nhận từng nhóm kiểm tra vẫn có tiêu chí rõ ràng, có thể đánh dấu đạt/chưa đạt.

**Kịch bản chấp nhận**:

1. **Cho trước** một checklist dùng làm gate trước bước tiếp theo, **Khi** người review đánh giá từng item, **Thì** mỗi item thể hiện rõ điều kiện đạt/chưa đạt.

---

### Trường hợp biên

- Checklist có thuật ngữ kỹ thuật hoặc tên command: giữ nguyên định danh kỹ thuật bằng English, chỉ Việt hóa phần mô tả và hướng dẫn.
- Checklist có link tới file, command hoặc artifact: giữ nguyên đường dẫn, tên command và tên file.
- Checklist có nội dung do người dùng nhập bằng English: không tự dịch phần trích dẫn nguyên văn từ đầu vào của người dùng.
- Checklist cũ đã tồn tại bằng tiếng Anh: không bắt buộc sửa hồi tố vì phạm vi chỉ là template sinh checklist mới.

---

## 4. Yêu cầu chức năng *(bắt buộc)*

- **YC-001**: Template sinh checklist PHẢI tạo checklist mới bằng tiếng Việt có dấu cho các phần người dùng đọc và review.
- **YC-002**: Hệ thống PHẢI giữ nguyên định danh kỹ thuật như tên file, thư mục, command, package, API, framework và mã checklist khi các định danh đó cần chính xác.
- **YC-003**: Hệ thống PHẢI diễn đạt các item checklist theo dạng có thể kiểm tra đạt/chưa đạt, không dùng câu mơ hồ.
- **YC-004**: Template KHÔNG ĐƯỢC làm mất nhóm kiểm tra bắt buộc, mục đích checklist, liên kết artifact hoặc phần ghi chú cần thiết trong checklist.
- **YC-005**: Template PHẢI áp dụng quy tắc tiếng Việt cho checklist mới do chính template đó sinh ra.
- **YC-006**: Người review PHẢI có thể xác định checklist đang kiểm tra artifact nào và bước workflow nào.

---

## 5. Yêu cầu phi chức năng

- **YCPCK-001**: Checklist mới PHẢI dễ đọc trong Markdown preview phổ biến, không vỡ bảng hoặc mất cấu trúc tick box.
- **YCPCK-002**: Ít nhất 95% nội dung mô tả hướng tới người dùng trong checklist mới PHẢI là tiếng Việt có dấu; phần còn lại chỉ dành cho định danh kỹ thuật hoặc trích dẫn nguyên văn.
- **YCPCK-003**: Người review quen workflow Speckit PHẢI hoàn tất việc hiểu mục đích checklist và các nhóm kiểm tra chính trong dưới 2 phút.

---

## 6. Thực thể dữ liệu

- **Checklist Speckit**: Tài liệu kiểm tra dạng Markdown gồm tiêu đề, mục đích, ngày tạo, liên kết artifact, nhóm item, trạng thái tick và ghi chú.
- **Artifact được kiểm tra**: Spec, plan, tasks hoặc tài liệu workflow mà checklist dùng để đánh giá readiness hoặc chất lượng.
- **Quy tắc ngôn ngữ workspace**: Quy định rằng trả lời, tài liệu và ghi chú sử dụng tiếng Việt có dấu, trong khi định danh kỹ thuật giữ nguyên English.

---

## 7. Tiêu chí thành công *(bắt buộc)*

- **TC-001**: 100% checklist mới sinh từ template đã sửa có tiêu đề và nhóm nội dung chính bằng tiếng Việt có dấu.
- **TC-002**: 0 checklist mới còn các nhãn người dùng phổ biến bằng tiếng Anh như "Purpose", "Created", "Feature", "Content Quality", "Requirement Completeness", "Notes" nếu không phải trích dẫn nguyên văn.
- **TC-003**: 90% người review nội bộ có thể xác định ý nghĩa của từng item checklist mà không cần tham khảo bản tiếng Anh.
- **TC-004**: Không có checklist mới nào mất khả năng dùng làm gate review so với checklist trước khi Việt hóa.

---

## 8. Giả định & Ràng buộc

**Giả định**:
- Người dùng muốn sửa nội dung template để checklist mới sinh ra bằng tiếng Việt, không yêu cầu đổi toàn bộ tên feature/workflow hoặc dịch hồi tố toàn bộ checklist cũ.
- Các định danh kỹ thuật vẫn giữ nguyên English để tránh sai lệch khi chạy command hoặc tham chiếu file.
- Template và hướng dẫn Speckit hiện tại vẫn là nguồn tạo checklist chính cần review.

**Ràng buộc**:
- PHẢI tuân thủ quy tắc ngôn ngữ trong `AGENTS.md` của workspace.
- PHẢI giữ checklist ở định dạng Markdown có thể review và tick item.
- KHÔNG ĐƯỢC đưa token, mật khẩu, khóa API, connection string hoặc thông tin nhạy cảm vào checklist.

---

## 9. Ngoài phạm vi

- Không dịch hồi tố toàn bộ checklist đã sinh trước feature này, trừ khi chúng được người dùng yêu cầu riêng.
- Không thay đổi bản chất workflow Speckit hoặc thứ tự các bước specify, clarify, plan, tasks, implement.
- Không thay đổi ngôn ngữ của tên command, tên file, tên thư mục hoặc định danh kỹ thuật.
- Không tạo thêm loại checklist mới ngoài nhu cầu sửa nội dung template checklist hiện có.

---

## 10. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Dịch thuật làm thay đổi ý nghĩa tiêu chí kiểm tra | Trung | Cao | Review từng item theo ý nghĩa nghiệp vụ, không dịch máy từng chữ |
| Dịch cả định danh kỹ thuật khiến checklist khó dùng | Thấp | Trung | Quy định rõ định danh kỹ thuật giữ nguyên English |
| Một số template hoặc hướng dẫn sinh checklist bị bỏ sót | Trung | Trung | Kiểm tra các nguồn template/hướng dẫn có khả năng tạo checklist trong workspace |

---

## 11. Phụ thuộc

- Quy tắc ngôn ngữ trong `AGENTS.md` và tài liệu workspace.
- Các template hoặc hướng dẫn Speckit đang sinh checklist cho workflow hiện tại.
- Người review xác nhận thuật ngữ tiếng Việt dùng trong checklist đủ rõ và nhất quán.

---

## 12. Câu hỏi mở

- Không có câu hỏi mở tại thời điểm tạo spec.
