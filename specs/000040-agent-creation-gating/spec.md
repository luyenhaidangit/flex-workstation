# Đặc tả tính năng: Phân tách trạng thái tạo và cấu hình Agent

**Branch**: `000040-agent-creation-gating`  
**Ngày tạo**: 2026-08-26  
**Trạng thái**: Bản nháp  
**Người phụ trách**: Luyện Hải Đăng  
**Stakeholder xác nhận**: Luyện Hải Đăng  
**Đầu vào**: Làm rõ màn hình tạo Agent chỉ cho nhập thông tin chung trước khi có `AgentId`, sau đó mới mở khóa các bước cấu hình và hiển thị hành động phù hợp với từng trạng thái.

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

Màn hình hiện tại hiển thị các bước cấu hình, khung chat và các khu vực điều hướng như thể Agent đã tồn tại. Người dùng có thể nhấp vào bước bị khóa, khiến Agent được tạo ngầm dù chưa chủ động xác nhận hành động tạo. Các nút “Lưu nháp” và “Lưu và phát hành lại” cũng chưa phản ánh đúng trạng thái của Agent mới.

**Tổng quan tính năng**:

Tách rõ hai giai đoạn “Tạo Agent” và “Cấu hình Agent”. Khi chưa có `AgentId`, người dùng chỉ nhập thông tin chung và chủ động bấm “Tạo Agent và tiếp tục”. Sau khi tạo thành công, hệ thống hiển thị trạng thái “Bản nháp”, mở khóa các bước cấu hình và cho phép người dùng “Lưu và tiếp tục”.

---

## 2. Mục tiêu

- **MT-001**: Giúp người dùng nhận biết ngay Agent chưa được tạo và chưa thể cấu hình các bước tiếp theo.
- **MT-002**: Ngăn việc tạo Agent ngoài ý muốn khi người dùng chỉ nhấp vào một bước đang khóa.
- **MT-003**: Làm cho tiêu đề, trạng thái, điều hướng và nút hành động phản ánh đúng giai đoạn của Agent.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Trạng thái chưa có `AgentId` chỉ cho phép thao tác trên bước “Thông tin chung”; các bước còn lại hiển thị biểu tượng khóa và thông báo hướng dẫn khi người dùng tương tác.
- **MVP-002**: Màn hình tạo mới hiển thị tiêu đề “Tạo Agent mới”, mô tả hướng dẫn, trạng thái chưa tạo, không hiển thị thời điểm cập nhật và thay khung chat bằng thông báo chưa thể kiểm thử.
- **MVP-003**: Nút chính ở trạng thái chưa tạo là “Tạo Agent và tiếp tục”; sau khi tạo thành công, hệ thống nhận `AgentId`, chuyển sang màn hình cấu hình và mở khóa stepper.
- **MVP-004**: Trạng thái đã có Agent nhưng chưa phát hành sử dụng nút “Lưu và tiếp tục”; giao diện “Lưu nháp” được giữ nguyên nhưng chưa yêu cầu cơ chế lưu nháp riêng ở backend.
- **MVP-005**: Khi chưa có `AgentId`, khu vực “Hội thoại”, “Báo cáo hoạt động” và khung “Chat với Agent” bị ẩn hoặc khóa; sau khi có Agent, các khu vực này mới được hiển thị theo trạng thái hiện có.

---

## 4. Người dùng & Bối cảnh

**Người dùng chính**: Quản trị viên và chuyên viên quản lý Agent.

**Bối cảnh sử dụng**: Người dùng bắt đầu tạo Agent mới từ danh mục Agent và cần hoàn tất thông tin định danh trước khi cấu hình tri thức, kỹ năng, kiểm thử hoặc phát hành.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Người dùng nghiệp vụ hoặc quản trị viên.

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Tạo Agent chủ động từ thông tin chung (Ưu tiên: P1)

Là người quản lý Agent, tôi muốn nút chính nói rõ rằng thao tác sẽ tạo Agent và mở khóa bước tiếp theo để tôi không nhầm với việc chỉ lưu dữ liệu tạm thời.

**Lý do ưu tiên**: Đây là điểm xác nhận tạo thực thể Agent và là điều kiện để tiếp tục toàn bộ luồng.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003

**Test độc lập**: Mở `/agents/create`, nhập hợp lệ thông tin bắt buộc và bấm “Tạo Agent và tiếp tục”.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** người dùng ở màn hình tạo mới chưa có `AgentId`, **Khi** người dùng bấm “Tạo Agent và tiếp tục” với dữ liệu hợp lệ, **Thì** hệ thống tạo Agent, nhận `AgentId`, hiển thị trạng thái “Bản nháp” và mở khóa các bước cấu hình.
2. **AC-002**: **Cho trước** dữ liệu thông tin chung chưa hợp lệ, **Khi** người dùng bấm “Tạo Agent và tiếp tục”, **Thì** hệ thống hiển thị validation và không gọi thao tác tạo Agent.

### US-002 — Nhận biết và xử lý bước bị khóa (Ưu tiên: P1)

Là người dùng, tôi muốn thấy rõ các bước chưa thể dùng và lý do bị khóa để không tưởng rằng hệ thống bị lỗi.

**Lý do ưu tiên**: Ngăn thao tác sai và giảm nhầm lẫn trong giai đoạn chưa có Agent.

**Liên quan yêu cầu**: FR-004, FR-005

**Test độc lập**: Mở màn hình tạo mới và tương tác với từng bước từ 2 đến 5.

**Acceptance Criteria**:

1. **AC-003**: **Cho trước** màn hình chưa có `AgentId`, **Khi** người dùng xem sidebar, **Thì** bước 1 ở trạng thái đang thực hiện và bước 2 đến 5 có biểu tượng khóa cùng trạng thái bị khóa.
2. **AC-004**: **Cho trước** một bước đang khóa, **Khi** người dùng hover, focus hoặc click vào bước đó, **Thì** hệ thống hiển thị “Vui lòng tạo Agent trước để tiếp tục cấu hình.” và không tạo Agent.

### US-003 — Lưu và tiếp tục cấu hình Agent đã tạo (Ưu tiên: P1)

Là người quản lý Agent đã tạo, tôi muốn lưu thông tin chung rồi tiếp tục cấu hình để không mất thay đổi hiện tại.

**Lý do ưu tiên**: Đây là hành động chính sau khi Agent đã nhận diện được.

**Liên quan yêu cầu**: FR-006

**Test độc lập**: Mở một Agent đã tạo, thay đổi thông tin chung và bấm “Lưu và tiếp tục”.

**Acceptance Criteria**:

1. **AC-005**: **Cho trước** Agent đã có `AgentId`, **Khi** người dùng bấm “Lưu và tiếp tục” với dữ liệu hợp lệ, **Thì** thay đổi được lưu theo hành vi hiện có và người dùng được tiếp tục sang bước cấu hình.
2. **AC-006**: **Cho trước** dữ liệu chưa hợp lệ, **Khi** người dùng bấm “Lưu và tiếp tục”, **Thì** hệ thống giữ người dùng ở bước hiện tại và hiển thị validation.

### US-004 — Không kiểm thử Agent trước khi Agent tồn tại (Ưu tiên: P2)

Là người dùng tạo Agent, tôi muốn được hướng dẫn thay vì nhìn thấy khung chat có thể nhập khi Agent chưa tồn tại.

**Lý do ưu tiên**: Tránh tạo kỳ vọng sai về khả năng kiểm thử.

**Liên quan yêu cầu**: FR-007

**Test độc lập**: Mở `/agents/create` và kiểm tra top navigation cùng khu vực bên phải.

**Acceptance Criteria**:

1. **AC-007**: **Cho trước** chưa có `AgentId`, **Thì** “Hội thoại”, “Báo cáo hoạt động” và input chat không cho thao tác; khu vực bên phải hiển thị hướng dẫn tạo và cấu hình Agent trước khi trò chuyện.

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Màn hình tạo mới không hiển thị thông tin cập nhật của một Agent chưa tồn tại.
- **Dữ liệu không hợp lệ**: Hiển thị validation tại các trường bắt buộc và không thực hiện tạo/lưu.
- **Không có quyền**: Giữ nguyên cơ chế phân quyền hiện có của route tạo và chỉnh sửa Agent.
- **Lỗi hệ thống**: Hiển thị thông báo lỗi theo cơ chế thông báo hiện có; không chuyển bước khi thao tác thất bại.
- **Timeout**: Giữ người dùng ở màn hình hiện tại và cho phép thử lại thao tác.
- **Dữ liệu bị thay đổi bởi người khác**: Không thay đổi phạm vi xử lý hiện tại.
- **Người dùng thao tác lặp lại**: Vô hiệu hóa nút tạo/lưu trong lúc đang xử lý để tránh gửi trùng.
- **Trường hợp biên khác**: Nếu người dùng rời màn hình khi form đã thay đổi, hiển thị xác nhận rời trang theo hành vi hiện có.

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI phân biệt trạng thái chưa có `AgentId` với trạng thái đã tạo Agent.
  **Liên quan**: US-001, US-002
- **FR-002** `[P1]`: Hệ thống PHẢI dùng nhãn “Tạo Agent và tiếp tục” cho hành động chính khi chưa có `AgentId`.
  **Liên quan**: US-001, AC-001
- **FR-003** `[P1]`: Hệ thống PHẢI chỉ tạo Agent sau khi người dùng chủ động xác nhận bằng hành động tạo và dữ liệu bắt buộc hợp lệ.
  **Liên quan**: US-001, AC-002, US-002, AC-004
- **FR-004** `[P1]`: Hệ thống PHẢI hiển thị các bước cấu hình chưa khả dụng với biểu tượng khóa và trạng thái không khả dụng khi chưa có `AgentId`.
  **Liên quan**: US-002, AC-003
- **FR-005** `[P1]`: Hệ thống KHÔNG ĐƯỢC tự tạo Agent khi người dùng nhấp vào một bước đang khóa.
  **Liên quan**: US-002, AC-004
- **FR-006** `[P1]`: Hệ thống PHẢI cung cấp hành động “Lưu và tiếp tục” cho Agent đã tạo và chưa phát hành.
  **Liên quan**: US-003, AC-005
- **FR-007** `[P2]`: Hệ thống PHẢI ẩn hoặc khóa các khu vực Hội thoại, Báo cáo hoạt động và Chat với Agent trước khi có `AgentId`.
  **Liên quan**: US-004, AC-007
- **FR-008** `[P2]`: Hệ thống PHẢI giữ giao diện “Lưu nháp” nhưng KHÔNG ĐƯỢC mở rộng phạm vi sang cơ chế lưu nháp backend trong MVP này.
  **Liên quan**: MVP-004

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Chưa có `AgentId` chỉ được thao tác trên bước Thông tin chung.
- **BR-002**: Nhấp vào bước đang khóa không được tạo Agent và phải hiển thị lý do bị khóa.
- **BR-003**: Sau khi tạo thành công, Agent được hiển thị ở trạng thái “Bản nháp” cho đến khi có hành động phát hành theo phạm vi hiện có.
- **BR-004**: “Lưu và tiếp tục” phải bảo toàn thay đổi hợp lệ trước khi chuyển sang bước cấu hình.
- **BR-005**: Cơ chế lưu nháp riêng cho Agent đã phát hành không thuộc phiên bản này.

**Luồng trạng thái nếu có**:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| Chưa tạo | Tạo Agent và tiếp tục | Bản nháp | Thông tin bắt buộc hợp lệ và tạo thành công |
| Bản nháp | Lưu và tiếp tục | Bản nháp | Thông tin thay đổi hợp lệ |
| Chưa tạo | Nhấp bước khóa | Chưa tạo | Không tạo Agent |

---

## 9. Thực thể dữ liệu

- **Agent**: Thực thể được tạo sau khi người dùng xác nhận thông tin chung; `AgentId` là điều kiện để mở khóa cấu hình tiếp theo.
- **Trạng thái Agent**: Nhãn nghiệp vụ thể hiện Agent chưa tạo, bản nháp hoặc đã phát hành theo khả năng hiện có của hệ thống.

---

## 10. Phân quyền & Bảo mật

**Ai được xem**:
- Người dùng có quyền truy cập danh mục Agent.

**Ai được thao tác**:
- Người dùng có quyền tạo hoặc chỉnh sửa Agent theo cơ chế phân quyền hiện có.

**Ai không được phép**:
- Người dùng chỉ có quyền xem hoặc không có quyền truy cập Agent.

**Dữ liệu nhạy cảm**:
- Không phát sinh dữ liệu nhạy cảm mới trong phạm vi UI này.

- **SEC-001**: Hệ thống PHẢI giữ nguyên kiểm tra quyền hiện có trước khi cho phép tạo hoặc chỉnh sửa Agent.
- **SEC-002**: Hệ thống KHÔNG ĐƯỢC cho phép khu vực cấu hình giả định một Agent tồn tại khi chưa có `AgentId`.

---

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Có, sử dụng audit của thao tác tạo/cập nhật Agent hiện có; không bổ sung loại audit mới trong phạm vi UI này.

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: Người dùng phải nhận biết trạng thái khóa bằng cả biểu tượng và chữ, không chỉ bằng màu sắc.
- **NFR-002**: Các bước khóa phải có thể nhận biết và tương tác được bằng bàn phím hoặc công nghệ hỗ trợ.
- **NFR-003**: Thay đổi UI không được làm gián đoạn luồng tạo Agent hiện có trên màn hình desktop được hỗ trợ.

---

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: 100% thao tác nhấp vào bước bị khóa trước khi có `AgentId` không tạo ra Agent mới.
- **SC-002**: 100% người dùng ở trạng thái chưa tạo nhìn thấy hành động “Tạo Agent và tiếp tục” và không thấy input chat có thể gửi tin nhắn.
- **SC-003**: Sau một lần tạo Agent thành công, người dùng nhìn thấy trạng thái “Bản nháp” và có thể tiếp tục cấu hình mà không cần quay lại danh sách.

---

## 14. Giả định & Ràng buộc

**Giả định**:
- Thao tác tạo Agent hiện có trả về `AgentId` khi thành công.
- Các màn hình Tri thức, Kỹ năng, Đào tạo và Phát hành chưa mở rộng thêm trong phạm vi này.
- UI “Lưu nháp” được giữ lại theo quyết định của stakeholder nhưng chưa có persistence backend riêng.

**Ràng buộc**:
- Phải tuân thủ giao diện và pattern hiện có của màn hình Angular trong `flex-microfrontend`.
- Không thay đổi API hoặc mô hình dữ liệu backend trong MVP này.

---

## 15. Ngoài phạm vi

- Xây dựng backend draft/versioning cho Agent.
- Thay đổi trạng thái hoặc contract backend ngoài thao tác tạo/cập nhật hiện có.
- Xây dựng mới các màn hình Tri thức, Kỹ năng, Đào tạo, Phát hành, Hội thoại hoặc Báo cáo hoạt động.
- Bổ sung tính năng chat hoặc kiểm thử Agent trước khi Agent tồn tại.

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Nhãn “Lưu nháp” vẫn tồn tại nhưng chưa lưu backend | Trung bình | Trung bình | Giữ rõ ngoài phạm vi và không mô tả nút này như hành động persistence trong MVP |
| Các bước sau được mở khóa nhưng nội dung thực tế chưa hoàn thiện | Trung bình | Trung bình | Chỉ mở khóa theo điều kiện có `AgentId`; không mở rộng nội dung ngoài phạm vi |

---

## 17. Phụ thuộc

- Cơ chế tạo và cập nhật Agent hiện có.
- Routing và màn hình Agent hiện có.
- Quyền truy cập danh mục Agent hiện có.

---

## 18. Câu hỏi mở

- Không có.

---

## Clarifications

### Session 2026-08-26

- Q: Có triển khai backend cho “Lưu nháp” trong phạm vi này không? → A: Chưa; giữ giao diện nhưng không mở rộng cơ chế lưu nháp backend.
- Q: Người dùng nhấp vào bước bị khóa có được tự động tạo Agent không? → A: Không; chỉ hiển thị thông báo “Vui lòng tạo Agent trước để tiếp tục cấu hình.”
- Q: Nút tiếp tục sau khi Agent đã tạo nên có nhãn gì? → A: “Lưu và tiếp tục”.

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

---

## 20. Đánh giá tác động tài liệu nghiệp vụ

- **Trạng thái**: CÓ CẬP NHẬT
- **Căn cứ**: Thay đổi này điều chỉnh luồng nghiệp vụ tạo → cấu hình Agent, quy tắc khóa bước trước khi Agent tồn tại và điều kiện không cho kiểm thử trước khi Agent sẵn sàng. Đây là thay đổi material đối với lifecycle của Agent và trải nghiệm của người cấu hình.
- **Tài liệu đã cập nhật**:
  - `docs/business/12-agent-creation-and-configuration.md`: tạo tài liệu nghiệp vụ cho luồng tạo và cấu hình Agent.
  - `docs/business/11-ai-chat-integration.md`: cập nhật điều kiện Agent phải được khởi tạo/sẵn sàng trước khi kiểm thử.
  - `docs/business/business-docs-index.md`: thêm tài liệu nghiệp vụ MVP 12 vào index.
