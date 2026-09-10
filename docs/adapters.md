# Adapters

An adapter is a shell script in `actions/run-agent/adapters/`. It receives a fixed env-var contract from `run-agent` and must write a JSON object to stdout. Adapters are the only place CLI-specific logic lives — the rest of the pipeline is CLI-agnostic.

---

## Input Contract (Env Vars)

| Variable | Description |
|---|---|
| `ROLE` | Logical role name (`po`, `frontend-engineer`, …) |
| `CLI` | Resolved CLI name |
| `MODEL` | Resolved model name |
| `EXECUTION_ID` | Stable demand-scoped correlation token (e.g. `exec-42`) |
| `PROMPT` | The task — always from the issue, never mixed into the system prompt |
| `SYSTEM_FILE` | Path to the role's XML system prompt extracted from `agent.yml` |
| `PLATFORM_SKILLS_DIR` | `brain/skills/` — shared, platform-managed |
| `REPO_SKILLS_DIR` | `.agentic/skills/` — repo-specific, agent-writable |
| `MCP_CONFIG` | Abstract MCP declarations (`brain/mcp/servers.yml`) |
| `MEMORY_DIR` | `.agentic/memory/` if memory is enabled, else empty |
| `AGENTS_MEMORY_FILE` | `.agentic/memory/AGENTS.md` if validated clean |
| `SEMANTIC_MEMORY_FILE` | `.agentic/memory/MEMORY.md` if validated clean |

---

## Output Contract (stdout JSON)

```json
{
  "role": "frontend-engineer",
  "execution_id": "exec-42",
  "status": "ask | approved | escalated | done | dispatched_to_cloud",
  "question": "...",
  "scope": "...",
  "notes": "...",
  "token_usage": {
    "input_tokens": 1234,
    "output_tokens": 567,
    "cache_read_input_tokens": 0,
    "cache_creation_input_tokens": 0
  }
}
```

All adapters **must** include `token_usage`. With `dry-run` all counts are zero. With `dispatched_to_cloud` all counts are zero — execution happens in Codex Cloud, not the runner.

---

## Available Adapters

| Adapter | CLI | Execution | API key |
|---|---|---|---|
| `dry-run.sh` | `dry-run` | None — simulates pipeline mechanics | None |
| `claude-code.sh` | `claude-code` | Local runner | `ANTHROPIC_API_KEY` |
| `cursor.sh` | `cursor` | Local runner | `CURSOR_API_KEY` |
| `codex.sh` | `codex` | Local runner or Codex Cloud | `OPENAI_API_KEY` (local) / GitHub App (cloud) |

Adapters do **not** share a common output format beyond the env-var contract. Each adapter handles skill loading and MCP setup in its own CLI-native way.

---

## Registering a New Adapter

1. Add `actions/run-agent/adapters/my-cli.sh` implementing the env-var contract above
2. Register the CLI in `config/allowlist.yml` under `clis:`
3. No other file changes needed — `run-agent` discovers adapters from the allowlist

```yaml
# config/allowlist.yml
clis:
  my-cli: { approved: true, adapter: actions/run-agent/adapters/my-cli.sh }
```

---

← [Back to README](../README.md) · [Execution Modes](./execution-modes.md) · [MCP Servers →](./mcp-servers.md)
