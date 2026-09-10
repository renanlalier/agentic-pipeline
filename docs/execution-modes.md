# Execution Modes

Every agent run goes through `run-agent` (composite action), which resolves the execution mode from three levels of config. The mode determines what actually runs.

```mermaid
flowchart LR
    A["run-agent fires"]:::action
    B{{"execution_target?"}}:::decision
    C{{"cli?"}}:::decision

    subgraph LOCAL["🖥️ Local Execution"]
        direction TB
        DR["<b>dry-run</b>\nNo model called\nSimulates JSON output\nValidates pipeline mechanics"]:::dryrun
        CC["<b>claude-code</b>\nClaude Code CLI\non GH Actions runner\nAPI key: ANTHROPIC_API_KEY"]:::cli
        CX["<b>cursor</b>\nCursor CLI\non GH Actions runner\nAPI key: CURSOR_API_KEY"]:::cli
        CXL["<b>codex (local)</b>\nOpenAI Codex CLI\non GH Actions runner\nAPI key: OPENAI_API_KEY"]:::cli
    end

    subgraph CLOUD["☁️ Codex Cloud Execution"]
        direction TB
        T1["Generates .codex/agents/&lt;role&gt;.toml\nfrom brain/agents/&lt;role&gt;/agent.yml\ncommits to repo"]:::cloudstep
        T2["Posts @codex comment\n(minimized — invisible to humans)\nCodex Cloud bot receives webhook"]:::cloudstep
        T3["Bot runs in isolated sandbox\nReads .codex/agents/&lt;role&gt;.toml\nfor developer_instructions"]:::cloudstep
        T4["Bot posts response comment\nwith <!-- codex:status:X --> marker"]:::cloudstep
        T5["codex-response-received job\nreads marker → applies label transition"]:::cloudstep
        T1 --> T2 --> T3 --> T4 --> T5
    end

    A --> B
    B -->|local| C
    B -->|cloud + cli=codex| CLOUD
    C -->|dry-run| DR
    C -->|claude-code| CC
    C -->|cursor| CX
    C -->|codex| CXL

    classDef action fill:#f3effa,stroke:#6e40c9,stroke-width:2px
    classDef decision fill:#f5f5f5,stroke:#888,stroke-width:1px
    classDef dryrun fill:#f0f0f0,stroke:#aaa,stroke-width:1px,color:#444
    classDef cli fill:#e8f4fd,stroke:#2196f3,stroke-width:1px,color:#0d47a1
    classDef cloudstep fill:#fce4ec,stroke:#e91e63,stroke-width:1px,color:#880e4f
```

---

## Mode Comparison

| | `dry-run` | Local CLI | Codex Cloud |
|---|---|---|---|
| **Model called** | No | Yes | Yes (via Codex Cloud) |
| **Runs on** | GH Actions runner | GH Actions runner | Codex Cloud sandbox |
| **API key needed** | None | CLI-specific | None (GitHub App) |
| **Config** | `cli: dry-run` | `cli: claude-code \| cursor \| codex` + `execution_target: local` | `cli: codex` + `execution_target: cloud` |
| **Output** | Synthetic JSON | Real agent output | Codex bot comment |
| **Pipeline sees** | Simulated result | Adapter stdout | `<!-- codex:status:X -->` marker |
| **Useful for** | Validating mechanics, CI, cost-zero testing | Full local execution | Codex Cloud subscription users |

---

## POC Default Configuration

All three product/intake repos are currently set to **Codex Cloud**:

```
poc-agentic-intake   → cli: codex · execution_target: cloud · po/tech-lead: codex-1
app-poc-1            → cli: codex · execution_target: cloud · frontend-engineer/qa: codex-1
app-poc-2            → cli: codex · execution_target: cloud · backend-engineer/qa: codex-1
```

---

## Codex Cloud — State Machine

When `execution_target: cloud` is active, the pipeline becomes a state machine driven by Codex bot responses rather than synchronous adapter output.

```mermaid
stateDiagram-v2
    [*] --> brainstorming : issues.opened\nbrainstorm-start fires

    brainstorming --> awaiting_codex : @codex dispatched\nawaiting-agent-response applied
    awaiting_codex --> brainstorming : codex → ask\nhuman replies → brainstorm-continue fires
    awaiting_codex --> scope_defined : codex → approved\nscope-defined applied

    brainstorming --> scope_defined : [local mode]\nPO returns approved

    scope_defined --> awaiting_scope : agent-lead fires\nTech Lead posts proposal + pipe:lead
    awaiting_scope --> awaiting_codex_lead : [cloud] @codex dispatched
    awaiting_codex_lead --> awaiting_scope : codex → ok\nproposal posted → scope-continue listens
    awaiting_scope --> awaiting_scope : human requests changes\nscope-continue → agent revises
    awaiting_scope --> implementing : human approves via comment\nagent applies scope-approved\nfanout creates sub-issues

    implementing --> planning : repository_dispatch(agent-plan)\nper product repo
    planning --> awaiting_codex_plan : [cloud] @codex dispatched
    awaiting_codex_plan --> planning : codex → ask\nhuman replies
    awaiting_codex_plan --> hitl2 : codex → approved\nplan proposal posted
    planning --> hitl2 : [local] engineer posts plan

    hitl2 --> impl_running : human comments plan-approved\nagent-dev fires
    impl_running --> awaiting_codex_dev : [cloud] @codex dispatched
    awaiting_codex_dev --> done : codex → done\ndraft PR opened
    impl_running --> done : [local] runner opens draft PR

    done --> [*]
```

### How the Bot Response Is Processed

```
Codex bot posts comment
  └── codex-response-received job fires (on-issue.yml in intake)
        ├── extracts <!-- codex:status:X --> marker from comment body
        ├── removes awaiting-agent-response label
        ├── reads current labels to identify stage
        └── applies transition:
              brainstorming + ask     → keep brainstorming
              brainstorming + approved → remove brainstorming
                                         add scope-defined
              awaiting-scope + ok     → post proposal comment; scope-continue now handles human replies
              escalated               → remove labels, log, stop
```

### Role Contract Delivery in Cloud Mode

In Codex Cloud, the agent runs in a repo sandbox — not in the GitHub Actions runner. The system prompt must reach it via the repo's `.codex/agents/<role>.toml` file.

`run-agent` generates and commits this file automatically before dispatching:

```
brain/agents/<role>/agent.yml          ← source of truth (platform owns this)
        ↓  to-codex-toml.sh
.codex/agents/<role>.toml              ← generated at dispatch time, committed to repo
        ↓  Codex Cloud reads
developer_instructions = """           ← role contract (XML system prompt, cloud output format)
```

The TOML is regenerated on every dispatch. Product repos never maintain it manually. The platform is always the source of truth.

---

← [Back to README](../README.md) · [Phases](./phases.md) · [Adapters →](./adapters.md)
