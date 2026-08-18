---
name: "speckit-docbiz"
description: "Use when a feature spec changes: assess its business-documentation impact, then update the relevant existing business documents or create one only when no suitable document exists."
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

## Active Feature Reporting

In the Completion Report, print `ACTIVE_FEATURE_DIRECTORY: <resolved FEATURE_DIR>` as the first line before any other result.

You **MUST** consider the user input before proceeding (if not empty).

## Outline

### 1. Locate the current feature spec

Resolve `FEATURE_DIR` using `SPECIFY_FEATURE_DIRECTORY`, falling back to
`.specify/feature.json`. Load `<FEATURE_DIR>/spec.md`; if it does not exist, stop
with: "spec.md not found in {FEATURE_DIR}. Run /speckit-specify first."

Extract the feature number prefix and short display name from the directory name.

### 2. Run the Documentation Impact Assessment

This assessment is mandatory even when no document will be changed. Compare the
feature's business scope with the existing documentation and classify the result:

- **Material — update required**: the spec adds or changes an end-to-end business
  flow, actor responsibility or hand-off, business rule, business entity/lifecycle,
  business scope, or a stakeholder-facing compliance obligation.
- **Not material — no update required**: the change is implementation-only,
  refactoring, test/observability/performance work, or does not alter the business
  meaning already documented.

Do not treat a new feature number, a new API, or a technical design decision alone
as evidence of material documentation impact. State the concrete spec sections and
business facts that support the decision.

### 3. Find the right document before creating anything

Scan existing Markdown under `docs/business/` first, including
`business-docs-index.md`. Then scan other stakeholder-facing files under `docs/`
when the business subject is documented there. Match candidates in this order:

1. Explicit links to `FEATURE_DIR` or its feature number.
2. The same business domain, actor chain, entity, or end-to-end flow.
3. A cross-cutting document whose stated scope includes the changed rule or flow.

Do not select a document merely because it shares a generic word. Record the
evidence for every selected candidate.

- If the impact is **not material**, set `MODE = no-change`; do not create or edit a
  business document.
- If one or more suitable documents exist, set `MODE = update` and keep their
  existing filenames. Multiple documents may be updated when the change genuinely
  affects each of them.
- Create `docs/business/<NN>-<slug>.md` only when the impact is material and no
  suitable document exists. Derive `<NN>` from the highest existing two-digit
  business-document prefix, not from the number of Markdown files.

### 4. Extract only the business content needed for the change

Read `spec.md` and extract only the business-relevant elements below. Skip
implementation details, technical constraints, and acceptance-criteria mechanics.

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

### 5. Update conservatively or create a narrowly scoped document

Write entirely in Vietnamese for BA and non-technical stakeholders.

For `MODE = update`, edit only the sections affected by the assessed change. Preserve
unrelated content, existing structure, history, links, and filename. Do not replace
the whole document with a fresh feature narrative, duplicate an existing flow, or
invent a new document just to match the current feature number. Add or adjust the
spec trace link where appropriate.

For `MODE = create`, generate one business narrative using this structure:

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

- [Đặc tả tính năng](<FEATURE_DIR>/spec.md): user stories, acceptance criteria và ràng buộc kỹ thuật.
[+ any external regulation links or dependency docs extracted from spec Section 17]
```

### 6. Record the gate decision and update the index when needed

Update `spec.md` section `## 20. Đánh giá tác động tài liệu nghiệp vụ` with:

- assessment status: `CÓ CẬP NHẬT` or `KHÔNG CẦN CẬP NHẬT`;
- concise evidence from the spec;
- every document changed, or `Không áp dụng` for `MODE = no-change`.

If that section is absent in an older spec, add it after section 19 without
reordering unrelated content.

For `MODE = create`, also update `docs/business/business-docs-index.md` in its
appropriate existing category. Do not add an index row for a no-change assessment.

### 7. Completion Report

Report to the user:
- Documentation impact: material / not material, with the reason
- Mode: no change / updated / created
- `DOC_FILES` — paths changed, if any
- Sections updated and documents considered
- Next step if applicable (e.g. `/speckit-plan` if planning has not started)

**HARD STOP**: This command is complete. Do NOT auto-invoke `/speckit-plan` or any other command. Report completion and wait for the user to explicitly invoke the next step.

## Done When

- [ ] `FEATURE_DIR` resolved (`SPECIFY_FEATURE_DIRECTORY` env var, or `.specify/feature.json` fallback)
- [ ] `spec.md` loaded from the feature directory
- [ ] Documentation impact assessed against concrete business changes
- [ ] Existing documentation scanned and selected by evidence before any creation
- [ ] `spec.md` documentation-impact section updated
- [ ] Existing document updated minimally, or a new document and its index entry created only when required
- [ ] Completion reported with the assessment and affected paths
