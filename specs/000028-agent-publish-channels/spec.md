# Đặc tả tính năng: Tab Thiết lập thông tin chung & Phát hành đa kênh cho Agent

**Branch**: `000028-agent-publish-channels`
**Ngày tạo**: 2026-08-05
**Trạng thái**: Bản nháp
**Người phụ trách**: Luyện Hải Đăng
**Stakeholder xác nhận**: Luyện Hải Đăng
**Đầu vào**: Tổ chức lại màn hình chi tiết agent thành các tab, đưa thông tin chính vào tab "Thiết lập thông tin chung", và bổ sung tab "Phát hành" để lưu cấu hình cho phép agent chat trên nhiều kênh (Website, ...).

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

Màn hình chi tiết agent hiện tại (`specs/000026-agent-catalog`) chỉ có một khối thông tin duy nhất (tên, mô tả, trạng thái). Khi cần bổ sung cấu hình cho phép agent phục vụ chat trên nhiều kênh khác nhau (Website và các kênh khác trong tương lai), nếu tiếp tục đặt mọi thứ trên cùng một màn hình phẳng, giao diện sẽ rối và khó mở rộng khi có thêm kênh mới. Cần tách rõ "thông tin định danh của agent" và "cấu hình kênh mà agent được phép phục vụ" thành hai khu vực riêng biệt để quản trị viên thao tác rõ ràng và hệ thống dễ mở rộng thêm kênh sau này.

**Tổng quan tính năng**:

Tổ chức lại màn hình chi tiết/sửa agent thành dạng nhiều tab. Tab đầu tiên "Thiết lập thông tin chung" chứa các thông tin chính hiện có của agent (tên, mô tả, trạng thái). Tab thứ hai "Phát hành" cho phép quản trị viên bật/tắt và lưu cấu hình các kênh mà agent được phép phục vụ chat, bắt đầu với kênh Website và có thể bổ sung kênh khác sau này.

---

## 2. Mục tiêu

- **MT-001**: Quản trị viên xem và sửa thông tin chính của agent trong một tab riêng ("Thiết lập thông tin chung") tách biệt khỏi cấu hình kênh phát hành.
- **MT-002**: Quản trị viên bật được kênh Website cho một agent và lưu lại cấu hình đó, làm nền tảng để agent phục vụ chat qua kênh này.
- **MT-003**: Cấu trúc tab cho phép bổ sung thêm kênh mới trong tương lai mà không phải thiết kế lại màn hình.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Chuyển màn hình chi tiết/sửa agent hiện có sang bố cục 2 tab: "Thiết lập thông tin chung" và "Phát hành".
- **MVP-002**: Tab "Thiết lập thông tin chung" giữ nguyên các trường và hành vi hiện có của `specs/000026-agent-catalog` (tên, mô tả, trạng thái) — không đổi logic nghiệp vụ, chỉ đổi vị trí hiển thị.
- **MVP-003**: Tab "Phát hành" cho phép bật/tắt kênh Website cho agent; thao tác bật/tắt dùng chung một hành động "Lưu" duy nhất với tab "Thiết lập thông tin chung" — bật/tắt trên giao diện chỉ là thay đổi tạm thời, chỉ được ghi nhận khi quản trị viên bấm "Lưu".
- **MVP-004**: Tab "Phát hành" chỉ hiển thị/thao tác được sau khi agent đã được tạo (đã tồn tại trong danh mục).
- **MVP-005**: Tab "Phát hành" PHẢI hiển thị đủ danh sách kênh dự kiến của hệ thống (Fanpage Facebook, Zalo OA doanh nghiệp, Website, Chatbot, Zalo cá nhân), nhưng chỉ kênh Website cho phép bật/tắt và lưu; các kênh còn lại hiển thị ở trạng thái "chưa khả dụng" (vô hiệu hóa, không thao tác được).
- **MVP-006**: Giới hạn MVP: chưa tích hợp kỹ thuật thật với các kênh "chưa khả dụng" (Zalo, Facebook, Chatbot, ...), chưa tạo phiên bản bất biến/rollback theo luồng phát hành ở `specs/000008-agent-platform-mvp`, chưa sinh mã nhúng widget hay xử lý runtime chat thực tế cho bất kỳ kênh nào.

---

## 4. Người dùng & Bối cảnh

**Người dùng chính**: Quản trị viên hệ thống (người đang quản lý danh mục agent).

**Bối cảnh sử dụng**: Sau khi đã tạo agent trong danh mục, quản trị viên mở màn hình chi tiết agent để chỉnh thông tin chung hoặc cấu hình kênh mà agent được phép phục vụ.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Quản trị viên.

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Xem/sửa thông tin chung trong tab riêng (Ưu tiên: P1)

Quản trị viên mở màn hình chi tiết một agent đã có, thấy tab "Thiết lập thông tin chung" được chọn mặc định, chứa tên, mô tả, trạng thái như hiện tại; sửa và lưu vẫn hoạt động như trước khi có tab.

**Lý do ưu tiên**: Đây là hành vi hiện có (`specs/000026-agent-catalog`) không được phép hỏng khi tái cấu trúc giao diện; là điều kiện tiên quyết trước khi thêm tab mới.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003

**Test độc lập**: Mở agent đã có, xác nhận tab "Thiết lập thông tin chung" hiển thị mặc định với đúng dữ liệu hiện có; sửa tên/mô tả và lưu, xác nhận thay đổi được lưu đúng như hành vi trước khi có tab.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** quản trị viên mở màn hình chi tiết một agent đã có, **Khi** màn hình tải xong, **Thì** tab "Thiết lập thông tin chung" được chọn mặc định và hiển thị đúng tên, mô tả, trạng thái hiện có của agent.
2. **AC-002**: **Cho trước** quản trị viên đang ở tab "Thiết lập thông tin chung", **Khi** sửa tên hoặc mô tả hợp lệ và lưu, **Thì** hệ thống lưu thay đổi và áp dụng đúng các quy tắc nghiệp vụ đã có ở `specs/000026-agent-catalog` (bắt buộc tên, không trùng tên, giới hạn độ dài).
3. **AC-003**: **Cho trước** đang tạo agent mới, **Khi** quản trị viên mở màn hình tạo agent, **Thì** hệ thống hiển thị tab "Thiết lập thông tin chung" để nhập thông tin khởi tạo; tab "Phát hành" bị vô hiệu hóa cho tới khi agent được tạo thành công.

---

### US-002 — Bật kênh Website và lưu cấu hình phát hành (Ưu tiên: P1)

Quản trị viên mở tab "Phát hành" của một agent đã tồn tại, bật công tắc kênh Website; thay đổi này tạm thời chưa được ghi nhận cho tới khi quản trị viên bấm nút "Lưu" chung của màn hình (cùng nút dùng cho tab "Thiết lập thông tin chung") — khi đó cấu hình mới được gửi xuống hệ thống và ghi nhận agent đã được cho phép phục vụ chat trên kênh Website.

**Lý do ưu tiên**: Đây là mục tiêu chính của tính năng — có nơi lưu cấu hình kênh trước khi xây luồng phát hành/chat thực tế.

**Liên quan yêu cầu**: FR-004, FR-005, FR-006, FR-008

**Test độc lập**: Mở tab "Phát hành" của một agent đã có, bật kênh Website, bấm "Lưu"; tải lại màn hình và xác nhận kênh Website vẫn hiển thị ở trạng thái đã bật.

**Acceptance Criteria**:

1. **AC-004**: **Cho trước** quản trị viên đang ở tab "Phát hành" của một agent đã tồn tại, **Khi** bật kênh Website và bấm "Lưu", **Thì** hệ thống lưu lại trạng thái "đã bật" cho kênh Website của agent đó.
2. **AC-005**: **Cho trước** kênh Website của agent đã được bật và lưu, **Khi** quản trị viên mở lại tab "Phát hành", **Thì** hệ thống hiển thị đúng trạng thái đã lưu (đã bật).
3. **AC-006**: **Cho trước** quản trị viên chưa bật kênh nào, **Khi** mở tab "Phát hành" lần đầu của agent mới tạo, **Thì** hệ thống hiển thị Website ở trạng thái mặc định tắt, không tự động bật.
4. **AC-008**: **Cho trước** quản trị viên bật công tắc kênh Website nhưng chưa bấm "Lưu", **Khi** quản trị viên rời màn hình hoặc tải lại trang mà không lưu, **Thì** thay đổi bật kênh KHÔNG được ghi nhận — hệ thống vẫn hiển thị trạng thái đã lưu trước đó ở lần mở kế tiếp.

---

### US-003 — Tắt kênh đã bật (Ưu tiên: P2)

Quản trị viên tắt kênh Website đã từng bật cho một agent và bấm "Lưu" (nút chung của màn hình); cấu hình ghi nhận agent không còn được cho phép phục vụ chat trên kênh đó.

**Lý do ưu tiên**: Cần có khả năng thu hồi cấu hình đã cấp, tránh agent tiếp tục ở trạng thái "được phép" ngoài ý muốn.

**Liên quan yêu cầu**: FR-006, FR-008

**Test độc lập**: Với agent đã bật kênh Website, tắt kênh và bấm "Lưu"; tải lại tab "Phát hành" và xác nhận kênh hiển thị trạng thái tắt.

**Acceptance Criteria**:

1. **AC-007**: **Cho trước** kênh Website của agent đang ở trạng thái đã bật, **Khi** quản trị viên tắt kênh và bấm "Lưu", **Thì** hệ thống lưu lại trạng thái "đã tắt" cho kênh đó.

---

### US-004 — Xem danh sách kênh chưa khả dụng (Ưu tiên: P3)

Quản trị viên mở tab "Phát hành" và thấy đầy đủ danh sách các kênh dự kiến của hệ thống (Fanpage Facebook, Zalo OA, Website, Chatbot, Zalo cá nhân), trong đó chỉ Website thao tác được; các kênh còn lại hiển thị nhưng không bật được, giúp quản trị viên biết trước lộ trình mở rộng kênh.

**Lý do ưu tiên**: Hỗ trợ đúng cảm nhận giao diện "chọn kênh từ danh sách có sẵn" mà không đòi hỏi tích hợp kỹ thuật thật với các kênh chưa sẵn sàng.

**Liên quan yêu cầu**: FR-009

**Test độc lập**: Mở tab "Phát hành" của một agent bất kỳ, xác nhận toàn bộ 5 kênh hiển thị; xác nhận công tắc của các kênh ngoài Website ở trạng thái vô hiệu hóa, không bật được.

**Acceptance Criteria**:

1. **AC-009**: **Cho trước** quản trị viên mở tab "Phát hành" của bất kỳ agent nào, **Khi** màn hình tải xong, **Thì** hệ thống hiển thị đủ danh sách kênh dự kiến (Fanpage Facebook, Zalo OA, Website, Chatbot, Zalo cá nhân).
2. **AC-010**: **Cho trước** quản trị viên đang xem danh sách kênh, **Khi** thử bật một kênh ngoài Website, **Thì** hệ thống KHÔNG cho phép bật (công tắc ở trạng thái vô hiệu hóa/chưa khả dụng).

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Agent mới tạo chưa có cấu hình kênh nào — tab "Phát hành" hiển thị Website ở trạng thái mặc định tắt (AC-006).
- **Dữ liệu không hợp lệ**: Không áp dụng (tab "Phát hành" MVP chỉ có thao tác bật/tắt, không có trường nhập liệu tự do).
- **Không có quyền**: Không áp dụng (kế thừa cơ chế xác thực/phân quyền hiện có của `specs/000026-agent-catalog`, chưa có vai trò mới trong phạm vi này).
- **Lỗi hệ thống**: Nếu lưu cấu hình kênh thất bại, hệ thống PHẢI báo lỗi rõ ràng và giữ nguyên trạng thái đã lưu trước đó, không để giao diện hiển thị sai lệch với dữ liệu đã lưu.
- **Timeout**: Không áp dụng.
- **Dữ liệu bị thay đổi bởi người khác**: Không áp dụng ở MVP (chưa có yêu cầu xử lý chỉnh sửa đồng thời).
- **Người dùng thao tác lặp lại**: Bật/tắt lại cùng một kênh nhiều lần liên tiếp trước khi lưu chỉ tính trạng thái cuối cùng trên giao diện; chỉ khi bấm "Lưu" mới gửi đúng một trạng thái cuối cùng xuống hệ thống, không tạo bản ghi trùng lặp.
- **Trường hợp biên khác**: Quản trị viên cố mở tab "Phát hành" khi agent chưa được tạo (đang ở luồng tạo mới, chưa lưu lần đầu) — hệ thống vô hiệu hóa tab này (AC-003).

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI hiển thị màn hình chi tiết/sửa agent dưới dạng tab, gồm tối thiểu "Thiết lập thông tin chung" và "Phát hành".
  **Liên quan**: US-001, AC-001
- **FR-002** `[P1]`: Tab "Thiết lập thông tin chung" PHẢI chứa đúng các trường và giữ nguyên hành vi nghiệp vụ hiện có của agent (tên, mô tả, trạng thái) như đã định nghĩa ở `specs/000026-agent-catalog`.
  **Liên quan**: US-001, AC-001, AC-002
- **FR-003** `[P1]`: Hệ thống PHẢI chọn tab "Thiết lập thông tin chung" làm mặc định khi mở màn hình chi tiết agent.
  **Liên quan**: US-001, AC-001
- **FR-004** `[P1]`: Tab "Phát hành" PHẢI cho phép quản trị viên bật/tắt kênh Website cho agent.
  **Liên quan**: US-002, AC-004
- **FR-005** `[P1]`: Hệ thống PHẢI lưu lại trạng thái bật/tắt của từng kênh theo agent và hiển thị đúng trạng thái đã lưu ở lần mở tiếp theo.
  **Liên quan**: US-002, AC-005, US-003, AC-007
- **FR-006** `[P1]`: Hệ thống PHẢI mặc định mọi kênh ở trạng thái tắt khi agent chưa từng được cấu hình kênh.
  **Liên quan**: US-002, AC-006
- **FR-007** `[P2]`: Hệ thống KHÔNG ĐƯỢC cho phép thao tác trên tab "Phát hành" khi agent chưa được tạo/lưu lần đầu.
  **Liên quan**: US-001, AC-003
- **FR-008** `[P1]`: Hệ thống PHẢI dùng chung một hành động "Lưu" cho cả tab "Thiết lập thông tin chung" và tab "Phát hành"; thay đổi trạng thái bật/tắt kênh KHÔNG ĐƯỢC gửi xuống hệ thống cho tới khi hành động "Lưu" chung này được thực hiện.
  **Liên quan**: US-002, AC-004, AC-008, US-003, AC-007
- **FR-009** `[P3]`: Tab "Phát hành" PHẢI hiển thị đủ danh sách kênh dự kiến của hệ thống (Fanpage Facebook, Zalo OA, Website, Chatbot, Zalo cá nhân); hệ thống KHÔNG ĐƯỢC cho phép bật các kênh ngoài Website ở MVP.
  **Liên quan**: US-004, AC-009, AC-010

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Cấu hình kênh phát hành luôn gắn với một agent cụ thể đã tồn tại; không có cấu hình kênh độc lập không thuộc agent nào.
- **BR-002**: Việc tổ chức lại thành tab KHÔNG ĐƯỢC thay đổi quy tắc nghiệp vụ hiện có của tab "Thiết lập thông tin chung" (bắt buộc tên, chống trùng tên, giới hạn độ dài) đã định nghĩa ở `specs/000026-agent-catalog`.
- **BR-003**: Bật một kênh trong tab "Phát hành" chỉ là lưu cấu hình cho phép; KHÔNG tạo phiên bản bất biến và KHÔNG kích hoạt luồng chat thực tế — nội dung đó thuộc phạm vi các đặc tả khác (`specs/000008-agent-platform-mvp`).
- **BR-004**: Trạng thái bật/tắt kênh khi chưa lưu chỉ tồn tại tạm thời trên giao diện (client-side); chỉ hành động "Lưu" chung của màn hình mới làm thay đổi có hiệu lực và được hệ thống ghi nhận.

**Luồng trạng thái nếu có**:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| Kênh Website: Tắt (mặc định) | Bật kênh và lưu | Kênh Website: Bật | Agent đã tồn tại |
| Kênh Website: Bật | Tắt kênh và lưu | Kênh Website: Tắt | Agent đã tồn tại |

---

## 9. Thực thể dữ liệu

- **Agent**: Thực thể đã có từ `specs/000026-agent-catalog` (tên, mô tả, trạng thái); không đổi trong tính năng này.
- **Cấu hình kênh phát hành**: Gắn với một agent, gồm loại kênh và trạng thái bật/tắt. Danh sách loại kênh hiển thị ở MVP gồm 5 loại cố định (Fanpage Facebook, Zalo OA, Website, Chatbot, Zalo cá nhân); chỉ loại Website có trạng thái bật/tắt thao tác được và được lưu, các loại còn lại ở trạng thái "chưa khả dụng" cố định. Cấu trúc PHẢI cho phép chuyển một loại kênh từ "chưa khả dụng" sang thao tác được trong tương lai mà không đổi mô hình dữ liệu ở mức khái niệm.

---

## 10. Phân quyền & Bảo mật

**Ai được xem**:
- Quản trị viên hệ thống (kế thừa quyền xem/sửa agent hiện có).

**Ai được thao tác**:
- Quản trị viên hệ thống đã đăng nhập — bật/tắt kênh và lưu cấu hình.

**Ai không được phép**:
- Người chưa đăng nhập hoặc không có quyền quản trị agent.

**Dữ liệu nhạy cảm**:
- Không. Cấu hình kênh MVP chỉ là cờ bật/tắt, không chứa thông tin định danh khách hàng hay bí mật kết nối.

- **SEC-001**: Hệ thống PHẢI kiểm tra quyền trước khi cho phép bật/tắt kênh phát hành, dùng đúng cơ chế xác thực/phân quyền hiện có của `specs/000026-agent-catalog`.
- **SEC-002**: Hệ thống KHÔNG ĐƯỢC cho phép thao tác cấu hình kênh của agent khi chưa xác thực.

---

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Không áp dụng ở MVP.

Cấu hình kênh phát hành MVP chỉ là cờ bật/tắt phục vụ nền tảng cho các tính năng phát hành đầy đủ sau này; audit chi tiết (ai, khi nào, thay đổi gì) thuộc phạm vi `specs/000008-agent-platform-mvp` khi luồng phát hành thực tế được xây dựng.

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: Việc chuyển đổi giữa các tab không được làm mất dữ liệu chưa lưu ở tab đang thao tác mà không cảnh báo người dùng.
- **NFR-002**: Tính năng không được làm gián đoạn luồng tạo/sửa/xóa agent hiện có của `specs/000026-agent-catalog`.

---

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: Quản trị viên tìm và mở đúng tab "Phát hành" của một agent trong vòng 5 giây kể từ khi mở màn hình chi tiết agent.
- **SC-002**: 100% cấu hình bật/tắt kênh được lưu hiển thị đúng khi quản trị viên quay lại xem sau đó (không lệch giữa lần lưu và lần xem lại).
- **SC-003**: Không phát sinh lỗi hồi quy trên luồng tạo/sửa/xóa thông tin chung của agent sau khi chuyển sang bố cục tab.

---

## 14. Giả định & Ràng buộc

**Giả định**:
- Màn hình chi tiết/sửa agent hiện tại của `specs/000026-agent-catalog` đã hoạt động và là nền để tái cấu trúc thành tab, không xây lại từ đầu.
- "Nhiều kênh" trong yêu cầu ban đầu được hiểu là hiển thị đủ danh sách kênh dự kiến của hệ thống ngay từ MVP (theo mẫu tham khảo của người dùng), nhưng chỉ Website thao tác/lưu được thật; các kênh còn lại hiển thị "chưa khả dụng" để định hướng lộ trình mở rộng.
- Cơ chế xác thực/phân quyền hiện có của danh mục agent được tái sử dụng, không có vai trò mới.

**Ràng buộc**:
- PHẢI tương thích ngược với dữ liệu agent đã tạo trước khi có tính năng này (agent cũ vẫn mở được tab "Thiết lập thông tin chung" bình thường, mặc định chưa bật kênh nào).

---

## 15. Ngoài phạm vi

- Tích hợp kỹ thuật thực tế với kênh Website hoặc kênh khác (sinh mã nhúng widget, xử lý tin nhắn realtime) — thuộc `specs/000008-agent-platform-mvp`.
- Quản lý phiên bản, rollback khi phát hành — thuộc `specs/000008-agent-platform-mvp`.
- Cho phép bật/lưu thật các kênh Fanpage Facebook, Zalo OA, Chatbot, Zalo cá nhân — các kênh này chỉ hiển thị ở trạng thái "chưa khả dụng" trong MVP, việc kích hoạt thao tác cho từng kênh để lại cho lần lặp sau.
- Cấu hình chi tiết theo từng kênh (ví dụ giới hạn domain cho Website) — chưa có trong MVP này.

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Tái cấu trúc giao diện sang tab làm hỏng hành vi nghiệp vụ hiện có của tab "Thiết lập thông tin chung" | Trung bình | Cao | Chỉ thay đổi bố cục hiển thị, không sửa logic nghiệp vụ đã có; kiểm thử hồi quy đầy đủ luồng CRUD hiện tại |
| Mô hình dữ liệu cấu hình kênh không mở rộng được khi thêm kênh mới sau này | Thấp | Trung bình | Thiết kế cấu hình kênh dạng danh sách theo loại kênh ngay từ đầu, dù MVP chỉ có Website |

---

## 17. Phụ thuộc

- Phụ thuộc vào tính năng danh mục agent đã có (`specs/000026-agent-catalog`) — agent phải tồn tại trước khi cấu hình kênh phát hành.
- Là nền tảng cho luồng phát hành đầy đủ ở `specs/000008-agent-platform-mvp` (tạo phiên bản, mã nhúng, audit) — không thay thế luồng đó.

---

## 18. Câu hỏi mở

Không áp dụng — phạm vi danh sách kênh và cơ chế lưu cho MVP đã được làm rõ ở mục Clarifications (Session 2026-08-05).

---

## Clarifications

### Session 2026-08-05

- Q: Cách lưu cấu hình kênh trên tab Phát hành — có nút Lưu riêng trên tab đó không? → A: Không tách biệt; dùng chung nút "Lưu" với tab Thiết lập thông tin chung. Bật/tắt công tắc kênh chỉ thay đổi trạng thái tạm ở FE; chỉ khi bấm "Lưu" (chung cho cả 2 tab), thay đổi mới được gửi xuống BE và ghi nhận.
- Q: Danh sách kênh hiển thị trên tab Phát hành ở MVP gồm những gì? → A: Hiển thị đủ danh sách nhiều kênh theo mẫu tham khảo của người dùng (Fanpage Facebook, Zalo OA doanh nghiệp, Website, Chatbot, Zalo cá nhân), nhưng chỉ kênh Website thực sự bật/lưu được ở MVP; các kênh còn lại hiển thị ở trạng thái "chưa khả dụng" (vô hiệu hóa, không thao tác được).

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
