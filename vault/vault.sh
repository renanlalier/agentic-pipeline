#!/usr/bin/env bash
# vault.sh — provider-agnostic vault interface for the agentic pipeline.
#
# Public contract:
#   vault_get <secret-name>            → prints secret value to stdout
#   vault_put <secret-name> <value>    → writes the secret to the vault
#
# The active provider is read from VAULT_CONFIG_FILE (defaults to the
# config/vault.yml file alongside this script's parent directory).
#
# Auth must be established by the caller BEFORE invoking these functions.
# For Azure Key Vault that means azure/login@v2 has already run.
# This script only handles secret retrieval/storage, not authentication.

set -euo pipefail

_VAULT_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_VAULT_CONFIG="${VAULT_CONFIG_FILE:-${_VAULT_SCRIPT_DIR}/../config/vault.yml}"

_vault_provider() {
  if [ ! -f "$_VAULT_CONFIG" ]; then
    echo "::error::Vault config not found: $_VAULT_CONFIG" >&2
    return 1
  fi
  yq -r '.provider' "$_VAULT_CONFIG"
}

vault_get() {
  local secret_name="$1"
  local provider
  provider=$(_vault_provider)

  case "$provider" in
    azure-keyvault)
      # shellcheck source=vault/providers/azure-keyvault.sh
      source "${_VAULT_SCRIPT_DIR}/providers/azure-keyvault.sh"
      _vault_azure_get "$secret_name"
      ;;
    aws-secrets-manager)
      source "${_VAULT_SCRIPT_DIR}/providers/aws-secrets-manager.sh"
      _vault_aws_get "$secret_name"
      ;;
    hashicorp-vault)
      source "${_VAULT_SCRIPT_DIR}/providers/hashicorp-vault.sh"
      _vault_hc_get "$secret_name"
      ;;
    *)
      echo "::error::Unknown vault provider: '$provider'. Valid values: azure-keyvault, aws-secrets-manager, hashicorp-vault." >&2
      return 1
      ;;
  esac
}

vault_put() {
  local secret_name="$1"
  local secret_value="$2"
  local provider
  provider=$(_vault_provider)

  case "$provider" in
    azure-keyvault)
      source "${_VAULT_SCRIPT_DIR}/providers/azure-keyvault.sh"
      _vault_azure_put "$secret_name" "$secret_value"
      ;;
    aws-secrets-manager)
      source "${_VAULT_SCRIPT_DIR}/providers/aws-secrets-manager.sh"
      _vault_aws_put "$secret_name" "$secret_value"
      ;;
    hashicorp-vault)
      source "${_VAULT_SCRIPT_DIR}/providers/hashicorp-vault.sh"
      _vault_hc_put "$secret_name" "$secret_value"
      ;;
    *)
      echo "::error::Unknown vault provider: '$provider'." >&2
      return 1
      ;;
  esac
}
