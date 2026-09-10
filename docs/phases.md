# Pipeline Phases

The pipeline executes demands through five sequential phases. Two human-in-the-loop (HITL) gates ensure human oversight before scope is committed and before implementation begins.

---

## Phase 1 — Brainstorm

| Field | Detail |
|---|---|
| **Trigger** | `issues.opened` in `poc-agentic-intake` |
| **Workflow** | `poc-agentic-intake/.github/workflows/on-issue.yml` → calls `agentic-pipeline/agent-brainstorm.yml@v1` |
| **Agent** | `po` (Product Owner) |
| **Loop** | Each human comment re-triggers `brainstorm-continue` job (while `brainstorming` label is present and sender is not the Codex bot) |
| **Anti-loop guard** | Pipeline comments carry `<!-- pipe:brainstorm -->`. Codex bot comments are excluded by `sender.login` check (`chatgpt-codex-connector[bot]`). Comments marked `awaiting-agent-response` are skipped. |
| **Outputs** | `status: ask` → posts question, keeps `brainstorming`<br>`status: approved` → fills `### Scope` in issue body, applies `scope-defined`<br>`status: escalated` → posts reason, stops |

---

## Phase 2 — Scope Proposal

| Field | Detail |
|---|---|
| **Trigger** | `issues.labeled = scope-defined` in `poc-agentic-intake` |
| **Workflow** | `on-issue.yml` (job: `propose-scope`) → calls `agentic-pipeline/agent-lead.yml@v1` |
| **Agent** | `tech-lead` |
| **What it does** | Reads all org repos via GitHub API, checks each repo's description and README, applies `evaluate-eligible-repositories` skill, produces a markdown table: `repo \| role \| why \| type`. Posts proposal with `<!-- pipe:lead -->` marker. |
| **Loop (HITL 1)** | Human comments on the proposal. `scope-continue` job re-invokes `agent-lead.yml@v1` while `awaiting-scope-approval` label is present. Agent can revise (`status: revised`) or self-approve (`status: approved` → applies `scope-approved` label automatically). |
| **Gate** | No manual label required. The Tech Lead applies `scope-approved` when the human approves via comment. |

---

## Phase 3 — Fanout

| Field | Detail |
|---|---|
| **Trigger** | `issues.labeled = scope-approved` in `poc-agentic-intake` |
| **Workflow** | `on-issue.yml` (job: `fanout`) → calls `agentic-pipeline/agent-dispatch.yml@v1` |
| **What it does** | Parses the Tech Lead's approved table. For each repo: creates a cross-repo sub-issue (via REST `/sub_issues`), stamps `execution:exec-N` and `type/<type>` labels, sends `repository_dispatch(agent-plan)` |
| **Correlation token** | `execution_id = exec-<issue-number>` — stamped on every sub-issue as a label. This is the only link between upstream and downstream. No prompt content crosses the boundary. |
| **Result** | Parent issue gets `implementing`. Product repos' workflows fire independently in isolated VMs. |

---

## Phase 4 — Plan

> **HITL Gate 2**: Human must comment `plan-approved` on the sub-issue to proceed to Phase 5.

| Field | Detail |
|---|---|
| **Trigger** | `repository_dispatch` with `event_type: agent-plan` in each product repo |
| **Workflow** | `app-poc-1/.github/workflows/agentic.yml` or `app-poc-2/...` → calls `agentic-pipeline/agent-plan.yml@v1` |
| **Agent** | `frontend-engineer` (app-poc-1) or `backend-engineer` (app-poc-2) |
| **Loop** | Each human comment re-triggers planning iteration while `planning` is present |
| **Gate** | Human comments `plan-approved` on the sub-issue |

---

## Phase 5 — Implement

| Field | Detail |
|---|---|
| **Trigger** | `issue_comment.created` containing `plan-approved` on a sub-issue with `planning` label |
| **Workflow** | `agentic.yml` → calls `agentic-pipeline/agent-dev.yml@v1` |
| **Agent** | Same role as planning (`frontend-engineer` or `backend-engineer`) |
| **Quality gates** | Runs `build` and `test` after implementation. Configurable in `.agentic/config.yml` under `gates:` |
| **Output** | Draft PR opened against `main`. Labels: `agentic`. Sub-issue gets `status-done`. |

---

← [Back to README](../README.md) · [Architecture →](./architecture.md)
