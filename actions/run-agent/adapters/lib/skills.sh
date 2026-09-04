#!/usr/bin/env bash
# Biblioteca compartilhada para descobrir e selecionar skills no formato
# padrao (pasta/SKILL.md com frontmatter). Usada por adapters cujo CLI
# NAO tem carregamento nativo de skill por description - o fallback aqui
# e um matcher simples por palavras-chave da description contra o prompt.
#
# CLIs com carregamento nativo (ex: Claude Code, que escaneia .claude/skills/
# e decide relevancia semanticamente) NAO devem usar este fallback - devem
# copiar as pastas de skill para onde o proprio CLI as descobre e deixar
# ele decidir. Ver cursor.sh para o caso de carregamento nativo/best-effort.

# list_skill_files <dir> - imprime um caminho de SKILL.md por linha
list_skill_files() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  find "$dir" -mindepth 2 -maxdepth 2 -name SKILL.md 2>/dev/null
}

# skill_frontmatter <path> - imprime so o bloco YAML entre os dois '---'
skill_frontmatter() {
  awk '/^---[[:space:]]*$/{c++; next} c==1{print} c>=2{exit}' "$1"
}

# skill_body <path> - imprime o conteudo apos o segundo '---'
skill_body() {
  awk 'BEGIN{c=0} /^---[[:space:]]*$/{c++; next} c>=2{print}' "$1"
}

# skill_field <path> <campo> - le um campo do frontmatter (name, description)
skill_field() {
  local path="$1" field="$2"
  skill_frontmatter "$path" | yq -r ".$field // \"\""
}

# select_skills_by_keyword <prompt_normalizado> <dir...>
# Fallback generico: casa palavras de 5+ letras da description com o
# prompt. Imprime o BODY de cada skill que casou, com um cabecalho de
# origem. Usado quando o CLI nao tem mecanismo proprio de carregamento
# sob demanda por description.
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
        echo "## [skill: $name | origem: $origin] $desc" >&1
        skill_body "$skill_file"
        echo ""
        echo "carregada: $name ($origin)" >&2
      else
        echo "ignorada (sem match): $name ($origin)" >&2
      fi
    done < <(list_skill_files "$dir")
  done
}
