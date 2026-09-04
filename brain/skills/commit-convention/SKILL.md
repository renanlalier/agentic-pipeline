---
name: commit-convention
description: Use this skill whenever creating a branch, commit, or pull request in this pipeline, regardless of the repository's stack. Defines the expected branch name format, commit message, and PR structure.
---

# Commit and branch convention

This skill is stack-agnostic — it applies to any product repository,
regardless of language or framework.

## Branch

`agentic/<execution_id>` — always. Never reuse a branch from a
previous execution, even if the demand seems similar.

## Commit

`feat: <role> for #<sub_issue> (exec <execution_id>)`.

## Pull request

Always in draft, always referencing `Closes #<sub_issue>`. Title with
the role in brackets: `[frontend-engineer] ...`.
