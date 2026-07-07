---
description: "Task list for speckit-codex-support implementation"
---

# Tasks: Speckit hỗ trợ Codex

**Input**: Design documents from `specs/000001-speckit-codex-support/`

**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/skill-directory.md ✅

**Note**: Tính năng này là workspace configuration — không có src/ hay tests/. Tất cả thay đổi nằm trong workspace root files.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Có thể chạy song song (file khác nhau, không phụ thuộc nhau)
- **[Story]**: User story tương ứng (US1, US2)

---

## Phase 1: Setup (Chuẩn bị)

**Purpose**: Đảm bảo workspace ở trạng thái sẵn sàng để migrate.

- [x] T001 Xác nhận `.agents/skills/` directory tồn tại và có thể ghi (bootstrap đã tạo `.agents/` trong `Initialize-WorkspaceProjectConfig`)

---

## Phase 2: Foundational — Di chuyển skill source

**Purpose**: Di chuyển skill source sang vị trí agent-agnostic. Bắt buộc hoàn thành trước khi thực hiện cả hai user story.

**⚠️ CRITICAL**: US1 và US2 đều phụ thuộc phase này.

- [x] T002 Copy 10 speckit skills từ `.claude/skills/*/SKILL.md` sang `.agents/skills/*/SKILL.md`
- [x] T003 Xóa các thư mục gốc trong `.claude/skills/` (sau khi đã copy sang `.agents/skills/`)

**Checkpoint**: `.agents/skills/` có đủ 10 skill directories, `.claude/skills/` rỗng — sẵn sàng tạo junctions.

---

## Phase 3: User Story 1 — Codex chạy speckit (Ưu tiên: P1) 🎯 MVP

**Goal**: Codex CLI tìm thấy và invoke được 10 speckit skills từ `.agents/skills/`.

**Independent Test**: Mở Codex CLI, gõ `$` để mở skill picker, xác nhận 10 speckit skills hiện ra với đúng `name` và `description`.

### Implementation

- [x] T004 [US1] Tạo 10 Windows Directory Junctions `.claude/skills/<name>` → `.agents/skills/<name>` (dùng `mklink /J` qua PowerShell)
- [x] T005 [P] [US1] Thêm hàm `Sync-SkillJunctions` vào `scripts/bootstrap.ps1` — idempotent, tự migrate legacy real-dirs thành junctions
- [x] T006 [US1] Thêm lời gọi `Sync-SkillJunctions` vào luồng bootstrap chính trong `scripts/bootstrap.ps1` (sau `Initialize-WorkspaceProjectConfig`)
- [x] T007 [P] [US1] Thêm `.claude/skills/` vào `.gitignore` với comment giải thích lý do (junctions là machine-local)
- [ ] T008 [US1] Verify live: Mở Codex CLI trong workspace, xác nhận skill picker hiển thị 10 speckit skills (Scenario 3 trong `quickstart.md`)

**Checkpoint**: Codex tìm thấy skills từ `.agents/skills/`. Thay đổi nội dung skill tại `.agents/` tự động có hiệu lực cho cả hai agent (Scenario 4 trong `quickstart.md`).

---

## Phase 4: User Story 2 — AGENTS.md với speckit workflow (Ưu tiên: P2)

**Goal**: `AGENTS.md` có đầy đủ bảng Development Workflow 9 bước speckit cho Codex, tương đương với phần trong `CLAUDE.md`/constitution.

**Independent Test**: Đọc `AGENTS.md`, xác nhận thấy bảng với đủ 9 lệnh `$speckit-*` và chú thích optional/required.

### Implementation

- [x] T009 [US2] Thêm section "Speckit Workflow" vào `AGENTS.md` với bảng 9 bước dùng cú pháp Codex (`$speckit-*`) và note về vị trí skill source

**Checkpoint**: Developer Codex mới có thể đọc `AGENTS.md` và biết đủ để bắt đầu luồng speckit.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Verify toàn bộ, đảm bảo không có regression.

- [ ] T010 [P] Chạy Scenario 1 (bootstrap smoke test): `.\scripts\bootstrap.ps1 -SkipClaudeInstall -SkipCcusageInstall -SkipRtkInstall -SkipSpecifyInstall` — xác nhận output "[OK] Skill junctions synced: 10 skills"
- [ ] T011 [P] Chạy Scenario 2 (Claude Code smoke test): Mở Claude Code, chạy `/skills`, xác nhận 10 speckit skills vẫn hiển thị (no regression)
- [ ] T012 Chạy Scenario 5 (new skill pickup): Tạo test skill trong `.agents/skills/`, chạy bootstrap, xác nhận junction tự động xuất hiện, cleanup

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1** (Setup): Không phụ thuộc — bắt đầu ngay
- **Phase 2** (Foundational): Phụ thuộc Phase 1 — **BLOCKS cả US1 và US2**
- **Phase 3** (US1): Phụ thuộc Phase 2 completion
- **Phase 4** (US2): Phụ thuộc Phase 2 completion — **có thể chạy song song với Phase 3**
- **Phase 5** (Polish): Phụ thuộc Phase 3 + 4 completion

### User Story Dependencies

- **US1 (P1)**: Không phụ thuộc US2 — độc lập hoàn toàn
- **US2 (P2)**: Không phụ thuộc US1 — độc lập hoàn toàn sau Phase 2

### Parallel Opportunities

- T002, T003: tuần tự (T003 phụ thuộc T002)
- T004, T005, T007: có thể song song (T004 tạo junctions, T005 viết hàm, T007 gitignore — file khác nhau)
- T006: phụ thuộc T005
- T009: hoàn toàn độc lập với T004-T007
- T010, T011: song song (verify hai agent riêng)

---

## Parallel Example: Phase 3 + Phase 4

```
# Sau khi Phase 2 hoàn thành, có thể làm song song:

Agent/Session A (US1):
  T004 — tạo junctions
  T005 — viết Sync-SkillJunctions function  [P với T004, T007]
  T007 — cập nhật .gitignore               [P với T004, T005]
  T006 — gọi hàm trong bootstrap           (sau T005)
  T008 — verify live Codex

Agent/Session B (US2):
  T009 — cập nhật AGENTS.md
```

---

## Implementation Strategy

### MVP (US1 — Codex chạy speckit)

1. ✅ Phase 2: Di chuyển skill source
2. ✅ Phase 3: T004-T007 (junctions + bootstrap + gitignore)
3. ⬜ Phase 3: T008 — verify live với Codex CLI
4. **STOP và VALIDATE**: Codex thấy 10 skills, Claude Code không bị regression

### Incremental Delivery

1. ✅ Phase 2 + Phase 3 (T004-T007) → Foundation + US1 code complete
2. ⬜ T008 → US1 verified live
3. ✅ Phase 4 (T009) → US2 complete (documentation)
4. ⬜ Phase 5 (T010-T012) → Full verification pass

---

## Notes

- **Tất cả T001–T007, T009** đã hoàn thành trong phiên làm việc 2026-07-07
- **T008** (live Codex verify) cần chạy thủ công với Codex CLI thực tế
- **T010–T012** là verification scenarios từ `quickstart.md`
- Khi thêm skill mới vào `.agents/skills/` trong tương lai: chạy bootstrap để tạo junction tự động
- Xóa skill: xóa trong `.agents/skills/`, xóa junction trong `.claude/skills/` thủ công (chưa có automation)
