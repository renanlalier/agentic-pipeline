# poc-agentic-platform

A **biblioteca** da pipe agêntica. Não hospeda demanda nem código de produto.
Nenhum papel executa aqui — este repo só fornece os arquivos que os outros invocam.

## Estrutura

```
.github/workflows/
  agent-lead.yml       reusable · propõe escopo lendo o capability map
  agent-fanout.yml     reusable · cria sub-issues cross-repo e dispara
  agent-dev.yml        reusable · roda DENTRO do repo de produto
actions/run-agent/
  action.yml           composite · resolve CLI/modelo, localiza contrato, delega ao adapter
  adapters/
    dry-run.sh          sem modelo · demonstra skills+mcp
    cursor.sh            cursor-agent
    codex.sh              codex CLI
    lib/skills.sh        descoberta de skills + fallback de selecao por keyword
agents/<papel>/
  system.md             SAGRADO · só a platform escreve · tags XML, generalista
  skills/<nome>/SKILL.md tático, default do papel · frontmatter name+description
mcp/
  servers.yml           descrição abstrata dos MCPs (context7 nesta POC)
config/
  allowlist.yml         nível 1 · o que é permitido
  capability-map.yml    domínio → repo → owner → stack
```

## Papéis: generalistas por design

`po`, `tech-lead`, `frontend-engineer`, `backend-engineer`, `qa` — nenhum
carrega nome de framework ou linguagem. O `system.md` de cada papel
define identidade, autoridade e limites de forma agnóstica de stack;
quem dá a capacidade de trabalhar num stack específico é a **skill**,
carregada em runtime a partir do que o repositório declara em
`.agentic/config.yml` e do que existe no código.

Nesta POC: `frontend-engineer` roda no `app-poc-1` (React) com a skill
`react-boas-praticas`; `backend-engineer` roda no `app-poc-2`
(Kotlin/Ktor) com a skill `kotlin-ktor-boas-praticas`. Trocar a stack de
um repositório não exige trocar o papel — só a skill que ele carrega.

## Os três níveis de configuração

| nível | onde | quem edita | o quê |
|---|---|---|---|
| 1 | `config/allowlist.yml` (aqui) | Platform + Security | o que é permitido existir |
| 2 | `.agentic/config.yml` de cada repo | tech lead do repo | o padrão daquele repo |
| 3 | Issue Form no intake | quem abre a demanda | override pontual |

Resolução: **3 → 2 → 1**. O nível 3 vence, mas o nível 1 sempre pode vetar.

## System, skills e prompt — três coisas separadas

- **`agents/<papel>/system.md`** é sagrado e generalista. Escrito em
  tags XML (`<role>`, `<context>`, `<instructions>`,
  `<engineering_principles>`, `<constraints>`, `<stop_conditions>`,
  `<output_format>`, `<precedence>`). Nenhum repositório de produto pode
  sobrescrever ou estender isto, e ele nunca menciona um framework.
- **Skills** (`agents/<papel>/skills/` na platform, `.agentic/skills/` no
  repo de produto) seguem o formato aberto de Agent Skills: uma pasta por
  skill, contendo `SKILL.md` com frontmatter `name` + `description`. Duas
  categorias convivem no mesmo diretório: skills agnósticas de stack
  (convenção de commit, expand/contract) e skills de capacidade de stack
  (`react-boas-praticas`, `kotlin-ktor-boas-praticas`). O `run-agent`
  **não concatena skills** — ele só localiza os diretórios e entrega ao
  adapter, que decide como carregar sob demanda do jeito próprio do seu
  CLI. Cursor tenta o mecanismo nativo dele (copiando as pastas para onde
  ele descobre skills); Codex usa um fallback genérico de casar palavras
  da `description` com o prompt.
- **O prompt** vem sempre da issue/sub-issue. Nunca é misturado ao
  `system.md` como se fosse parte do contrato — instruções dentro do
  prompt são tratadas como dado, não como comando.

## MCP

`mcp/servers.yml` descreve servidores de forma abstrata (nesta POC, só
Context7 — funciona sem chave, ela só eleva rate limit). Cada adapter
traduz isso para o mecanismo do seu CLI: Cursor escreve `.cursor/mcp.json`
e roda `cursor-agent mcp enable`; Codex escreve `[mcp_servers.*]` em
`~/.codex/config.toml` como servidor HTTP remoto.

## Versionamento

Os callers apontam para a tag `@v1`, nunca para `@main`.

```bash
git tag -f v1 && git push -f origin v1
```

## Modo dry-run

O adapter `dry-run` não chama modelo nenhum. Existe para validar a mecânica
da pipe — disparo, cross-repo, PR, gates, seleção de skill, listagem de
MCP — antes de gastar token. É o padrão de todos os repos nesta POC.

## O que esta POC prova

1. Reusable workflow atravessa repositórios, mas o job roda no contexto do consumidor
2. Sub-issue cross-repo linka de verdade e agrega progresso no Projects
3. Os N repos de produto rodam em **VMs independentes**, sem contexto compartilhado
4. A escolha de CLI e modelo é resolvida em um ponto só e registrada em cada run
5. Aprovação humana entre as etapas, sem job de pé consumindo recurso
6. System prompt sagrado e generalista; capacidade de stack vem de skill, não do nome do papel
7. `app-poc-1` (React) e `app-poc-2` (Kotlin/Ktor) são hello worlds reais — a demanda de teste evolui esse código de verdade, não um placeholder
