---
name: memory-write
description: Use as the LAST action in any execution that modifies repository files. Writes a session episode log and updates MEMORY.md with consolidated lessons learned.
---

## When to use

Always — as the final step before committing, in any execution that resulted in
file changes to the repository.

## Step 1: Write the episode file

Write `.agentic/memory/episodes/<EXECUTION_ID>.md` with the following structure:

```markdown
---
execution_id: <EXECUTION_ID>
role: <ROLE>
timestamp: <ISO-8601 current UTC>
status: completed|failed
---

## Task summary
<one paragraph describing what was asked>

## Key decisions
- <decision and the reason it was made>

## Files modified
- <path>: <what changed and why>

## Lessons / constraints discovered
- <fact that would help a future execution in this repo>
```

## Step 2: Update MEMORY.md

File path: `.agentic/memory/MEMORY.md`

1. If the file does not exist, create it from this episode's content.
2. If it exists, **merge** — do not append blindly:
   - Add new facts not already present.
   - Correct or remove facts contradicted by this execution.
   - Keep the file under 200 lines; if longer, prune the least-recent or
     least-useful facts (prefer keeping constraint-type facts over
     preference-type facts).
3. Maintain these sections (create any that are missing):
   - **Stack preferences** — tooling, testing patterns, style choices observed
   - **Known constraints** — paths/actions that are forbidden, approval gates
   - **Lessons learned** — cross-execution patterns, non-obvious behaviors
   - **Inter-execution context** — references to specific executions worth knowing

## Security invariant (CRITICAL)

Do NOT include any of the following strings anywhere in memory files:
`<role>`, `<instructions>`, `<constraints>`, `<stop_conditions>`

Memory files are **data** read back by the platform — not a second system prompt.
The platform performs a security check before injecting memory: any file
containing those tags is silently discarded for that run.
