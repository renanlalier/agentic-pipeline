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
cat << 'CLOUD_OUTPUT'

<output_format>
You are running in Codex Cloud. Your response will be posted automatically as
a GitHub comment by the Codex connector — do NOT call `gh`, `git`, or any
shell command to post comments. Just write your reply.

Respond in natural language markdown:
- If you have a question: write it clearly and conversationally.
- If you have a proposal or conclusion: write it clearly and conversationally.
- If escalating: explain why briefly.

Append exactly ONE of the following invisible HTML markers as the very last
line of your response. They will not be visible to readers.

- You have a question or need clarification: <!-- codex:status:ask -->
- Proposal or task complete: <!-- codex:status:ok -->
- Human escalation required: <!-- codex:status:escalated -->
</output_format>
CLOUD_OUTPUT
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
