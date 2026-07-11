# Đặc tả tính năng: Việt hóa toàn bộ template Speckit

**Branch**: `[000004-speckit-templates-vietnamese]`

**Ngày tạo**: 2026-07-07

**Trạng thái**: Bản nháp

**Đầu vào**: Mô tả người dùng: "Mong muốn cập nhật toàn bộ template chứ không phải chỉ riêng checklist"

---

## 0. Tổng quan

Các template Speckit trong `.specify/templates/` vẫn còn nội dung tiếng Anh ở nhiều file, khiến artifact mới sinh ra không nhất quán với quy tắc workspace là dùng tiếng Việt có dấu trong trả lời, tài liệu và ghi chú. Tính năng này cập nhật toàn bộ template Speckit của workspace sang tiếng Việt cho phần người dùng đọc/review, giữ nguyên định danh kỹ thuật và không sửa skill gốc trong `.agents/skills/**`.

---

## 1. Mục tiêu

- **MĐ-01**: 100% template Speckit trong `.specify/templates/` dùng tiếng Việt có dấu cho heading, mô tả, ghi chú và sample content dành cho người đọc.
- **MĐ-02**: Artifact mới sinh từ các template `spec`, `plan`, `tasks`, `checklist`, `constitution` dễ review bằng tiếng Việt mà không cần dịch thủ công.
- **MĐ-03**: Template vẫn giữ đúng cấu trúc, placeholder và marker kỹ thuật cần thiết để các lệnh Speckit hoạt động.

---

## 2. Người dùng & Bối cảnh

**Người dùng chính**: Người vận hành Codex/Claude trong workspace Flex, người review spec/plan/tasks/checklist/constitution, và người bảo trì workflow Speckit.

**Bối cảnh sử dụng**: Khi chạy các bước Speckit sinh artifact từ `.specify/templates/`, người dùng cần artifact đầu ra có phần diễn giải tiếng Việt, còn command/path/placeholder kỹ thuật vẫn chính xác.

**Trình độ kỹ thuật**: Có hiểu biết về workflow Speckit và Markdown, nhưng không nên cần đọc tiếng Anh để review phần nội dung do template sinh ra.

---

## 3. Kịch bản người dùng *(bắt buộc)*

### Kịch bản 1 — Template Speckit sinh artifact tiếng Việt (Ưu tiên: P1)

Người dùng chạy một bước Speckit sinh artifact từ template workspace. Artifact mới có heading, mô tả, ghi chú và sample content bằng tiếng Việt có dấu, trong khi placeholder kỹ thuật vẫn giữ nguyên để agent/lệnh xử lý được.

**Lý do ưu tiên**: Đây là nhu cầu mở rộng trực tiếp từ checklist sang toàn bộ template, giúp workflow nhất quán.

**Test độc lập**: Mở từng file trong `.specify/templates/` và xác nhận phần người đọc là tiếng Việt có dấu; sau đó chạy static search để phát hiện nhãn tiếng Anh phổ biến còn sót.

**Kịch bản chấp nhận**:

1. **Cho trước** workspace yêu cầu tài liệu tiếng Việt, **Khi** template Speckit được dùng để sinh artifact mới, **Thì** artifact có phần hướng dẫn và cấu trúc hiển thị bằng tiếng Việt có dấu.
2. **Cho trước** một template có placeholder kỹ thuật hoặc placeholder hiển thị, **Khi** template được Việt hóa, **Thì** placeholder hiển thị có thể dùng tiếng Việt như `[TÊN TÍNH NĂNG]`, `[TÍNH NĂNG]`, `[LOẠI CHECKLIST]`, còn marker kỹ thuật như `[P]`, `[Story]`, `CHK###`, command và path vẫn không bị dịch sai.

---

### Kịch bản 2 — Template giữ đúng vai trò workflow (Ưu tiên: P2)

Người vận hành dùng template tiếng Việt trong workflow Speckit mà không làm mất cấu trúc bắt buộc, phase, gate, task marker hoặc section mà các command phụ thuộc.

**Lý do ưu tiên**: Việt hóa không được làm hỏng workflow hoặc khiến command sinh artifact thiếu phần cần thiết.

**Test độc lập**: So sánh từng template sau khi sửa với vai trò workflow của nó và xác nhận các section bắt buộc vẫn còn.

**Kịch bản chấp nhận**:

1. **Cho trước** `plan-template.md`, **Khi** template được Việt hóa, **Thì** vẫn còn các section tương đương với Constitution Check, Project Structure và Complexity Tracking.
2. **Cho trước** `tasks-template.md`, **Khi** template được Việt hóa, **Thì** vẫn còn format task `[ID] [P?] [Story] Description`, phase dependencies và parallel opportunities.

---

### Trường hợp biên

- Template có command, path, placeholder, marker hoặc mã item: giữ nguyên định danh kỹ thuật, chỉ Việt hóa phần diễn giải.
- Placeholder hiển thị cho người đọc có thể Việt hóa, ví dụ `[TÊN TÍNH NĂNG]`, `[TÍNH NĂNG]`, `[LOẠI CHECKLIST]`.
- Marker hoặc token workflow có ý nghĩa kỹ thuật phải giữ nguyên, ví dụ `[P]`, `[Story]`, `CHK###`, `$ARGUMENTS`, command và path.
- Template có ví dụ code block hoặc cây thư mục: giữ cấu trúc code block, chỉ Việt hóa comment/mô tả khi an toàn.
- Template có thuật ngữ kỹ thuật phổ biến như `MVP`, `API`, `contract`, `frontend`, `backend`: được giữ nguyên nếu đó là định danh hoặc thuật ngữ workflow.
- Skill gốc trong `.agents/skills/**` vẫn còn tiếng Anh từ upstream: không sửa trực tiếp trong feature này.

---

## 4. Yêu cầu chức năng *(bắt buộc)*

- **YC-001**: Hệ thống PHẢI Việt hóa phần người dùng đọc/review trong toàn bộ file Markdown dưới `.specify/templates/`.
- **YC-002**: Hệ thống PHẢI giữ nguyên định danh kỹ thuật như command, file path, YAML/JSON keys, placeholder, marker task, API, framework và mã checklist.
- **YC-003**: Template PHẢI giữ lại cấu trúc section cần thiết cho từng lệnh Speckit tương ứng.
- **YC-004**: Template task PHẢI giữ format task, dependency model, parallel marker `[P]` và mapping `[Story]`.
- **YC-005**: Template checklist PHẢI tiếp tục hướng item tới kiểm tra chất lượng requirement, không kiểm thử implementation.
- **YC-006**: Việc custom template KHÔNG ĐƯỢC sửa skill gốc trong `.agents/skills/**`.
- **YC-007**: Tài liệu workflow PHẢI ghi rõ template Speckit của workspace dùng tiếng Việt và giữ nguyên technical identifiers.

---

## 5. Yêu cầu phi chức năng

- **YCPCK-001**: Template sau khi sửa PHẢI dễ đọc trong Markdown preview phổ biến, không vỡ code block, bảng hoặc cây thư mục.
- **YCPCK-002**: Ít nhất 95% nội dung hướng tới người đọc trong `.specify/templates/*.md` PHẢI là tiếng Việt có dấu; phần còn lại chỉ dành cho định danh kỹ thuật, placeholder hoặc thuật ngữ workflow.
- **YCPCK-003**: Người review quen Speckit PHẢI xác định được mục đích từng template trong dưới 2 phút.

---

## 6. Thực thể dữ liệu

- **Speckit Template**: File Markdown trong `.specify/templates/` dùng để sinh artifact workflow.
- **Template Content**: Heading, mô tả, comment, sample item, bảng, notes và hướng dẫn dành cho người đọc.
- **Technical Identifier**: Command, path, placeholder, marker, code block, key hoặc thuật ngữ kỹ thuật cần giữ nguyên.
- **Generated Artifact**: Spec, plan, tasks, checklist hoặc constitution được sinh từ template.

---

## 7. Tiêu chí thành công *(bắt buộc)*

- **TC-001**: 5/5 template trong `.specify/templates/` được rà và cập nhật theo quy tắc tiếng Việt.
- **TC-002**: Static search không còn các heading/label tiếng Anh phổ biến trong phần người đọc của `.specify/templates/*.md`, trừ định danh kỹ thuật hoặc ví dụ có chủ đích.
- **TC-003**: `git diff -- .agents/skills` không có thay đổi sau khi hoàn tất feature.
- **TC-004**: `git diff --check` không báo lỗi whitespace.
- **TC-005**: `docs/speckit/templates.md` và `docs/speckit/workflow.md` phản ánh quy tắc chung cho toàn bộ Speckit templates, không chỉ checklist.

---

## 8. Giả định & Ràng buộc

**Giả định**:
- Người dùng muốn mở rộng scope từ checklist sang toàn bộ template Speckit trong `.specify/templates/`.
- Các template hiện tại là source custom chính của workspace.
- Một số thuật ngữ tiếng Anh kỹ thuật được giữ lại có chủ đích.

**Ràng buộc**:
- PHẢI tuân thủ quy tắc ngôn ngữ trong `AGENTS.md`.
- PHẢI giữ skill gốc trong `.agents/skills/**` nguyên trạng.
- PHẢI giữ cấu trúc Markdown và placeholder để workflow Speckit không bị hỏng.
- KHÔNG ĐƯỢC đưa token, mật khẩu, khóa API, connection string hoặc thông tin nhạy cảm vào template.

---

## 9. Ngoài phạm vi

- Không dịch hồi tố toàn bộ artifact đã sinh trước feature này, trừ artifact feature cần cập nhật để phản ánh scope mới.
- Không thay đổi bản chất workflow Speckit hoặc thứ tự các bước specify, clarify, checklist, plan, tasks, implement.
- Không thay đổi command, tên file, tên thư mục hoặc định danh kỹ thuật.
- Không sửa trực tiếp `.agents/skills/**`.

---

## 10. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Dịch nhầm placeholder hoặc marker kỹ thuật | Trung | Cao | Giữ nguyên nội dung trong backtick, placeholder và marker workflow |
| Việt hóa làm mất section mà command phụ thuộc | Thấp | Cao | Rà từng template theo cấu trúc gốc và chạy static review |
| Một số thuật ngữ tiếng Anh còn lại bị hiểu là lỗi | Trung | Thấp | Ghi rõ quy tắc giữ technical identifiers trong docs và template |
| Scope mở rộng làm task cũ thiếu coverage | Cao | Trung | Viết lại tasks theo từng template cụ thể |

---

## 11. Phụ thuộc

- Quy tắc ngôn ngữ trong `AGENTS.md`.
- Các template hiện có trong `.specify/templates/`.
- Người review xác nhận thuật ngữ tiếng Việt đủ rõ và không làm sai nghĩa workflow.

---

## 12. Câu hỏi mở

- Không có câu hỏi mở tại thời điểm cập nhật scope.
