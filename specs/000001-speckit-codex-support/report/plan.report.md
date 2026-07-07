# Plan Report: Speckit hỗ trợ Codex

**Feature**: `specs/000001-speckit-codex-support`
**Date**: 2026-07-07
**Phase**: Plan complete

---

## Tổng số tasks

**5 tasks** — tất cả đã hoàn thành trong phiên speckit-specify + research (2026-07-07).

---

## Danh sách tasks theo dependency order

| # | Task | Phụ thuộc | Status |
|---|------|-----------|--------|
| T-01 | Di chuyển 10 skills từ `.claude/skills/` sang `.agents/skills/` | — | ✅ Done |
| T-02 | Tạo directory junctions `.claude/skills/<name>` → `.agents/skills/<name>` | T-01 | ✅ Done |
| T-03 | Thêm `Sync-SkillJunctions` vào `scripts/bootstrap.ps1` | T-01 | ✅ Done |
| T-04 | Ignore `.claude/skills/` trong `.gitignore` | T-02 | ✅ Done |
| T-05 | Bổ sung Speckit Workflow section vào `AGENTS.md` | T-01 | ✅ Done |

---

## Risks đã xác định

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Codex CLI không thực sự pickup `.agents/skills/` trên máy cụ thể | Thấp | Cao | Chạy Scenario 3 trong quickstart.md để verify |
| Directory Junction không tạo được (ổ đĩa khác, permissions) | Thấp | Cao | Bootstrap warning + manual fallback documented |
| Skill mới thêm sau này không tự có junction | Trung | Trung | `Sync-SkillJunctions` trong bootstrap xử lý — nhưng cần nhớ chạy bootstrap |

---

## Assumptions đã xác định

1. Codex CLI scans `.agents/skills/` — confirmed qua research, documented trong `research.md`
2. Claude Code chỉ scan `.claude/skills/` — confirmed, feature request custom path chưa có timeline
3. Windows Directory Junctions không cần admin rights — confirmed với `mklink /J`
4. Workstation luôn chạy trên cùng ổ đĩa (Junction yêu cầu same volume) — hợp lý cho single-machine dev setup

---

## Estimated Effort

| Task | Thực tế |
|------|---------|
| Research (Q1, Q2, Q3) | ~30 phút |
| Migration + junctions | ~10 phút |
| Bootstrap update | ~5 phút |
| AGENTS.md update | ~5 phút |
| Spec/plan/docs | ~20 phút |
| **Total** | **~70 phút** |

---

## Artifacts sinh ra

- `specs/000001-speckit-codex-support/research.md`
- `specs/000001-speckit-codex-support/plan.md`
- `specs/000001-speckit-codex-support/data-model.md`
- `specs/000001-speckit-codex-support/quickstart.md`
- `specs/000001-speckit-codex-support/contracts/skill-directory.md`
