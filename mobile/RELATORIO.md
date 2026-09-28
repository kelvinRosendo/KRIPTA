# Relatório de Implementação — KRIPTA Mobile

Documento de acompanhamento do que foi construído no cliente Flutter, o que
foi verificado e o que ficou dependente de terceiros. Complementa o
[`README.md`](README.md), que é o guia de uso.

## 1. Escopo

Cliente Android/iOS do KRIPTA, consumindo a API Spring Boot já existente.
Escopo funcional: autenticação, sessão persistente, matérias com unidades e
materiais, tarefas, calendário, avisos, gamificação na Home, perfil e chat
com o agente Kai.

## 2. Stack e versões

| Item | Versão |
|---|---|
| Flutter | 3.47.2 |
| Dart | 3.13.2 |
| `flutter_riverpod` | 3.4.3 |
| `dio` | 5.11.1 |
| `go_router` | 18.0.2 |
| `flutter_secure_storage` | 11.2.0 |
| `json_serializable` | via `build_runner` |
| `google_fonts` | 9.0.0 |
| `speech_to_text` | 7.5.0 |

## 3. Arquitetura

Quatro camadas com dependência unidirecional:

```
core/      config · network · error · utils · theme · widgets · di · router
domain/    entities · repositories (contratos)
data/      dto (+ *.g.dart) · mappers · repositories (implementações)
features/  auth · home · materias · tarefas · calendario · avisos · kai · perfil · shell
```

Três invariantes sustentam o desenho:

1. **Fronteira de erro.** Nenhuma `DioException`, `JsonException` ou
   `Exception` crua sai de um repositório. `ApiRepositoryBase.guard` converte
   tudo em `Failure`, que é selada — o `switch` sobre `kind` faz o analyzer
   apontar qualquer tipo novo sem tratamento.
2. **Independência da UI.** `presentation` importa `core` e `domain`, nunca
   `dio` nem `data/dto`. Isso permite testar telas sem servidor.
3. **IA só no backend.** Não há chave de OpenAI/Gemini no aplicativo. O Kai é
   acessado por `POST /api/ai/chat`, como já faz o frontend web.

### Decisões que valem registro

**Riverpod 3 sem APIs legadas.** `StateProvider` e `StateNotifierProvider`
estão fora. Estados assíncronos usam `AsyncNotifierProvider`; síncronos
(sessão, conversa), `NotifierProvider`.

**`.family` com argumento no construtor.** Unidades por disciplina, materiais
por unidade e calendário por mês usam
`AsyncNotifierProvider.family<Ctrl, Estado, Arg>(Ctrl.new)`. Não existe
`FamilyAsyncNotifier` no Riverpod 3, e o tipo de retorno de `.family` não deve
ser anotado. Também é preciso normalizar a chave: `DateTime` compara
instantes, então o dia 1 do mês seria chave diferente de `DateTime.now()` e
recarregaria o provider à toa — daí `chaveMes()`.

**Entidade `MaterialEstudo`, não `Material`.** A entidade de domínio se chama
assim porque `Material` colide com o widget do Flutter: todo arquivo de UI que
importasse ambos não compilaria sem `hide`.

**Identificadores em ASCII.** O scanner do Dart **rejeita** caracteres
acentuados em identificadores (`_Balão` gera `illegal_character`), embora os
aceite em comentários e strings. Todos os identificadores do projeto são
ASCII; acentos ficam na documentação.

**Estado `List<MensagemKai>` no controller do Kai, não `AsyncValue`.** Uma
falha de resposta não pode invalidar o histórico: a mensagem que falhou entra
no lugar, com a mensagem do mapper, e as anteriores continuam legíveis.
Envolver a conversa em `AsyncValue` colocaria tudo sob um único estado de
carregamento.

**Callbacks em `ref` são seguros após `dispose`.** Riverpod 3 torna
inválido o uso de `ref` no `dispose`, mas o `ref` capturado num
`StateNotifier` continua válido para leituras. O `AuthController` depende
disso para o interceptor ajustar o estado depois do logout.

## 4. Funcionalidades

| Feature | Tela | Estado |
|---|---|---|
| Sessão | Splash, login, cadastro, interceptor JWT, logout | Completo |
| Home | Dashboard, estatísticas, atalhos | Completo |
| Matérias | Disciplinas → unidades → materiais | Completo |
| Tarefas | Lista, filtro, conclusão otimista | Completo |
| Agenda | Calendário mensal de 6 semanas, avisos agrupados | Completo |
| Perfil | Dados, edição, papel, saída | Completo |
| Kai | Chat, sugestões, indicador "digitando" | Completo |
| Gamificação | Estatísticas e conquistas na Home | Completo |
| **Kai por voz** | `speech_to_text` com permissão | **Não integrado** |

### Atualização otimista

Concluir tarefa ou material altera a lista na hora e reverte se o servidor
recusar. A resposta do servidor prevalece, porque traz campos que a
estimativa local não tem — `xpConquistado`, por exemplo.

## 5. Verificações executadas

| Verificação | Resultado |
|---|---|
| `flutter analyze lib test` | **0 erros, 0 avisos** (4 infos pré-existentes) |
| `flutter test` | **53 testes, todos passando** |
| `dart run build_runner build` | Sucesso, sem avisos |
| `flutter build apk --debug` | **APK gerado** |
| `flutter build apk --debug -t lib/main_debug.dart` | **APK gerado** |

Os testes cobrem as regras que quebram silenciosamente: comparação de prazo
por dia inteiro (tarefa que vence às 23h não está atrasada às 10h), tarefa
concluída nunca atrasada, `fromWire` tolerante a papéis e tipos de material
desconhecidos, e o `Result` (`when`, `map` preservando falha, `isSuccess` /
`isFailure`).

**Regressão do crash de locale.** A Home formatava a data em pt-BR já no
primeiro sliver, e o `intl` só aceita `DateFormat('EEE', 'pt_BR')` depois de
`initializeDateFormatting` — sem isso, `LocaleDataException` subia pelo `build`
e derrubava a tela inteira, gamificação junto. Hoje `AppDateFormat` tem
`inicializar()` (chamado nos dois entrypoints) e uma guarda que transforma o
`LocaleDataException` anônimo em um `StateError` dizendo o que fazer. A
regressão é coberta em `test/app_date_format_test.dart` e
`test/home_screen_test.dart` — este último é o primeiro teste de widget do
projeto e monta a Home com o container mínimo que ela lê.

## 6. Pendências do backend

O app consome contratos que **não têm controller implementado**. Isso não
bloqueia o uso: cada tela trata a falha e mostra mensagem amigável, sem
travar a navegação.

| # | Endpoint | Consumido por |
|---|---|---|
| 1 | `GET\|POST /api/disciplinas/{id}/unidades` | Matérias |
| 2 | `GET\|POST /api/unidades/{id}/materiais` | Matérias |
| 3 | `PATCH /api/materiais/{id}/concluir` | Matérias |
| 4 | `GET\|POST /api/tarefas`, `PATCH /api/tarefas/{id}/concluir` | Tarefas, Agenda |
| 5 | `GET /api/calendario?inicio=&fim=` | Agenda |
| 6 | `GET /api/avisos` | Agenda |
| 7 | `GET /api/dashboard` | Home |
| 8 | `GET /api/progresso`, `/api/gamificacao/*` | Home, Perfil |
| 9 | `POST /api/ai/chat` | Kai |

Os itens 1 a 3 e 7 a 9 são **contratos propostos** — existem no TCC ou são
consumidos pelo frontend web, mas não há implementação que os confirme. Precisam
de validação antes de virar API real. O status de cada rota está registrado em
`lib/core/config/api_endpoints.dart`.

### Campo novo proposto: `minutesToday`

A Home exibe um anel de progresso da meta diária de estudo ("foguinho"), como
no protótipo web. O anel precisa saber quantos minutos o aluno já acumulou
hoje, e **nenhum contrato existente carrega esse dado**: o `stats` do
`/api/dashboard` traz só `xp`, `level` e `streak`. O texto do protótipo
("Faltam 3 min hoje") era HTML fixo, sem lastro em dado nenhum.

Proposta: `GET /api/dashboard` passa a devolver

```json
{ "stats": { "xp": 1240, "level": 4, "streak": 7, "minutesToday": 7 } }
```

A origem não é invenção: o TCC (2.7) define que a sequência de dias só se
mantém com **pelo menos 10 minutos de uso por dia**, então o backend já tem
como medir isso. O campo está pronto no mobile
(`ResumoGamificacao.minutosHoje`, com default 0), então até o backend enviar
o campo o app funciona — o anel simplesmente mostra a meta zerada, que é o
estado honesto.

A **meta de 10 minutos não vai no contrato**: é regra de produto fixa e mora
em `AppGamificacao.metaMinutosDiarios`, no cliente. Só viraria campo da API se
um dia a meta fosse configurável por turma.

## 7. Divergências e riscos

**Papéis.** Backend usa `ADMIN` / `USUARIO`; o TCC prevê Aluno / Professor.
`PerfilUsuario.fromWire` cai em `usuario` para valores desconhecidos, então um
papel novo não impede o login — mas o app não consegue exibir "Professor"
antes de o backend passar a enviar esse valor.

**Datas sem fuso.** O backend emite `LocalDateTime` sem offset. O app trata
todos os valores como hora local (`toLocal()`), sem conversão. Se o backend
migrar para `Instant`/UTC, essa suposição quebra silenciosamente em prazos e
no calendário.

**Fontes em runtime.** `google_fonts` baixa Nunito e Inter na primeira
execução. Sem rede no primeiro lançamento, a tipografia cai no fallback do
sistema. Recomendação: empacotar os `.ttf` em `assets/fonts/` antes de
publicar.

**`KaiController` bloqueia envios concorrentes.** A caixa de texto e o botão
desabilitam enquanto há resposta pendente. Dois envios simultâneos
misturariam as respostas na ordem de chegada, não na de envio.

**Sem paginação.** Avisor, calendário e listas assumem resposta única. Com
histórico grande, o contrato precisará de `page`/`size` e a UI de *load more*.

## 8. Trabalho restante

1. Integrar o Kai por voz — a dependência e a permissão já estão prontas.
2. Escrever testes de widget e de repositório com `Dio` mockado.
3. Empacotar as fontes em `assets/fonts/`.
4. Adicionar *deep link* e *push notification* (avisos).
5. Validar com o backend os 9 endpoints da seção 6.

Nenhuma alteração foi commitada: o trabalho está no working tree da branch
`feature/mobile`.
