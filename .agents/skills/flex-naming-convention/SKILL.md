---
name: flex-naming-convention
description: Review backend names for semantic accuracy, domain vocabulary, architectural role, and project consistency instead of checking casing alone. Use when a .NET task creates, renames, exposes, or changes the responsibility of classes, methods, DTOs, commands, queries, events, endpoints, repositories, services, providers, configuration, or realtime contracts.
---

# FLEX Naming Convention

## Overview

Ensure names communicate what a component represents, which responsibility it owns, and how it fits the existing backend architecture. Treat casing and language style as the lowest-priority checks; a correctly cased name is still wrong when it misrepresents the domain or responsibility.

Naming review is a design quality gate. Do not rename public APIs, wire events, database objects, or persisted types for preference alone; identify compatibility impact and require an explicit migration decision for breaking changes.

## When to Use

- Use during backend design before implementing a new or changed symbol.
- Use during final review when a diff adds or renames architectural or public symbols.
- Use when names such as `Manager`, `Service`, `Helper`, `Processor`, `Handler`, `Data`, or `Info` make responsibility unclear.
- Use for C# classes, interfaces, records, enums, methods, properties, variables, parameters, DTOs, endpoints, commands, queries, handlers, repositories, providers, configuration, exceptions, error codes, database-facing names, and realtime contracts.

Do not use this skill for a purely mechanical casing or formatting operation unless the user explicitly asks for a naming review.

## Core Process

### 1. Identify the symbol

Determine what is being named:

- domain concept, entity, value object, enum, or exception;
- class, interface, record, method, property, variable, parameter, or constant;
- controller, endpoint, command, query, handler, DTO, repository, service, provider, factory, or configuration;
- integration event, realtime event, group, channel, or wire contract.

Never recommend a name before identifying the symbol's role.

### 2. Determine responsibility

Describe the symbol's actual primary responsibility in one sentence. Inspect its call path and contents rather than trusting its current name.

If one symbol has several unrelated responsibilities, report the abstraction problem before proposing a rename. A better name cannot repair a class that should be split.

### 3. Determine domain vocabulary

Search the bounded context and affected feature for canonical terms. Prefer vocabulary already used consistently by the project over personal preference.

Do not introduce synonyms for one concept without a semantic reason. Terms such as `Conversation`, `ChatRoom`, `Thread`, and `ChatSession` may coexist only when the domain distinguishes them.

### 4. Inspect existing conventions

Search nearby and sibling code for equivalent roles and naming patterns:

- `*Command`, `*Query`, `*Handler`, `*Request`, and `*Response`;
- `*Repository`, `*Provider`, `*Mapper`, `*Validator`, and `*Options`;
- event names, error codes, configuration keys, namespaces, and folders;
- realtime method, event, group, and channel names.

Existing consistent project conventions take precedence over generic preferences. If the convention is inconsistent or misleading, report the inconsistency instead of silently copying it.

### 5. Evaluate semantic correctness

Check whether the name describes the symbol's actual meaning:

- Classes use a precise noun or role: `MessageRepository`, `TokenProvider`, `RealtimeConnectionManager`.
- Methods use an action and object: `CreateMessage`, `FindConversation`, `ValidateAccess`, `MarkAsRead`.
- Booleans read as propositions: `IsActive`, `HasPermission`, `CanSendMessage`, `ShouldReconnect`.
- Collections are plural unless the collection type is business-significant: `messages`, `conversationIds`, `connectedUsers`.
- Generic suffixes such as `Manager`, `Service`, `Helper`, `Utils`, `Common`, `Processor`, and `Handler` require a responsibility-based justification; they are not automatic errors.

### 6. Evaluate architectural role

Use names that distinguish intent from fact:

- Commands express intent: `SendMessageCommand`, `CreateConversationCommand`.
- Queries express information retrieval: `GetConversationQuery`, `SearchMessagesQuery`.
- Events express facts that already happened: `MessageCreated`, `AgentAssigned`, `ConversationClosed`.
- Realtime or integration wire names follow the existing contract. Prefer fact-oriented names such as `message.created` only when the contract and project convention support them.
- DTO names identify transport purpose: `CreateMessageRequest`, `MessageResponse`, `MessageCreatedPayload`.
- A repository, provider, validator, mapper, or service name must match the responsibility it actually owns.

Do not rename a public route, event, Hub method, queue key, or serialized field solely to satisfy this skill. Record compatibility impact and propose a migration or alias when a rename is genuinely required.

### 7. Report recommendations

Use this format for each finding:

```text
Current name: [name]
Symbol type: [type and architectural role]
Responsibility: [what it actually does]
Issue: [semantic, architectural, ambiguity, or style problem]
Severity: [ERROR | WARNING | SUGGESTION]
Recommended name: [name]
Reason: [why the recommendation is more accurate]
Alternatives: [only when meaningful]
Compatibility impact: [none, internal, or public-contract migration required]
```

`ERROR` means semantic or architectural mismatch. `WARNING` means ambiguous or misleading naming. `SUGGESTION` means style or consistency improvement without behavior impact.

## Realtime Naming

Realtime contracts — Hub methods, wire events, channel names, and payload records — follow dedicated conventions that differ from general C# naming. Apply this section whenever a symbol belongs to the realtime surface.

### The four-layer separation

Treat each layer as a distinct naming problem. Mixing layers is the root cause of most realtime naming bugs.

| Layer | Direction | Convention | Example |
| --- | --- | --- | --- |
| Command | Client → Server | `<resource>.<verb>` (dot) or `PascalCase` Hub method | `message.send` / `SendMessage` |
| Event | Server → Client | `<resource>.<past-tense-event>` (lowercase dot) | `message.created` |
| Group / Channel | Routing | `<resource>:<id>` (colon) | `conversation:123` |
| Payload | Data | `<EventName>Payload` (PascalCase) | `MessageCreatedPayload` |

**Command = intention. Event = fact.** The same business flow produces both: `message.send` (command) causes `message.created` (event). These are never the same string.

### Event names

Events describe what already happened in the domain, not what the server is transmitting.

Use **lowercase dot-separated** format. Prefer past tense or state-completed form:

```text
message.created     message.edited      message.deleted     message.read
conversation.created                    conversation.updated
member.joined       member.left
typing.started      typing.stopped
presence.changed    agent.status.changed
```

**Name events after the business fact, not the receiver.** The same event may reach sender, recipient, other devices, and group members. The event name must not encode who receives it.

Avoid receiver-side qualifiers:
```text
receiveMessage  incomingMessage  messageForAdmin  directMessage  senderMessage
```
→ all map to `message.created`.

**Do not embed transport technology in event names.** Business events outlive transport layers.

Avoid:
```text
signalRMessage  socketMessage  websocketNotification  hubMessage  pushMessage
```
→ all map to `message.created`.

**Prefer domain-specific events over generic CRUD when business meaning is known.**

Prefer `order.paid`, `order.cancelled`, `ticket.assigned`, `message.recalled` over `order.updated`, `ticket.changed`. Reserve `*.changed` for generic state synchronization where no specific business event applies.

### Command names

Commands express client intent. In C# use **PascalCase** Hub method names. For a cross-language consistent contract, use the **lowercase dot** form and derive the Hub method name from it.

```text
C# Hub method         Cross-language dot form
SendMessage           message.send
EditMessage           message.edit
DeleteMessage         message.delete
MarkMessageAsRead     message.markAsRead
JoinConversation      conversation.join
LeaveConversation     conversation.leave
```

Choose one form per project and do not mix within the same codebase.

### Group and channel names

Groups are routing identifiers, not events. Use **`<resource>:<id>`** with a colon separator to distinguish them visually from dot-separated event names.

```text
conversation:123    user:admin    agent:456    tenant:abc
```

For multi-level routing: `tenant:abc:conversation:123`. Do not reuse event-name format for groups.

### Payload names

Map each event name to a dedicated payload type. Derive the record name from the event name in PascalCase with the `Payload` suffix:

```text
message.created       → MessageCreatedPayload
message.edited        → MessageEditedPayload
typing.started        → TypingStartedPayload
presence.changed      → PresenceChangedPayload
```

If a `Type` discriminator property exists on the payload for client-side introspection, populate it from the same constant used in `SendAsync`, never from a positional string literal inline at the call site.

### Namespace for large systems

When bounded contexts share the same Hub or broker, use a three-part pattern:

```text
<domain>.<resource>.<past-tense-event>

chat.message.created    chat.conversation.updated
support.ticket.assigned
agent.status.changed
```

Do not exceed three levels without a strong reason.

### Centralizing constants

Do not scatter string literals. Define one constants class per project surface and reference it everywhere.

```csharp
public static class RealtimeEvents
{
    public static class Message
    {
        public const string Created = "message.created";
        public const string Edited  = "message.edited";
        public const string Deleted = "message.deleted";
        public const string Read    = "message.read";
    }
    public static class Typing
    {
        public const string Started = "typing.started";
        public const string Stopped = "typing.stopped";
    }
}
```

Mirror the same structure in the frontend:

```ts
export const RealtimeEvents = {
  Message: {
    Created: 'message.created',
    Edited:  'message.edited',
    Deleted: 'message.deleted',
    Read:    'message.read',
  },
  Typing: { Started: 'typing.started', Stopped: 'typing.stopped' },
} as const;
```

Both ends must reference the same string value. A mismatch silently breaks the contract at runtime.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "The casing is valid, so the name is fine." | Syntax-valid names can still misrepresent domain meaning or responsibility. |
| "Everything can be called a Service or Manager." | Generic suffixes hide boundaries and make ownership harder to understand. |
| "A new synonym is clearer to me." | Existing bounded-context vocabulary reduces translation cost and inconsistent concepts. |
| "Rename the public event now; clients can be fixed later." | Public names are contracts; rename only with compatibility or migration planning. |
| "The class is too broad, so a better name will solve it." | A name cannot repair multiple unrelated responsibilities; report the boundary problem first. |

## Red Flags

- A naming recommendation is made before the symbol's responsibility is known.
- The recommendation is based only on casing or personal preference.
- A new synonym is introduced despite an existing canonical domain term.
- A public API, realtime event, queue key, or serialized field is renamed without compatibility analysis.
- `Manager`, `Service`, `Helper`, `Processor`, or `Handler` is rejected or accepted without checking its actual responsibility.
- A name hides that the component crosses multiple architectural boundaries.
- A naming change is mixed with unrelated refactoring.
- A realtime event name answers "what is the server sending?" instead of "what happened in the domain?"
- A receiver-side qualifier appears in an event name (`receiveMessage`, `incomingMessage`, `messageForAdmin`).
- A transport technology appears in an event name (`signalRMessage`, `socketMessage`, `websocketNotification`).
- The same string is used as both a command name and an event name.
- A group/channel name uses dot format instead of `<resource>:<id>` colon format.
- A payload type name does not correspond to its event name (e.g. `DirectChatMessage` for event `"directMessage"` instead of `MessageCreatedPayload` for `"message.created"`).
- A `Type` discriminator property on a payload is populated from a positional string literal instead of a shared constant.
- The same event name string literal appears in more than one place without referencing a shared constant.

## Verification

- [ ] Symbol type and primary responsibility are explicitly identified.
- [ ] Domain vocabulary and equivalent existing conventions were searched.
- [ ] Semantic and architectural role were checked before casing/style.
- [ ] Public-contract compatibility was assessed before recommending a rename.
- [ ] Findings use `ERROR`, `WARNING`, or `SUGGESTION` with evidence and exact locations.
- [ ] No code was modified unless the parent task explicitly authorized implementation.

**Realtime-specific (apply when any realtime symbol is in scope):**

- [ ] Each realtime symbol was classified into one of the four layers: Command, Event, Group/Channel, or Payload.
- [ ] Event names describe a domain fact in past tense, not a server action or receiver identity.
- [ ] Command names (Hub invocable methods) are distinct from event names — no string is used as both.
- [ ] Group and channel names use `<resource>:<id>` colon format, not dot format.
- [ ] Each server event has a corresponding payload type named `<EventName>Payload`.
- [ ] No transport technology appears in any event, command, or group name.
- [ ] No receiver identity appears in event names.
- [ ] All realtime string literals reference a shared constant; no inline duplicates exist.
- [ ] BE and FE constant values are identical for every shared event name.
