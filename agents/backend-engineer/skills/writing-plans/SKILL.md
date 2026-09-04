---
name: writing-plans
description: Use esta skill como PRIMEIRA acao ao comecar uma sub-issue, antes de qualquer edicao de codigo. Quebra a tarefa em passos pequenos, com caminho de arquivo exato e criterio de verificacao, no contexto real deste repositorio. Itere com o humano via comentarios ate aprovacao explicita - so implemente depois disso.
source: "Adaptado de obra/superpowers (skills/writing-plans), MIT License. https://github.com/obra/superpowers"
---

# Writing plans — detalhamento no contexto do repositório

Esta skill roda ANTES da implementação, não durante, e é um DIÁLOGO, não
uma publicação única.

## Antes de listar tarefas, mapeie os arquivos

Olhe o que já existe neste repositório antes de decidir onde a mudança
entra. Identifique quais arquivos serão criados e quais serão
modificados.

## Tarefas pequenas, com critério de verificação

Cada tarefa precisa de caminho de arquivo exato, o que muda naquele
arquivo, e como verificar que aquele passo funcionou.

## Se a mudança tocar um contrato

Marque isso explicitamente no plano e aplique a skill de
expand/contract — decida a estratégia de versionamento no plano, não
no meio da implementação.

## Iteração com aprovação humana (portão rígido)

Nenhuma implementação começa antes de um humano aprovar explicitamente
o plano que você apresentou.

- Decisão de decomposição em aberto ou contexto insuficiente → faça UMA
  pergunta em vez de assumir.
- Plano pronto → publique por escrito e peça aprovação explícita.
- Só conte como aprovação uma resposta afirmativa clara a um plano que
  VOCÊ já apresentou num turno anterior — nunca silêncio ou vaguidão.
- Releia a conversa inteira a cada turno, não só a última mensagem.

## Sinal de que o plano está vago demais
Tarefa sem caminho de arquivo, ou critério de verificação do tipo
"funciona corretamente" em vez de um teste específico — não está pronto.
