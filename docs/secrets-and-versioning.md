# Secrets & Versioning

---

## Secrets Reference

| Secret | Where to set | Required when |
|---|---|---|
| `PIPE_TOKEN` | `poc-agentic-intake` | Always — cross-repo issue creation and `repository_dispatch` |
| `ANTHROPIC_API_KEY` | each product repo | `cli: claude-code` |
| `OPENAI_API_KEY` | each product repo | `cli: codex` (local mode) |
| `CURSOR_API_KEY` | each product repo | `cli: cursor` |
| `CONTEXT7_API_KEY` | each product repo | Optional — raises MCP rate limit only |

With `cli: dry-run` or `execution_target: cloud`, no model API key is needed on the runner.

---

## Versioning

Callers always pin to a tag, never `@main`. This ensures platform changes are opt-in.

```bash
# After any platform change in agentic-pipeline:
git tag -f v1 && git push -f origin v1
```

A breaking change increments the tag (`v2`). Product repos opt into the new version explicitly by updating their `uses:` lines:

```yaml
# In app-poc-1/.github/workflows/agentic.yml
uses: renanlalier/agentic-pipeline/.github/workflows/agent-dev.yml@v2
```

### Stability Guarantees

| Tag | Guarantee |
|---|---|
| `@v1` | Stable. Breaking changes require `@v2`. |
| `@main` | **Never use.** May break at any commit. |

---

← [Back to README](../README.md) · [Memory](./memory.md) · [Known Gaps →](./known-gaps.md)
