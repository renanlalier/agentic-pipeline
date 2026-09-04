#!/usr/bin/env bash
# Shared library for discovering and selecting skills in the standard format
# (folder/SKILL.md with frontmatter). Used by adapters whose CLI does NOT
# have native skill loading by description — the fallback here is a simple
# keyword matcher of the description against the prompt.
#
# CLIs with native loading (e.g. Claude Code, which scans .claude/skills/
# and decides relevance semantically) should NOT use this fallback — they
# should copy skill folders to where the CLI discovers them and let it decide.
# See cursor.sh for the native/best-effort loading case.

# list_skill_files <dir> - prints one SKILL.md path per line
list_skill_files() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  find "$dir" -mindepth 2 -maxdepth 2 -name SKILL.md 2>/dev/null
}

# skill_frontmatter <path> - prints only the YAML block between the two '---'
skill_frontmatter() {
  awk '/^---[[:space:]]*$/{c++; next} c==1{print} c>=2{exit}' "$1"
}

# skill_body <path> - prints the content after the second '---'
skill_body() {
  awk 'BEGIN{c=0} /^---[[:space:]]*$/{c++; next} c>=2{print}' "$1"
}

# skill_field <path> <field> - reads a field from the frontmatter (name, description)
skill_field() {
  local path="$1" field="$2"
  skill_frontmatter "$path" | yq -r ".$field // \"\""
}

# select_skills_by_keyword <normalized_prompt> <dir...>
# Generic fallback: matches 5+ letter words from the description against the
# prompt. Prints the BODY of each matched skill with an origin header.
# Used when the CLI has no native on-demand skill loading by description.
select_skills_by_keyword() {
  local prompt_norm="$1"; shift
  local dir origin
  for dir in "$@"; do
    [ -d "$dir" ] || continue
    if [ "$dir" = "$PLATFORM_SKILLS_DIR" ]; then origin="platform"; else origin="repo"; fi
    while IFS= read -r skill_file; do
      [ -z "$skill_file" ] && continue
      local desc name matched word
      desc=$(skill_field "$skill_file" description)
      name=$(skill_field "$skill_file" name)
      matched=0
      for word in $(echo "$desc" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' ' '); do
        [ ${#word} -lt 5 ] && continue
        if echo "$prompt_norm" | grep -qF -- "$word"; then matched=1; break; fi
      done
      if [ "$matched" = "1" ]; then
        echo "## [skill: $name | origin: $origin] $desc" >&1
        skill_body "$skill_file"
        echo ""
        echo "loaded: $name ($origin)" >&2
      else
        echo "skipped (no match): $name ($origin)" >&2
      fi
    done < <(list_skill_files "$dir")
  done
}
