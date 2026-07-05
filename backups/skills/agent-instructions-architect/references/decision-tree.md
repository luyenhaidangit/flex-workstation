# Decision Tree — Chọn tầng instruction

```
Áp dụng cho ai/khi nào?
│
├─ Mọi session trong project, mọi người
│  ├─ Stable, project-wide, ngắn → CLAUDE.md (root)
│  ├─ Chỉ áp dụng trong subdir → CLAUDE.md (subdir) hoặc rules file path-scoped
│  └─ Một rule ngắn, path-scoped, độc lập → .claude/rules/<topic>.md
│
├─ Chỉ user này, mọi project
│  └─ ~/.claude/CLAUDE.md
│
├─ Học/tích lũy theo conversation (xuất hiện dần qua tương tác)
│  ├─ Về user (role, preference, expertise) → memory type=user
│  ├─ User correct hoặc confirm cách làm → memory type=feedback (kèm Why + How to apply)
│  ├─ Context project (deadline, decision, motivation) → memory type=project (kèm Why + How to apply)
│  └─ Pointer ra hệ thống ngoài (Linear, Grafana, Slack...) → memory type=reference
│
├─ Khi Claude làm task cụ thể cần context riêng / tool allow-list riêng
│  └─ Subagent (.claude/agents/)
│
├─ Khi user gõ /xxx
│  └─ Slash command (.claude/commands/)
│
├─ Khi user invoke skill, hoặc skill auto-trigger theo description
│  └─ SKILL.md (.claude/skills/)
│
└─ Đổi tone / format / cách trình bày output (không đổi hành vi)
   └─ Output style (.claude/output-styles/)
```
