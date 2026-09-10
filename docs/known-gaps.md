# Known Gaps

This document tracks known limitations of the current proof-of-concept. These are not bugs — they are deliberate trade-offs made to validate the orchestration model before investing in hardening.

> See the [main README](../README.md) for the POC warning context.

---

## Current Gaps

| Gap | Detail | Impact |
|---|---|---|
| **Budgets are declarative only** | `config/allowlist.yml` defines `budgets` but nothing enforces them at runtime | A demand can exceed `hard_stop_usd_per_demand` without being stopped |
| **`gateway.enabled` is inert** | `run-agent` prints attribution headers but no gateway consumes them | Per-user cost attribution is not enforced end to end |
| **Cursor skill path unverified** | `cursor.sh` copies skills to `.cursor/skills/`, assuming parity with Claude Code's open Agent Skills format | If the path is wrong, skills are silently never loaded |
| **No automated tests** | The pipeline has no test suite validating adapter contracts or config resolution | Regressions surface only at runtime inside a real demand |

---

## Roadmap to Production

Before using this in production, these gaps should be addressed:

1. **Budget enforcement** — integrate a token/cost meter into `run-agent` that reads `allowlist.yml` budgets and terminates runs that exceed `hard_stop_usd_per_demand`
2. **Gateway wiring** — route all adapter calls through a gateway that reads attribution headers and tracks per-user, per-demand costs
3. **Cursor skills verification** — validate the `cursor.sh` skill path against a real Cursor CLI installation
4. **Adapter contract tests** — add a test suite that runs all adapters in dry-run mode and validates the output JSON against the output contract schema

---

← [Back to README](../README.md) · [Secrets & Versioning](./secrets-and-versioning.md)
