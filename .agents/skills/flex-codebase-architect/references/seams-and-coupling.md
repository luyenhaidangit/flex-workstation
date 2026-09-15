# Seams, Coupling & Dependency Direction

Read this when a change touches a **boundary** — you're about to add an import
that crosses layers, you need to call a database/external API/clock/queue from
business logic, or you're unsure whether to introduce an interface. This is the
deep-dive behind the skill's rules "dependencies point inward and downward" and
"functional core, imperative shell." For the placement question (which folder),
see `language-conventions.md` instead.

## The one rule that generates the rest

**Inner layers must not know about outer layers.** Business/domain logic is the
inner core; transport (HTTP, CLI), persistence (DB), and external services are
the outer shell. The core defines *what* it needs as an abstraction; the shell
provides the concrete *how* and is wired in at the edge.

```
        ┌─────────────────── outer shell ───────────────────┐
        │  HTTP handler · CLI · DB driver · 3rd-party SDK    │
        │      │  depends on ▼ (never the reverse)           │
        │  ┌───────────────── inner core ─────────────────┐  │
        │  │  pure domain logic + interfaces it requires   │  │
        │  └───────────────────────────────────────────────┘ │
        └─────────────────────────────────────────────────────┘
```

If you find an inner module importing an outer one (domain importing the web
framework, a service importing the ORM's request object), that is the smell.
Fix it by **inverting** the dependency: define an interface the core owns, and
let the outer layer implement it.

## When to introduce a seam (interface), and when NOT to

Introduce a seam at a point you genuinely expect to **swap or isolate**:
- The database / persistence mechanism.
- An external API or SDK you don't control.
- Non-determinism you need to test around: the clock, randomness, the network.
- A queue, cache, or message bus.

Do **not** introduce a seam:
- For a single internal caller that will never be swapped (that's premature
  abstraction — see the WET-before-DRY rule; abstract on the 3rd real use).
- "Just in case." A seam has a cost: indirection the reader must trace. It must
  pay for itself with a real, present need (testability counts as a real need).

The test: *"Will I plausibly need to replace what's on the other side of this
line, or fake it in a test?"* Yes → seam. No → call it directly.

## Pass data, not god-objects

A function should receive **the data it needs**, not the whole request, context,
or session object. Passing the god-object couples the callee to the caller's
world and hides what the function actually depends on.

**Before — hidden coupling:**
```python
def price_order(request):              # depends on the entire HTTP request
    items = request.json["items"]
    tier = request.user.subscription.tier
    return _compute(items, tier)
```

**After — explicit, testable dependencies:**
```python
def price_order(items: list[Item], tier: Tier) -> Money:
    return _compute(items, tier)       # the transport layer extracts and passes
```

Now `price_order` is pure, trivially testable, and reusable from a CLI or a job
without faking an HTTP request.

## Inverting a concrete dependency (the most common fix)

**Before — service reaches out and down into a concrete email SDK:**
```python
class OrderService:
    def confirm(self, order):
        sendgrid.Mail(to=order.email, body=render(order)).send()  # tight coupling
```
Problems: `OrderService` now owns email transport (two responsibilities), can't
be tested without SendGrid, and can't switch channels.

**After — depend on an abstraction the core owns:**
```python
class ReceiptNotifier(Protocol):           # interface lives with the domain
    def send_receipt(self, order: Order) -> None: ...

class OrderService:
    def __init__(self, notifier: ReceiptNotifier):
        self._notifier = notifier          # injected at the edge
    def confirm(self, order: Order):
        self._notifier.send_receipt(order)

class SendgridReceiptNotifier:             # concrete impl lives in the shell
    def send_receipt(self, order): ...
```
Now the channel can change (email → SMS), tests pass a fake notifier, and
`OrderService` has one responsibility again.

## Functional core, imperative shell

Push I/O and side effects to the edges; keep decision logic pure in the middle.
A pure core is the cheapest thing in the world to test — no mocks, no setup,
just input → output.

```
read inputs (shell)  →  decide (pure core)  →  perform effects (shell)
```

If a single function reads from the DB, applies business rules, and writes back,
split it: a pure function that takes the loaded data and returns a decision, and
a thin shell that loads, calls it, and persists the result.

## Sibling coupling

Sibling modules should not reach into each other's internals. If feature A needs
something from feature B, it goes through B's public surface (an exported
function/interface), not B's private files. If two siblings keep needing the
same thing, that shared thing wants its own named home — extract it (on the 3rd
real use), don't cross-import internals.

## Quick decision checklist for any boundary change

1. Does this import point **inward/downward**? If it points up or sideways into
   internals, invert it via an interface.
2. Am I passing **only the data needed**, or a whole context/request object?
3. Is there a real, present reason for this seam (swap or test)? If not, call
   directly — don't abstract speculatively.
4. After the change, does each unit still have **one** responsibility?
