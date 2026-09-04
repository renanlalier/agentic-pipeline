<div align="center">

<h1>agentic-pipeline</h1>

<p>A reusable GitHub Actions library that orchestrates AI agents across repositories —<br>
with human-in-the-loop gates, multi-CLI support, and hard upstream/downstream isolation.</p>

[![version](https://img.shields.io/github/v/tag/renanlalier/agentic-pipeline?label=version&style=flat-square&color=0d1b2a)](https://github.com/renanlalier/agentic-pipeline/tags)
[![status](https://img.shields.io/badge/status-proof--of--concept-orange?style=flat-square)]()
[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-powered-2088FF?style=flat-square&logo=github-actions&logoColor=white)](https://github.com/features/actions)
[![CLIs](https://img.shields.io/badge/CLIs-Claude_Code_%7C_Cursor_%7C_Codex-6e40c9?style=flat-square)](./actions/run-agent/adapters)

**[Quick Start](#quick-start) · [Architecture](#architecture) · [Configuration](#configuration) · [Roles & Skills](#roles--skills) · [Adapters](#contributing-an-adapter)**

</div>

> [!WARNING]
> **Proof of Concept** — This repository demonstrates the orchestration model and pipeline mechanics. Some documented features are not yet fully implemented. See [Known Gaps](#known-gaps) before using in production.

---

## What is this?

`agentic-pipeline` is a **platform library**, not an application. Product repositories call a single `uses:` line and get fully orchestrated AI agents — CLI resolution, model selection, skill discovery, MCP wiring, and human-approval gates included. It defines **how** agents run; it never holds product code or demands.

It provides:

- **Role-based agents** (`po`, `tech-lead`, `frontend-engineer`, `backend-engineer`) whose system prompts are stack-agnostic — stack knowledge lives in *skills*, not role names
- **Multi-CLI support** via swappable adapters: Claude Code, Cursor, Codex, or `dry-run` (mechanics validated, no model called)
- **Three-level configuration** where platform governance is always the final veto, but repos keep meaningful defaults
- **Two human-in-the-loop gates** — one between scope definition and planning, one between planning and implementation
- **Strict isolation** — each product repo runs in its own VM; no shared context, no cross-repo secrets

---

## Architecture

```mermaid
flowchart TD
    A([Issue opened\nin intake repo]) --> B[agent-brainstorm\nPO — iterates via comments]
    B -->|PO concludes| C{status-scope-defined}
    C --> D[agent-lead\nTech Lead — reads repo descriptions\nvia GitHub API]
    D -->|HITL 1| E{"scope-approved\n← human applies label"}
    E --> F[agent-dispatch\nCreates sub-issues per repo\nFires repository_dispatch]
    F --> G[agent-plan\nPer repo — iterative planning loop]
    G -->|HITL 2| H{"plan-approved\n← human comment"}
    H --> I[agent-dev\nRuns inside the product repo\nOpens a draft PR]
```

### Upstream / Downstream boundary

The pipeline has a hard separation between two worlds. Intake orchestrates demand; product repos execute it. Nothing crosses the boundary except a sub-issue body and a correlation token.

| | Upstream | Downstream |
|---|---|---|
| **Repos** | `agentic-upstream` | `app-poc-1`, `app-poc-2`, any product repo |
| **Trigger** | Human opens a GitHub Issue | `repository_dispatch` from `agent-dispatch` |
| **Agent sees** | Demand description + repo summaries (GitHub API) | Only its sub-issue + approved plan |
| **Token scope** | `issues: write`, `contents: read` | `contents: write`, `pull-requests: write` |
| **Shared context** | None | None — independent VMs per repo |
| **Platform ref** | `@v1` | `@v1` |

The `execution_id` label — stamped on every sub-issue by `agent-dispatch` — is the only correlation between the two worlds. It ties cost and trace back to the original demand without exposing the original prompt to the downstream agent.

---

## Quick Start

### 1 · Register your repo in the capability map

In this repository, add your repo to `config/capability-map.yml`:

```yaml
repos:
  - name: your-repo
    role: frontend-engineer     # or: backend-engineer, qa
    owner_team: your-team
    summary: "One sentence on what this repo is responsible for."
```

### 2 · Create `.agentic/config.yml` in your product repo

```yaml
version: 1

defaults:
  cli: claude-code              # or: cursor | codex | dry-run
  models:
    frontend-engineer: claude-sonnet-4-6

constraints:
  forbid_paths:
    - .env
    - secrets/

# Optional — episodic memory across runs
memory:
  enabled: false
  max_episodes: 20
```

### 3 · Add the workflow caller

Create `.github/workflows/agentic.yml` in your product repo:

```yaml
name: agentic

on:
  repository_dispatch:
    types: [agentic-dev]

jobs:
  implement:
    uses: renanlalier/agentic-pipeline/.github/workflows/agent-dev.yml@v1
    with:
      role: frontend-engineer
      sub_issue: ${{ github.event.client_payload.sub_issue }}
    secrets:
      ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

### 4 · Set secrets

| Secret | Scope | Purpose |
|---|---|---|
| `PIPE_TOKEN` | intake repo | Cross-repo issue creation and `repository_dispatch` |
| `ANTHROPIC_API_KEY` | each product repo | Claude Code adapter |
| `OPENAI_API_KEY` | each product repo | Codex adapter |

That's it. The platform resolves CLI, model, skills, and MCPs from there.

---

## Configuration

Configuration resolves in three levels. **Level 3 wins; level 1 can always veto.**

### Level 1 — `config/allowlist.yml` (this repo)

Edited by Platform Engineering and Security. Defines what is permitted to exist at all: approved CLIs, approved models per role, cost budgets. A repo config or demand override can only select from this list.

```yaml
clis:
  claude-code:
    approved: true
    adapter: actions/run-agent/adapters/claude-code.sh

models:
  frontend-engineer: [dry-run, claude-sonnet-4-6, gpt-5]

budgets:
  default_usd_per_demand: 5
  hard_stop_usd_per_demand: 10
  max_retries_per_role: 2
```

### Level 2 — `.agentic/config.yml` in each product repo

Repo-level defaults. Cannot select a CLI or model absent from the allowlist.

### Level 3 — issue form or `repository_dispatch` payload

Per-demand overrides via `cli_override` and `model_override`. Useful for testing a new model on a single demand without changing any config file. The allowlist still vetoes.

---

## Roles & Skills

Roles are **generalists by design**. The role `frontend-engineer` carries no framework name — that belongs in a skill.

### Platform skills (available to all repos)

| Skill | Purpose |
|---|---|
| `brainstorming` | Structured clarification loop for the PO phase |
| `writing-plans` | Plan format and iteration protocol for the planning phase |
| `commit-convention` | Conventional Commits with scope rules |
| `evaluate-eligible-repositories` | Scope reasoning across the capability map |
| `memory-read` / `memory-write` | Episode read/write in `.agentic/memory/` |

### Repo skills — `.agentic/skills/<name>/SKILL.md`

```markdown
---
name: react-best-practices
description: Patterns and conventions for React 18 with Vite and Vitest.
---

## Skill content ...
```

Skills are **discovered, not concatenated**. `run-agent` locates the directories and passes them to the adapter, which loads them in its own CLI-native way. No skill may redefine the protected sections of a role's `system.md` (`<role>`, `<instructions>`, `<constraints>`, `<stop_conditions>`).

---

## Contributing an Adapter

An adapter is a shell script in `actions/run-agent/adapters/`. It receives these env vars and must produce output on stdout:

| Variable | Description |
|---|---|
| `ROLE` | Logical role name |
| `CLI` | Resolved CLI name |
| `MODEL` | Resolved model name |
| `EXECUTION_ID` | Stable demand-scoped correlation token |
| `PROMPT` | The task — always from the issue, never mixed into the system |
| `SYSTEM_FILE` | Path to the sacred role system prompt |
| `PLATFORM_SKILLS_DIR` | Platform skill directory |
| `REPO_SKILLS_DIR` | Repo-specific skill directory |
| `MCP_CONFIG` | Abstract MCP declarations (`brain/mcp/servers.yml`) |
| `MEMORY_DIR` | `.agentic/memory/` if memory is enabled, else empty |
| `AGENTS_MEMORY_FILE` | `.agentic/memory/AGENTS.md` if validated clean |
| `SEMANTIC_MEMORY_FILE` | `.agentic/memory/MEMORY.md` if validated clean |

Register the adapter in `config/allowlist.yml` under `clis:`. No other file changes.

---

## Memory

When `memory.enabled: true` in `.agentic/config.yml`, the platform injects two context files into the agent run:

- **`AGENTS.md`** — how roles collaborate in this repo
- **`MEMORY.md`** — semantic facts to carry across runs (decisions, constraints, conventions)
- **`episodes/`** — timestamped files written by `memory-write`, loaded selectively by `memory-read`

**Security**: files containing XML tags matching protected system-prompt sections are blocked before injection and flagged in the job summary. The run continues without memory.

---

## Versioning

Callers always pin to a tag, never `@main`.

```bash
git tag -f v1 && git push -f origin v1
```

A breaking change increments the tag (`v2`). Product repos opt into the new version explicitly.

---

## Known Gaps

This is a proof-of-concept. The table below documents what is described in this README but not yet fully implemented on disk.

| Gap | Detail | Impact |
|---|---|---|
| `brain/prompts/qa/system.md` | Directory exists; `system.md` is missing | `role: qa` fails at runtime in `run-agent` |
| `agent-dev.yml` missing `secrets:` block | `ANTHROPIC_API_KEY` is not forwarded to the reusable workflow | Claude Code adapter cannot authenticate; documented Quick Start example does not work as written |
| `CURSOR_API_KEY` undocumented | The `cursor.sh` adapter requires this secret; it is absent from the secrets table above | Cursor CLI path is unusable |
| `LICENSE` file | The MIT badge links to `./LICENSE`, which does not exist | Broken link |
| `mcp/` root directory | Empty stub with no declared purpose | No functional impact |

---

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=renanlalier/agentic-pipeline,renanlalier/agentic-upstream&type=Date)](https://star-history.com/#renanlalier/agentic-pipeline&renanlalier/agentic-upstream&Date)

---

<div align="center">
<sub>Built with GitHub Actions · No standing jobs · No shared context between repos</sub>
</div>
