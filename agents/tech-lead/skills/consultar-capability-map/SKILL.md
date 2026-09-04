---
name: consultar-capability-map
description: Use esta skill quando precisar decidir quais repositorios de produto sao afetados por uma demanda. Cobre como cruzar o texto da demanda com o capability-map.yml, aplicar regras de propagacao (implies) e decidir o nivel de confianca do escopo proposto.
---

# Consultar o capability map

Conhecimento tático. Complementa `system.md`, nunca o substitui.

## Procedimento
1. Normalize o texto da demanda (minúsculas, sem acento).
2. Cruze com `keywords` de cada domínio em `config/capability-map.yml`.
3. Aplique `implies`: se um repo casou, verifique se ele puxa outro.
4. Nunca proponha repositório listado em `excluded`.
5. Na dúvida entre incluir e não incluir um repo, INCLUA e explique a
   dúvida no campo `notes` da saída.

## Boas práticas de justificativa
Cada repositório proposto precisa de uma frase curta dizendo POR QUE
entrou — não basta listar o nome.
