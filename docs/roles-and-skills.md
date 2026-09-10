# Roles & Skills

Roles are **stack-agnostic by design**. The name `frontend-engineer` carries no framework assumption. Stack knowledge lives in skills, loaded on demand — not baked into the role.

---

## Roles

| Role | Phases | Runs in | System prompt location |
|---|---|---|---|
| `po` | Brainstorm | `poc-agentic-intake` | `brain/agents/po/agent.yml` |
| `tech-lead` | Scope proposal | `poc-agentic-intake` | `brain/agents/tech-lead/agent.yml` |
| `frontend-engineer` | Plan + Implement | `app-poc-1` | `brain/agents/frontend-engineer/agent.yml` |
| `backend-engineer` | Plan + Implement | `app-poc-2` | `brain/agents/backend-engineer/agent.yml` |
| `qa` | Validate | `app-poc-1`, `app-poc-2` | `brain/agents/qa/agent.yml` |

### `agent.yml` Structure

Each `brain/agents/<role>/agent.yml` contains:

- `name`, `description`, `version`
- `mcps` — list of allowed MCP server names (must match keys in `brain/mcp/servers.yml`)
- `system` — XML-tagged sacred system prompt with the following sections:
  - `<role>` — identity and high-level purpose
  - `<context>` — what the agent knows about its environment
  - `<instructions>` — the actual task instructions
  - `<constraints>` — hard limits the agent must never violate
  - `<stop_conditions>` — when to stop and wait for human input
  - `<output_format>` — exact JSON/Markdown output the adapter expects
  - `<precedence>` — what wins when instructions conflict

> **The `system` field is sacred.** No skill, repo config, or memory file may override any of its sections. Skills extend capabilities; they never replace the identity contract.

---

## Platform Skills

Available to all repos and all roles. Loaded on demand by the adapter — not concatenated at boot.

| Skill | File | Purpose |
|---|---|---|
| `brainstorming` | `brain/skills/brainstorming/SKILL.md` | Structured clarification loop protocol for the PO phase |
| `writing-plans` | `brain/skills/writing-plans/SKILL.md` | Plan format and iteration protocol for the planning phase |
| `commit-convention` | `brain/skills/commit-convention/SKILL.md` | Conventional Commits with scope rules |
| `evaluate-eligible-repositories` | `brain/skills/evaluate-eligible-repositories/SKILL.md` | Semantic scope reasoning over repos discovered from the org |
| `react-best-practices` | `brain/skills/react-best-practices/SKILL.md` | React 18 / Vite / Vitest patterns (loaded in app-poc-1 runs) |

---

## Repo Skills — `.agentic/skills/<name>/SKILL.md`

Product repos can declare their own skills. They follow the same format as platform skills:

```markdown
---
name: react-best-practices
description: Patterns and conventions for React 18 with Vite and Vitest.
---

## Skill content ...
```

Skills are discovered by `run-agent` and passed as directories to the adapter. Each adapter loads them in its own CLI-native way.

**No skill may redefine the protected system prompt sections** (`<role>`, `<instructions>`, `<constraints>`, `<stop_conditions>`).

---

## Skill Discovery Order

```
run-agent
  ├── reads brain/agents/<role>/agent.yml       → extracts system prompt + mcps
  ├── scans brain/skills/                       → platform skills (all available)
  └── scans <repo>/.agentic/skills/             → repo-specific skills
        ↓
      adapter receives PLATFORM_SKILLS_DIR + REPO_SKILLS_DIR
        ↓
      CLI loads skills in its own native way
```

---

← [Back to README](../README.md) · [Configuration](./configuration.md) · [Adapters →](./adapters.md)
