#!/usr/bin/env bash
# AWS Secrets Manager provider for vault.sh — NOT YET IMPLEMENTED.
#
# When ready:
#   1. Set provider: aws-secrets-manager in config/vault.yml.
#   2. Add region to vault/config.yml under aws-secrets-manager.region.
#   3. Configure AWS OIDC auth in agent-dev.yml (aws-actions/configure-aws-credentials).
#   4. Replace the stubs below with real `aws secretsmanager` calls.

set -euo pipefail

_vault_aws_get() {
  echo "::error::AWS Secrets Manager provider is not yet implemented. Switch to azure-keyvault or implement this provider." >&2
  return 1
}

_vault_aws_put() {
  echo "::error::AWS Secrets Manager provider is not yet implemented. Switch to azure-keyvault or implement this provider." >&2
  return 1
}
