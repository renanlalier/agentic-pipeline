---
name: writing-plans
description: Use esta skill como PRIMEIRA acao ao comecar uma sub-issue, antes de qualquer edicao de codigo. Quebra a tarefa em passos pequenos, com caminho de arquivo exato e criterio de verificacao, no contexto real deste repositorio. Itere com o humano via comentarios ate aprovacao explicita - so implemente depois disso.
source: "Adaptado de obra/superpowers (skills/writing-plans), MIT License. https://github.com/obra/superpowers"
---

# Writing plans — detalhamento no contexto do repositório

Esta skill roda ANTES da implementação, não durante, e é um DIÁLOGO, não
uma publicação única. Você já sabe o destino (a sub-issue e o contrato
recebido), mas o caminho dentro deste repositório específico precisa
ser validado por um humano antes de virar código.

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
expand/contract no próprio plano — não decida a estratégia de
versionamento no meio da implementação.

## Iteração com aprovação humana (portão rígido)

Nenhuma implementação começa antes de um humano aprovar explicitamente
o plano que você apresentou. Isso não é uma sugestão — é um portão.

- Se o plano ainda tem uma decisão de decomposição em aberto, ou se
  você não tem certeza suficiente do contexto deste repositório para
  decompor bem, faça UMA pergunta em vez de assumir.
- Quando achar que o plano está pronto, publique-o por escrito e peça
  aprovação explícita — nunca assuma que "parece bom" é aprovação.
- Só trate como aprovação uma resposta afirmativa clara a um plano que
  VOCÊ mesmo já apresentou num turno anterior. Silêncio, uma pergunta de
  volta, ou um comentário vago não contam.
- Cada resposta do humano é um novo turno: releia a conversa inteira, não
  só a última mensagem, antes de decidir se já pode prosseguir.

## Sinal de que o plano está vago demais
Se uma tarefa não tem caminho de arquivo, ou o critério de verificação
é algo como "funciona corretamente" em vez de um teste específico, o
plano não está pronto para ser apresentado — refine antes.
