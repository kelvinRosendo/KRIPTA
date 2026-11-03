# Kai — provedores substituíveis

Web e Flutter usam um contrato estável: POST `/api/ai/chat`, corpo `{ "message": "..." }`, resposta `{ "reply": "..." }`. Autenticação JWT é exigida pelo filtro existente. Mensagem entre 1 e 4000 caracteres; resposta limitada a 16000 caracteres. Falha ou ausência de provedor retorna 503 com código IA_INDISPONIVEL e mensagem controlada.

## Estrutura

`KaiController → KaiService → AiProvider`

Cada adaptador implementa `AiProvider` e é registrado como bean Spring (por exemplo, `@Component`). O método `id()` fornece identificador único, como `provedor-a`; `reply(instructions, message, timeout)` traduz a chamada para a API específica. O adaptador configura autenticação, modelo, limites de saída e timeouts de conexão/leitura. Chaves vêm de variáveis de ambiente exclusivas daquele adaptador. Nunca colocar chaves no frontend.

`KaiService` recebe todos os adaptadores e escolhe um por `AI_PROVIDER`. Para trocar entre adaptadores já instalados, alterar a variável e reiniciar o backend. Para adicionar um fornecedor com protocolo diferente, implementar outro adaptador, sem modificar controller, serviço ou consumidores. Para adicionar modelos do mesmo fornecedor, o adaptador pode expor uma variável de modelo.

Padrão: `AI_PROVIDER=disabled`. O sistema inicia normalmente sem credenciais; o chat retorna indisponibilidade. Nenhum adaptador de fornecedor real foi incluído nesta entrega. Há dois adaptadores de teste para comprovar a seleção, não disponíveis no aplicativo.

## Comportamento operacional

O tempo de espera é configurado por AI_TIMEOUT_SECONDS (20 por padrão; entre 1 e 60). Executor limitado a 4 chamadas ativas e 8 aguardando; excesso retorna indisponibilidade. Timeout cancela a tarefa; cada adaptador também deve respeitar o prazo no cliente HTTP, porque interrupção Java não garante cancelar qualquer operação de rede. Não há fallback automático para outro fornecedor: isso evita reenviar mensagens a outro serviço e gerar custos sem configuração explícita.

Esta estrutura ainda não inclui cotas individuais, histórico de conversa, acesso aos dados acadêmicos ou cobrança. Antes de habilitar um provedor real, definir limites por usuário e orçamento, adicionar o adaptador e testar uma chamada real. A Etapa 06 só estará completa após essa validação e o teste no navegador. O contrato atual envia apenas a mensagem; Kai não conhece tarefas ou materiais do usuário.

Testes cobrem seleção entre dois provedores, ausência de configuração, duplicidade de identificadores, resposta vazia, erro sem vazamento e timeout.
