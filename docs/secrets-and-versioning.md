# Secrets & Versioning

---

## Secrets Reference

| Secret | Where to set | Required when |
|---|---|---|
| `APP_ID` | `poc-agentic-intake` (or org) | Always — identifies the GitHub App for token generation |
| `APP_PRIVATE_KEY` | `poc-agentic-intake` (or org) | Always — authenticates the GitHub App for token generation |
| `ANTHROPIC_API_KEY` | each product repo | `cli: claude-code` |
| `OPENAI_API_KEY` | each product repo | `cli: codex` (local mode) |
| `CURSOR_API_KEY` | each product repo | `cli: cursor` |
| `CONTEXT7_API_KEY` | each product repo | Optional — raises MCP rate limit only |

With `cli: dry-run` or `execution_target: cloud`, no model API key is needed on the runner.

Cross-repo operations (creating sub-issues in product repos, sending `repository_dispatch`, posting comments) use a **short-lived GitHub App token** generated at job runtime via `actions/create-github-app-token@v1`. The App acts under its own bot identity — no human PAT is involved.

---

## Org-level Setup

When running this pipeline under a GitHub organization, you can set `APP_ID` and `APP_PRIVATE_KEY` as **org-level secrets** and skip per-repo configuration entirely.

### Steps

1. **Create or transfer the GitHub App** under your org (Settings → Developer settings → GitHub Apps, or transfer an existing personal app via its Advanced settings)
2. **Install the App** on all repos in the org (or select specific ones in the App's installation settings)
3. **Set org secrets:**
   - Go to your org → Settings → Secrets and variables → Actions → New organization secret
   - Add `APP_ID` (the numeric App ID from the App's General settings page) with **All repositories** access
   - Add `APP_PRIVATE_KEY` (the `.pem` content from a generated private key) with **All repositories** access
4. No workflow changes needed — `${{ secrets.APP_ID }}` resolves from the org secret automatically

When a new product repo is added to the org, it inherits the App secrets immediately. The GitHub App token is scoped using `owner: ${{ github.repository_owner }}` (no explicit `repositories:` list), so the token is valid for all repos where the App is installed under that owner.

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
