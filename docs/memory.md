# Memory

When `memory.enabled: true` in `.agentic/config.yml`, `run-agent` injects three context sources into the agent's environment before execution.

---

## Memory Files

| File | Purpose | Written by |
|---|---|---|
| `.agentic/memory/AGENTS.md` | How roles collaborate in this repo — conventions, handoff protocols, ownership rules | Human or agent |
| `.agentic/memory/MEMORY.md` | Semantic facts across runs — decisions, constraints, architectural conventions | Human or agent |
| `.agentic/memory/episodes/` | Timestamped execution snapshots | `memory-write` skill |

---

## Configuration

```yaml
# In .agentic/config.yml
memory:
  enabled: true
  max_episodes: 20
```

When `enabled: false` or the key is absent, `MEMORY_DIR`, `AGENTS_MEMORY_FILE`, and `SEMANTIC_MEMORY_FILE` are all empty strings — adapters must handle this gracefully.

---

## Security

Any memory file containing XML tags that match **protected system prompt sections** is blocked before injection and flagged in the job summary:

- `<role>`
- `<instructions>`
- `<constraints>`
- `<stop_conditions>`

The run continues without memory — it is never aborted by a bad memory file. The agent operates with its base system prompt intact.

This prevents prompt injection via memory files committed to the product repo.

---

## Episode Management

The `memory-write` skill writes timestamped snapshots to `.agentic/memory/episodes/`. When the episode count exceeds `max_episodes`, the oldest episodes are pruned automatically. This bounds the injected context size across long-running demands.

---

← [Back to README](../README.md) · [MCP Servers](./mcp-servers.md) · [Secrets & Versioning →](./secrets-and-versioning.md)
