# YourMemory — Claude Integration Guide

## Memory Workflow (follow on every task)

You have access to a persistent memory system via the `yourmemory` MCP tools.
Use them on **every interaction** in this project:

### Step 1 — Recall before acting
At the start of every task, call `recall_memory` with keywords from the user's request.
This surfaces relevant facts, preferences, and past instructions.

```
recall_memory(query="<keywords from prompt>", user_id="sachit")
```

### Step 2 — Decide: store, update, or ignore

You are the sole decision-maker. Apply this policy to every fact revealed in the conversation:

| Case | Condition | Action |
|---|---|---|
| **Contradiction** | New fact directly conflicts with a recalled memory | `update_memory(memory_id, new_content)` — replace with the new fact only |
| **Extension** | New fact adds detail to a recalled memory | `update_memory(memory_id, merged_sentence)` — write one combined sentence |
| **New knowledge** | Fact is new and contains real knowledge about Sachit **or the task at hand** | `store_memory(content)` — insert |
| **Ignore** | Trivial exchange, a question, conversational filler, or no knowledge content | Do nothing |

**Rules:**
- A memory has "knowledge" if it reveals a preference, habit, instruction, goal, or fact about:
  - **Sachit** (the user) — preferences, instructions, identity, goals
  - **The current task** — architectural decisions, assumptions, constraints, design choices, domain facts discovered during the task
- Never store questions (`why is X?`, `how do I?`)
- Never store Claude's own responses or opinions
- Write user facts as: `"Sachit prefers..."` / `"Sachit uses..."`
- Write task facts as: `"The YourMemory project uses pgvector..."` / `"The decay job uses λ=0.16..."`

### Step 3 — Complete the task using memory context
Use the recalled context to inform your response.
Example: if memory says "use Python not JS", apply that preference without being told again.

### Step 4 — Persist the decision
Call the MCP tool immediately after identifying the case — do not batch or defer.
You **must always** decide `importance` yourself (never omit it):

| Importance | When to use |
|---|---|
| `0.9–1.0` | Core identity, permanent preferences ("Sachit uses Python", "Sachit is building YourMemory") |
| `0.7–0.8` | Strong recurring preferences, project-level architectural decisions |
| `0.5` | Regular facts, one-time project choices |
| `0.2–0.3` | Transient session context ("Sachit asked about X today") |

- **store_memory** → `store_memory(content="Sachit ...", importance=<your decision>, user_id="sachit")`
- **update_memory** → `update_memory(memory_id=<id from recall>, new_content="Sachit ...", importance=<your decision>)`

---

## MCP Tools Reference

### `recall_memory`
```
recall_memory(query, user_id="sachit", top_k=5)
```
Returns: `{memoriesFound, context, memories: [{id, content, category, similarity, score}]}`

### `store_memory`
```
store_memory(content, user_id="sachit")
```
Stores a new fact. Skips exact duplicates (bumps recall count instead).

### `update_memory`
```
update_memory(memory_id, new_content)
```
Re-embeds and replaces an existing memory. Use for merge and override.

---

## User
- Name: Sachit
- Default user_id: `"sachit"`
