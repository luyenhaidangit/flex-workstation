# Audit Rubric — judging a skill against fixed criteria

Read this when auditing a skill (named or catalog-wide) and for the pre-delivery adversarial review in SKILL.md's Quality bar. A verdict like "this skill looks fine" is not a finding; every judgment below maps to a criterion and a severity.

## Stance

Assume the skill has defects and look for them. The author of a skill, and an agent that just wrote it, read it charitably and approve it. A reviewer who is told to find the flaw reads what the text says instead of what its author meant.

## Criteria

| Criterion | Questions to answer from the files |
| --- | --- |
| Trigger precision | Does `description` state what, when (positive triggers), and when not (negative triggers)? Compare it with the routing-table rows and neighbouring descriptions in `flex-using-agent-skills`: would two skills fire on the same prompt? Which phrasing would cause a false positive or a miss? |
| Context efficiency | Does `SKILL.md` stay within the ~400-line guideline (no script checks it, so count)? Does it restate what the model already knows, or copy content that lives in a `references/` file or another skill? Are long tables and checklists in `references/`? |
| Instruction clarity | Do any two rules contradict? Is the step order unambiguous, including step numbering across modes? Are there vague verbs ("try to", "if appropriate") instead of IF/THEN conditions and a definition of done? Is there a fallback for missing input or a failing tool? |
| Tool and script safety | Does any command delete, overwrite, push, or edit shared files without asking the user first? Does a script read external data (web, logs, repo text) and let it steer actions, which opens a prompt-injection path? Are secrets kept out? |
| Output determinism | Is the output format literal, with an example? Could two runs produce different shapes of the same report? Are the labels in the language `AGENTS.md` requires for user-visible text? |

## Severity

- **Blocker** — breaks the workflow or is unsafe: contradictory rules that stall execution, a destructive step with no confirmation, a prompt-injection path, a skill that can never trigger.
- **Major** — lowers quality or wastes tokens: ambiguous triggers or collisions, duplicated checklists that will drift, missing output format, a missing negative-trigger clause.
- **Minor** — polish: wording, inconsistent numbers, an example that would sharpen a rule.

## Finding format

Report each finding in Vietnamese, ordered Blocker first:

```
[Major] flex-example / "When to use" — description trùng trigger với flex-other
Vấn đề: cả hai cùng nhận câu "review migration"
Hậu quả: router chọn sai skill khoảng một nửa số lần
Đề xuất: thêm vào description "Không dùng cho X (→ flex-other)"
```

A finding without a concrete replacement (text or diff) is incomplete. Sections with no finding get no line.
