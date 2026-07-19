---
name: "speckit-docbiz"
description: "Synthesize the current feature spec into a business narrative document in docs/bussiness/ — written for BA and non-technical stakeholders."
argument-hint: "Optional notes or extra context for the business doc"
compatibility: "Requires .specify/feature.json and a completed spec.md"
metadata:
  author: "flex-workstation"
  source: "local"
user-invocable: true
disable-model-invocation: false
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

### 1. Locate the current feature spec

Read `.specify/feature.json` to get `feature_directory` (e.g. `specs/000013-trading-session-bots`).

- Extract the **feature number prefix** from the directory name: the leading digit sequence before the first `-` (e.g. `000013`).
- Derive a **short display name** from the directory name: strip the numeric prefix and replace hyphens with spaces (e.g. `trading session bots`).

Load `<feature_directory>/spec.md`.
- If it does not exist, stop with: "spec.md not found in {feature_directory}. Run /speckit-specify first."

### 2. Check for an existing business doc

Scan `docs/bussiness/` for any `.md` file whose content contains the feature spec number (e.g. `000013`). Also check if any file references the feature directory path.

- **If found**: `DOC_FILE = <that file path>`, `MODE = update`
- **If not found**: `MODE = create`
  - Count existing `.md` files in `docs/bussiness/` to determine the next sequential number (e.g. if `01-*` and `02-*` exist, next is `03`). Zero-pad to 2 digits.
  - Derive `DOC_SLUG` from the feature directory short name: use the portion after the numeric prefix, keep hyphens (e.g. `trading-session-bots`).
  - `DOC_FILE = docs/bussiness/<NN>-<DOC_SLUG>.md`

### 3. Extract business content from spec.md

Read `spec.md` and extract only the business-relevant elements listed below. **Skip implementation details, technical constraints, and acceptance criteria details** — those belong in the spec.

| Spec section | What to extract |
|---|---|
| Header + Section 1 (Bối cảnh & vấn đề) | Feature name, MVP number (from dir prefix), business problem being solved, brief purpose |
| Section 2 (Mục tiêu) | Business objectives (MT-*) — rewrite as business outcomes in plain language |
| Section 3 (Phạm vi MVP) | What is in scope for this MVP (MVP-* items) |
| Section 4 (Người dùng) | Actors: roles, real-world responsibilities, FlexSim mapping |
| Section 5 (Kịch bản) | Derive the end-to-end business flow narrative from user stories (US-*); omit AC-* details |
| Section 8 (Quy tắc nghiệp vụ) | Business rules (BR-*); rephrase for non-technical audience; keep the WHY |
| Section 9 (Thực thể dữ liệu) | Key business entities and their business meaning; strip technical field details |
| Section 15 (Ngoài phạm vi) | Out-of-scope items; group by theme |
| Section 17 (Phụ thuộc) | Related documents for the reference section |

### 4. Generate the business narrative document

Write **entirely in Vietnamese**. Audience: BA and non-technical stakeholders who need to understand WHAT this MVP does and WHY, without reading technical specs or code.

- Explain the real-world business domain being simulated — not just the system behavior.
- Use plain, concrete language. Prefer examples over abstractions.
- For each business rule, state the real-world origin or rationale if available in spec, not just the rule.
- Do NOT mention framework names, database types, API endpoints, or code-level terms.

Use this document structure:

```markdown
# Nghiệp vụ MVP [NN] — [Feature name from spec]

## Mục đích và phạm vi

[2-4 sentences: business problem, what this MVP simulates, what it deliberately excludes, how it fits the FlexSim roadmap. Reference the spec file path.]

## Bối cảnh nghiệp vụ

[Explain the real-world business domain this MVP simulates — who the real actors are, what they do, how they interact. Use concrete terms. If applicable include a simple ASCII flow.]

## Vai trò trong thị trường thực tế

```text
[ASCII flow showing actor chain, e.g.: Actor A → Actor B → Actor C]
[Mark which segment is the scope of this MVP]
```

[Table: Vai trò | Trách nhiệm thực tế | Trong FlexSim MVP này]

## Luồng nghiệp vụ đầu-cuối

[Numbered list of steps in the full business flow. Mark which steps are IN SCOPE for this MVP and which steps are handled by other actors/MVPs.]

## Đối tượng nghiệp vụ và đầu ra

[Table: Đối tượng | Ý nghĩa trong MVP này]

## Quy tắc nghiệp vụ

[List of BR-* rules in plain language. For each rule, if it has a real-world origin (e.g. exchange regulation), mention it briefly.]

## Kịch bản và ngoại lệ

[Table: Tình huống | Kết quả nghiệp vụ mong đợi]

## Ngoài phạm vi

[Bullet list of what this MVP explicitly does NOT do. For each item, note which future MVP covers it if known from the spec.]

## Truy vết và nguồn tham khảo

- [Đặc tả tính năng](<feature_directory>/spec.md): user stories, acceptance criteria và ràng buộc kỹ thuật.
[+ any external regulation links or dependency docs extracted from spec Section 17]
```

### 5. Write or update the document

- **MODE = create**: Write the generated content to `DOC_FILE`. Create `docs/bussiness/` if it does not exist.
- **MODE = update**: Overwrite the existing file at `DOC_FILE` with the newly generated content. Do not change the filename.

### 6. Completion Report

Report to the user:
- `DOC_FILE` — path of the written document
- Mode: created / updated
- Key sections included
- Next step if applicable (e.g. `/speckit-plan` if planning has not started)

**HARD STOP**: This command is complete. Do NOT auto-invoke `/speckit-plan` or any other command. Report completion and wait for the user to explicitly invoke the next step.

## Done When

- [ ] `.specify/feature.json` read and feature directory resolved
- [ ] `spec.md` loaded from the feature directory
- [ ] `docs/bussiness/` scanned for an existing doc matching this feature
- [ ] Business narrative document written to `DOC_FILE`
- [ ] Completion reported to user with file path and mode
