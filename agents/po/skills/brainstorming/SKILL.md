---
name: brainstorming
description: Use esta skill sempre que uma demanda ainda nao tiver escopo claro o suficiente para virar trabalho tecnico. Guia o refinamento por perguntas, uma de cada vez, ate obter aprovacao explicita do humano sobre um escopo final por escrito. Nao pule esta skill mesmo para demandas que parecam simples.
source: "Adaptado de obra/superpowers (skills/brainstorming), MIT License. https://github.com/obra/superpowers"
---

# Brainstorming — refinamento socrático assíncrono

O original desta skill (superpowers) assume um chat ao vivo, onde o
agente pergunta e a pessoa responde na mesma sessão. Aqui o meio é
assíncrono — cada comentário de issue é um turno separado, com sua
própria execução do agente. A disciplina é a mesma; a mecânica muda.

## O portão rígido (hard gate)

Nenhuma sub-issue, nenhum código, nenhuma proposta de repositório
acontece antes de um escopo ser apresentado por escrito E aprovado
explicitamente pelo humano. Isso vale mesmo que a demanda pareça óbvia
— é justamente nas demandas "óbvias" que suposições não examinadas
custam mais caro depois.

## Classifique antes de perguntar

Antes da primeira pergunta, classifique a demanda mentalmente:

- **Spike/investigação** — a resposta certa nem é código, é uma
  investigação. Diga isso e proponha investigar em vez de perguntar.
- **Limitada** — escopo claro, poucas variáveis. Uma ou duas perguntas
  de confirmação bastam antes de apresentar o escopo.
- **Arquitetural** — decisão que molda vários repositórios ou muda
  contrato entre eles. Merece mais rodadas de pergunta antes de fechar.

## Uma pergunta por turno

Nunca acumule uma lista de perguntas num comentário só. Pergunte a coisa
mais importante que ainda está em aberto. Isso é mais lento em número
de turnos, mas cada resposta do humano é mais fácil de dar — e você
aprende com cada resposta antes de decidir a próxima pergunta.

## Apresentar o escopo

Quando achar que já tem o suficiente, não pergunte "posso prosseguir?"
sem mostrar o que vai construir. Escreva o escopo por escrito, curto,
do ponto de vista do que muda para quem usa — e só então peça aprovação
explícita.

## O que conta como aprovação

Uma resposta afirmativa clara a um escopo que VOCÊ já apresentou no
turno anterior. Nunca trate silêncio, uma pergunta de volta, ou um
comentário vago como aprovação — isso é exatamente o tipo de suposição
não examinada que esta skill existe para evitar.

## Ao concluir

O escopo aprovado vira a descrição canônica da demanda para todo agente
posterior — especialmente o Tech Lead, que nunca releu a conversa
inteira. Escreva pensando nisso: alguém que só vai ler o campo Escopo,
não o histórico de comentários, precisa conseguir agir sobre ele.
