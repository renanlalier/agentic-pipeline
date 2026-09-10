# MCP Servers

`brain/mcp/servers.yml` declares MCP servers abstractly. Each adapter translates this declaration into its CLI's native config format — no two adapters share a config syntax.

---

## Declaration Format

```yaml
servers:
  context7:
    description: >
      Resolves library names to IDs and fetches up-to-date documentation.
      Prevents hallucination of outdated APIs.
    remote:
      transport: http
      url: https://mcp.context7.com/mcp
      api_key_env: CONTEXT7_API_KEY   # optional — only raises rate limits
```

---

## Available Servers

| Server | Purpose | API key required |
|---|---|---|
| `context7` | Resolves library names to IDs and fetches up-to-date documentation. Prevents hallucination of outdated APIs. | No. `CONTEXT7_API_KEY` is optional — setting it only raises the rate limit. |

---

## How Adapters Use MCP Config

Adapters receive the path to `servers.yml` via `MCP_CONFIG`. Each adapter translates the abstract declaration into whatever format its CLI expects:

- `claude-code.sh` — generates a `mcp.json` / `settings.json` entry
- `codex.sh` — generates Codex-native MCP configuration
- `cursor.sh` — generates Cursor-native MCP configuration
- `dry-run.sh` — lists MCP names in the simulated output (no actual connection)

This keeps the platform definition in one place while letting each CLI use its native format.

---

## Adding a New MCP Server

1. Add the server to `brain/mcp/servers.yml`
2. Update the adapters that need to support it (they read from `MCP_CONFIG`)
3. Optionally add the server name to `mcps:` in the relevant `brain/agents/<role>/agent.yml` files to control which roles can use it

---

← [Back to README](../README.md) · [Adapters](./adapters.md) · [Memory →](./memory.md)
