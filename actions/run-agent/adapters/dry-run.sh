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
#
# Para o papel tech-lead: como este adapter nao tem julgamento semantico
# real (nao chama modelo), ele nao tenta decidir relevancia - segue a
# propria politica do system.md ("na duvida, inclua") no seu caso
# extremo: propoe TODOS os repos elegiveis que aparecem no fingerprint
# recebido no prompt, e diz explicitamente que isso e uma proposta
# conservadora de modo dry-run, nao um julgamento real.
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
  tech-lead)
    # Extrai "### nome-do-repo" e "papel logico sugerido: X" do fingerprint
    # que o workflow embutiu no prompt. Sem modelo real, nao ha como
    # avaliar RELEVANCIA - so ha como listar o que existe. Proposta
    # conservadora: todos entram, com nota honesta sobre a limitacao.
    REPOS_JSON="[]"
    CURRENT_NAME=""
    while IFS= read -r line; do
      if [[ "$line" =~ ^\#\#\#\ (.+)$ ]]; then
        CURRENT_NAME="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^papel\ logico\ sugerido:\ (.+)$ ]] && [ -n "$CURRENT_NAME" ]; then
        CURRENT_ROLE="${BASH_REMATCH[1]}"
        REPOS_JSON=$(echo "$REPOS_JSON" | jq --arg n "$CURRENT_NAME" --arg r "$CURRENT_ROLE" \
          '. + [{"name":$n,"role":$r,"reason":"modo dry-run: sem chamada de modelo, logo sem julgamento semantico real - proposta conservadora inclui todos os repos elegiveis do fingerprint"}]')
        CURRENT_NAME=""
      fi
    done <<< "$PROMPT"

    N_FOUND=$(echo "$REPOS_JSON" | jq 'length')
    echo "repos encontrados no fingerprint (modo dry-run, sem julgamento): $N_FOUND" >&2

    jq -n \
      --arg role "$ROLE" \
      --arg exec_id "$EXECUTION_ID" \
      --argjson repos "$REPOS_JSON" \
      --arg n_skills "$N_SKILLS" \
      '{
        role: $role,
        execution_id: $exec_id,
        status: "ok",
        summary: ("Proposta conservadora em modo dry-run (" + ($repos | length | tostring) + " repo(s) do fingerprint, " + $n_skills + " skill(s) carregada(s) por keyword)"),
        repos: $repos,
        contract_ref: "v1",
        notes: "adapter dry-run nao tem julgamento semantico - roda com CLI real (cursor/codex) para uma proposta que de fato analisa o fingerprint de cada repo"
      }'
    ;;
  frontend-engineer|backend-engineer)
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
