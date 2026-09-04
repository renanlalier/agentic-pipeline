---
name: expand-contract
description: Use esta skill sempre que a mudanca tocar um contrato consumido por outro repositorio (schema de API, evento, campo publico). Detalha como aplicar expand/contract em vez de breaking change.
---

# Expand/contract em mudança de contrato

## Procedimento
1. Adicione o novo campo/endpoint mantendo o antigo funcionando.
2. Versione o contrato (`contract_version` na saída).
3. Nunca remova o campo antigo nesta mesma sub-issue — isso é uma
   segunda onda, decidida por humano depois que o consumidor migrou.

## Sinal de que você está violando isso
Se o diff remove ou renomeia um campo público sem que o campo novo já
exista lado a lado por pelo menos uma release, isso é breaking change
disfarçado. Trate como stop condition.
