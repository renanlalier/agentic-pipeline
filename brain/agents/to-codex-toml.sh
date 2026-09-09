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
SYSTEM=$(yq '.system' "$AGENT_YML")

printf 'name = "%s"\n' "$NAME"
printf 'description = "%s"\n\n' "$DESC"

# developer_instructions is the Codex Cloud equivalent of a system prompt.
# Triple-quoted TOML strings allow newlines and all characters except """.
printf 'developer_instructions = """\n'
printf '%s\n' "$SYSTEM"

# Output markers appended after the system prompt. These invisible HTML
# comments allow the pipeline to detect what Codex decided and apply the
# correct label transition in codex-response-received.
cat << 'MARKERS'

## Output Markers (cloud mode — REQUIRED)
Append exactly one of the following markers at the very end of your response.
They are HTML comments and will not be visible to human readers.

- You have a question or need clarification: <!-- codex:status:ask -->
- Task or scope is complete / approved: <!-- codex:status:approved -->
- Human escalation required: <!-- codex:status:escalated -->
- Implementation done, PR opened: <!-- codex:status:done -->
MARKERS

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
