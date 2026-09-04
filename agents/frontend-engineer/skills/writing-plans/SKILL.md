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
modificados, e o que cada um é responsável por. É aqui que a decisão de
decomposição é travada — depois disso, a lista de tarefas é só
consequência.

## Tarefas pequenas, com critério de verificação

Cada tarefa do plano deve ser pequena o suficiente para revisar de uma
vez (pense em poucos minutos de trabalho, não em "implementar a
feature inteira"). Cada uma precisa de:

- caminho de arquivo exato
- o que muda naquele arquivo
- como verificar que aquele passo específico funcionou (rodar qual
  teste, checar qual comportamento)

## Se a mudança tocar um contrato

Se alguma tarefa do plano envolve rota, payload, schema ou qualquer
coisa que outro repositório consome, marque isso explicitamente no
plano e aplique a skill de expand/contract — não decida a estratégia
de versionamento no meio da implementação, decida agora, no plano.

## Publique antes de implementar

O plano vira um comentário na sub-issue antes do primeiro commit. Isso
não é burocracia: é o que permite a um humano interromper uma decisão
de decomposição errada antes de ela virar código, e é o que dá ao
Meta Observer uma trilha de por que o código ficou do jeito que ficou.

## Sinal de que o plano está vago demais
Se uma tarefa do seu plano não tem caminho de arquivo, ou o critério de
verificação é algo como "funciona corretamente" em vez de um teste ou
comportamento específico, o plano não está pronto — refine antes de
publicar.
