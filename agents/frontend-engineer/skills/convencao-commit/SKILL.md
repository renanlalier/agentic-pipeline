---
name: convencao-commit
description: Use esta skill sempre que criar branch, commit ou pull request nesta pipe, independente da stack do repositorio. Define o formato de nome de branch, mensagem de commit e estrutura do PR esperados.
---

# Convenção de commit e branch

Esta skill é agnóstica de stack — vale para qualquer repositório de
produto, seja qual for a linguagem ou framework.

## Branch
`agentic/<execution_id>` — sempre. Nunca reutilize branch de execução
anterior, mesmo que a demanda pareça similar.

## Commit
`feat: <papel> para #<sub_issue> (exec <execution_id>)`.

## Pull request
Sempre em draft, sempre referenciando `Closes #<sub_issue>`. Título com
o papel entre colchetes: `[frontend-engineer] ...`.
