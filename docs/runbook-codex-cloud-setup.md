# Runbook: Codex Cloud Setup

This runbook covers every manual step required to activate cloud execution mode
(`execution_target: cloud`) for the agentic pipeline. Each section is a one-time
setup action per repository.

---

## A — GitHub App authorization (one-time per repository)

Codex Cloud operates as a GitHub App that must be explicitly installed in each
repository before it can receive `@codex` mentions.

1. Go to [chatgpt.com/codex](https://chatgpt.com/codex) → **Settings** → **GitHub**.
2. Click **Add repositories** and authorize each of:
   - `poc-agentic-intake`
   - `app-poc-1`
   - `app-poc-2`
3. After installation, verify the bot's actual login name by inspecting a webhook
   event in GitHub (Settings → Webhooks → Recent Deliveries on any of the repos).
   Look for `sender.login` in a comment event payload.
   - If the login differs from `codex[bot]`, update the `github.event.sender.login`
     checks in every `on-issue.yml` and `on-subissue.yml`.

> **Note:** GitHub App authorization is completely independent of the
> `OPENAI_API_KEY` GitHub Actions secret used by the local CLI adapter.

---

## B — Codex Cloud environment creation (one-time per repository)

Codex Cloud environments are created manually in the Codex UI. There is no
public API.

### poc-agentic-intake — minimal environment

| Setting | Value |
|---|---|
| Repository | `poc-agentic-intake` |
| Environment type | Minimal (no build) |
| Agent internet access | **ON** (required for remote MCP HTTP calls) |

**Setup script** (paste into the environment "Setup commands" field):
```bash
#!/usr/bin/env bash
set -euo pipefail

git clone "https://x-access-token:${GITHUB_PAT}@github.com/renanlalier/agentic-pipeline" \
  --depth=1 --branch v1 /tmp/platform

mkdir -p .codex/agents
bash /tmp/platform/brain/agents/to-codex-toml.sh po        > .codex/agents/po.toml
bash /tmp/platform/brain/agents/to-codex-toml.sh tech-lead > .codex/agents/tech-lead.toml
```

**Secrets to configure in the environment UI:**

| Secret | Purpose |
|---|---|
| `GITHUB_PAT` | Read access to `renanlalier/agentic-pipeline` to clone platform and generate agent TOMLs |
| `CONTEXT7_API_KEY` | Authentication for the Context7 MCP server (raises rate limits; omit to use anonymous) |

---

### app-poc-1 — full environment (React/Vite)

| Setting | Value |
|---|---|
| Repository | `app-poc-1` |
| Environment type | Full (Node.js) |
| Agent internet access | **ON** |

**Setup script:**
```bash
#!/usr/bin/env bash
set -euo pipefail

npm install

git clone "https://x-access-token:${GITHUB_PAT}@github.com/renanlalier/agentic-pipeline" \
  --depth=1 --branch v1 /tmp/platform

mkdir -p .codex/agents
bash /tmp/platform/brain/agents/to-codex-toml.sh frontend-engineer \
  > .codex/agents/frontend-engineer.toml
```

**Same secrets as above:** `GITHUB_PAT`, `CONTEXT7_API_KEY`.

---

### app-poc-2 — full environment (Kotlin/Ktor)

| Setting | Value |
|---|---|
| Repository | `app-poc-2` |
| Environment type | Full (JVM/Gradle) |
| Agent internet access | **ON** |

**Setup script:**
```bash
#!/usr/bin/env bash
set -euo pipefail

gradle dependencies --no-daemon --quiet

git clone "https://x-access-token:${GITHUB_PAT}@github.com/renanlalier/agentic-pipeline" \
  --depth=1 --branch v1 /tmp/platform

mkdir -p .codex/agents
bash /tmp/platform/brain/agents/to-codex-toml.sh backend-engineer \
  > .codex/agents/backend-engineer.toml
```

**Same secrets:** `GITHUB_PAT`, `CONTEXT7_API_KEY`.

---

> ⚠️ **Critical — "Agent internet access" is OFF by default.** The setup script
> runs with internet access regardless of this setting. The agent (the model
> executing the task) does not. You must explicitly enable "Agent internet access"
> in the environment settings for remote MCP HTTP calls (e.g. Context7) to work
> at agent runtime.

---

## C — GitHub Actions secrets and variables (one-time per repository)

These are separate from the Codex Cloud environment secrets above.

### GitHub App (cross-repo operations)

The pipeline uses a **GitHub App** to perform cross-repo operations (creating sub-issues, sending `repository_dispatch`, posting comments). A short-lived installation token is generated at job runtime — no long-lived PAT.

**Setup steps:**
1. Go to your GitHub profile (or org) → **Settings → Developer settings → GitHub Apps → New GitHub App**
2. Set the following **permissions:**
   - Repository: `Issues: Read and Write`, `Contents: Read`, `Actions: Read and Write` (for `repository_dispatch`)
   - No user or org permissions needed
3. After creation, note the **App ID** from the General settings page
4. Go to **Private keys → Generate a private key** and save the `.pem` file
5. Install the App on all relevant repositories (or all repos in your org)
6. Set the following secrets on `poc-agentic-intake` (or as org secrets — see below):

| Secret | Value |
|---|---|
| `APP_ID` | The numeric App ID from the App's General settings page |
| `APP_PRIVATE_KEY` | The full contents of the generated `.pem` private key file |

> **Org-level:** Set these as org secrets with **All repositories** access. New repos added to the org will inherit them automatically with no per-repo configuration.

### Other secrets and variables

| Repository | Secret/Variable | Value | Purpose |
|---|---|---|---|
| All product repos | Secret: `OPENAI_API_KEY` | OpenAI key | Local `codex exec` adapter (independent of GitHub App) |
| All repos | Variable: `CODEX_EXECUTION_TARGET` | `local` or `cloud` | Switches execution mode; default is `local` if absent |

To set a variable at the repo level:
```
Settings → Secrets and variables → Actions → Variables → New repository variable
```

Setting `CODEX_EXECUTION_TARGET=cloud` activates cloud mode for all pipeline stages
in that repository. Leaving it unset or setting it to `local` keeps the existing
local CLI adapter behavior.

---

## D — Role contract update procedure

Agent TOMLs (`.codex/agents/<role>.toml`) are generated by the setup script at
environment boot time by running `brain/agents/to-codex-toml.sh`. They are never
committed to product repositories.

When a role contract (`brain/agents/<role>/agent.yml`) is updated on the platform:

1. Publish the change: `cd agentic-pipeline && git tag -f v1 && git push -f origin v1`
2. The next Codex Cloud environment boot will run the setup script again, cloning
   the updated platform at `--branch v1`, and generate updated TOMLs.
3. Environments cache for 12 hours. To force immediate refresh, trigger a manual
   environment reset in the Codex Cloud UI, or wait for cache expiry.

---

## E — Post-setup verification

Run these checks after completing sections A–C.

### 1. Verify setup script generates TOMLs correctly

Clone the platform locally and run the converter:
```bash
git clone https://github.com/renanlalier/agentic-pipeline --depth=1 --branch v1 /tmp/platform
bash /tmp/platform/brain/agents/to-codex-toml.sh po
```

Expected output: a valid TOML with `name`, `description`, `developer_instructions`
(the full XML role prompt), and `[mcp_servers.context7]`.

### 2. Test connectivity in a sandbox issue

On any repository where the GitHub App is installed, open a test issue and post:
```
@codex [po agent] Reply with a single sentence confirming you received this. <!-- codex:status:approved -->
```

Expect:
- 👀 reaction from the bot within seconds
- A reply comment from `codex[bot]` within 1–3 minutes
- The comment ends with one of the `<!-- codex:status:... -->` markers

### 3. Verify label transitions

Set `CODEX_EXECUTION_TARGET=cloud` on a test issue and trigger the pipeline:

1. Open an issue → `brainstorm-start` fires → `@codex [po agent] ...` posted
2. Issue gets labels `status-brainstorming` + `status-awaiting-codex-response`
3. Codex bot responds with `<!-- codex:status:approved -->` or `<!-- codex:status:ask -->`
4. `codex-response-received` job fires → label transitions correctly:
   - `approved` → `status-awaiting-codex-response` removed, `status-scope-defined` added
   - `ask` → `status-awaiting-codex-response` removed, `status-brainstorming` kept
5. Audit comment with `<!-- pipe:audit -->` marker posted on the issue
6. Confirm `brainstorm-continue` does NOT retrigger on the Codex bot's reply
   (sender filter blocks it)
