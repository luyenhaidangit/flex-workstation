---
description: "Template danh sách task triển khai feature"
---

# Tasks: [TÊN TÍNH NĂNG]

**Đầu vào**: Artifacts thiết kế từ `/specs/[NNNNNN-ten-tinh-nang]/` (`spec.md`, `plan.md`, và `data-model.md` / `contracts/` / `research.md` / `quickstart.md` nếu có)  
**Chế độ Spec**: [Full / Compact]  
**Test Gate**: Bắt buộc sinh task kiểm thử tự động (viết fail trước khi code) hoặc task manual/command validation cụ thể (kèm lý do không áp dụng automated test) cho mọi rủi ro cần xác minh trong `plan.md`.

<!-- Quy tắc chi tiết xem tại .agents/skills/speckit-tasks/references/task-generation-rules.md. Lệnh /speckit-tasks PHẢI thay toàn bộ phần ví dụ dưới đây bằng task thật của feature; không giữ placeholder [FeatureName], [Entity], [UseCaseName], TXXX hay story không tồn tại trong spec.md. -->

## Format: `- [ ] T### [P?] [US#?] Mô tả hành động cụ thể kèm file path hoặc command`

- **`T###`**: Mã tăng tuần tự (`T001`, `T002`...).
- **`[P]`**: Chạy song song được (khác file, không phụ thuộc task chưa xong trong cùng phase; không liên quan priority `P1`/`P2`).
- **`[US#]`**: Bắt buộc cho các phase User Story (`[US1]`, `[US2]`...); không gắn cho Setup, Foundational, Polish.

---

## Phase 1: Setup (Shared Infrastructure)

**Mục đích**: Khởi tạo cấu trúc/cấu hình cần thiết (ghi `Không áp dụng` nếu repo đã sẵn sàng).

- [ ] T001 [Mô tả khởi tạo kèm path thật, hoặc xóa nếu không có task Setup riêng]

---

## Phase 2: Foundational (Blocking Prerequisites)

**Mục đích**: Hạ tầng dùng chung cho ≥2 user stories hoặc điều kiện bắt buộc (migration nền, contract/auth chung) PHẢI xong trước khi vào các story.

- [ ] T002 [Mô tả task nền tảng kèm path thật — không đặt task của riêng 1 story tại đây]

**Checkpoint**: Foundation hoàn tất — bắt đầu triển khai từng User Story.

---

## Phase 3: User Story 1 - [Tiêu đề] (Priority: P1) MVP

**Goal**: [Giá trị nghiệp vụ story này mang lại]  
**Independent Test**: [Các bước chạy lệnh / gọi API / thao tác UI và kết quả cụ thể để xác nhận độc lập US1]

### Tests / Validation cho User Story 1
- [ ] T003 [P] [US1] [Tạo unit/integration/contract test hoặc manual/command validation kèm path/command thật]

### Implementation cho User Story 1
- [ ] T004 [P] [US1] [Tạo/sửa model/DTO/validator kèm path thật — nếu sửa file có sẵn phải nêu rõ class/method]
- [ ] T005 [US1] [Implement handler/service/endpoint/UI kèm path thật (phụ thuộc T004)]

**Definition of Done (US1)**: Task của US1 hoàn tất, Independent Test pass, quyền/validation/log liên quan đã xử lý, không làm gãy luồng hiện có.

---

<!-- Thêm Phase 4 (US2), Phase 5 (US3)... CHỈ KHI các story đó thực sự tồn tại trong spec.md. -->

## Final Phase: Polish & Cross-Cutting Concerns

- [ ] T006 [Kiểm tra log không lộ secret/token, kiểm tra phân quyền chéo, chạy quickstart validation bằng command thật; chỉ thêm task tài liệu khi `plan.md` §Tác động tài liệu nghiệp vụ nêu rõ file + section còn lại]

---

## Validation Commands

- **Build**: `[command thật]`
- **Tests**: `[command thật]`
- **Quickstart / Smoke check**: `[command thật hoặc Không áp dụng]`

---

## Traceability Matrix

<!-- Liệt kê từng Task ID thực tế (không ghi gộp dạng range T003-T008 nếu lẫn task không liên quan). -->

| Nguồn (`MVP` / `US` / `FR` / `AC` / `BR` / `SEC` / `NFR`) | Covered by Task IDs |
|---|---|
| MVP-001 | T004, T005 |
| US1 / AC-001 | T003, T005 |
| FR-001 | T004, T005 |

---

## Dependencies & Parallel Opportunities

- **Thứ tự Phase**: `Setup` → `Foundational` → `User Stories (theo P1 → P2... hoặc song song nếu không đụng file tổng hợp)` → `Polish`.
- **Cơ hội chạy song song (`[P]`)**: [Liệt kê các cụm task `[P]` khác file và cách xử lý nếu nhiều story chạm chung file đăng ký DI/routes].

---

## Checklist chất lượng trước khi implement

- [ ] Không còn placeholder (`[FeatureName]`, `[Entity]`, `TXXX`) hay story giả định ngoài `spec.md`.
- [ ] Mọi task có ID tuần tự từ `T001`, có file path cụ thể (kèm tên class/method nếu sửa file cũ) hoặc command cụ thể.
- [ ] Không có hai task `[P]` cùng phase sửa chung một file; các phụ thuộc đã ghi rõ `(phụ thuộc T###)`.
- [ ] Mỗi User Story có `Independent Test`, `Definition of Done`, và test/validation task phủ rủi ro trong `plan.md`.
- [ ] `Traceability Matrix` đã phủ đủ `MVP`/`US`/`FR`/`BR`/`SEC`/`NFR` (kể cả từng vế của FR đa điều kiện).
