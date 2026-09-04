#!/usr/bin/env bash
# Adapter de POC. Nao chama modelo nenhum.
# Contrato comum a todos os adapters:
#   SYSTEM_FILE  -> caminho do system.md do papel (sagrado, so leitura)
#   SKILLS_FILE  -> caminho do bundle de skills (platform + repo, taticas)
#   PROMPT       -> a tarefa (env var, vem da issue - nunca vira system)
#   ROLE, MODEL, EXECUTION_ID
set -euo pipefail

: "${ROLE:?}"
: "${EXECUTION_ID:?}"
: "${PROMPT:?}"
: "${SYSTEM_FILE:?}"
: "${SKILLS_FILE:?}"

echo "--- system usado (nao editavel pelo repo) ---" >&2
head -c 200 "$SYSTEM_FILE" >&2; echo "..." >&2
echo "--- skills somadas ---" >&2
grep '^## \[' "$SKILLS_FILE" >&2 || echo "(nenhuma)" >&2

case "$ROLE" in
  lead-swe)
    cat <<JSON
{
  "role": "$ROLE",
  "execution_id": "$EXECUTION_ID",
  "status": "ok",
  "summary": "Plano tecnico gerado em modo dry-run",
  "contract_ref": "v1",
  "notes": "adapter dry-run: system e skills foram lidos separadamente do prompt, nenhuma chamada de modelo foi feita"
}
JSON
    ;;
  frontend-swe|backend-swe)
    cat <<JSON
{
  "role": "$ROLE",
  "execution_id": "$EXECUTION_ID",
  "status": "ok",
  "summary": "Alteracao simulada em modo dry-run",
  "changed_files": ["CHANGELOG-agentic.md"],
  "notes": "adapter dry-run: system e skills foram lidos separadamente do prompt, nenhuma chamada de modelo foi feita"
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
