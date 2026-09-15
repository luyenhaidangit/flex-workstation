# Language & Framework Conventions

Read this when the **placement** decision is non-obvious — i.e. you've run
`scripts/orient.py` but still aren't sure which layer or directory a change
belongs in, or you're working in an ecosystem whose conventions you want to
confirm before inventing structure. The goal is always the same: **put the
change where this ecosystem's maintainers would expect to find it**, beside its
existing siblings, using the layer names the framework already uses.

The skill's layering rule is universal (transport → domain → data, dependencies
point inward). What changes per ecosystem is the *vocabulary* and the *folder a
given concern conventionally lives in*. Use the table for your stack, then
confirm against what `orient.py` actually found in the repo — the real repo
always wins over this generic guide.

## Quick reference by ecosystem

### Python — Django
- Transport: `views.py` / DRF `viewsets`, `serializers.py`, `urls.py`.
- Domain/business logic: a `services.py` or a `services/` package per app —
  **not** in views and **not** in models. Fat models are acceptable for
  data-centric behavior, but orchestration belongs in services.
- Data: `models.py`, custom `managers.py`/`querysets.py` for reusable queries.
- Config/literals: `settings.py` + environment variables (django-environ).
- Tests: `tests/` package or `tests.py` per app; `test_*.py` naming.

### Python — FastAPI / Flask
- Transport: `routers/` (FastAPI) or `blueprints/` (Flask) — parse, validate,
  delegate only.
- Domain: `services/` or `domain/`. Pydantic models for I/O schemas live near
  the routers; domain entities stay framework-free.
- Data: `repositories/` or `db/`; SQLAlchemy models in `models/`.
- Config: a `Settings` (pydantic-settings) object loaded from env.

### JavaScript / TypeScript — Node/Express/Nest
- Transport: `routes/` or `controllers/` (Nest `*.controller.ts`).
- Domain: `services/` (`*.service.ts`), `use-cases/`, or `domain/`.
- Data: `repositories/`, `models/`, or an ORM layer (Prisma/TypeORM).
- Config: a central `config/` module reading `process.env`; never `process.env`
  scattered through business logic.
- Tests: co-located `*.test.ts`/`*.spec.ts` or a `__tests__/` dir — match what
  the repo already does.

### Frontend — React / Vue / Svelte
- Presentation: components render; they don't fetch or hold business rules.
- Data fetching: hooks (`useX`), a `queries/` or `api/` layer, or a store
  (Redux/Zustand/Pinia). Components call these, not `fetch` inline.
- Shared logic: `hooks/`, `lib/`, `utils/` — but only for genuinely shared,
  named concerns, never as a dumping ground.
- Constants/config: a `constants.ts` / `config.ts`; env via the bundler's
  mechanism (`VITE_*`, `NEXT_PUBLIC_*`).

### Java / Kotlin — Spring
- Transport: `@RestController` / `@Controller`.
- Domain: `@Service` classes; keep them focused, not one mega-service.
- Data: `@Repository` / Spring Data interfaces; entities in a `domain`/`model`
  package.
- Config: `application.yml` / `application.properties` + `@ConfigurationProperties`.
- Tests: `src/test/java`, mirroring the main package tree.

### Go
- Domain packages by capability (`order/`, `billing/`), not by layer name.
  Interfaces are defined by the *consumer* package, satisfied by providers.
- Transport: `handler/` or `http/`; wiring in `cmd/<binary>/main.go`.
- Data: `store/` or `repo/`.
- Config: a `config` package reading env/flags.
- Tests: `_test.go` beside the code under test.

### Ruby on Rails
- Transport: `app/controllers/`.
- Domain: `app/services/` (service objects) or `app/models/concerns/`; resist
  cramming everything into ActiveRecord models.
- Data: `app/models/`.
- Config: `config/` + Rails credentials/env.
- Tests: `spec/` (RSpec) or `test/` (Minitest), mirroring `app/`.

## How to use this

1. Identify the **concern** of your change (transport? business rule?
   persistence? presentation? config?).
2. Find the row for your stack and the directory that concern conventionally
   occupies.
3. Cross-check with `orient.py` output — if the repo deviates from the
   convention, follow the *repo*, and note the deviation in your Decision Log.
4. If no suitable home exists, that is a real signal: ask whether a new boundary
   is warranted rather than silently inventing a top-level directory.

## Anti-pattern reminder for placement

A new generic bucket — `utils/`, `helpers/`, `common/`, `misc/`, `core/`,
`manager/` — is almost never the right answer for genuinely new behavior. These
attract unrelated code and become god-modules. Name the actual concern
("`receipt/`", "`pricing/`", "`notifications/`") and give it a home next to
similar concerns instead.
