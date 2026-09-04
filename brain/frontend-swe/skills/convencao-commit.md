# Skill: convenção de commit e branch

Conhecimento tático da platform - vale como padrão para qualquer repo
de produto, mas um repo pode ter uma skill própria que reforça ou
detalha isso para o stack dele.

## Branch
`agentic/<execution_id>` — sempre. Nunca reutilize branch de execução
anterior, mesmo que a demanda pareça similar.

## Commit
Mensagem no formato `feat: <papel> para #<sub_issue> (exec <execution_id>)`.
Um commit por run é suficiente para a POC; em produção, prefira commits
menores e semânticos se o CLI suportar granularidade.

## Pull request
Sempre em draft. Sempre referenciando `Closes #<sub_issue>`. O título
carrega o papel entre colchetes: `[frontend-swe] ...`.
