#!/usr/bin/env bash
# Adapter Cursor CLI.
# Contrato comum a todos os adapters:
#   entrada  -> $SKILL_FILE (contrato do papel), $PROMPT, $ROLE, $MODEL, $EXECUTION_ID
#   saida    -> JSON no stdout, no formato de handoff
#   segredo  -> CURSOR_API_KEY vindo do ambiente do job
set -euo pipefail

: "${ROLE:?}"
: "${MODEL:?}"
: "${PROMPT:?}"
: "${SKILL_FILE:?}"
: "${EXECUTION_ID:?}"

if [ -z "${CURSOR_API_KEY:-}" ]; then
  echo "::error::CURSOR_API_KEY nao configurado. Use cli: dry-run para rodar sem chave." >&2
  exit 1
fi

if ! command -v cursor-agent >/dev/null 2>&1; then
  curl -fsSL https://cursor.com/install | bash
  export PATH="$HOME/.cursor/bin:$PATH"
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

cursor-agent --print --output-format text --model "$MODEL" "$INPUT"
