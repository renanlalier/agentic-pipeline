---
name: react-boas-praticas
description: Use esta skill sempre que o repositorio em que voce esta rodando for um projeto React. Cobre convencoes de componente, hooks, estado, testes com Testing Library e acessibilidade basica. Nao use em repositorios que nao sejam React.
---

# React — boas práticas

Esta é uma skill de capacidade de stack: ensina COMO trabalhar bem em um
projeto React. Ela não te diz o que você pode ou não pode fazer — isso
está no `system.md`, que esta skill não substitui.

## Componentes
- Componentes funcionais com Hooks. Não introduza componente de classe.
- Um componente por arquivo, nome do arquivo igual ao nome do componente
  (`App.jsx` exporta `App`).
- Props tipadas via PropTypes ou JSDoc quando o repositório não usa
  TypeScript; siga o que já existe no repositório antes de escolher.

## Hooks
- Nunca chame Hook dentro de condicional, loop ou função aninhada.
- `useEffect` sempre com array de dependências explícito — não omita.
- Extraia lógica reutilizável para um Hook customizado (`useAlgumaCoisa`)
  em vez de duplicar `useEffect`/`useState` entre componentes.

## Estado
- Estado local (`useState`) para o que só aquele componente e seus
  filhos diretos precisam. Não suba estado para um nível global sem
  necessidade real de compartilhamento.

## Testes
- Testing Library: teste o comportamento visível ao usuário (texto na
  tela, resposta a clique), não detalhe de implementação interna.
- Nunca use seletor de classe CSS ou estrutura do DOM como asserção
  primária — prefira `getByRole` e `getByText`.

## Acessibilidade básica
- Todo elemento interativo precisa ser alcançável por teclado.
- Imagem com conteúdo semântico leva `alt`; imagem decorativa,
  `alt=""`.

## Sinal de que algo está errado
Se você se pegar manipulando o DOM diretamente (`document.querySelector`
dentro de um componente) fora de um caso excepcional documentado, pare —
isso quase sempre indica que o problema deveria ser resolvido com estado
ou uma ref do React, não com acesso direto ao DOM.
