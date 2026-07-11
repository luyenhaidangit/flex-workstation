# Đặc tả tính năng: Speckit Quick

**Branch**: `000006-speckit-quick`

**Ngày tạo**: 2026-07-11

**Trạng thái**: Bản nháp

**Người phụ trách**: Nhóm Flex

**Stakeholder xác nhận**: Nhóm Flex

**Đầu vào**: Mô tả người dùng: "Mong muốn thêm bộ speckit ví dụ /speckit.quick để thực hiện các tác vụ nhỏ, đơn giản"

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 0. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

Workflow Speckit hiện tại phù hợp với feature có phạm vi rõ và cần đầy đủ spec, clarify,
plan, tasks, analyze, implement. Với các tác vụ nhỏ như chỉnh tài liệu, sửa template đơn giản
hoặc cập nhật quy ước nhỏ, người dùng phải đi qua quá nhiều bước so với giá trị nhận được.
Điều này làm Speckit bị nặng tay cho việc thường ngày và dễ khiến người dùng bỏ qua chuẩn
spec-before-code.

**Tổng quan tính năng**:

Tính năng này bổ sung một bộ Speckit ví dụ tên `/speckit.quick` để hướng dẫn thực hiện các tác
vụ nhỏ, đơn giản bằng một luồng rút gọn nhưng vẫn giữ kiểm soát phạm vi, traceability tối thiểu
và điều kiện dừng rõ ràng. Người hưởng lợi là người dùng và agent làm việc trong
`flex-workstation` khi cần xử lý thay đổi nhỏ mà không muốn mở workflow Speckit đầy đủ.

---

## 1. Mục tiêu

- **MT-001**: Giảm thời gian chuẩn bị cho tác vụ nhỏ xuống còn một luồng gọn, dễ nhớ và dễ áp dụng.
- **MT-002**: Giữ nguyên nguyên tắc spec-before-code bằng cách vẫn yêu cầu mô tả mục tiêu, phạm vi,
  đầu ra và kiểm tra tối thiểu trước khi thực hiện.
- **MT-003**: Giúp người dùng nhận biết khi nào tác vụ không còn "quick" và phải chuyển sang workflow
  Speckit đầy đủ.

---

## 2. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Một entrypoint người dùng gọi được với tên `/speckit.quick` hoặc tên tương đương trong
  runtime hiện hành.
- **MVP-002**: Hướng dẫn rõ cách mô tả tác vụ nhỏ gồm mục tiêu, phạm vi, file/khu vực liên quan và
  tiêu chí kiểm tra.
- **MVP-003**: Bộ quy tắc phân loại tác vụ đủ nhỏ để dùng quick flow và tác vụ phải chuyển sang
  Speckit đầy đủ.
- **MVP-004**: Một ví dụ hoàn chỉnh minh họa quick flow cho thay đổi nhỏ trong workspace.
- **MVP-005**: Checklist chất lượng tối thiểu để xác nhận tác vụ quick không vượt phạm vi.

---

## 3. Người dùng & Bối cảnh

**Người dùng chính**: Người dùng workspace Flex và coding agent đang xử lý tác vụ nhỏ.

**Bối cảnh sử dụng**: Khi người dùng muốn sửa đổi nhỏ trong tài liệu, template, script hoặc cấu hình
workspace mà không cần tạo bộ artifact Speckit đầy đủ.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Kỹ thuật hoặc người dùng nghiệp vụ có hiểu biết cơ bản về
workspace và Speckit.

---

## 4. Kịch bản người dùng *(bắt buộc)*

### US-001 — Chạy quick flow cho tác vụ nhỏ (ưu tiên: P1)

Người dùng mô tả một tác vụ nhỏ, ví dụ cập nhật một đoạn tài liệu hoặc chỉnh một template đơn giản.
Hệ thống hướng dẫn agent xác nhận phạm vi, thực hiện thay đổi và báo lại kết quả theo một mẫu gọn.

**Lý do ưu tiên**: Đây là giá trị cốt lõi của tính năng, giúp giảm ma sát cho công việc nhỏ mà vẫn
giữ kỷ luật thay đổi.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003, FR-004

**Test độc lập**: Đưa một yêu cầu chỉnh tài liệu nhỏ và xác minh quick flow tạo được đầu ra gồm phạm
vi, thay đổi, kiểm tra và kết quả mà không yêu cầu full spec/plan/tasks.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** một tác vụ chỉ chạm một khu vực nhỏ, **Khi** người dùng gọi
   `/speckit.quick` với mô tả rõ, **Thì** agent PHẢI nêu phạm vi, giả định và tiêu chí kiểm tra trước
   khi sửa.
2. **AC-002**: **Cho trước** tác vụ đã hoàn thành, **Khi** agent báo kết quả, **Thì** báo cáo PHẢI
   nêu file/khu vực đã thay đổi, cách kiểm tra và phần chưa làm nếu có.

---

### US-002 — Chặn tác vụ vượt phạm vi quick (ưu tiên: P1)

Người dùng đưa một yêu cầu tưởng là nhỏ nhưng thực tế ảnh hưởng nhiều module, dữ liệu, quyền hoặc
hành vi release. Quick flow phải nhận diện và yêu cầu chuyển sang workflow Speckit đầy đủ.

**Lý do ưu tiên**: Nếu không có chặn phạm vi, quick flow có thể làm suy yếu constitution và tạo
đường tắt nguy hiểm.

**Liên quan yêu cầu**: FR-005, FR-006, BR-001, BR-002

**Test độc lập**: Đưa yêu cầu có thay đổi quyền hoặc contract và xác minh quick flow từ chối thực
hiện như tác vụ nhỏ, đồng thời đề xuất dùng `speckit-specify`.

**Acceptance Criteria**:

1. **AC-003**: **Cho trước** tác vụ ảnh hưởng quyền, dữ liệu, contract hoặc nhiều repo, **Khi** người
   dùng gọi `/speckit.quick`, **Thì** agent PHẢI dừng quick flow và hướng người dùng sang workflow
   Speckit đầy đủ.
2. **AC-004**: **Cho trước** tác vụ có mô tả mơ hồ, **Khi** thiếu thông tin làm thay đổi phạm vi,
   **Thì** agent PHẢI hỏi làm rõ hoặc thu hẹp phạm vi trước khi thực hiện.

---

### US-003 — Dùng ví dụ quick làm mẫu học tập (ưu tiên: P2)

Người dùng mới đọc bộ ví dụ để hiểu cách áp dụng quick flow cho các thay đổi nhỏ trong workspace,
từ lúc nhận yêu cầu đến lúc báo cáo kết quả.

**Lý do ưu tiên**: Ví dụ giúp chuẩn hóa hành vi giữa người dùng và agent, giảm diễn giải khác nhau.

**Liên quan yêu cầu**: FR-007, FR-008

**Test độc lập**: Người dùng đọc ví dụ và có thể tự phân biệt một tác vụ quick hợp lệ với một feature
cần workflow đầy đủ trong vòng vài phút.

**Acceptance Criteria**:

1. **AC-005**: **Cho trước** một người dùng chưa dùng quick flow, **Khi** đọc ví dụ, **Thì** người dùng
   PHẢI nhận biết được input tối thiểu, output mong đợi và điều kiện chuyển sang full Speckit.

---

## 5. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Nếu tác vụ không nêu file/khu vực liên quan, quick flow PHẢI dựa vào context
  hiện có hoặc hỏi lại khi không xác định được phạm vi an toàn.
- **Dữ liệu không hợp lệ**: Nếu mô tả tác vụ mâu thuẫn hoặc không đủ kiểm chứng, quick flow PHẢI yêu
  cầu làm rõ trước khi sửa.
- **Không có quyền**: Nếu tác vụ yêu cầu thay đổi ngoài workspace hoặc ngoài quyền hiện hành, quick
  flow PHẢI dừng và báo rõ lý do.
- **Lỗi hệ thống**: Nếu không thể đọc hoặc ghi artifact cần thiết, quick flow PHẢI báo lỗi và không
  suy đoán rằng thay đổi đã hoàn tất.
- **Timeout**: Nếu kiểm tra mất quá lâu so với tác vụ nhỏ, quick flow PHẢI báo phần đã kiểm tra và
  rủi ro còn lại.
- **Dữ liệu bị thay đổi bởi người khác**: Nếu phát hiện thay đổi chưa rõ nguồn trong file liên quan,
  quick flow PHẢI làm việc với thay đổi đó hoặc hỏi lại khi không thể tiếp tục an toàn.
- **Người dùng thao tác lặp lại**: Nếu gọi quick flow lần nữa cho cùng tác vụ, agent PHẢI nhận diện
  trạng thái hiện có và tránh tạo trùng artifact hoặc lặp thay đổi.
- **Trường hợp biên khác**: Nếu tác vụ có dấu hiệu ảnh hưởng hành vi sản phẩm, release, dữ liệu,
  permission hoặc contract, quick flow PHẢI chuyển sang workflow đầy đủ.

---

## 6. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI cung cấp một entrypoint quick flow có tên người dùng nhận biết là
  `/speckit.quick`.
  **Liên quan**: US-001, AC-001
- **FR-002** `[P1]`: Quick flow PHẢI yêu cầu hoặc suy ra được mục tiêu, phạm vi, đầu ra mong đợi và
  cách kiểm tra tối thiểu của tác vụ.
  **Liên quan**: US-001, AC-001
- **FR-003** `[P1]`: Quick flow PHẢI cho phép thực hiện tác vụ nhỏ mà không bắt buộc tạo đủ
  `spec.md`, `plan.md` và `tasks.md` cho từng thay đổi.
  **Liên quan**: US-001, AC-002
- **FR-004** `[P1]`: Báo cáo kết quả của quick flow PHẢI nêu thay đổi đã làm, phạm vi file/khu vực,
  kiểm tra đã chạy hoặc lý do không chạy.
  **Liên quan**: US-001, AC-002
- **FR-005** `[P1]`: Quick flow KHÔNG ĐƯỢC xử lý như tác vụ nhỏ nếu yêu cầu ảnh hưởng dữ liệu,
  quyền, contract, release, nhiều repo hoặc hành vi nghiệp vụ chưa được specify.
  **Liên quan**: US-002, AC-003
- **FR-006** `[P1]`: Khi vượt phạm vi quick, hệ thống PHẢI hướng người dùng sang workflow
  `speckit-specify` trước khi implementation.
  **Liên quan**: US-002, AC-003
- **FR-007** `[P2]`: Bộ quick flow PHẢI có ít nhất một ví dụ hoàn chỉnh cho tác vụ nhỏ trong
  `flex-workstation`.
  **Liên quan**: US-003, AC-005
- **FR-008** `[P2]`: Ví dụ quick flow PHẢI chỉ rõ input, quyết định phạm vi, hành động, kiểm tra và
  báo cáo kết quả.
  **Liên quan**: US-003, AC-005

---

## 7. Quy tắc nghiệp vụ

- **BR-001**: Một tác vụ được xem là quick khi có mục tiêu rõ, phạm vi nhỏ, rủi ro thấp, có thể kiểm
  tra trong cùng phiên làm việc và không làm thay đổi ý nghĩa nghiệp vụ đã duyệt.
- **BR-002**: Tác vụ không được xem là quick nếu có một trong các yếu tố: thay đổi quyền, dữ liệu,
  contract, migration, release/rollback, nhiều repo hoặc yêu cầu chưa rõ MVP.
- **BR-003**: Quick flow PHẢI ưu tiên thay đổi phẫu thuật; không được thêm tính năng suy đoán hoặc
  refactor ngoài phạm vi tác vụ.
- **BR-004**: Nếu quick flow phát hiện tác vụ cần artifact Speckit đầy đủ, nó PHẢI dừng trước khi
  sửa và nêu lý do chuyển workflow.

**Luồng trạng thái nếu có**:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| Yêu cầu mới | Đánh giá phạm vi | Quick hợp lệ | Mục tiêu rõ, phạm vi nhỏ, rủi ro thấp |
| Yêu cầu mới | Đánh giá phạm vi | Cần Speckit đầy đủ | Ảnh hưởng dữ liệu, quyền, contract, release hoặc nhiều repo |
| Quick hợp lệ | Thực hiện và kiểm tra | Hoàn tất | Có báo cáo thay đổi và kiểm tra |
| Quick hợp lệ | Phát hiện rủi ro mới | Cần Speckit đầy đủ | Rủi ro vượt tiêu chí quick |

---

## 8. Thực thể dữ liệu

- **Quick Task**: Một yêu cầu nhỏ có mục tiêu, phạm vi, đầu ra mong đợi, tiêu chí kiểm tra và kết quả
  thực hiện.
- **Quick Example**: Một ví dụ minh họa cách áp dụng quick flow cho một tác vụ nhỏ, gồm input, phạm
  vi, quyết định, kiểm tra và báo cáo.
- **Escalation Decision**: Kết luận rằng yêu cầu không đủ điều kiện quick và phải chuyển sang workflow
  Speckit đầy đủ.

---

## 9. Phân quyền & Bảo mật

**Ai được xem**:
- Người dùng và agent làm việc trong `flex-workstation`.

**Ai được thao tác**:
- Người dùng hoặc agent có quyền sửa runtime guidance, skill source hoặc tài liệu workspace liên quan.

**Ai không được phép**:
- Người dùng hoặc agent không có quyền sửa workspace hiện hành.
- Quick flow không được tự ý sửa project con khi yêu cầu chỉ thuộc workstation.

**Dữ liệu nhạy cảm**:
- Không áp dụng cho dữ liệu nghiệp vụ nhạy cảm. Quick flow vẫn KHÔNG ĐƯỢC ghi token, mật khẩu, khóa
  API, connection string hoặc thông tin nhạy cảm vào artifact.

- **SEC-001**: Hệ thống PHẢI giữ nguyên quy tắc không đưa credential hoặc secret vào repo.
- **SEC-002**: Hệ thống KHÔNG ĐƯỢC dùng quick flow để bỏ qua kiểm tra quyền, dữ liệu hoặc contract.

---

## 10. Audit & Lịch sử thay đổi

**Có cần audit không**: Có, ở mức lịch sử thay đổi workspace.

Nếu có, hệ thống PHẢI ghi nhận:

- Ai thực hiện
- Thao tác gì
- Thời điểm thực hiện
- File hoặc artifact đã thay đổi
- Lý do chuyển sang workflow đầy đủ nếu quick flow bị từ chối

---

## 11. Yêu cầu phi chức năng

- **NFR-001**: Người dùng có thể đọc và hiểu điều kiện dùng quick flow trong dưới 5 phút.
- **NFR-002**: Với tác vụ quick hợp lệ, agent có thể hoàn tất đánh giá phạm vi ban đầu trong dưới
  2 phút khi context đã có sẵn.
- **NFR-003**: Quick flow không được làm giảm khả năng trace thay đổi: mỗi lần hoàn tất phải có mô
  tả thay đổi và cách kiểm tra tối thiểu.

---

## 12. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: 90% tác vụ tài liệu/template nhỏ được xử lý bằng quick flow có báo cáo phạm vi, thay
  đổi và kiểm tra đầy đủ.
- **SC-002**: Người dùng có thể phân loại đúng ít nhất 4/5 ví dụ là "quick" hoặc "cần Speckit đầy đủ"
  sau khi đọc hướng dẫn.
- **SC-003**: Không có thay đổi quick nào chạm dữ liệu, quyền, contract, release hoặc nhiều repo mà
  không được chuyển sang workflow Speckit đầy đủ.
- **SC-004**: Với tác vụ quick hợp lệ, thời gian từ yêu cầu đến báo cáo kết quả giảm ít nhất 30% so
  với việc tạo đầy đủ spec, plan và tasks riêng cho tác vụ đó.

---

## 13. Giả định & Ràng buộc

**Giả định**:
- Người dùng muốn quick flow cho các tác vụ nhỏ trong `flex-workstation`, không phải thay thế workflow
  Speckit đầy đủ.
- `/speckit.quick` là tên hiển thị mong muốn; runtime cụ thể có thể cần alias tương đương nếu không
  hỗ trợ dấu chấm trong command.
- Tác vụ quick chủ yếu là tài liệu, template, skill guidance, script hoặc cấu hình workspace có rủi
  ro thấp.

**Ràng buộc**:
- PHẢI tuân thủ constitution hiện hành, đặc biệt là spec-before-code, thay đổi phẫu thuật và không
  sửa code project con khi yêu cầu chỉ thuộc workstation.
- PHẢI giữ nguyên tiếng Việt có dấu cho phần người đọc/review và giữ technical identifiers bằng
  English/ASCII khi đó là định danh kỹ thuật.

---

## 14. Ngoài phạm vi

- Thay thế workflow `speckit-specify`, `speckit-plan`, `speckit-tasks` hoặc `speckit-implement`.
- Cho phép quick flow xử lý thay đổi dữ liệu, quyền, contract, migration, release hoặc nhiều repo.
- Tạo cơ chế tự động quyết định thay người dùng cho các thay đổi có rủi ro nghiệp vụ.
- Triển khai chi tiết runtime, file layout hoặc command registration; phần này thuộc plan kỹ thuật.

---

## 15. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Người dùng dùng quick flow cho task quá lớn | Trung | Cao | Quy định tiêu chí quick và điều kiện bắt buộc chuyển sang Speckit đầy đủ |
| Quick flow làm giảm traceability | Trung | Trung | Bắt buộc báo cáo phạm vi, thay đổi và kiểm tra tối thiểu |
| Tên `/speckit.quick` không tương thích với một runtime | Thấp | Trung | Cho phép tên tương đương nhưng giữ `/speckit.quick` là tên người dùng nhận biết |
| Ví dụ quá hẹp khiến người dùng áp dụng sai | Trung | Trung | Cung cấp ví dụ quick hợp lệ và ví dụ phải chuyển workflow đầy đủ |

---

## 16. Phụ thuộc

- Constitution hiện hành của `flex-workstation`.
- Bộ skill/runtime Speckit hiện có trong workspace.
- Quy ước agent hiện hành trong `AGENTS.md`, `CLAUDE.md` và tài liệu Speckit liên quan.

---

## 17. Câu hỏi mở

- Không có câu hỏi mở blocker tại thời điểm specify. Các giả định về tên runtime và phạm vi tác vụ
  quick đã được ghi rõ để xác nhận ở bước plan.

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
