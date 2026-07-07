# Tasks: Mở Nhanh Các Project Code

**Input**: Design documents từ `specs/000002-cmd-open-projects/`

**Prerequisites**: plan.md ✅ | spec.md ✅ | research.md ✅ | data-model.md ✅ | contracts/ ✅

**Tests**: Không yêu cầu trong spec — validation thủ công theo quickstart.md

**Organization**: Tasks nhóm theo user story; US1 và US2 dùng chung cùng 2 file implementation.

## Format: `[ID] [P?] [Story] Mô tả với đường dẫn file`

- **[P]**: Có thể chạy song song (khác file, không dependency)
- **[Story]**: User story tương ứng (US1, US2)

---

## Phase 1: Setup

**Purpose**: Xác nhận cấu trúc workspace sẵn sàng cho implementation

- [x] T001 Xác nhận thư mục `scripts/` tồn tại tại workspace root (tạo mới nếu chưa có)

---

## Phase 2: User Story 1 — Mở toàn bộ project bằng một click (Priority: P1) 🎯 MVP

**Goal**: Developer click đúp `OPEN_CODE.cmd` → tất cả repo trong `workstation.json` mở trong VS Code

**Independent Test**: Double-click `OPEN_CODE.cmd` → đếm cửa sổ VS Code mở ra khớp với số repo được clone

### Implementation

- [x] T002 [US1] Tạo `scripts/open-code.ps1` — đọc `workstation.json` từ `$PSScriptRoot\..`, duyệt `repositories.items`, kiểm tra `Test-Path` cho từng `name`, gọi `code <path>` nếu tồn tại, in `[SKIP] <name>: thư mục không tồn tại` nếu không
- [x] T003 [US1] Tạo `OPEN_CODE.cmd` tại workspace root — wrapper gọi `PowerShell -ExecutionPolicy Bypass -File "%~dp0scripts\open-code.ps1"`
- [ ] T004 [US1] Validate Scenario 1 (happy path) và Scenario 2 (skip missing repo) theo `specs/000002-cmd-open-projects/quickstart.md`

**Checkpoint**: `OPEN_CODE.cmd` hoạt động đúng khi double-click — US1 hoàn tất

---

## Phase 3: User Story 2 — Chạy từ command line (Priority: P2)

**Goal**: Gọi `OPEN_CODE.cmd` từ terminal tại workspace root cho kết quả giống double-click

**Independent Test**: Mở terminal, `cd` vào workspace root, gõ `OPEN_CODE.cmd` → kết quả giống Scenario 1

### Implementation

*(US2 dùng chung file với US1 — không cần thêm code)*

- [ ] T005 [US2] Validate Scenario 3 (run từ terminal) theo `specs/000002-cmd-open-projects/quickstart.md`

**Checkpoint**: US1 + US2 đều hoạt động — launcher sẵn sàng dùng thực tế

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Kiểm tra toàn diện và cập nhật tài liệu

- [ ] T006 Validate Scenario 4 (thêm repo mới vào `workstation.json` tự nhận diện) theo `specs/000002-cmd-open-projects/quickstart.md`
- [x] T007 [P] Kiểm tra `OPEN_CODE.cmd` xuất hiện trong thư mục root và consistent với các file launcher khác (`SYNC_WORKSPACE.cmd`, `OPEN_CLAUDE.cmd`, `OPEN_CODEX.cmd`) về naming convention
- [x] T008 [P] Cập nhật `docs/onboarding.md` nếu có mention bước mở project thủ công — thay bằng hướng dẫn dùng `OPEN_CODE.cmd`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Không dependency — bắt đầu ngay
- **US1 (Phase 2)**: Phụ thuộc Phase 1 — T002 và T003 có thể làm song song nhau
- **US2 (Phase 3)**: Phụ thuộc Phase 2 hoàn tất (T002, T003)
- **Polish (Phase 4)**: Phụ thuộc Phase 3

### Task Dependencies chi tiết

```
T001
 └── T002 ──┐
 └── T003 ──┴── T004 ── T005 ── T006
                                  └── T007 [P]
                                  └── T008 [P]
```

### Parallel Opportunities

- T002 và T003 không phụ thuộc nhau (khác file) → có thể làm song song
- T007 và T008 trong Phase 4 → có thể làm song song

---

## Parallel Example: User Story 1

```
# T002 và T003 có thể viết đồng thời:
Task A: "Tạo scripts/open-code.ps1"
Task B: "Tạo OPEN_CODE.cmd"
# → Merge và chạy T004 để validate
```

---

## Implementation Strategy

### MVP (User Story 1 only — ~30 phút)

1. T001: Xác nhận `scripts/` tồn tại
2. T002: Viết `scripts/open-code.ps1`
3. T003: Viết `OPEN_CODE.cmd`
4. T004: **VALIDATE** — double-click và kiểm tra
5. ✅ Dừng ở đây nếu US2 chưa cần thiết

### Full Delivery

1. MVP xong → T005 validate terminal usage
2. T006–T008: polish và docs
3. Commit toàn bộ

---

## Notes

- [P] = khác file, không dependency, có thể chạy song song
- US2 không cần code thêm — chỉ validation
- Không có test suite yêu cầu — validation thủ công đủ cho scope này
- Commit sau T004 (MVP) và sau T008 (full)
