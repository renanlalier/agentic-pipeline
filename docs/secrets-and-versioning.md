# Secrets & Versioning

---

## Secrets Reference

### GitHub App (always required)

| Secret | Where to set | Purpose |
|---|---|---|
| `APP_ID` | `poc-agentic-intake` (or org) | Identifies the GitHub App for token generation |
| `APP_PRIVATE_KEY` | `poc-agentic-intake` (or org) | Authenticates the GitHub App for token generation |

Cross-repo operations (creating sub-issues, sending `repository_dispatch`, posting comments) use a **short-lived GitHub App token** generated at job runtime via `actions/create-github-app-token@v1`. The App acts under its own bot identity — no human PAT is involved.

### CLI API Keys — two modes

#### Mode A: GitHub Secrets (default)

| Secret | Where to set | Required when |
|---|---|---|
| `ANTHROPIC_API_KEY` | each product repo | `cli: claude-code` |
| `OPENAI_API_KEY` | each product repo | `cli: codex` (local mode) |
| `CURSOR_API_KEY` | each product repo | `cli: cursor` |
| `CONTEXT7_API_KEY` | each product repo | Optional — raises MCP rate limit only |

#### Mode B: Vault (recommended — per-user isolation)

Set `secrets.source: vault` in the repo's `.agentic/config.yml`. No API key secrets are stored in GitHub. Instead:

1. Each user registers their own key once via the `agentic-credentials` repo workflow.
2. Keys are stored in Azure Key Vault as `{SECRET_NAME}--{github-username}` (e.g. `ANTHROPIC-API-KEY--alice`).
3. At runtime, `run-agent` fetches the key of the issue author and injects it as a masked env var.

The following **repository variables** (not secrets) must be set on the intake repo and all product repos (or org-level):

| Variable | Value |
|---|---|
| `AZURE_CLIENT_ID` | App Registration client ID |
| `AZURE_TENANT_ID` | Azure tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |
| `AZURE_VAULT_URL` | `https://my-vault.vault.azure.net` |

OIDC authentication requires `permissions: id-token: write` on the job — already set in all reusable workflows that support vault.

See [`agentic-credentials`](https://github.com/renanlalier/agentic-credentials) for full setup instructions and OIDC diagrams.

With `cli: dry-run` or `execution_target: cloud`, no model API key is needed on the runner regardless of mode.

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
