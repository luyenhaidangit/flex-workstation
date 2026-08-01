# Đặc tả tính năng: Danh mục Agent (CRUD cơ bản)

**Branch**: `000026-agent-catalog`
**Ngày tạo**: 2026-08-01
**Trạng thái**: Bản nháp
**Người phụ trách**: Luyện Hải Đăng
**Stakeholder xác nhận**: Luyện Hải Đăng
**Đầu vào**: Triển khai module Danh mục Agent ở mức cơ bản nhất, mục tiêu đầu tiên là quản trị viên thao tác CRUD được (tạo, xem, sửa, xóa) một agent trong danh mục.

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

Hiện tại chưa có nơi nào để quản trị viên tạo và quản lý danh sách các agent đang có trong hệ thống. Trước khi xây dựng các khả năng nâng cao hơn (nạp tri thức, chạy thử, phát hành lên kênh — xem `specs/000008-agent-platform-mvp`), cần có một danh mục agent cơ bản để lưu và quản lý thông tin định danh của từng agent: tên, mô tả, trạng thái. Nếu không có bước nền tảng này, các tính năng agent nâng cao sau đó không có nơi lưu trữ và tham chiếu thực thể agent.

**Tổng quan tính năng**:

Xây dựng module Danh mục Agent cho phép quản trị viên tạo mới, xem danh sách, xem chi tiết, sửa thông tin và xóa một agent. Đây là phiên bản tối thiểu (v1): chỉ tập trung vào CRUD thông tin định danh của agent, chưa bao gồm cấu hình tri thức, chạy thử hội thoại hay phát hành.

---

## 2. Mục tiêu

- **MT-001**: Quản trị viên tạo được một agent mới trong danh mục với thông tin cơ bản (tên, mô tả).
- **MT-002**: Quản trị viên xem được toàn bộ danh sách agent hiện có và chi tiết từng agent.
- **MT-003**: Quản trị viên sửa và xóa được một agent đã tạo.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Tạo agent mới với tên và mô tả.
- **MVP-002**: Xem danh sách agent (tên, trạng thái) và xem chi tiết một agent.
- **MVP-003**: Sửa tên/mô tả của agent đã tạo.
- **MVP-004**: Xóa một agent khỏi danh mục.
- **MVP-005**: Giới hạn MVP: chưa bao gồm nạp tri thức, chạy thử hội thoại, phát hành lên kênh, quản lý phiên bản, hay phân quyền theo tenant — các khả năng này thuộc phạm vi `specs/000008-agent-platform-mvp` và sẽ xây dựng sau khi danh mục agent đã có.
- **MVP-006**: Quản trị viên PHẢI đăng nhập thành công trước khi thao tác CRUD với danh mục agent; mọi thao tác CRUD chỉ khả dụng sau khi xác thực.

---

## 4. Người dùng & Bối cảnh

**Người dùng chính**: Quản trị viên hệ thống.

**Bối cảnh sử dụng**: Quản trị viên cần khởi tạo và duy trì danh sách agent trước khi các tính năng nâng cao (tri thức, chạy thử, phát hành) được xây dựng và sử dụng.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Quản trị viên.

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Tạo agent mới (Ưu tiên: P1)

Quản trị viên nhập tên và mô tả cho một agent mới, hệ thống lưu lại và agent xuất hiện trong danh mục.

**Lý do ưu tiên**: Không thể có danh mục nếu không tạo được agent; đây là luồng nền tảng của toàn bộ tính năng.

**Liên quan yêu cầu**: FR-001, FR-002, FR-005

**Test độc lập**: Tạo một agent với tên hợp lệ, xác nhận agent xuất hiện trong danh sách với đúng thông tin đã nhập.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** quản trị viên đang ở màn hình danh mục agent, **Khi** nhập tên hợp lệ và xác nhận tạo, **Thì** agent mới được lưu và hiển thị trong danh sách.
2. **AC-002**: **Cho trước** quản trị viên để trống tên agent, **Khi** xác nhận tạo, **Thì** hệ thống từ chối và báo rõ tên là bắt buộc.
3. **AC-003**: **Cho trước** đã tồn tại agent có tên trùng, **Khi** quản trị viên tạo agent mới với cùng tên, **Thì** hệ thống từ chối và báo tên đã tồn tại.
4. **AC-010**: **Cho trước** quản trị viên nhập tên vượt quá 100 ký tự hoặc mô tả vượt quá 500 ký tự, **Khi** xác nhận tạo, **Thì** hệ thống từ chối và báo rõ giới hạn độ dài.

---

### US-002 — Xem danh sách và chi tiết agent (Ưu tiên: P1)

Quản trị viên xem được toàn bộ agent hiện có trong danh mục và xem chi tiết một agent cụ thể.

**Lý do ưu tiên**: Cần thấy được dữ liệu đã tạo để xác nhận đúng và làm cơ sở cho sửa/xóa.

**Liên quan yêu cầu**: FR-003

**Test độc lập**: Với danh mục đã có sẵn agent, mở danh sách và mở chi tiết một agent, xác nhận thông tin hiển thị khớp dữ liệu đã lưu.

**Acceptance Criteria**:

1. **AC-004**: **Cho trước** danh mục có ít nhất một agent (quy mô dự kiến tối đa vài chục agent ở v1), **Khi** quản trị viên mở màn hình danh mục, **Thì** danh sách hiển thị toàn bộ agent trong một lần xem, không cần phân trang, với tên và trạng thái.
2. **AC-005**: **Cho trước** danh mục chưa có agent nào, **Khi** quản trị viên mở màn hình danh mục, **Thì** hệ thống hiển thị trạng thái rỗng rõ ràng thay vì lỗi.

---

### US-003 — Sửa thông tin agent (Ưu tiên: P2)

Quản trị viên cập nhật tên hoặc mô tả của một agent đã tạo.

**Lý do ưu tiên**: Thông tin agent có thể cần chỉnh sửa sau khi tạo, ví dụ đặt lại tên cho rõ nghĩa hơn.

**Liên quan yêu cầu**: FR-004, FR-005

**Test độc lập**: Sửa tên của một agent có sẵn, xác nhận danh sách và chi tiết phản ánh tên mới.

**Acceptance Criteria**:

1. **AC-006**: **Cho trước** một agent đã tồn tại, **Khi** quản trị viên sửa tên/mô tả hợp lệ và lưu, **Thì** thông tin agent được cập nhật và phản ánh ngay trong danh sách/chi tiết.
2. **AC-007**: **Cho trước** quản trị viên sửa tên agent trùng với agent khác đang tồn tại, **Khi** lưu thay đổi, **Thì** hệ thống từ chối và báo tên đã tồn tại.

---

### US-004 — Xóa agent (Ưu tiên: P2)

Quản trị viên xóa một agent không còn cần thiết khỏi danh mục.

**Lý do ưu tiên**: Cần dọn dẹp danh mục khi agent tạo nhầm hoặc không còn dùng.

**Liên quan yêu cầu**: FR-006

**Test độc lập**: Xóa một agent có sẵn, xác nhận agent không còn xuất hiện trong danh sách.

**Acceptance Criteria**:

1. **AC-008**: **Cho trước** một agent đã tồn tại, **Khi** quản trị viên xác nhận xóa, **Thì** agent không còn xuất hiện trong danh mục.
2. **AC-009**: **Cho trước** quản trị viên bấm xóa, **Khi** thao tác xóa được yêu cầu, **Thì** hệ thống yêu cầu xác nhận trước khi xóa vĩnh viễn.

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Danh sách hiển thị trạng thái rỗng rõ ràng (xem AC-005).
- **Dữ liệu không hợp lệ**: Tên trống hoặc trùng bị từ chối kèm thông báo rõ ràng (xem AC-002, AC-003, AC-007).
- **Không có quyền**: Người dùng chưa đăng nhập bị chặn truy cập màn hình danh mục agent và không thực hiện được bất kỳ thao tác CRUD nào (xem §10, MVP-006).
- **Lỗi hệ thống**: Hệ thống báo lỗi rõ ràng và không làm mất dữ liệu đã nhập khi thao tác tạo/sửa thất bại.
- **Timeout**: Không áp dụng ở v1.
- **Dữ liệu bị thay đổi bởi người khác**: Không áp dụng ở v1 — chưa có nhiều quản trị viên thao tác đồng thời trong phạm vi này.
- **Người dùng thao tác lặp lại**: Bấm tạo/lưu nhiều lần liên tiếp không được tạo trùng bản ghi.
- **Trường hợp biên khác**: Xóa agent yêu cầu xác nhận trước khi thực hiện (xem AC-009).

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI cho phép quản trị viên tạo agent mới với tên và mô tả.
  **Liên quan**: US-001, AC-001
- **FR-002** `[P1]`: Hệ thống PHẢI từ chối tạo agent khi tên trống, trùng với agent đã tồn tại, hoặc vượt quá giới hạn độ dài (tên trên 100 ký tự, mô tả trên 500 ký tự).
  **Liên quan**: US-001, AC-002, AC-003, AC-010
- **FR-003** `[P1]`: Hệ thống PHẢI cho phép quản trị viên xem danh sách toàn bộ agent và chi tiết từng agent.
  **Liên quan**: US-002, AC-004, AC-005
- **FR-004** `[P2]`: Hệ thống PHẢI cho phép quản trị viên sửa tên và mô tả của agent đã tồn tại.
  **Liên quan**: US-003, AC-006
- **FR-005** `[P1]`: Hệ thống KHÔNG ĐƯỢC cho phép hai agent có cùng tên tồn tại đồng thời trong danh mục.
  **Liên quan**: US-001, US-003, AC-003, AC-007
- **FR-006** `[P2]`: Hệ thống PHẢI cho phép quản trị viên xóa một agent khỏi danh mục sau khi xác nhận.
  **Liên quan**: US-004, AC-008, AC-009
- **FR-007** `[P1]`: Hệ thống PHẢI yêu cầu quản trị viên đăng nhập thành công trước khi cho phép truy cập danh mục agent hoặc thực hiện thao tác CRUD.
  **Liên quan**: US-001, US-002, US-003, US-004, SEC-003

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Tên agent là bắt buộc và phải duy nhất trong toàn bộ danh mục; so khớp trùng tên có phân biệt chữ hoa/chữ thường (ví dụ "Agent A" và "agent a" được coi là hai tên khác nhau, không trùng nhau).
- **BR-002**: Mô tả agent là tùy chọn.
- **BR-004**: Tên agent tối đa 100 ký tự; mô tả agent tối đa 500 ký tự.
- **BR-003**: Xóa agent là thao tác không thể hoàn tác và phải được xác nhận trước khi thực hiện.

**Luồng trạng thái nếu có**: Không áp dụng — ở v1 agent chỉ có một trạng thái tồn tại/không tồn tại, chưa có luồng trạng thái nghiệp vụ (nháp/đã phát hành...).

---

## 9. Thực thể dữ liệu

- **Agent**: Đại diện cho một agent trong danh mục. Thuộc tính nghiệp vụ quan trọng: tên (duy nhất — phân biệt hoa/thường, bắt buộc, tối đa 100 ký tự), mô tả (tùy chọn, tối đa 500 ký tự), thời điểm tạo.

---

## 10. Phân quyền & Bảo mật

**Ai được xem**: Quản trị viên hệ thống.

**Ai được thao tác**: Quản trị viên hệ thống (tạo, sửa, xóa).

**Ai không được phép**: Người dùng chưa đăng nhập hoặc không có vai trò quản trị viên.

**Dữ liệu nhạy cảm**: Không. Thông tin agent ở v1 (tên, mô tả) không phải dữ liệu nhạy cảm.

- **SEC-001**: Hệ thống PHẢI kiểm tra quyền trước khi cho phép thao tác.
- **SEC-002**: Hệ thống KHÔNG ĐƯỢC cho người dùng truy cập dữ liệu ngoài phạm vi được cấp quyền.
- **SEC-003**: Hệ thống PHẢI yêu cầu quản trị viên đăng nhập thành công trước khi truy cập danh mục agent hoặc thực hiện bất kỳ thao tác CRUD nào.

---

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Không áp dụng ở v1 — danh mục agent v1 chỉ là CRUD nền tảng, chưa có yêu cầu nghiệp vụ về truy vết thay đổi. Audit cho thao tác agent sẽ được xem xét lại khi xây dựng các khả năng nâng cao (phát hành, phân quyền tenant) trong `specs/000008-agent-platform-mvp`.

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: Danh sách agent hiển thị trong vòng 3 giây trong điều kiện tải thông thường.
- **NFR-002**: Tính năng không làm gián đoạn các luồng nghiệp vụ hiện có.

---

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: Quản trị viên tạo xong một agent mới trong dưới 1 phút.
- **SC-002**: 100% thao tác tạo/sửa với tên trùng hoặc trống bị từ chối kèm thông báo rõ ràng.
- **SC-003**: Quản trị viên xác nhận đúng danh sách agent hiện có mà không cần tra cứu thủ công ở nơi khác.

---

## 14. Giả định & Ràng buộc

**Giả định**:
- Chỉ có một vai trò thao tác ở v1 (quản trị viên); chưa phân biệt nhiều vai trò hay nhiều tenant.
- Mỗi agent trong danh mục v1 chỉ có thông tin định danh cơ bản, chưa gắn với kênh, tri thức hay cấu hình vận hành.
- Quy mô danh mục ở v1 nhỏ (tối đa vài chục agent), nên chưa cần phân trang hoặc tìm kiếm/lọc.

**Ràng buộc**:
- Thực thể Agent tạo ở v1 phải là nền tảng để tái sử dụng cho các khả năng nâng cao trong `specs/000008-agent-platform-mvp`, không tạo mô hình dữ liệu xung đột.

---

## 15. Ngoài phạm vi

- Nạp tri thức cho agent.
- Chạy thử hội thoại (test chat).
- Phát hành agent lên kênh (web widget, Instagram...).
- Quản lý phiên bản, rollback.
- Phân quyền nhiều vai trò/nhiều tenant.
- Audit chi tiết theo từng thao tác.

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Mô hình dữ liệu Agent v1 quá đơn giản, phải sửa lớn khi ghép với `specs/000008-agent-platform-mvp` | Trung bình | Trung bình | Khi lập plan kỹ thuật, tham chiếu thực thể Agent dự kiến trong `specs/000008-agent-platform-mvp/data-model.md` để tránh xung đột về sau. |

---

## 17. Phụ thuộc

- Không áp dụng — module Danh mục Agent v1 không phụ thuộc dịch vụ hay quyết định nghiệp vụ nào khác để hoạt động độc lập.

---

## 18. Câu hỏi mở

- Không có câu hỏi mở chặn lập plan ở thời điểm hiện tại.

---

## Clarifications

### Session 2026-08-01

- Q: Spec ghi "Ai không được phép: người dùng chưa đăng nhập hoặc không có vai trò quản trị viên", nhưng chưa rõ v1 có cần xây cơ chế đăng nhập/xác thực hay không → A: V1 PHẢI có đăng nhập/xác thực thật trước khi thao tác CRUD
- Q: BR-001 nói tên agent phải duy nhất — so khớp trùng có phân biệt hoa/thường hay không? → A: Phân biệt hoa/thường — "Agent A" và "agent a" là hai tên khác nhau, được phép tồn tại song song
- Q: AC-004 yêu cầu danh sách hiển thị đầy đủ agent — quy mô dự kiến là bao nhiêu, có cần phân trang không? → A: Quy mô nhỏ (tối đa vài chục agent) — hiển thị toàn bộ danh sách một lần, không cần phân trang ở v1
- Q: Spec chưa nêu giới hạn độ dài cho tên và mô tả agent → A: Tên tối đa 100 ký tự, mô tả tối đa 500 ký tự

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
