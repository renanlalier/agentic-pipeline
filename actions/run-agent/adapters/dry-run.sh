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
# LIMITACAO GERAL: sem modelo real, nenhum dos loops abaixo (po/brainstorm,
# engineer/planejamento) faz julgamento de verdade - so detecta uma
# palavra de aprovacao no texto acumulado. Prova a MECANICA do loop, nao
# a qualidade da decisao. Com CLI real (cursor/codex) o comportamento muda.
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
APPROVAL_REGEX='aprovad[oa]|aprovo\b|approved|pode seguir'

case "$ROLE" in
  po)
    # Loop de brainstorming (issue pai). Ver skill brainstorming.
    if echo "$PROMPT_NORM" | grep -qE "$APPROVAL_REGEX"; then
      DEMANDA=$(echo "$PROMPT" | awk '/^## Demanda original/{c=1;next} /^## Conversa/{c=0} c')
      ESCOPO="[modo dry-run - escopo aproximado, nao e julgamento real de design]

$(echo "$DEMANDA" | sed '/^$/d')"

      jq -n \
        --arg role "$ROLE" --arg exec_id "$EXECUTION_ID" --arg escopo "$ESCOPO" \
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
        QUESTION="[pergunta enlatada de dry-run] Ha alguma restricao ou algo que NAO deve mudar (non-goal)? Se nao houver mais nada em aberto, comente 'aprovado'."
      fi

      jq -n \
        --arg role "$ROLE" --arg exec_id "$EXECUTION_ID" --arg question "$QUESTION" \
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
      --arg role "$ROLE" --arg exec_id "$EXECUTION_ID" --argjson repos "$REPOS_JSON" --arg n_skills "$N_SKILLS" \
      '{
        role: $role, execution_id: $exec_id, status: "ok",
        summary: ("Proposta conservadora em modo dry-run (" + ($repos | length | tostring) + " repo(s) do fingerprint, " + $n_skills + " skill(s) carregada(s) por keyword)"),
        repos: $repos, contract_ref: "v1",
        notes: "adapter dry-run nao tem julgamento semantico - roda com CLI real (cursor/codex) para uma proposta que de fato analisa o fingerprint de cada repo"
      }'
    ;;

  frontend-engineer|backend-engineer)
    if echo "$PROMPT" | grep -q 'MODO: PLANEJAMENTO_ITERATIVO'; then
      # Loop de detalhamento tecnico (sub-issue). Ver skill writing-plans.
      if echo "$PROMPT_NORM" | grep -qE "$APPROVAL_REGEX"; then
        jq -n \
          --arg role "$ROLE" --arg exec_id "$EXECUTION_ID" \
          '{
            role: $role, execution_id: $exec_id, status: "approved",
            kind: "", content: "",
            notes: "adapter dry-run: aprovacao detectada por texto, nao e julgamento real"
          }'
      else
        N_PIPE=$(echo "$PROMPT" | grep -c '\[PIPE\]' || true)
        if [ "$N_PIPE" -eq 0 ]; then
          KIND="plan"
          CONTENT="[plano enlatado de dry-run]
1. Mapear o arquivo principal que a sub-issue afeta neste repositorio.
2. Implementar a mudanca descrita, seguindo o padrao ja existente no repo.
3. Escrever/atualizar teste cobrindo o comportamento novo.

Aprove comentando 'aprovado', ou pergunte algo antes."
        else
          KIND="question"
          CONTENT="[pergunta enlatada de dry-run] O plano acima cobre o suficiente, ou falta algum caso de borda? Comente 'aprovado' para seguir."
        fi

        jq -n \
          --arg role "$ROLE" --arg exec_id "$EXECUTION_ID" --arg kind "$KIND" --arg content "$CONTENT" \
          '{
            role: $role, execution_id: $exec_id, status: "ask",
            kind: $kind, content: $content,
            notes: "adapter dry-run: conteudo enlatado, nao ha julgamento real sem modelo"
          }'
      fi
    else
      # Fase de implementacao (apos plano aprovado)
      cat <<JSON
{
  "role": "$ROLE",
  "execution_id": "$EXECUTION_ID",
  "status": "ok",
  "summary": "Implementacao simulada em modo dry-run ($N_SKILLS skill(s) carregada(s) por keyword)",
  "changed_files": ["CHANGELOG-agentic.md"],
  "notes": "adapter dry-run: nenhuma chamada de modelo foi feita"
}
JSON
    fi
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
