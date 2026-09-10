<div align="center">

<h1>agentic-pipeline</h1>

<p>A reusable GitHub Actions library that orchestrates AI agents across repositories —<br>
with human-in-the-loop gates, multi-CLI support, and hard upstream/downstream isolation.</p>

![version](https://img.shields.io/badge/version-v1-0d1b2a?style=flat-square)
![status](https://img.shields.io/badge/status-proof--of--concept-orange?style=flat-square)
[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-powered-2088FF?style=flat-square&logo=github-actions&logoColor=white)](https://github.com/features/actions)
[![CLIs](https://img.shields.io/badge/CLIs-Claude_Code_%7C_Cursor_%7C_Codex-6e40c9?style=flat-square)](./actions/run-agent/adapters)
[![license](https://img.shields.io/badge/license-MIT-3da639?style=flat-square)](./LICENSE)

</div>

> [!WARNING]
> **Proof of Concept** — This repository demonstrates the orchestration model and pipeline mechanics. See [Known Gaps](./docs/known-gaps.md) before using in production.

---

## What Is This?

`agentic-pipeline` is a **platform library**, not an application. It provides reusable GitHub Actions workflows, role-based agent contracts, and CLI adapters. Product repositories call a single `uses:` line and get fully orchestrated AI agents — CLI resolution, model selection, skill discovery, MCP wiring, and human-approval gates included.

It defines **how** agents run. It never holds product code or demands.

---

## How the Pipeline Works

Demands enter through `poc-agentic-intake` as GitHub Issues and flow through five sequential phases — two of which require explicit human approval.

```
Issue opened in poc-agentic-intake
  → [Phase 1] agent-brainstorm  (PO role — iterates with requester via comments)
  ↓ PO concludes → applies label "scope-defined"
  → [Phase 2] agent-lead        (Tech Lead — proposes which product repos are in scope)
  ↓ [HITL 1]  Human approves repo list via comment → Tech Lead applies "scope-approved"
  → [Phase 3] agent-dispatch    (creates cross-repo sub-issues, fires repository_dispatch)
  → [Phase 4] agent-plan        (per repo — engineer proposes technical plan iteratively)
  ↓ [HITL 2]  Human approves plan via comment ("plan-approved")
  → [Phase 5] agent-dev         (per repo — implements the plan, opens draft PR)
```

Product repos (`app-poc-1`, `app-poc-2`) run in **isolated VMs**. No shared context crosses the boundary — only the correlation token (`exec-N`) travels via `repository_dispatch`.

---

## Repository Structure

```
renanlalier/
├── agentic-pipeline/       ← YOU ARE HERE — platform library
├── poc-agentic-intake/     ← demand intake (GitHub Issues portal)
├── app-poc-1/              ← product: frontend (React 18 / Vite)
└── app-poc-2/              ← product: backend (Kotlin / Ktor)
```

---

## Documentation

| Topic | Description |
|---|---|
| [Architecture](./docs/architecture.md) | Repository map, full pipeline flow diagrams, event & trigger table |
| [Phases](./docs/phases.md) | Detailed breakdown of each of the five pipeline phases |
| [Execution Modes](./docs/execution-modes.md) | dry-run, local CLI, Codex Cloud — mode comparison and state machine |
| [Configuration](./docs/configuration.md) | Three-level config resolution: allowlist → repo config → per-demand override |
| [Roles & Skills](./docs/roles-and-skills.md) | Role contracts, platform skills, repo skills, discovery order |
| [Adapters](./docs/adapters.md) | Input/output contracts, available adapters, registering a new one |
| [MCP Servers](./docs/mcp-servers.md) | Abstract MCP declarations and per-adapter translation |
| [Memory](./docs/memory.md) | Cross-run memory system, episode management, security |
| [Secrets & Versioning](./docs/secrets-and-versioning.md) | Required secrets per CLI, platform tag pinning strategy |
| [Known Gaps](./docs/known-gaps.md) | Current POC limitations and the path to production |
| [Codex Cloud Setup](./docs/runbook-codex-cloud-setup.md) | Runbook: configuring Codex Cloud for a product repo |

---

## Quick Reference

### Calling the Pipeline from a Product Repo

```yaml
# In app-poc-1/.github/workflows/agentic.yml
jobs:
  implement:
    uses: renanlalier/agentic-pipeline/.github/workflows/agent-dev.yml@v1
    with:
      role: frontend-engineer
    secrets: inherit
```

### Switching Execution Mode

```yaml
# .agentic/config.yml in the product repo
defaults:
  cli: dry-run          # dry-run | claude-code | cursor | codex
  execution_target: local  # local | cloud
```

### Publishing a Platform Change

```bash
cd agentic-pipeline
git tag -f v1 && git push -f origin v1
```

---

## Design Principles

- **Platform as library** — called via `uses:`, never triggered directly
- **Hard isolation** — each product repo runs in its own VM; no shared context, no shared file system
- **Upstream/downstream separation** — intake never touches product code; product repos never see the demand body
- **Prompt injection prevention** — issue body text always travels through a file or env var, never `${{ }}` inside a `run:` block
- **Stack-agnostic roles** — the role `frontend-engineer` carries no framework assumption; stack knowledge lives in skills

---

<div align="center">
<sub>Built with GitHub Actions · No standing jobs · No shared context between repos · No product code in the platform</sub>
</div>
