#!/usr/bin/env bash
# Adapter Codex CLI.
# Mesmo contrato do cursor.sh - so muda a invocacao.
# E este o ponto do desenho: trocar de CLI mexe AQUI, e em mais nada.
set -euo pipefail

: "${ROLE:?}"
: "${MODEL:?}"
: "${PROMPT:?}"
: "${SKILL_FILE:?}"
: "${EXECUTION_ID:?}"

if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "::error::OPENAI_API_KEY nao configurado. Use cli: dry-run para rodar sem chave." >&2
  exit 1
fi

if ! command -v codex >/dev/null 2>&1; then
  npm install -g @openai/codex
fi

INPUT=$(cat <<EOF
$(cat "$SKILL_FILE")

---
## Tarefa
$PROMPT

## Formato de saida obrigatorio
Responda APENAS com um objeto JSON contendo:
role, execution_id, status, summary, changed_files, notes.
Sem markdown, sem cercas de codigo.
EOF
)

codex exec --model "$MODEL" --skip-git-repo-check "$INPUT"
