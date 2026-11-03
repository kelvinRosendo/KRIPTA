# Etapas 07 e 08 — integração e revisão de entrega

Atualizado em 03/11/2026. Este relatório complementa o roadmap original; não atesta a conclusão integral do TCC.

## O que mudou

- Flutter usa cadastro ALUNO com RM, login real e armazenamento seguro do JWT. Cadastro chama o login após registrar.
- Cache de autenticação renovado após login; expiração encerra a sessão. Dados e conversa local são invalidados na troca de conta.
- Home agrega tarefas, progresso e conquistas dos endpoints existentes, sem `/dashboard` fictício.
- Notificações usam `/notificacoes`, data do evento e leitura persistida; conquistas usam `code/name/earned/earnedAt`.
- Unidades e materiais devolvem seus identificadores de vínculo na API.
- Catálogo de conteúdos aprovados acessível pelo livro na tela Matérias.
- Criação de tarefas e de eventos pessoais no dia selecionado, conclusão de tarefas e atualização de XP/perfil.
- Heartbeat a cada 15 segundos apenas com sessão de aluno e aplicativo em primeiro plano; o servidor calcula o tempo.
- Navegação de meses corrigida para meses civis, sem soma fixa de 30 dias.
- Respostas com contrato inválido geram erro visível em vez de descartar registros silenciosamente.
- Logs HTTP não registram corpos nem cabeçalhos com credenciais. O parâmetro web `?mock=on` não ativa mais dados de demonstração.
- Conflitos de integridade retornam 409 sanitizado. Exclusão de contas com registros vinculados permanece bloqueada; não há exclusão em cascata indiscriminada.
- Kai mantém o mesmo contrato independente de provedor; sem adaptador real responde 503. O timeout mobile padrão é 70 segundos, acima do máximo configurável de 60 segundos do serviço.

## Matriz de aceitação

| Caso | Evidência automatizada | Limite de aceitação |
| --- | --- | --- |
| UC01 autenticar | testes Java e HTTP; Flutter cadastro, login, token, erro 401 e logout | verificar armazenamento seguro e retorno ao app em aparelho |
| UC02 calendário/avisos | isolamento, intervalo e leitura Java; contratos e fluxo HTTP Flutter | revisão visual da agenda em aparelho |
| UC03 consultar | Java impede conteúdo pendente/rejeitado por ID; catálogo Flutter usa rota aprovada | navegação visual dos links externos |
| UC04 Kai | autenticação, validação, timeout e 503 testados | resposta real pendente por decisão de manter o provedor desativado |
| UC05 cadastrar conteúdo | fluxo Java/PostgreSQL e web integrada | publicação por professor na web; Flutter focado no aluno |
| UC06 aprovar | permissão do servidor e decisão repetida testadas | conferir interface do professor na web |
| UC07 progresso | XP único concorrente, 600 segundos, virada de dia e pausas Java | uso em primeiro plano no aparelho; heartbeat não prova atenção humana |
| UC08 consultar progresso | Java persistência e Flutter decodificação de XP/conquistas | conferência visual do perfil |

## Resultado local

57 testes Flutter aprovados (1 integração real reservada à CI), análise sem avisos e APK debug gerado. Seis testes web e build aprovados. 93 testes Java locais passaram; o workflow repete os testes sobre o código final e PostgreSQL. Resultado remoto deve ser conferido nos checks da PR 7.

## Testes reproduzíveis

- `backend`: JDK 21, `./mvnw test` (Windows: `./mvnw.cmd test`).
- `frontend`: `npm ci`, `node --test tests/*.test.cjs`, `npm run build`.
- `mobile`: Flutter 3.47.4 / Dart 3.13.3, `flutter pub get`, `flutter analyze`, `flutter test`.
- Com uma API de teste real iniciada: `flutter test test/api_integration_test.dart --dart-define=TEST_API_URL=http://localhost:8080/api/` dentro de `mobile`.
- `flutter build apk --debug`: alvo padrão `lib/main.dart`, sem dublês.

O teste Flutter de integração cria uma conta com identificador único em uma base de testes. Um segundo cliente HTTP cria uma tarefa, o repositório Flutter consulta e conclui, e o segundo cliente verifica a atualização. O teste também verifica unidades/materiais, notificações, calendário, XP após novo login e Kai desativado. Não equivale a abrir o navegador e o APK em um emulador.

O workflow `.github/workflows/auth-tests.yml` executa testes, migrations PostgreSQL, reinício do backend, integração Flutter e gera o artefato `kripta-debug-apk`.

## Pendências para declarar pronto

1. Integrar e validar um provedor real do Kai, com limites de uso/custo, quando autorizado.
2. Testar APK em aparelho/emulador, incluindo sessão restaurada, ausência de rede, teclado e retorno do segundo plano.
3. Executar o roteiro visual web ↔ APK com a mesma conta; testar responsividade e acessibilidade da web.
4. Conferir o PDF original do TCC, que não foi disponibilizado nesta execução.
5. Interfaces completas de publicação/aprovação seguem na web. No mobile, calendário é consulta/criação de evento pessoal; edição/exclusão e gestão completa de matérias/materiais continuam disponíveis pela web.
6. Antes de disponibilizar na internet: configurar HTTPS, URL real da API, origens CORS do domínio de entrega e proteção contra abuso no login/Kai. Não há publicação de produção nesta PR.

Portanto: etapa 7 tem integração implementada e validação automatizada; aceite em dispositivo pendente. Etapa 8 tem revisão e automação de entrega, mas o aceite final permanece aberto nos itens acima.
