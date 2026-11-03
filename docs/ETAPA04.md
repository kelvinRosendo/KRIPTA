# Etapa 04 — calendário e notificações

Eventos pessoais pertencem ao criador. Eventos escolares são publicados por professores e visíveis a todos os usuários autenticados da instituição; só o autor pode editar/excluir. Não há turmas nesta versão.

## Contrato

- GET `/api/calendario?inicio=2026-11-01&fim=2026-11-30&scope=ALL`: intervalo inclusivo, máximo de 366 dias; scope PESSOAL/ESCOLAR/ALL.
- GET/POST `/api/calendario/eventos`: lista pessoal ou criação.
- GET/PUT/DELETE `/api/calendario/eventos/{id}`: consulta, edição e exclusão autorizadas.
- Corpo: title obrigatório (até 200), note opcional (até 4000), date obrigatório YYYY-MM-DD, time opcional HH:mm, scope PESSOAL por padrão e type EVENT/EXAM/TASK.
- GET `/api/notificacoes`: avisos derivados dos eventos visíveis, cada um com id/eventId, title, message, date, type e read.
- PATCH `/api/notificacoes/{id}/ler`: marca leitura individual, de forma idempotente.

Datas e horários representam o calendário civil da instituição em America/Sao_Paulo. Eventos sem horário são de dia inteiro. A API usa LocalDate/LocalTime e não converte datas à meia-noite UTC, evitando deslocamento de dia na web. Não há conversão automática para fuso de viagem nem push.

Cada evento gera um aviso identificado pelo próprio eventId. O conteúdo do aviso vem do evento persistido; leitura fica em tabela própria por usuário. Alterar o evento redefine a leitura para que a mudança seja vista; excluir remove o aviso e as leituras. Eventos escolares também geram avisos para contas criadas posteriormente, sem duplicar eventos por destinatário.

## Web

Visões dia/semana/mês consultam a mesma API. Na agenda do dia o autor pode editar/excluir. O formulário permite horário e tipo, e categoria escolar para professores. A central permite marcar avisos como lidos. A seção de avisos reutiliza as notificações reais, sem dados de demonstração.

## Verificação

CalendarFlowTest cobre intervalo inclusivo, ausência de registros, intervalo invertido, acesso direto de outro usuário, edição/exclusão restritas, leitura idempotente e isolada, edição que redefine leitura, eventos escolares e exclusão do aviso. CI executa o teste em PostgreSQL com Flyway e verifica evento/leitura após reiniciar a aplicação. Testes web verificam contratos e filtragem por dia.

Teste visual no navegador ainda pendente. Não foi implementado agendamento de lembretes ou envio push, que não são exigidos para a central interna desta etapa.
