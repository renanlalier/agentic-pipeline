# poc-agentic-platform

A **biblioteca** da pipe agêntica. Não hospeda demanda nem código de produto.
Nenhum papel executa aqui — este repo só fornece os arquivos que os outros invocam.

## Estrutura

```
.github/workflows/
  agent-lead.yml      reusable · propõe escopo lendo o capability map
  agent-fanout.yml    reusable · cria sub-issues cross-repo e dispara
  agent-dev.yml       reusable · roda DENTRO do repo de produto
actions/run-agent/
  action.yml          composite · resolve CLI e modelo, valida allowlist
  adapters/           dry-run · cursor · codex
skills/               contratos de papel, portáveis entre CLIs
config/
  allowlist.yml       nível 1 · o que é permitido
  capability-map.yml  domínio → repo → owner
```

## Os três níveis de configuração

| nível | onde | quem edita | o quê |
|---|---|---|---|
| 1 | `config/allowlist.yml` (aqui) | Platform + Security | o que é permitido existir |
| 2 | `.agentic/config.yml` de cada repo | tech lead do repo | o padrão daquele repo |
| 3 | Issue Form no intake | quem abre a demanda | override pontual |

Resolução: **3 → 2 → 1**. O nível 3 vence, mas o nível 1 sempre pode vetar.

## Versionamento

Os callers apontam para a tag `@v1`, nunca para `@main`. Um commit aqui
não deve mudar o comportamento de 4 repositórios sem release explícito.

```bash
git tag -f v1 && git push -f origin v1
```

## Modo dry-run

O adapter `dry-run` não chama modelo nenhum. Existe para validar a mecânica
da pipe — disparo, cross-repo, PR, gates — antes de gastar token.
É o padrão de todos os repos nesta POC.

## O que esta POC prova

1. Reusable workflow atravessa repositórios, mas o job roda no contexto do consumidor
2. Sub-issue cross-repo linka de verdade e agrega progresso no Projects
3. Os N repos de produto rodam em **VMs independentes**, sem contexto compartilhado
4. A escolha de CLI e modelo é resolvida em um ponto só e registrada em cada run
5. Aprovação humana entre as etapas, sem job de pé consumindo recurso
