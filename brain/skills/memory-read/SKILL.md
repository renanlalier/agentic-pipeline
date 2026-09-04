---
name: memory-read
description: Use when the current task explicitly references a prior execution or when the automatically injected MEMORY.md is insufficient and a specific past episode must be consulted.
---

## When to use

Use this skill ONLY when one of these conditions is true:

- The task description references "last time", "the previous run", "in exec-N",
  or a specific execution ID.
- MEMORY.md (already injected automatically) is silent on a fact you need to
  make a decision, and you have a specific execution ID to look up.

## How to read an episode

Episodes live at `.agentic/memory/episodes/<execution_id>.md`.

Read the specific file by its execution ID — do NOT scan or load all files in
the directory. Loading all episodes defeats the purpose of the semantic memory
layer (MEMORY.md) and expands the context window unnecessarily.

## What NOT to do with this skill

- Do NOT pre-emptively load all episodes before starting work.
- Do NOT use this skill as a substitute for MEMORY.md — MEMORY.md is already
  automatically injected as `<semantic_memory>` context before your task; read
  it first.
- Do NOT load episodes from other repositories; episodes are local to the repo
  where they were written.
