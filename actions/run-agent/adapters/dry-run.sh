#!/usr/bin/env bash
# Adapter de POC. Nao chama modelo nenhum.
# Existe para validar a MECANICA da pipe (disparo, cross-repo, PR, gates)
# antes de gastar token. Emite o mesmo formato de handoff que os
# adapters reais precisam emitir.
set -euo pipefail

: "${ROLE:?}"
: "${EXECUTION_ID:?}"
: "${PROMPT:?}"

case "$ROLE" in
  lead-swe)
    # Escopo e proposto pelo workflow que le o capability-map;
    # aqui o adapter apenas confirma o handoff.
    cat <<JSON
{
  "role": "$ROLE",
  "execution_id": "$EXECUTION_ID",
  "status": "ok",
  "summary": "Plano tecnico gerado em modo dry-run",
  "contract_ref": "v1",
  "notes": "adapter dry-run: nenhuma chamada de modelo foi feita"
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
