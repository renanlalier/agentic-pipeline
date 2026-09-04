---
name: convencao-commit
description: Use esta skill ao criar branch, commit ou pull request nesta pipe. Define o formato de nome de branch, mensagem de commit e estrutura do PR esperados por qualquer repositorio de produto.
---

# Convenção de commit e branch

## Branch
`agentic/<execution_id>` — sempre. Nunca reutilize branch de execução
anterior, mesmo que a demanda pareça similar.

## Commit
Mensagem no formato `feat: <papel> para #<sub_issue> (exec <execution_id>)`.

## Pull request
Sempre em draft. Sempre referenciando `Closes #<sub_issue>`. O título
carrega o papel entre colchetes: `[frontend-swe] ...`.
