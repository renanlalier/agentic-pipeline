#!/usr/bin/env bash
# Reads brain/agents/<role>/agent.yml and writes a .codex/agents/<role>.toml
# to stdout, ready to be placed in the Codex Cloud container by an environment
# setup script that clones this platform repo.
#
# Usage: to-codex-toml.sh <role>
# Deps:  yq (https://github.com/mikefarah/yq)
#
# The agent TOML carries the role's full XML system prompt as
# developer_instructions (the Codex Cloud equivalent of a system prompt),
# plus MCP server blocks derived from brain/mcp/servers.yml.
# No static TOML files need to be committed to product repos.
set -euo pipefail

ROLE="${1:?Usage: to-codex-toml.sh <role>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT_YML="$SCRIPT_DIR/$ROLE/agent.yml"
MCP_YML="$SCRIPT_DIR/../mcp/servers.yml"

if [ ! -f "$AGENT_YML" ]; then
  echo "::error::Agent definition not found: $AGENT_YML" >&2
  exit 1
fi

NAME=$(yq '.name' "$AGENT_YML")
# Folded YAML scalar '>': yq returns the value with a trailing newline; strip it.
DESC=$(yq '.description' "$AGENT_YML" | tr '\n' ' ' | sed 's/[[:space:]]*$//')

# Extract system prompt minus the <output_format> block — that block is for
# local/CI execution (JSON output consumed by the workflow). In Codex Cloud the
# agent's response becomes a GitHub comment automatically via the connector, so
# the output contract is different and defined below.
SYSTEM=$(yq '.system' "$AGENT_YML" | \
  sed '/<output_format>/,/<\/output_format>/d')

printf 'name = "%s"\n' "$NAME"
printf 'description = "%s"\n\n' "$DESC"

# developer_instructions is the Codex Cloud equivalent of a system prompt.
# Triple-quoted TOML strings allow newlines and all characters except """.
printf 'developer_instructions = """\n'
printf '%s\n' "$SYSTEM"

# Cloud-mode output contract: replaces the <output_format> block stripped above.
# If a per-role cloud_output_format.txt exists, use it; otherwise fall back to
# the generic format below.
CLOUD_FORMAT_FILE="$SCRIPT_DIR/$ROLE/cloud_output_format.txt"
if [ -f "$CLOUD_FORMAT_FILE" ]; then
  cat "$CLOUD_FORMAT_FILE"
else
printf '\n<output_format>\n'
printf 'You are running in Codex Cloud. Your response will be posted automatically as\n'
printf 'a GitHub comment by the Codex connector — do NOT call `gh`, `git`, or any\n'
printf 'shell command to post comments. Just write your reply.\n\n'
printf 'IMPORTANT: Always write your response in English, regardless of the language\n'
printf 'used in the issue or comments. This is a hard requirement.\n\n'
printf 'Start every response with the following identification field as the very first line:\n\n'
printf '  Agente: %s\n\n' "$NAME"
printf 'Then write your response body in natural language markdown:\n'
printf '- If you have a question: write it clearly and conversationally.\n'
printf '- If you have a proposal or conclusion: write it clearly and conversationally.\n'
printf '- If escalating: explain why briefly.\n\n'
printf 'Append exactly ONE of the following invisible HTML markers as the very last\n'
printf 'line of your response. They will not be visible to readers.\n\n'
printf '- You have a question or need clarification: <!-- codex:status:ask -->\n'
printf '- Proposal or task complete: <!-- codex:status:ok -->\n'
printf '- Human escalation required: <!-- codex:status:escalated -->\n'
printf '</output_format>\n'
fi

printf '"""\n'

# MCP server blocks — one per server listed in this agent's mcps field.
# The URL and bearer token env-var name come from brain/mcp/servers.yml.
while IFS= read -r mcp_name; do
  [ -z "$mcp_name" ] && continue
  URL=$(yq ".servers.${mcp_name}.remote.url" "$MCP_YML")
  API_KEY_ENV=$(yq ".servers.${mcp_name}.remote.api_key_env" "$MCP_YML")
  printf '\n[mcp_servers.%s]\nurl = "%s"\nbearer_token_env_var = "%s"\n' \
    "$mcp_name" "$URL" "$API_KEY_ENV"
done < <(yq '.mcps[]' "$AGENT_YML" 2>/dev/null || true)
