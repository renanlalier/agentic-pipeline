# poc-agentic-platform

The **library** for the agentic pipeline. Does not host demands or product code.
No role executes here — this repo only provides the files that others invoke.

## Structure

```
.github/workflows/
  agent-brainstorm.yml reusable · PO dialogue to define scope
  agent-lead.yml       reusable · proposes scope by reading the capability map
  agent-fanout.yml     reusable · creates cross-repo sub-issues and dispatches
  agent-plan.yml       reusable · iterative planning loop on the sub-issue
  agent-dev.yml        reusable · runs INSIDE the product repo
actions/run-agent/
  action.yml           composite · resolves CLI/model, locates contract, delegates to adapter
  adapters/
    dry-run.sh          no model · demonstrates skills + mcp
    cursor.sh           cursor-agent
    codex.sh            codex CLI
    lib/skills.sh       skill discovery + keyword-based selection fallback
agents/<role>/
  system.md             SACRED · only the platform writes this · XML tags, stack-agnostic
  skills/<name>/SKILL.md tactical, role default · frontmatter name + description
mcp/
  servers.yml           abstract description of MCPs (context7 in this POC)
config/
  allowlist.yml         level 1 · what is permitted
  capability-map.yml    domain → repo → owner → stack
```

## Roles: generalists by design

`po`, `tech-lead`, `frontend-engineer`, `backend-engineer`, `qa` — none
carries a framework or language name. Each role's `system.md` defines
identity, authority, and limits in a stack-agnostic way; the ability to
work with a specific stack comes from a **skill**, loaded at runtime from
what the repository declares in `.agentic/config.yml` and from what exists
in the code.

In this POC: `frontend-engineer` runs in `app-poc-1` (React) with the
`react-best-practices` skill; `backend-engineer` runs in `app-poc-2`
(Kotlin/Ktor) with the `kotlin-ktor-best-practices` skill. Changing a
repository's stack does not require changing the role — only the skill it loads.

## Three configuration levels

| level | where | who edits | what |
|---|---|---|---|
| 1 | `config/allowlist.yml` (here) | Platform + Security | what is permitted to exist |
| 2 | `.agentic/config.yml` of each repo | repo tech lead | defaults for that repo |
| 3 | Issue Form in intake | whoever opens the demand | one-off override |

Resolution: **3 → 2 → 1**. Level 3 wins, but level 1 can always veto.

## System, skills, and prompt — three separate things

- **`agents/<role>/system.md`** is sacred and stack-agnostic. Written in XML
  tags (`<role>`, `<context>`, `<instructions>`, `<engineering_principles>`,
  `<constraints>`, `<stop_conditions>`, `<output_format>`, `<precedence>`).
  No product repository can override or extend this, and it never mentions
  a framework.
- **Skills** (`agents/<role>/skills/` on the platform, `.agentic/skills/` in
  the product repo) follow the Agent Skills open format: one folder per skill,
  containing a `SKILL.md` with `name` + `description` frontmatter. Two
  categories coexist in the same directory: stack-agnostic skills (commit
  convention, expand/contract) and stack-capability skills (`react-best-practices`,
  `kotlin-ktor-best-practices`). `run-agent` **does not concatenate skills** —
  it only locates the directories and hands them to the adapter, which decides
  how to load them on demand in its own CLI's native way. Cursor tries its
  native mechanism (copying folders to where it discovers skills); Codex uses
  a generic fallback that matches words from the `description` against the
  prompt.
- **The prompt** always comes from the issue/sub-issue. It is never mixed
  into `system.md` as if it were part of the contract — instructions inside
  the prompt are treated as data, not as commands.

## MCP

`mcp/servers.yml` describes servers in an abstract way (in this POC, only
Context7 — works without a key; the key only raises rate limits). Each adapter
translates this into its CLI's mechanism: Cursor writes `.cursor/mcp.json` and
runs `cursor-agent mcp enable`; Codex writes `[mcp_servers.*]` in
`~/.codex/config.toml` as a remote HTTP server.

## Versioning

Callers point to the `@v1` tag, never to `@main`.

```bash
git tag -f v1 && git push -f origin v1
```

## Dry-run mode

The `dry-run` adapter calls no model. It exists to validate the pipeline
mechanics — dispatch, cross-repo, PR, gates, skill selection, MCP listing —
before spending tokens. It is the default for all repos in this POC.

## What this POC proves

1. Reusable workflow crosses repositories, but the job runs in the consumer's context
2. Cross-repo sub-issue links correctly and aggregates progress in Projects
3. The N product repos run in **independent VMs**, with no shared context
4. CLI and model selection is resolved in one place and recorded in each run
5. Human approval between steps, with no standing job consuming resources
6. Sacred and stack-agnostic system prompt; stack capability comes from skills, not the role name
7. `app-poc-1` (React) and `app-poc-2` (Kotlin/Ktor) are real hello worlds — the test demand evolves this actual code, not a placeholder
