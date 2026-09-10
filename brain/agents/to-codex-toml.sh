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
DISPLAY_NAME=$(yq '.display_name // ""' "$AGENT_YML")
[ -z "$DISPLAY_NAME" ] && DISPLAY_NAME="$NAME"
# Folded YAML scalar '>': yq returns the value with a trailing newline; strip it.
DESC=$(yq '.description' "$AGENT_YML" | tr '\n' ' ' | sed 's/[[:space:]]*$//')

SYSTEM=$(yq '.system' "$AGENT_YML")

printf 'name = "%s"\n' "$NAME"
printf 'description = "%s"\n\n' "$DESC"

# developer_instructions is the Codex Cloud equivalent of a system prompt.
# Triple-quoted TOML strings allow newlines and all characters except """.
printf 'developer_instructions = """\n'
printf '%s\n' "$SYSTEM"

# Inline cloud_skills listed in agent.yml.
# Local adapters load skills dynamically; Codex Cloud only sees developer_instructions,
# so we embed the full SKILL.md content here.
SKILLS_DIR="$SCRIPT_DIR/../skills"
while IFS= read -r skill_name; do
  [ -z "$skill_name" ] && continue
  SKILL_FILE="$SKILLS_DIR/$skill_name/SKILL.md"
  if [ -f "$SKILL_FILE" ]; then
    printf '\n'
    cat "$SKILL_FILE"
    printf '\n'
  else
    printf '::warning::cloud_skill "%s" not found: %s\n' "$skill_name" "$SKILL_FILE" >&2
  fi
done < <(yq '.cloud_skills[]' "$AGENT_YML" 2>/dev/null || true)

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
