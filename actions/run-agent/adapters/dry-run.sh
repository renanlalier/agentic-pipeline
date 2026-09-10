#!/usr/bin/env bash
# POC adapter — does not call any model.
#
# Common contract for all adapters (env vars):
#   ROLE, MODEL, EXECUTION_ID, PROMPT
#   SYSTEM_FILE          -> system prompt extracted from agent.yml (sacred, read-only)
#   AGENT_MCPS           -> comma-separated list of MCP server names from agent.yml
#   PLATFORM_SKILLS_DIR  -> brain/skills/ in the platform repo
#   REPO_SKILLS_DIR      -> .agentic/skills/ in the consumer repo
#   MCP_CONFIG           -> brain/mcp/servers.yml (abstract description)
#   MEMORY_DIR           -> .agentic/memory/ (empty string if memory disabled)
#   AGENTS_MEMORY_FILE   -> .agentic/memory/AGENTS.md (empty string if not present/invalid)
#   SEMANTIC_MEMORY_FILE -> .agentic/memory/MEMORY.md (empty string if not present/invalid)
#
# This adapter uses the keyword-based skill selection fallback (lib/skills.sh)
# to DEMONSTRATE the on-demand skill loading mechanism without token cost.
#
# GENERAL LIMITATION: without a real model, none of the loops below
# (po/brainstorm, engineer/planning) make real judgments — they only detect
# an approval keyword in the accumulated text. Proves the MECHANICS of the
# loop, not decision quality. With a real CLI (cursor/codex) behavior changes.
set -euo pipefail

: "${ROLE:?}"
: "${EXECUTION_ID:?}"
: "${PROMPT:?}"
: "${SYSTEM_FILE:?}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/skills.sh
source "$SCRIPT_DIR/lib/skills.sh"

_emit() {
  local body="$1"
  jq -n --arg body "$body" \
    '{ body: $body, token_usage: { input_tokens: 0, output_tokens: 0, cache_read_input_tokens: 0, cache_creation_input_tokens: 0 } }'
}

echo "--- system used (sacred, not editable by the repo) ---" >&2
head -c 200 "$SYSTEM_FILE" >&2; echo "..." >&2

echo "--- memory context (dry-run: paths only, no injection) ---" >&2
if [ -n "${AGENTS_MEMORY_FILE:-}" ]; then
  echo "  agents_memory: $AGENTS_MEMORY_FILE ($(wc -l < "$AGENTS_MEMORY_FILE" | tr -d ' ') lines)" >&2
else
  echo "  agents_memory: not available" >&2
fi
if [ -n "${SEMANTIC_MEMORY_FILE:-}" ]; then
  echo "  semantic_memory: $SEMANTIC_MEMORY_FILE ($(wc -l < "$SEMANTIC_MEMORY_FILE" | tr -d ' ') lines)" >&2
else
  echo "  semantic_memory: not available" >&2
fi

echo "--- skill selection by keyword (generic fallback) ---" >&2
PROMPT_NORM=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')
SELECTED_SKILLS=$(select_skills_by_keyword "$PROMPT_NORM" "${PLATFORM_SKILLS_DIR:-}" "${REPO_SKILLS_DIR:-}")
echo "$SELECTED_SKILLS" >&2

echo "--- MCPs that would be installed (agent-filtered) ---" >&2
if [ -f "${MCP_CONFIG:-}" ]; then
  ALLOWED_MCPS=$(echo "${AGENT_MCPS:-}" | tr ',' '\n' | grep -v '^$' || true)
  yq -r '.servers | keys | .[]' "$MCP_CONFIG" | while read -r s; do
    if [ -n "$ALLOWED_MCPS" ] && ! echo "$ALLOWED_MCPS" | grep -qxF "$s"; then
      echo "  - $s: [skipped — not declared in agent.yml]" >&2
      continue
    fi
    echo "  - $s: $(yq -r ".servers.\"$s\".description" "$MCP_CONFIG" | head -c 80)" >&2
  done
fi

N_SKILLS=$(echo "$SELECTED_SKILLS" | grep -c '^## \[skill:' || true)
APPROVAL_REGEX='approved|looks good|can proceed|lgtm|ok to proceed'

case "$ROLE" in
  po)
    if echo "$PROMPT_NORM" | grep -qE "$APPROVAL_REGEX"; then
      DEMANDA=$(echo "$PROMPT" | awk '/^## Original demand/{c=1;next} /^## Conversation/{c=0} c')
      SCOPE_TEXT=$(echo "$DEMANDA" | sed '/^$/d')
      BODY="Agent: Product Owner

Aprovação detectada (dry-run — detecção textual, sem julgamento real).

<!-- scope-begin -->
${SCOPE_TEXT}
<!-- scope-end -->

<!-- codex:status:approved -->"
      _emit "$BODY"
    else
      N_HUMANO=$(echo "$PROMPT" | grep -c '\[HUMAN\]' || true)
      if [ "$N_HUMANO" -eq 0 ]; then
        QUESTION="[dry-run — pergunta enlatada] Qual comportamento exato deve mudar, do ponto de vista de quem usa o sistema?"
      else
        QUESTION="[dry-run — pergunta enlatada] Há restrições ou coisas que NÃO devem mudar (não-objetivos)? Se não houver nada pendente, comente 'approved'."
      fi
      BODY="Agent: Product Owner

${QUESTION}

> _dry-run adapter: pergunta enlatada, sem julgamento real sem modelo_

<!-- codex:status:ask -->"
      _emit "$BODY"
    fi
    ;;

  tech-lead)
    # Parse repo fingerprints from prompt to build a markdown table
    TABLE_ROWS=""
    CURRENT_NAME=""
    while IFS= read -r line; do
      if [[ "$line" =~ ^\#\#\#\ (.+)$ ]]; then
        CURRENT_NAME="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^suggested\ logical\ role:\ (.+)$ ]] && [ -n "$CURRENT_NAME" ]; then
        CURRENT_ROLE="${BASH_REMATCH[1]}"
        TABLE_ROWS="${TABLE_ROWS}| \`${CURRENT_NAME}\` | \`${CURRENT_ROLE}\` | dry-run: proposta conservadora sem julgamento semântico | \`task\` |
"
        CURRENT_NAME=""
      fi
    done <<< "$PROMPT"

    N_FOUND=$(echo "$TABLE_ROWS" | grep -c '^\|' || true)
    echo "repos found in fingerprint (dry-run mode, no judgment): $N_FOUND" >&2

    BODY="Agent: Tech Lead

Proposta conservadora em dry-run mode (${N_FOUND} repo(s) do fingerprint, ${N_SKILLS} skill(s) carregada(s) por keyword).

> _dry-run adapter: sem julgamento semântico — use cursor ou codex para uma proposta real_

## Scope proposed by the pipeline

| Repo | Role | Reason | Type |
|------|------|--------|------|
${TABLE_ROWS}
<!-- codex:status:ok -->"
    _emit "$BODY"
    ;;

  frontend-engineer|backend-engineer)
    if echo "$PROMPT" | grep -q 'MODE: ITERATIVE_PLANNING'; then
      if echo "$PROMPT_NORM" | grep -qE "$APPROVAL_REGEX"; then
        BODY="Agent: ${ROLE}

Aprovação detectada (dry-run — detecção textual, sem julgamento real).

<!-- codex:status:approved -->"
        _emit "$BODY"
      else
        N_PIPE=$(echo "$PROMPT" | grep -c '\[PIPE\]' || true)
        if [ "$N_PIPE" -eq 0 ]; then
          PLAN_CONTENT="[dry-run — plano enlatado]

1. Mapear o arquivo principal afetado por esta sub-issue neste repositório.
2. Implementar a mudança descrita, seguindo o padrão existente no repo.
3. Escrever/atualizar um teste cobrindo o novo comportamento.

Aprove comentando 'approved', ou faça uma pergunta antes."
        else
          PLAN_CONTENT="[dry-run — pergunta enlatada] O plano acima cobre o suficiente, ou há algum caso de borda faltando? Comente 'approved' para prosseguir."
        fi
        BODY="Agent: ${ROLE}

${PLAN_CONTENT}

> _dry-run adapter: conteúdo enlatado, sem julgamento real sem modelo_

<!-- codex:status:ask -->"
        _emit "$BODY"
      fi
    else
      BODY="Agent: ${ROLE}

**Status:** Concluído
**Resumo:** Implementação simulada em dry-run mode (${N_SKILLS} skill(s) carregada(s) por keyword)
**Arquivos alterados:** \`CHANGELOG-agentic.md\`

> _dry-run adapter: nenhuma chamada de modelo foi feita_

<!-- codex:status:ok -->"
      _emit "$BODY"
    fi
    ;;

  *)
    BODY="Agent: ${ROLE}

Execução em dry-run mode concluída.

<!-- codex:status:ok -->"
    _emit "$BODY"
    ;;
esac
