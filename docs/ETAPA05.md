# Etapa 05 — gamificação persistida

## Regras

- Concluir tarefa própria concede 25 XP. Histórico único por usuário/tarefa impede nova concessão, mesmo após repetição ou exclusão da tarefa. Tarefas novas têm IDs novos.
- Nível = 1 + piso(XP / 100). A cada 100 XP há novo nível. Progresso e XP restante vêm do servidor.
- Conquistas persistidas: FIRST_TASK (1 tarefa), TEN_TASKS (10 tarefas), FIRST_STREAK (primeiro dia de 600 segundos), WEEK_STREAK (7 dias consecutivos qualificados).
- Professores e administradores não participam; ALUNO e contas legadas USUARIO participam.
- Relógio do servidor; dia civil America/Sao_Paulo. Primeiro heartbeat inicia acompanhamento. Intervalos positivos de até 45 segundos creditam no máximo 30 segundos por chamada. Pausas maiores não contam. Na virada do dia só o trecho do novo dia é creditado.
- 600 segundos creditados qualificam o dia uma única vez. Dias consecutivos incrementam a sequência; dia perdido zera a sequência exibida e a próxima qualificação reinicia em 1.
- A web envia heartbeat a cada 15 segundos com aba visível, sem informar tempo creditável. O servidor ignora segundos enviados pelo cliente. Heartbeats demonstram continuidade autenticada; não comprovam atenção humana e não impedem automação de chamadas.

## Persistência e concorrência

Progresso agrega XP e uso diário atual; histórico de XP e conquistas preservam as concessões. Cada operação de gamificação bloqueia a linha do usuário durante a transação, serializando abas e requisições concorrentes. Unicidade no banco protege histórico e conquistas. Conclusão da tarefa e concessão de XP pertencem à mesma transação.

## API e web

- POST `/api/usage/heartbeat` sem corpo significativo.
- GET `/api/progresso` e `/api/gamificacao/estatisticas`: xp, level, xpToNextLevel, levelProgress, streak, seconds, threshold, progress, advanced.
- GET `/api/gamificacao/conquistas`: apenas conquistas desbloqueadas, com código, nome e data.
- A conclusão continua em PATCH `/api/tarefas/{id}/concluir`. A consulta de progresso mostra o novo saldo.
- Home e perfil usam dados reais. Logout interrompe o temporizador. Insígnias bloqueadas não são mostradas como desbloqueadas.

## Testes

GamificationFlowTest usa relógio controlado para testar limite de 600 segundos, repetição, pausas, dias consecutivos, dia perdido e meia-noite. GamificationConcurrencyTest envia quatro conclusões simultâneas da mesma tarefa e exige exatamente 25 XP. CI repete esses testes em PostgreSQL e verifica saldo e primeira conquista após reinício.

Pendente: conferência visual no navegador e validação da configuração de pontos/conquistas contra o PDF original. Os valores acima são a política implementada, sem alegar que foram prescritos pelo documento não disponível.
