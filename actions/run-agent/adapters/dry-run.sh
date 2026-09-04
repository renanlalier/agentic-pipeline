#!/usr/bin/env bash
# POC adapter — does not call any model.
#
# Common contract for all adapters (env vars):
#   ROLE, MODEL, EXECUTION_ID, PROMPT
#   SYSTEM_FILE          -> system.md for the role (sacred, read-only)
#   PLATFORM_SKILLS_DIR  -> brain/skills/ in the platform repo
#   REPO_SKILLS_DIR      -> .agentic/skills/ in the consumer repo
#   MCP_CONFIG           -> brain/mcp/servers.yml (abstract description)
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

echo "--- system used (sacred, not editable by the repo) ---" >&2
head -c 200 "$SYSTEM_FILE" >&2; echo "..." >&2

echo "--- skill selection by keyword (generic fallback) ---" >&2
PROMPT_NORM=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')
SELECTED_SKILLS=$(select_skills_by_keyword "$PROMPT_NORM" "${PLATFORM_SKILLS_DIR:-}" "${REPO_SKILLS_DIR:-}")
echo "$SELECTED_SKILLS" >&2

echo "--- MCPs that would be installed ---" >&2
if [ -f "${MCP_CONFIG:-}" ]; then
  yq -r '.servers | keys | .[]' "$MCP_CONFIG" | while read -r s; do
    echo "  - $s: $(yq -r ".servers.\"$s\".description" "$MCP_CONFIG" | head -c 80)" >&2
  done
fi

N_SKILLS=$(echo "$SELECTED_SKILLS" | grep -c '^## \[skill:' || true)
APPROVAL_REGEX='approved|looks good|can proceed|lgtm|ok to proceed'

case "$ROLE" in
  po)
    # Brainstorming loop (parent issue). See brainstorming skill.
    if echo "$PROMPT_NORM" | grep -qE "$APPROVAL_REGEX"; then
      DEMANDA=$(echo "$PROMPT" | awk '/^## Original demand/{c=1;next} /^## Conversation/{c=0} c')
      SCOPE="[dry-run mode — approximate scope, not real design judgment]

$(echo "$DEMANDA" | sed '/^$/d')"

      jq -n \
        --arg role "$ROLE" --arg exec_id "$EXECUTION_ID" --arg scope "$SCOPE" \
        '{
          role: $role, execution_id: $exec_id, status: "approved",
          question: "", scope: $scope,
          summary: "Approval detected in dry-run mode (textual detection, not real judgment)",
          notes: "dry-run adapter: use cli cursor or codex for real brainstorming"
        }'
    else
      N_HUMANO=$(echo "$PROMPT" | grep -c '\[HUMAN\]' || true)
      if [ "$N_HUMANO" -eq 0 ]; then
        QUESTION="[dry-run canned question] What exact behavior should change, from the perspective of the person using the system?"
      else
        QUESTION="[dry-run canned question] Are there any constraints or things that must NOT change (non-goals)? If nothing is open, comment 'approved'."
      fi

      jq -n \
        --arg role "$ROLE" --arg exec_id "$EXECUTION_ID" --arg question "$QUESTION" \
        '{
          role: $role, execution_id: $exec_id, status: "ask",
          question: $question, scope: "",
          summary: "Brainstorming turn in dry-run mode",
          notes: "dry-run adapter: canned question, no real judgment without a model"
        }'
    fi
    ;;

  tech-lead)
    REPOS_JSON="[]"
    CURRENT_NAME=""
    while IFS= read -r line; do
      if [[ "$line" =~ ^\#\#\#\ (.+)$ ]]; then
        CURRENT_NAME="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^suggested\ logical\ role:\ (.+)$ ]] && [ -n "$CURRENT_NAME" ]; then
        CURRENT_ROLE="${BASH_REMATCH[1]}"
        REPOS_JSON=$(echo "$REPOS_JSON" | jq --arg n "$CURRENT_NAME" --arg r "$CURRENT_ROLE" \
          '. + [{"name":$n,"role":$r,"reason":"dry-run mode: no model call, no real semantic judgment — conservative proposal includes all eligible repos from the fingerprint"}]')
        CURRENT_NAME=""
      fi
    done <<< "$PROMPT"

    N_FOUND=$(echo "$REPOS_JSON" | jq 'length')
    echo "repos found in fingerprint (dry-run mode, no judgment): $N_FOUND" >&2

    jq -n \
      --arg role "$ROLE" --arg exec_id "$EXECUTION_ID" --argjson repos "$REPOS_JSON" --arg n_skills "$N_SKILLS" \
      '{
        role: $role, execution_id: $exec_id, status: "ok",
        issue_type: "task",
        summary: ("Conservative proposal in dry-run mode (" + ($repos | length | tostring) + " repo(s) from fingerprint, " + $n_skills + " skill(s) loaded by keyword)"),
        repos: $repos, contract_ref: "v1",
        notes: "dry-run adapter has no semantic judgment — run with a real CLI (cursor/codex) for a proposal that actually analyzes each repo fingerprint"
      }'
    ;;

  frontend-engineer|backend-engineer)
    if echo "$PROMPT" | grep -q 'MODE: ITERATIVE_PLANNING'; then
      # Technical planning loop (sub-issue). See writing-plans skill.
      if echo "$PROMPT_NORM" | grep -qE "$APPROVAL_REGEX"; then
        jq -n \
          --arg role "$ROLE" --arg exec_id "$EXECUTION_ID" \
          '{
            role: $role, execution_id: $exec_id, status: "approved",
            kind: "", content: "",
            notes: "dry-run adapter: approval detected by text, not real judgment"
          }'
      else
        N_PIPE=$(echo "$PROMPT" | grep -c '\[PIPE\]' || true)
        if [ "$N_PIPE" -eq 0 ]; then
          KIND="plan"
          CONTENT="[dry-run canned plan]
1. Map the main file this sub-issue affects in this repository.
2. Implement the described change, following the existing pattern in the repo.
3. Write/update a test covering the new behavior.

Approve by commenting 'approved', or ask a question first."
        else
          KIND="question"
          CONTENT="[dry-run canned question] Does the plan above cover enough, or is there an edge case missing? Comment 'approved' to proceed."
        fi

        jq -n \
          --arg role "$ROLE" --arg exec_id "$EXECUTION_ID" --arg kind "$KIND" --arg content "$CONTENT" \
          '{
            role: $role, execution_id: $exec_id, status: "ask",
            kind: $kind, content: $content,
            notes: "dry-run adapter: canned content, no real judgment without a model"
          }'
      fi
    else
      # Implementation phase (after plan approved)
      cat <<JSON
{
  "role": "$ROLE",
  "execution_id": "$EXECUTION_ID",
  "status": "ok",
  "summary": "Simulated implementation in dry-run mode ($N_SKILLS skill(s) loaded by keyword)",
  "changed_files": ["CHANGELOG-agentic.md"],
  "notes": "dry-run adapter: no model call was made"
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
  "summary": "Role executed in dry-run mode"
}
JSON
    ;;
esac
