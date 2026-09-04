# Skill: expand/contract em mudança de contrato

Conhecimento tático - detalha COMO aplicar a regra que o system.md exige.

## Procedimento
1. Adicione o novo campo/endpoint mantendo o antigo funcionando.
2. Versione o contrato (`contract_version` na saída).
3. Nunca remova o campo antigo nesta mesma sub-issue - isso é uma
   segunda onda, decidida por humano depois que o consumidor migrou.

## Sinal de que você está violando isso
Se o diff remove ou renomeia um campo público sem que o campo novo já
exista lado a lado por pelo menos uma release, isso é breaking change
disfarçado. Trate como stop condition.
