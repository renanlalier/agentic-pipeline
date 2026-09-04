---
name: kotlin-ktor-boas-praticas
description: Use esta skill sempre que o repositorio em que voce esta rodando for um projeto Kotlin com Ktor. Cobre convencoes de rota, coroutines, serializacao, tratamento de erro e testes com o test engine do Ktor. Nao use em repositorios que nao sejam Kotlin/Ktor.
---

# Kotlin + Ktor — boas práticas

Skill de capacidade de stack: ensina COMO trabalhar bem em um projeto
Kotlin/Ktor. Não substitui o `system.md`.

## Rotas
- Organize rotas por recurso em funções de extensão de `Routing`
  (`Route.healthRoutes()`), não tudo dentro de um único bloco `routing { }`.
- Use os verbos HTTP corretos: `get`, `post`, etc. Não sobrecarregue um
  único endpoint com múltiplas semânticas via query param de ação.

## Coroutines
- Handlers de rota já rodam em uma coroutine fornecida pelo Ktor — não
  crie `GlobalScope.launch` para trabalho que deveria ser parte da
  resposta da requisição.
- Chamadas de I/O (banco, HTTP externo) sempre com função `suspend`.

## Serialização
- Use `kotlinx.serialization` com `@Serializable` em data classes para
  request/response. Não serialize manualmente com concatenação de string.
- Campo opcional em payload de resposta usa tipo anulável (`String?`)
  explícito, nunca um valor sentinela como string vazia para significar
  "ausente".

## Tratamento de erro
- Erros de validação retornam 4xx com corpo estruturado
  (`{"error": "mensagem"}`), nunca uma stack trace.
- Não deixe uma exceção não tratada estourar como 500 sem log — capture
  no nível apropriado e registre contexto suficiente para depurar.

## Testes
- Use `testApplication { }` do Ktor (`io.ktor:ktor-server-test-host`)
  para testar rotas fim a fim, com o `HttpClient` de teste.
- Teste o corpo E o status code da resposta — status 200 com corpo
  errado ainda é um teste que deveria falhar.

## Sinal de que algo está errado
Se você se pegar usando `!!` (non-null assertion) para "fazer o código
compilar", pare — isso quase sempre indica que o tipo deveria ser
anulável e tratado explicitamente, não forçado.
