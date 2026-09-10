#!/usr/bin/env bash
# Azure Key Vault provider for vault.sh
#
# Auth prerequisite: azure/login@v2 (OIDC) or az login --service-principal
# must have completed in the calling workflow before these functions are used.
#
# Required env var:
#   AZURE_VAULT_URL   — full Key Vault URL, e.g. https://my-vault.vault.azure.net
#                       Set as a GitHub Actions variable (not a secret).

set -euo pipefail

_vault_azure_vault_name() {
  if [ -z "${AZURE_VAULT_URL:-}" ]; then
    echo "::error::AZURE_VAULT_URL is not set. Configure it as a GitHub Actions variable (Settings > Secrets and variables > Variables)." >&2
    return 1
  fi
  # Extract vault name from URL: https://my-vault.vault.azure.net[/] → my-vault
  local url="${AZURE_VAULT_URL%/}"  # strip optional trailing slash
  local name="${url#https://}"
  echo "${name%.vault.azure.net}"
}

_vault_azure_get() {
  local secret_name="$1"
  local vault_name
  vault_name=$(_vault_azure_vault_name)

  az keyvault secret show \
    --vault-name "$vault_name" \
    --name "$secret_name" \
    --query "value" \
    --output tsv
}

_vault_azure_put() {
  local secret_name="$1"
  local secret_value="$2"
  local vault_name
  vault_name=$(_vault_azure_vault_name)

  az keyvault secret set \
    --vault-name "$vault_name" \
    --name "$secret_name" \
    --value "$secret_value" \
    --output none
}
