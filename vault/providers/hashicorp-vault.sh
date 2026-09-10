#!/usr/bin/env bash
# HashiCorp Vault provider for vault.sh — NOT YET IMPLEMENTED.
#
# When ready:
#   1. Set provider: hashicorp-vault in config/vault.yml.
#   2. Set VAULT_ADDR env var to the vault address.
#   3. Configure auth (token, AppRole, or GitHub auth method).
#   4. Replace the stubs below with real `vault kv get` calls.

set -euo pipefail

_vault_hc_get() {
  echo "::error::HashiCorp Vault provider is not yet implemented. Switch to azure-keyvault or implement this provider." >&2
  return 1
}

_vault_hc_put() {
  echo "::error::HashiCorp Vault provider is not yet implemented. Switch to azure-keyvault or implement this provider." >&2
  return 1
}
