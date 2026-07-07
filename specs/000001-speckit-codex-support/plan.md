# Implementation Plan: Speckit hỗ trợ Codex

**Branch**: `000001-speckit-codex-support` | **Date**: 2026-07-07 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/000001-speckit-codex-support/spec.md`

---

## Summary

Workspace hiện tại có 10 speckit skills chỉ nằm trong `.claude/skills/` — chỉ Claude Code tìm thấy. Codex CLI scan `.agents/skills/` theo cross-agent standard. Giải pháp: di chuyển skills sang `.agents/skills/` làm source of truth, tạo Windows Directory Junctions ngược lại `.claude/skills/` để Claude Code tiếp tục hoạt động. Bootstrap tự tạo/refresh junctions — không cần setup thủ công ở máy mới.

---

## Technical Context

**Language/Version**: PowerShell 5.1 (Windows), Bash (POSIX)

**Primary Dependencies**: Codex CLI, Claude Code, NTFS Directory Junctions (mklink /J)

**Storage**: Filesystem — `.agents/skills/` (source), `.claude/skills/` (junctions, gitignored)

**Testing**: Manual — bootstrap smoke test, skill picker verification trong cả hai agent

**Target Platform**: Windows 11 (workstation); Git Bash available

**Project Type**: Workspace configuration / tooling

**Performance Goals**: N/A — one-time bootstrap setup

**Constraints**: Không dùng admin rights; không tạo file config mới nếu không cần thiết

**Scale/Scope**: 10 speckit skills, 2 agents (Claude Code + Codex)

---

## Constitution Check

*GATE: Pass trước Phase 0. Re-check sau Phase 1.*

| Nguyên tắc | Gate | Status | Ghi chú |
|------------|------|--------|---------|
| I — Workspace Coordination | Thay đổi chỉ trong workstation root, không trong sub-repo | ✅ PASS | Chỉ động đến `.agents/`, `.claude/`, `scripts/`, `AGENTS.md`, `.gitignore` |
| II — Spec-Before-Code | Spec `000001` phải tồn tại và đầy đủ trước khi implement | ✅ PASS | `specs/000001-speckit-codex-support/spec.md` hoàn chỉnh, checklist 15/15 |
| III — Agent-Agnostic Tooling | Skill source tại `skills/` hoặc `.agents/skills/` — không hardcode vào một agent | ✅ PASS | `.agents/skills/` là source of truth; `.claude/skills/` chỉ là junctions |
| IV — Bootstrap Reproducibility | Setup tự động qua `SYNC_WORKSPACE.cmd` | ✅ PASS | `Sync-SkillJunctions` thêm vào `bootstrap.ps1` |
| V — Surgical Changes | Chỉ sửa đúng những gì cần | ✅ PASS | Không thay đổi nội dung skill, không refactor code không liên quan |

**Post-Phase 1 re-check**: Tất cả gates vẫn PASS — không có vi phạm phát sinh từ design.

---

## Project Structure

### Documentation (this feature)

```text
specs/000001-speckit-codex-support/
├── spec.md              ✅ (speckit-specify)
├── plan.md              ✅ (speckit-plan — this file)
├── research.md          ✅ (speckit-plan Phase 0)
├── data-model.md        ✅ (speckit-plan Phase 1)
├── quickstart.md        ✅ (speckit-plan Phase 1)
├── contracts/
│   └── skill-directory.md  ✅ (speckit-plan Phase 1)
└── tasks.md             ⬜ (speckit-tasks — not yet)
```

### Source Code (repository root)

```text
flex-workstation/
├── .agents/
│   └── skills/                    ← skill source of truth (10 SKILL.md dirs)
│       ├── speckit-analyze/
│       ├── speckit-checklist/
│       ├── speckit-clarify/
│       ├── speckit-constitution/
│       ├── speckit-converge/
│       ├── speckit-implement/
│       ├── speckit-plan/
│       ├── speckit-specify/
│       ├── speckit-tasks/
│       └── speckit-taskstoissues/
├── .claude/
│   └── skills/                    ← directory junctions (gitignored, machine-local)
│       └── speckit-*/             → .agents/skills/speckit-*/
├── scripts/
│   └── bootstrap.ps1              ← Sync-SkillJunctions function
├── AGENTS.md                      ← speckit workflow documentation cho Codex
└── .gitignore                     ← .claude/skills/ excluded
```

**Structure Decision**: Workspace-only change — không có src/, tests/ hay backend/frontend. Tất cả thay đổi là config files và directory structure trong workspace root.

---

## Implementation Tasks

Các tasks đã hoàn thành trong phiên làm việc 2026-07-07:

| # | Task | File(s) | Status |
|---|------|---------|--------|
| 1 | Di chuyển 10 skills sang `.agents/skills/` | `.agents/skills/*/SKILL.md` | ✅ Done |
| 2 | Tạo directory junctions `.claude/skills/<name>` | `.claude/skills/` | ✅ Done |
| 3 | Thêm `Sync-SkillJunctions` vào bootstrap | `scripts/bootstrap.ps1` | ✅ Done |
| 4 | Ignore `.claude/skills/` trong git | `.gitignore` | ✅ Done |
| 5 | Bổ sung Speckit Workflow vào AGENTS.md | `AGENTS.md` | ✅ Done |

**Còn lại** (dành cho `/speckit-tasks`):
- Verify Codex thực sự pickup `.agents/skills/` (Scenario 3 trong quickstart.md)
- Cleanup dangling junctions nếu skill bị xóa (optional — xem contracts/skill-directory.md)
