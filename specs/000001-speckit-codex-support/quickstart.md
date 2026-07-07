# Quickstart: Xác nhận Speckit hoạt động trên cả hai agent

**Feature**: `specs/000001-speckit-codex-support`

---

## Prerequisites

- Codex CLI đã được cài (`codex --version`)
- Claude Code đã được cài (`claude --version`)
- Đang ở thư mục `flex-workstation` root

---

## Scenario 1 — Verify bootstrap tạo junctions đúng

### Chạy

```powershell
.\scripts\bootstrap.ps1 -SkipClaudeInstall -SkipCcusageInstall -SkipRtkInstall -SkipSpecifyInstall
```

### Expected output

```
==> Syncing skill junctions (.agents/skills -> .claude/skills)
[OK] Skill junctions synced: 10 skills (.agents/skills -> .claude/skills)
```

### Verify

```powershell
# Đếm skills trong source
(Get-ChildItem .agents\skills -Directory).Count
# Expected: 10

# Kiểm tra tất cả là junctions
Get-ChildItem .claude\skills | ForEach-Object {
    $isJunction = $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint
    "$($_.Name): $(if ($isJunction) { 'junction' } else { 'ERROR - real dir' })"
}
# Expected: mỗi dòng kết thúc bằng 'junction'
```

---

## Scenario 2 — Verify Claude Code thấy skills

### Chạy

```bash
claude
# Trong Claude Code session:
/skills
```

### Expected

Danh sách hiện ra gồm 10 speckit skills: `speckit-specify`, `speckit-plan`, `speckit-tasks`, v.v.

---

## Scenario 3 — Verify Codex thấy skills

### Chạy

```bash
codex
# Trong Codex session, gõ '$' để mở skill picker
```

### Expected

Danh sách hiện ra gồm 10 speckit skills với `name` và `description` đúng như trong `SKILL.md`.

---

## Scenario 4 — Verify chỉnh sửa skill sync tức thì

### Chạy

```bash
# Thêm một dòng comment vào skill source
echo "<!-- test -->" >> .agents/skills/speckit-specify/SKILL.md

# Đọc từ Claude Code path
tail -1 .claude/skills/speckit-specify/SKILL.md
# Expected: <!-- test -->

# Rollback
# Xóa dòng vừa thêm
```

### Expected

Nội dung giống hệt nhau — không có độ trễ sync vì junction đọc trực tiếp từ source.

---

## Scenario 5 — Verify skill mới được pickup tự động sau bootstrap

### Chạy

```powershell
# Tạo skill test
New-Item -ItemType Directory ".agents\skills\test-skill"
Set-Content ".agents\skills\test-skill\SKILL.md" @'
---
name: "test-skill"
description: "Temporary test skill"
---
Test skill content.
'@

# Chạy bootstrap
.\scripts\bootstrap.ps1 -SkipClaudeInstall -SkipCcusageInstall -SkipRtkInstall -SkipSpecifyInstall

# Kiểm tra junction
Test-Path ".claude\skills\test-skill"
# Expected: True

# Cleanup
Remove-Item -Recurse ".agents\skills\test-skill"
[System.IO.Directory]::Delete(".claude\skills\test-skill")
```

---

## Failure Modes

| Symptom | Cause | Fix |
|---------|-------|-----|
| `.claude/skills/<name>` là real dir, không phải junction | Clone repo cũ trước khi migrate | Chạy `bootstrap.ps1` để tự động migrate |
| Skill không hiện trong Codex | `.agents/skills/` chưa tồn tại | Chạy `bootstrap.ps1` |
| Junction tạo thất bại | Hai path trên ổ đĩa khác nhau | Directory Junction yêu cầu cùng ổ đĩa |
