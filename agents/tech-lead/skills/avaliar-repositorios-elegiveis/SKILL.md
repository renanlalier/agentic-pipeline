---
name: avaliar-repositorios-elegiveis
description: Use esta skill sempre que precisar decidir quais repositorios de produto sao afetados por uma demanda. Cobre como ler o fingerprint real de cada repositorio elegivel (descricao do GitHub, README, linguagem) recebido no prompt e decidir relevancia por julgamento, nao por palavra-chave.
---

# Avaliar repositórios elegíveis

Conhecimento tático. Complementa `system.md`, nunca o substitui.

## O que você recebe
O prompt inclui, para cada repositório elegível, um bloco com o nome, o
papel lógico sugerido, um resumo de domínio dado pela platform, a
descrição real do repositório no GitHub, a linguagem principal e um
trecho do README — tudo obtido ao vivo, na hora em que esta execução
começou.

## Procedimento
1. Leia a demanda com atenção ao que ela descreve tecnicamente: qual
   comportamento está quebrado ou deve mudar, em qual camada isso
   provavelmente vive.
2. Para cada repositório elegível, compare o que a demanda descreve com
   o que a descrição, o README e a linguagem daquele repositório sugerem
   que ele faz. Não procure a palavra exata da demanda no texto — julgue
   se o domínio é o mesmo.
3. Aplique as regras de `implies` do capability map: se um repositório
   claramente entra, verifique se ele costuma puxar outro.
4. Nunca proponha um repositório que não esteja na lista de elegíveis
   recebida — mesmo que a demanda o mencione por nome.
5. Na dúvida entre incluir e não incluir, inclua e explique a dúvida em
   `notes`. Escopo a mais é corrigido pelo humano no HITL 1; escopo a
   menos vira retrabalho tardio e é mais caro.

## Boas práticas de justificativa
Cada `reason` no array `repos` precisa citar o que especificamente no
fingerprint (a descrição, o README, ou a demanda) levou à inclusão —
"parece relacionado" não é uma justificativa aceitável.
