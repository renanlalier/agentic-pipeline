#!/usr/bin/env bash
# Adapter de POC. Nao chama modelo nenhum.
#
# Contrato comum a todos os adapters (env vars):
#   ROLE, MODEL, EXECUTION_ID, PROMPT
#   SYSTEM_FILE          -> system.md do papel (sagrado, so leitura)
#   PLATFORM_SKILLS_DIR  -> agents/<role>/skills/ na platform
#   REPO_SKILLS_DIR      -> .agentic/skills/ no repo consumidor
#   MCP_CONFIG           -> mcp/servers.yml (descricao abstrata)
#
# Este adapter usa o fallback de selecao por keyword (lib/skills.sh) para
# DEMONSTRAR o mecanismo de carregamento sob demanda, sem custo de token.
set -euo pipefail

: "${ROLE:?}"
: "${EXECUTION_ID:?}"
: "${PROMPT:?}"
: "${SYSTEM_FILE:?}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/skills.sh
source "$SCRIPT_DIR/lib/skills.sh"

echo "--- system usado (sagrado, nao editavel pelo repo) ---" >&2
head -c 200 "$SYSTEM_FILE" >&2; echo "..." >&2

echo "--- selecao de skills por keyword (fallback generico) ---" >&2
PROMPT_NORM=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')
SELECTED_SKILLS=$(select_skills_by_keyword "$PROMPT_NORM" "${PLATFORM_SKILLS_DIR:-}" "${REPO_SKILLS_DIR:-}")
echo "$SELECTED_SKILLS" >&2

echo "--- MCPs que seriam instalados ---" >&2
if [ -f "${MCP_CONFIG:-}" ]; then
  yq -r '.servers | keys | .[]' "$MCP_CONFIG" | while read -r s; do
    echo "  - $s: $(yq -r ".servers.\"$s\".description" "$MCP_CONFIG" | head -c 80)" >&2
  done
fi

N_SKILLS=$(echo "$SELECTED_SKILLS" | grep -c '^## \[skill:' || true)

case "$ROLE" in
  lead-swe)
    cat <<JSON
{
  "role": "$ROLE",
  "execution_id": "$EXECUTION_ID",
  "status": "ok",
  "summary": "Plano tecnico gerado em modo dry-run ($N_SKILLS skill(s) carregada(s) por keyword)",
  "contract_ref": "v1",
  "notes": "adapter dry-run: system, skills selecionadas e mcp foram resolvidos separadamente do prompt; nenhuma chamada de modelo foi feita"
}
JSON
    ;;
  frontend-swe|backend-swe)
    cat <<JSON
{
  "role": "$ROLE",
  "execution_id": "$EXECUTION_ID",
  "status": "ok",
  "summary": "Alteracao simulada em modo dry-run ($N_SKILLS skill(s) carregada(s) por keyword)",
  "changed_files": ["CHANGELOG-agentic.md"],
  "notes": "adapter dry-run: nenhuma chamada de modelo foi feita"
}
JSON
    ;;
  *)
    cat <<JSON
{
  "role": "$ROLE",
  "execution_id": "$EXECUTION_ID",
  "status": "ok",
  "summary": "Papel executado em modo dry-run"
}
JSON
    ;;
esac
