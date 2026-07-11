---
name: "speckit-quick"
description: "Execute a guarded quick flow for small, clear, low-risk tasks without creating a full Speckit feature artifact set."
argument-hint: "Describe the small task to complete"
compatibility: "Requires spec-kit project structure with .specify/ directory"
user-invocable: true
disable-model-invocation: false
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding. If the command was invoked with an empty task description, ask for a concrete quick task and stop.

## Command Identity

**User-facing name**: `/speckit.quick`

**Runtime aliases**:
- `$speckit-quick` in Codex skill invocation.
- `/speckit-quick` when slash-command runtimes support hyphenated command names.

Treat `/speckit.quick`, `$speckit-quick`, and `/speckit-quick` as the same quick flow. Do not present them as different workflows.

## Pre-Execution Checks

**Check for extension hooks (before quick flow)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_quick` key.
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally.
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable.
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation.
- When constructing slash commands from hook command names, replace dots (`.`) with hyphens (`-`). For example, `speckit.git.commit` -> `/speckit-git-commit`.
- For each executable hook, output the following based on its `optional` flag:
  - **Optional hook** (`optional: true`):
    ```text
    ## Extension Hooks

    **Optional Pre-Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```
  - **Mandatory hook** (`optional: false`):
    ```text
    ## Extension Hooks

    **Automatic Pre-Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}

    Wait for the result of the hook command before proceeding to the Outline.
    ```
    After emitting the block above, actually invoke the hook and wait for it to finish before continuing.
- If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently.

## Goal

Handle a small, clear, low-risk task in the current workspace faster than the full Speckit workflow, while preserving explicit scope, safety gates, validation, and traceability through the final response and Git diff.

This command is not a shortcut around governance. If the task is not clearly quick, stop before editing and route the user to `$speckit-specify <mô tả nghiệp vụ>`.

## Operating Constraints

- Do not create a new `spec.md`, `plan.md`, `tasks.md`, checklist, contract, or feature directory for a valid quick task.
- Do not change approved business meaning, data behavior, permissions, contracts, release behavior, or multiple repos.
- Do not write token, password, API key, connection string, credential, secret, or sensitive data into the repo or final report.
- Do not modify project sub-repos unless the user explicitly names that sub-repo as the scope and the task still passes the quick gate.
- Keep edits surgical. Do not refactor, reformat, or rewrite adjacent content outside the task.
- Work with existing uncommitted changes. Never revert changes you did not make.

## Outline

1. **Parse input**
   - Extract goal, intended scope, expected output, and minimum validation.
   - If any item is missing but can be inferred safely from context, state the assumption.
   - If missing information may change scope, ask a concise clarification question or stop with an escalation report.

2. **Run Quick Eligibility Gate**
   - Classify the task as `quick`, `needs clarification`, or `needs full Speckit`.
   - If classification is not `quick`, do not edit files. Produce the appropriate report.

3. **Emit Pre-Change Statement**
   Before editing, state:
   - Assumptions.
   - Scope to touch.
   - Out of scope.
   - Validation criteria.

4. **Execute the task**
   - Read current file state before editing.
   - Make the smallest viable change.
   - Avoid duplicate artifacts or repeated edits when rerun.
   - If a new risk appears during execution, stop, report any partial changes, and route to full Speckit.

5. **Validate**
   - Run the smallest relevant command or manual/static check.
   - Prefer `rg`, targeted file reads, `git diff --check`, or domain-specific checks already present in the repo.
   - If a check is not run, explain why.

6. **Report completion**
   - Use the Completion Report format below.

## Quick Eligibility Gate

The task is `quick` only when all conditions are true:

- Goal is clear.
- Scope is small and bounded to this workspace or an explicitly named scope.
- Risk is low.
- Validation can run in the same session.
- The change does not alter approved business meaning.
- The change does not touch data, schema, migration, or backfill.
- The change does not touch permission or security model.
- The change does not touch API, event, public contract, or release behavior.
- The change does not require multiple repos.

If any condition fails, classify as `needs full Speckit`.

## Ambiguous Input Handling

Classify as `needs clarification` when the request is probably small but lacks concrete scope, output, or validation. Examples: "dọn lại Speckit", "làm gọn docs", "sửa cho đúng", "tối ưu workflow".

For `needs clarification`, ask one concise question that narrows the file/khu vực, expected output, or validation. Do not edit until the answer makes the task quick.

## Escalation Rules

Classify as `needs full Speckit` and stop when the request involves:

- Data, schema, migration, backfill, or cleanup affecting persisted data.
- Permission, security model, authentication, authorization, or access checks.
- API, event, public contract, integration contract, or release behavior.
- Multiple repos or project sub-repos beyond a clearly named low-risk documentation edit.
- New business workflow, changed MVP, changed P1/P2 flow, or unapproved business meaning.
- A broad cleanup/refactor where the blast radius cannot be bounded safely.

## Pre-Change Statement Format

Use this shape before editing:

```markdown
Giả định: ...
Phạm vi sẽ chạm: ...
Ngoài phạm vi: ...
Tiêu chí kiểm tra: ...
```

If the task fails the gate, do not emit a pre-change statement for editing; emit an Escalation Report instead.

## Completion Report Format

When a quick task completes, report:

```markdown
Phạm vi đã xử lý: ...
File/khu vực đã đổi: ...
Kiểm tra đã chạy: ...
Kiểm tra không chạy: ...
Chưa làm: ...
Rủi ro còn lại: ...
Audit: actor=..., timestamp=..., action=..., changed artifacts=...
```

The report may be concise, but it must explicitly cover checks run or why checks were not run.

## Escalation Report Format

When the task is not quick, report:

```markdown
Không xử lý bằng quick flow.
Lý do: ...
Bước tiếp theo: $speckit-specify <mô tả nghiệp vụ>
File đã sửa: chưa sửa file nào.  # or list partial changes if risk appeared mid-task
Audit: actor=..., timestamp=..., action=escalate quick request, escalation reason=...
```

## Mandatory Post-Execution Hooks

**You MUST complete this section before reporting completion to the user.**

Check if `.specify/extensions.yml` exists in the project root.
- If it does not exist, or no hooks are registered under `hooks.after_quick`, skip to the Completion Report.
- If it exists, read it and look for entries under the `hooks.after_quick` key.
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue to the Completion Report.
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable.
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation.
- When constructing slash commands from hook command names, replace dots (`.`) with hyphens (`-`).
- For each executable hook, output the following based on its `optional` flag:
  - **Mandatory hook** (`optional: false`):
    ```text
    ## Extension Hooks

    **Automatic Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}
    ```
    After emitting the block above, actually invoke the hook and wait for it to finish before continuing.
  - **Optional hook** (`optional: true`):
    ```text
    ## Extension Hooks

    **Optional Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```

## Complete Quick Example

Input:

```text
$speckit-quick Cập nhật một câu trong docs/speckit/maintenance.md để ghi chú quick flow không dùng cho thay đổi data hoặc permission.
```

Classification: `quick`

Reason:
- One documentation file in the workstation.
- Clear output and low risk.
- Validation can be `rg` or diff review.

Pre-change statement:

```markdown
Giả định: chỉ làm rõ một câu trong docs/speckit/maintenance.md.
Phạm vi sẽ chạm: section Quick Flow.
Ngoài phạm vi: không sửa skill core, project con, hoặc tạo spec/plan/tasks mới.
Tiêu chí kiểm tra: rg -n "quick flow|data|permission" docs/speckit/maintenance.md
```

Completion report:

```markdown
Phạm vi đã xử lý: section Quick Flow.
File/khu vực đã đổi: docs/speckit/maintenance.md.
Kiểm tra đã chạy: rg -n "quick flow|data|permission" docs/speckit/maintenance.md.
Kiểm tra không chạy: không có.
Chưa làm: không có.
Rủi ro còn lại: thấp; chỉ là guidance tài liệu.
Audit: actor=agent, timestamp=<ISO-8601>, action=update quick-flow note, changed artifacts=docs/speckit/maintenance.md
```

## Escalation Example

Input:

```text
$speckit-quick Thêm quick flow để tự động sửa quyền truy cập người dùng trong flex-auth-service và cập nhật contract API liên quan.
```

Classification: `needs full Speckit`

Escalation report:

```markdown
Không xử lý bằng quick flow.
Lý do: task đụng permission, API/public contract và project con flex-auth-service.
Bước tiếp theo: $speckit-specify <mô tả nghiệp vụ>
File đã sửa: chưa sửa file nào.
Audit: actor=agent, timestamp=<ISO-8601>, action=escalate quick request, escalation reason=permission + contract + project con
```

## Classification Examples

| Input mẫu | Classification | Lý do |
|-----------|----------------|-------|
| "Sửa một câu trong `docs/speckit/maintenance.md` để làm rõ quick flow" | `quick` | Tài liệu nhỏ, một file, kiểm tra bằng diff/rg |
| "Đổi tên heading trong `README.md` cho khớp docs" | `quick` | Phạm vi nhỏ, không đổi behavior |
| "Dọn lại Speckit cho gọn hơn" | `needs clarification` | Có thể nhỏ, nhưng mục tiêu/phạm vi/kiểm tra chưa rõ |
| "Thêm permission mới cho user admin trong `flex-auth-service`" | `needs full Speckit` | Đụng permission và project con |
| "Cập nhật API contract cho endpoint đăng nhập" | `needs full Speckit` | Đụng public contract |

## Done When

- [ ] User input was classified as `quick`, `needs clarification`, or `needs full Speckit`.
- [ ] Quick tasks emitted a pre-change statement before edits.
- [ ] Quick tasks made only scoped changes and ran or explained validation.
- [ ] Non-quick tasks stopped with an escalation report and did not edit files.
- [ ] Extension hooks were dispatched or skipped according to the rules above.
- [ ] Final response included completion or escalation report.
