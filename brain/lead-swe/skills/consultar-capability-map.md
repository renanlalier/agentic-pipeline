# Skill: como consultar o capability map

Esta skill é conhecimento tático - complementa o system.md, nunca o
substitui. Ela pode ser sobrescrita ou desativada, o system.md não pode.

## Procedimento
1. Normalize o texto da demanda (minúsculas, sem acento).
2. Cruze com `keywords` de cada domínio em `config/capability-map.yml`.
3. Aplique `implies`: se um repo casou, verifique se ele puxa outro.
4. Nunca proponha repositório listado em `excluded`.
5. Na dúvida entre incluir e não incluir um repo, INCLUA e explique a
   dúvida no campo `notes` da saída. Escopo a mais é corrigido pelo
   humano no HITL 1; escopo a menos vira retrabalho tardio e é mais caro.

## Boas práticas de justificativa
Cada repositório proposto precisa de uma frase curta dizendo POR QUE
entrou - não basta listar o nome. Isso é o que o humano vai ler para
decidir se aprova.
