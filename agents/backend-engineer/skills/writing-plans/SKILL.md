---
name: writing-plans
description: Use esta skill como PRIMEIRA acao ao comecar uma sub-issue, antes de qualquer edicao de codigo. Quebra a tarefa em passos pequenos, com caminho de arquivo exato e criterio de verificacao, no contexto real deste repositorio. Publique o plano como comentario na sub-issue antes de implementar.
source: "Adaptado de obra/superpowers (skills/writing-plans), MIT License. https://github.com/obra/superpowers"
---

# Writing plans — detalhamento no contexto do repositório

Esta skill roda ANTES da implementação, não durante. É o "abrir o mapa
antes de andar": você já sabe o destino (a sub-issue e o contrato
recebido), mas ainda não decidiu o caminho dentro deste repositório
específico.

## Antes de listar tarefas, mapeie os arquivos

Olhe o que já existe neste repositório antes de decidir onde a mudança
entra. Identifique quais arquivos serão criados e quais serão
modificados, e o que cada um é responsável por.

## Tarefas pequenas, com critério de verificação

Cada tarefa do plano precisa de caminho de arquivo exato, o que muda
naquele arquivo, e como verificar que aquele passo específico funcionou.

## Se a mudança tocar um contrato

Se alguma tarefa do plano envolve rota, payload ou schema que outro
repositório consome, marque isso explicitamente e aplique a skill de
expand/contract — decida a estratégia de versionamento no plano, não
no meio da implementação.

## Publique antes de implementar

O plano vira um comentário na sub-issue antes do primeiro commit — dá
a um humano a chance de interromper uma decomposição errada antes de
virar código, e dá ao Meta Observer uma trilha de por que o código
ficou do jeito que ficou.

## Sinal de que o plano está vago demais
Se uma tarefa não tem caminho de arquivo, ou o critério de verificação
é algo como "funciona corretamente" em vez de um teste específico, o
plano não está pronto.
