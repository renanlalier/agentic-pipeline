---
name: expand-contract
description: Use esta skill sempre que a mudanca tocar um contrato consumido por outro repositorio (rota, payload, status code). Detalha como aplicar expand/contract em vez de breaking change.
---

# Expand/contract em mudança de contrato

## Procedimento
1. Adicione o novo campo/rota mantendo o antigo funcionando.
2. Versione o contrato (`contract_version` na saída).
3. Nunca remova o campo antigo nesta mesma sub-issue.

## Sinal de que você está violando isso
Se o diff remove ou renomeia um campo público sem que o novo já exista
lado a lado, isso é breaking change disfarçado — trate como stop condition.
