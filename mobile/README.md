# KRIPTA Mobile

Aplicativo Flutter do **KRIPTA** — plataforma de gestão acadêmica e agentic
AI. Este é o cliente Android/iOS do sistema, consumindo a API Spring Boot do
backend.

## Requisitos

| Ferramenta | Versão usada |
|---|---|
| Flutter | 3.47.2 |
| Dart | 3.13.2 |
| Java (Android) | 17 |

## Como rodar

```bash
flutter pub get
dart run build_runner build
flutter run
```

### Apontando para uma API

A URL base vem de `--dart-define`, com padrão para o emulador Android:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
```

O emulador **não** enxerga o `localhost` da máquina host — use `10.0.2.2`
(AVD padrão) ou o IP da máquina na rede local para testar em aparelho físico.

## Modo de desenvolvimento sem backend

Enquanto o backend não implementa os endpoints, dá para rodar o aplicativo
inteiro com dados locais:

```bash
flutter run -t lib/main_debug.dart
```

O app abre direto na Home, sem login. Três cenários, escolhidos por
`--dart-define`:

| Comando | O que ver |
|---|---|
| `flutter run -t lib/main_debug.dart` | Listas preenchidas, com mutações funcionando |
| `flutter run -t lib/main_debug.dart --dart-define=CE_NARIO=vazio` | Estados `VazioView` |
| `flutter run -t lib/main_debug.dart --dart-define=CE_NARIO=erro` | Estados `ErroView` e "Tentar novamente" |

Para gerar o APK:

```bash
flutter build apk --debug -t lib/main_debug.dart
```

### Como funciona

Burlar o token não seria suficiente: `AuthController.restaurarSessao` chama
`GET /users/me`, e sem resposta o usuário volta para o login. O que o modo
debug faz é **substituir os repositories por dublês em memória**
(`lib/dev/`), de modo que controllers, telas, navegação e gamificação são
exercitados de verdade — só a rede some.

Alguns detalhes que não são óbvios:

- O estado é **único e mutável**: concluir uma tarefa na aba Tarefas também
  reduz o contador da Home, porque ambos leem a mesma lista.
- As respostas têm **300 ms de atraso** (900 ms no Kai). Sem isso o
  carregamento resolveria antes do primeiro `build` e os estados de
  carregamento nunca seriam pintados.
- As datas do seed são relativas a hoje, então o calendário já abre no mês
  certo e a Home mostra tarefas vencidas, de hoje e de amanhã.
- No cenário `erro` a **autenticação continua funcionando** de propósito: se
  `usuarioAtual` falhasse, o `go_router` mandaria para o login e nunca
  chegaríamos às telas que o cenário quer exercitar.
- Sair da conta funciona de verdade, e o login seguinte aceita qualquer
  credencial.

Só `main_debug.dart` importa `lib/dev/`, então o alvo padrão não inclui
nenhum dublê no APK. Isso **não** é coberto por teste automático: um teste
unitário não enxerga o que o tree shaking do compilador eliminou. A
conferência é manual, comparando o `kernel_blob.bin` dos dois builds:

```sh
flutter build apk --debug
# o blob não pode conter nenhuma string do seed
flutter build apk --debug -t lib/main_debug.dart
# agora "Ana Souza" e "Leitor compulsivo" aparecem
```

Marcadores do seed para procurar no binário padrão: `Ana Souza`,
`Leitor compulsivo`, `BancoFalso`, `modo de desenvolvimento`.

## Geração de código

Os DTOs usam `json_serializable`. Depois de alterar qualquer arquivo em
`lib/data/dto/`, regenere os `*.g.dart`:

```bash
dart run build_runner build
```

> A opção `--delete-conflicting-outputs` foi **removida** no build_runner atual;
> usá-la faz o comando falhar.

## Testes e análise estática

```bash
flutter test
flutter analyze lib test
flutter build apk --debug
flutter build apk --debug -t lib/main_debug.dart
```

## Arquitetura

Camadas, na ordem de dependência (nenhuma aponta para cima):

```
lib/
├── core/            # infra-estrutura: config, rede, erros, tema, DI, router
├── domain/          # entidades e contratos (não conhece Flutter nem HTTP)
├── data/            # DTOs, mapeadores e implementações dos contratos
├── features/        # uma pasta por feature, em application/ + presentation/
├── dev/             # dublês de repository; só importado por main_debug.dart
├── app.dart         # bootstrap compartilhado entre main.dart e main_debug.dart
├── main.dart        # produção: API real
└── main_debug.dart  # desenvolvimento: repositories em memória
```

Regras que o projeto respeita:

- **Nenhuma `DioException`, `JsonException` ou `Exception` crua atravessa um
  repositório.** Tudo vira `Failure`, que é agnóstico de rede e comparável.
- **A UI só conhece `Failure` e `Result`**, nunca `Dio` ou JSON.
- **O mobile nunca chama OpenAI/Gemini diretamente.** A chave, os limites de uso
  e o filtro de conteúdo ficam no backend; o app só conversa com
  `POST /api/ai/chat`.

### Estado (Riverpod 3)

- `AsyncNotifierProvider` para telas assíncronas, `NotifierProvider` para estado
  síncrono (sessão, conversa do Kai).
- `AsyncNotifierProvider.family<Notificador, Estado, Argumento>(Notificador.new)`
  quando cada item carrega dados próprios (unidades por disciplina, materiais
  por unidade, calendário por mês). O argumento chega pelo **construtor** do
  notifier — não existe uma classe `FamilyAsyncNotifier` no Riverpod 3.
- `ref.watch(...).value` é anulável (`valueOrNull` foi removido no 3.x).

## Autenticação

| Fluxo | Comportamento |
|---|---|
| `POST /api/auth/register` | Retorna **201** com o usuário, **sem token**. |
| Login pós-cadastro | O repositório chama `/auth/login` em seguida e guarda o token. |
| Persistência | JWT em `flutter_secure_storage` (Keychain / EncryptedSharedPreferences). |
| `401` | `AuthInterceptor` dispara `encerrarSessao()` e o router volta ao login. |
| Logout | Remove o token local; **não** há logout no backend (JWT é stateless). |

## Telas

| Aba | Telas |
|---|---|
| Início | Dashboard, estatísticas de gamificação, atalho para o Kai |
| Matérias | Disciplinas → Unidades → Materiais |
| Tarefas | Lista com filtro (todas / abertas / concluídas) |
| Agenda | Calendário mensal e Avisos |
| Perfil | Dados da conta, saída, e acesso ao Kai |

## Permissões

- **Android**: `INTERNET` (necessária em release) e `RECORD_AUDIO` para o Kai por
  voz, com `<queries>` para o reconhecedor do sistema no Android 11+.
- **iOS**: `NSMicrophoneUsageDescription`. Sem essa chave o app crasha ao pedir
  a permissão.

O microfone é opcional: quem não quiser usar a voz digita normalmente.

## Estado atual da integração

| Grupo | Status |
|---|---|
| Saúde, autenticação, usuários, disciplinas | **Implementado no backend** |
| Unidades, materiais, tarefas, calendário, avisos | Contrato definido, **sem controller** |
| Gamificação, dashboard | Contrato definido, **sem controller** |
| Kai (`/api/ai/chat`) | Consumido pelo frontend web, **sem controller** |

As telas que dependem dos endpoints ausentes já abrem normalmente e mostram
uma mensagem amigável quando a requisição falha — a navegação nunca fica
travada. O detalhamento por endpoint está em
[`lib/core/config/api_endpoints.dart`](lib/core/config/api_endpoints.dart).

## O que falta do lado do backend

Os itens abaixo são contratos que o TCC prevê e o app consome, mas que ainda
não têm controller. **Nenhum endpoint foi inventado sem registro**: os
propostos estão marcados como tal.

1. `GET|POST /api/disciplinas/{id}/unidades`
2. `GET|POST /api/unidades/{id}/materiais`
3. `PATCH /api/materiais/{id}/concluir`
4. `GET|POST /api/tarefas` e `PATCH /api/tarefas/{id}/concluir`
5. `GET /api/calendario?inicio=&fim=`
6. `GET /api/avisos`
7. `GET /api/dashboard`
8. `GET /api/progresso`, `/api/gamificacao/*`
9. `POST /api/ai/chat`

## Divergências conhecidas

- **Papéis**: o backend usa `ADMIN` / `USUARIO`; o TCC prevê Aluno / Professor.
  O `PerfilUsuario.fromWire` cai em `usuario` para qualquer valor novo, então
  um papel novo não quebra o login.
- **Datas**: o backend emite `LocalDateTime` sem fuso. O app trata todos os
  valores como hora **local** (`toLocal()`), sem conversão de fuso.

## Fontes

`google_fonts` baixa Nunito e Inter em runtime. Em produção, prefira
empacotar os `.ttf` em `assets/fonts/` e definir `fontFamily` direto no
`AppTheme` — hoje o app depende de rede no primeiro lançamento.
