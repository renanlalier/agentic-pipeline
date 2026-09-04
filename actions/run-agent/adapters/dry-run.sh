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
# Para o papel tech-lead: proposta conservadora (todos os repos do
# fingerprint), ver comentario mais abaixo.
#
# Para o papel po: SEM MODELO REAL nao ha como conduzir um brainstorming
# de verdade - o dry-run so consegue detectar uma palavra de aprovacao
# no texto acumulado e, na ausencia dela, devolver uma pergunta enlatada.
# Isso prova a MECANICA do loop (pergunta -> comentario -> pergunta de
# novo -> aprovacao -> escopo preenchido), nao a qualidade do
# refinamento. Com CLI real (cursor/codex) o comportamento muda.
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
  po)
    # Deteccao simplissima de aprovacao: qualquer ocorrencia de uma
    # palavra de aprovacao no texto acumulado (demanda + comentarios).
    # Limitacao conhecida: nao distingue "aprovado" dito de passagem na
    # demanda original de uma aprovacao real do humano a um design
    # apresentado - um modelo real faz essa distincao, o dry-run nao.
    if echo "$PROMPT_NORM" | grep -qE 'aprovad[oa]|aprovo\b|approved|pode seguir'; then
      DEMANDA=$(echo "$PROMPT" | awk '/^## Demanda original/{c=1;next} /^## Conversa/{c=0} c')
      ESCOPO="[modo dry-run - escopo aproximado, nao e julgamento real de design]

$(echo "$DEMANDA" | sed '/^$/d')"

      jq -n \
        --arg role "$ROLE" --arg exec_id "$EXECUTION_ID" \
        --arg escopo "$ESCOPO" \
        '{
          role: $role, execution_id: $exec_id, status: "approved",
          question: "", escopo: $escopo,
          summary: "Aprovacao detectada em modo dry-run (deteccao textual, nao julgamento real)",
          notes: "adapter dry-run: use cli cursor ou codex para um brainstorming real"
        }'
    else
      N_HUMANO=$(echo "$PROMPT" | grep -c '\[HUMANO\]' || true)
      if [ "$N_HUMANO" -eq 0 ]; then
        QUESTION="[pergunta enlatada de dry-run] Qual comportamento exato deve mudar, do ponto de vista de quem usa o sistema?"
      else
        QUESTION="[pergunta enlatada de dry-run] Ha alguma restricao ou algo que NAO deve mudar (non-goal) que devemos deixar explicito? Se nao houver mais nada em aberto, comente 'aprovado'."
      fi

      jq -n \
        --arg role "$ROLE" --arg exec_id "$EXECUTION_ID" \
        --arg question "$QUESTION" \
        '{
          role: $role, execution_id: $exec_id, status: "ask",
          question: $question, escopo: "",
          summary: "Turno de brainstorming em modo dry-run",
          notes: "adapter dry-run: pergunta enlatada, nao ha julgamento real sem modelo"
        }'
    fi
    ;;

  tech-lead)
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
  "summary": "Fase executada em modo dry-run ($N_SKILLS skill(s) carregada(s) por keyword) - a mesma saida generica serve tanto para a fase de detalhamento quanto para a de implementacao neste modo",
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
