---
name: flex-database-engineering
description: Designs, changes, reviews, and validates PostgreSQL schemas and Liquibase migrations using safe, SQL-first conventions. Use when creating or changing database schema, changelogs, formatted SQL changesets, seed data, indexes, constraints, database functions, Liquibase CI/CD workflows, or reviewing migration safety.
---

# Database Engineering

## Overview

Apply safe, production-oriented conventions to PostgreSQL schema work and Liquibase migrations. Preserve immutable migration history, make ownership and dependencies explicit, and prefer the smallest forward-only change that fulfills the requested behavior.

This skill governs schema, migration, seed, and Liquibase delivery work. It does not invent business constraints, cross-service relationships, or destructive cleanup that the requirement does not explicitly authorize.

## When to Use

- Creating, changing, reviewing, or diagnosing a PostgreSQL schema.
- Adding a Liquibase changelog, release, formatted SQL changeset, seed script, view, function, procedure, trigger, index, or approved constraint.
- Planning a database migration project, its master changelog, include order, local workflow, or CI/CD checks.
- Investigating Liquibase validation, checksum, include-order, locking, or migration-history problems.
- Reviewing a pull request for data-loss, compatibility, schema-drift, or deployment risks.

Do not use this skill for application-only persistence code that does not change database behavior. Use the applicable service engineering skill for EF Core mapping and application behavior, then apply this skill to the database migration boundary when it is in scope.

## Core Process

### 1. Establish scope, authority, and risk

Before modifying files or applying a database change:

1. Identify the target repository, database, PostgreSQL version, Liquibase entry point, affected tables/objects, and deployment environment.
2. Read repository instructions, database documentation, master changelog, the relevant release/domain changelog, and nearby changesets before choosing a location or format.
3. Classify the request: baseline, new migration, seed, repeatable programmable object, review, or operational diagnosis.
4. State the acceptance criteria, non-goals, compatibility risk, locking impact, and whether the request authorizes an actual database update.

Stop for direction when the target database, ownership boundary, release state, or permission to apply a migration is unclear. Never silently choose a production database or infer authority for destructive operations.

### 2. Determine database ownership and migration topology

Use existing repository conventions first. Where they are silent:

- A service that independently owns its database also owns its migration chain. Do not centralize unrelated microservice databases in one Liquibase project merely for convenience.
- A shared database can organize migrations by bounded context/domain, with one master changelog that includes each domain in a deliberate dependency order.
- Keep baseline schema distinct from post-release history when the project has an established baseline. Do not rewrite the baseline merely to make current schema look cleaner.
- Treat migration history as chronological. Grouping by domain/release is useful; grouping all future files only by object type (`table/`, `index/`, `alter/`) obscures ordering and evolution.
- DEV, TEST, STAGING, and PROD must use the same migration chain. Only connection and credentials vary by environment.

Keep one clear entry point per database. YAML or XML should orchestrate includes; use Liquibase formatted SQL for PostgreSQL DDL/DML when that is the local convention.

### 3. Design a safe changeset

For each intended change:

1. Create a new changeset in the next valid release/domain/timeline location. Follow the repository's naming pattern; if none exists, use `YYYYMMDD-sequence-description` consistently.
2. Give the changeset a stable, unique `author:id`. Do not rename, move, delete, or change the SQL of a changeset already executed in a shared environment.
3. Include the file exactly once, after all objects it depends on and before all objects that depend on it. Do not rely on accidental filesystem order.
4. Make compatibility explicit. Prefer expand → deploy compatible application → backfill/verify → contract for changes that could break old application versions or long-running workloads.
5. Add a rollback only when it is correct, scoped, and authorized. For production changes with data-loss or irreversibility risk, prefer backup/restore planning or a forward-fix rather than an automatic rollback.

Use PostgreSQL-compatible SQL. Name indexes and approved constraints explicitly. Create only the tables, columns, indexes, constraints, and programmable objects required by the stated specification.

### 4. Apply object-specific rules

#### Tables, columns, and constraints

- Do not add `FOREIGN KEY`, `CHECK`, `UNIQUE`, or business constraints unless the specification explicitly requires them. Application services may own validation across independent databases.
- Do not create foreign keys, joins, or transactions across independently owned business databases.
- Use `IF NOT EXISTS` only when intentional idempotency is required and a separate validation can detect an incompatible existing definition. Do not use it by default for indexes or constraints because it can hide schema drift.
- For write-heavy tables, favor compact, locality-friendly keys according to established repository practice. Do not introduce UUIDv4 as a primary key merely by habit.
- Use clear, stable names for indexes and constraints. A migration should fail visibly when the expected schema is absent or incompatible, unless the requirement explicitly accepts a controlled idempotent path.

#### Indexes and expensive changes

- Check table size, lock behavior, query need, and PostgreSQL capabilities before adding/rebuilding an index or changing a heavily used column.
- Do not use a transaction-invalid operation inside a transactional changeset. Use Liquibase transaction controls only when required by the specific PostgreSQL operation and document why.
- Avoid broad `DROP`/recreate patterns; target the named object only, and only when the change owns that object.

#### Seed and repeatable objects

- Seed only reference/local/test data unless production seed data is explicitly approved.
- Identify the business keys owned by a seed script. Never delete a whole table or unrelated records to refresh a seed set; do not hard-code generated surrogate IDs.
- Use `CREATE OR REPLACE` for functions, procedures, and views when the repository's repeatable-object strategy permits it. Use `runOnChange` or `runAlways` only when the intended re-execution behavior is explicit.
- Keep triggers, functions, views, and indexes in separate, clearly scoped changesets when their lifecycle differs from the table change.

#### Classified domain values

- For classified columns such as `status`, `type`, and `category`, define the domain value set and its business meaning before choosing storage.
- Use the same canonical vocabulary in the database and application contracts. Do not allow free-form text or duplicate inline string literals such as `"active"`, `"Active"`, and `"enabled"` for one domain state.
- Choose the representation by changeability: use an application enum or shared constants when the value set is stable; use reference data when values require administration, metadata, localization, ordering, or likely expansion.
- Persist a stable code when appropriate (for example, `PENDING`), rather than a UI label. Labels and presentation metadata belong in the application or reference data.
- Do not introduce a PostgreSQL enum by default. Use it only when its migration cost and the value set's long-term stability are explicitly accepted.

### 5. Protect configuration and deployment

- Keep passwords, tokens, real connection strings, and production hostnames out of source, changelogs, command output, and documentation.
- Commit examples/templates only; obtain credentials from environment variables, CI/CD secrets, or the approved secret manager.
- Run migrations before application code that requires the new schema, following the repository deployment order.
- Rely on Liquibase's `DATABASECHANGELOG` and `DATABASECHANGELOGLOCK`; do not create competing ad-hoc migration tracking.
- Do not run `liquibase update` against a real database unless the user explicitly asks, the target is identified, and the normal preview/validation steps have succeeded.

### 6. Verify and report evidence

Use repository scripts first. Otherwise, from the target database directory run the narrowest safe checks:

```text
liquibase --changelog-file=<master-changelog> validate
liquibase --changelog-file=<master-changelog> update-sql
```

Before reporting completion, verify changelog syntax and include order, inspect generated SQL, and review the diff for secret exposure and accidental destructive operations. After an explicitly authorized update, use `liquibase history` or `liquibase status --verbose` to confirm the applied state.

Report changed files, database target, commands actually run and their result, whether any database was updated, compatibility/rollback strategy, and any remaining operational risk.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "It is faster to edit the old changeset." | Liquibase checksums and deployed environments make historical changes unsafe. Create a new changeset. |
| "`IF NOT EXISTS` makes the migration safer." | It can silently preserve a wrong index or constraint definition and hide schema drift. Use it only with intentional idempotency and validation. |
| "Each environment needs its own migration SQL." | Divergent chains make promotion unreliable. Environments differ by configuration, not schema history. |
| "Rollback is always safer." | A rollback can lose newer data or be logically incorrect. Production recovery often needs backup/restore or a forward-fix. |
| "The service will need this index/constraint eventually." | Speculative schema creates permanent operational cost and behavior that nobody asked for. Add it when a concrete requirement exists. |
| "Validation passed, so it is safe to apply." | `validate` does not prove generated SQL, locks, data compatibility, or the target environment. Inspect `update-sql` and deployment risk. |

## Red Flags

- An executed changeset has altered SQL, `id`, `author`, path, or filename.
- A master changelog includes the same file twice, a copied SQL file, or relies on unverified directory order.
- A migration branches by environment instead of using shared history.
- `DROP TABLE`, `TRUNCATE`, broad `DELETE`, destructive rollback, or a rebuild is proposed without explicit authorization and recovery planning.
- `IF NOT EXISTS` masks a potentially incorrect index or constraint.
- A schema change adds a cross-database foreign key, join, or transaction.
- A new constraint or index has no requirement, query evidence, or migration compatibility assessment.
- A real secret or connection value appears in a file, terminal output, or final report.
- `liquibase update` is being run without an identified target and explicit user authorization.
- A result is reported as validated or applied without observed command output.

## Verification

- [ ] Applicable repository instructions, master changelog, and nearby migration conventions were read before the change.
- [ ] Database ownership, migration location, include order, and dependencies are explicit.
- [ ] No previously executed changeset was edited, moved, renamed, or removed.
- [ ] SQL is compatible with the target PostgreSQL version and object naming follows local convention.
- [ ] Constraints, indexes, FK relationships, and destructive actions are directly justified by the requirement.
- [ ] No secret, password, token, or real connection detail is included in files or output.
- [ ] `liquibase validate` and `update-sql` ran successfully when the tooling and target configuration are available; otherwise the limitation is stated.
- [ ] `liquibase update` ran only with explicit authorization; otherwise the report explicitly says no database was updated.
- [ ] After an authorized update, Liquibase history/status confirms the expected changeset state.
- [ ] The final handoff states changed files, validation evidence, deployment/compatibility plan, and residual risk.
