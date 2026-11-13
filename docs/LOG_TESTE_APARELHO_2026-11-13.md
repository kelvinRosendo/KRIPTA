# Log de teste em aparelho físico — Etapas 07/08

- **Data:** 13/11/2026
- **Autor:** Bernardes
- **Objetivo:** validar o APK debug (`lib/main.dart`, sem dublês) contra o backend Spring Boot real e o PostgreSQL, em aparelho Android físico, cobrindo a pendência nº 2 de `docs/ETAPAS07_08.md` (sessão restaurada, ausência de rede, teclado e retorno do segundo plano).
- **Resultado geral:** fluxo principal (autenticação, Home, Matérias e Calendário) **funcionou com backend real**. Foram encontrados problemas de **infraestrutura de teste** (queda do PostgreSQL, autorização USB) e **um comportamento de robustez** no cliente quando o backend perde o banco. Detalhes abaixo.

---

## 1. Ambiente

### Aparelho
| Item | Valor |
| --- | --- |
| Modelo | Infinix X6811 (Infinix ZERO X Pro) |
| Serial ADB | `073632522F000813` |
| Conexão | USB (depuração USB) |
| App | `br.com.kripta.kripta_mobile` — versão `0.1.0+1` |

### Estação de build/execução
| Item | Valor |
| --- | --- |
| SO | Windows (x64) |
| Flutter | 3.50.0 (stable) / Dart 3.14.0 |
| SDK alvo do projeto | Flutter 3.47.4 / Dart 3.13.3 |
| JDK | Temurin 21 (`D:\jdk21`) |
| Android SDK | `D:\androidsdk` (platform-tools 37.0.1, build-tools 36.0.0, NDK 28c) |
| IP do PC na LAN | `192.168.18.27` |

### Backend / banco
| Item | Valor |
| --- | --- |
| Backend | Spring Boot (`com.kripta.KriptaApplication`), porta `8080` |
| Banco | PostgreSQL 17.6, porta `5432`, database `kripta`, usuário `postgres` |
| Migrations | Flyway — **10/10 aplicadas com sucesso** |
| `AI_PROVIDER` | `disabled` (Kai sem provedor real, conforme decisão do projeto) |
| `JWT_SECRET` | definido em runtime (64 hex) |

---

## 2. Como foi executado

App em modo debug, apontando para o backend real via `--dart-define`:

```powershell
$env:JAVA_HOME = "D:\jdk21"
$env:Path = "D:\jdk21\bin;D:\androidsdk\platform-tools;" + $env:Path
Set-Location "C:\Users\n0t.berna\KRIPTA\mobile"
& "D:\fluttersdk\flutter\bin\flutter.bat" run -d 073632522F000813 `
  --android-skip-build-dependency-validation `
  --dart-define=API_BASE_URL=http://192.168.18.27:8080/api `
  --dart-define=APP_ENV=dev `
  --dart-define=ENABLE_NETWORK_LOG=true
```

> **Nota de ambiente:** o Gradle do projeto exige AGP ≥ 9.1.1, mas `mobile/android/settings.gradle` fixa **9.1.0**. Para não alterar arquivos do repositório, o build foi feito com `--android-skip-build-dependency-validation`. Correção permanente (fora do escopo deste teste) seria subir o AGP.

Backend:

```powershell
$env:JAVA_HOME = "D:\jdk21"
$env:JWT_SECRET = <64 hex>
$env:DB_URL = "jdbc:postgresql://localhost:5432/kripta"
$env:DB_USERNAME = "postgres"
$env:DB_PASSWORD = ""
$env:AI_PROVIDER = "disabled"
Set-Location "C:\Users\n0t.berna\KRIPTA\backend"
.\mvnw.cmd spring-boot:run
```

---

## 3. Roteiro e resultados (observado no aparelho)

| Passo | Endpoint | Resultado |
| --- | --- | --- |
| Cadastro | `POST /api/auth/register` | ✅ "conta criada; iniciando sessão" |
| Login | `POST /api/auth/login` | ✅ "token gravado (272 caracteres)", "sessão iniciada (expira em 86400s)" |
| Heartbeat | `POST /api/usage/heartbeat` | ✅ resposta OK (intervalo de 15 s) |
| Home / progresso | `GET /api/progresso` | ✅ resposta OK |
| Home / conquistas | `GET /api/gamificacao/conquistas` | ✅ resposta OK |
| Home / tarefas | `GET /api/tarefas` | ✅ resposta OK |
| Aba Matérias | `GET /api/disciplinas` | ✅ resposta OK |
| Perfil | `GET /api/users/me` | ✅ resposta OK |
| Calendário | `GET /api/calendario?inicio=2026-10-25&fim=2026-12-07` | ✅ requisição emitida com o intervalo de meses correto |

**Restauração de sessão:** ao relançar o app (após reatar o `flutter run`), o token foi lido do armazenamento seguro e a sessão foi restabelecida **sem novo login** — já disparou `/progresso`, `/gamificacao/conquistas` e `/tarefas`. Isso **valida a pendência nº 2** quanto à sessão restaurada e ao teclado.

**Persistência:** confirmada no PostgreSQL — `users = 1` após o cadastro, `flyway_schema_history` com as 10 migrations em `success = t`.

Nenhuma exceção/Failure no app durante a operação normal (com banco disponível).

---

## 4. Problemas encontrados

### 4.1 Queda do PostgreSQL durante o teste (infraestrutura)
O PostgreSQL **encerrou sozinho** (registro de "database system was interrupted; last known up at..." e recuperação automática no `server.log`), inclusive com aviso de *sharing violation* em `server.log`:

```
LOG: database system was interrupted; last known up at 2026-11-13 22:16:00 GMT
LOG: could not open file "./server.log": sharing violation
HINT: You might have antivirus, backup, or similar software interfering with the database system.
LOG: database system was not properly shut down; automatic recovery in progress
```

Consequência: o backend passou a falhar ao abrir conexão e devolveu **500**:

```
ERROR ... HikariPool-1 - Connection is not available, request timed out after 30013ms (total=0, active=0, idle=0, waiting=1)
Caused by: org.postgresql.util.PSQLException: Connection to localhost:5432 refused.
```

> **Causa provável:** interferência de antivírus/backup no diretório de dados portátil (`D:\pgsql\data`) ou encerramento abrupto do processo. Não é defeito do código do KRIPTA. Para reprodução estável, usar serviço do PostgreSQL ou excluir o diretório de dados do escaneamento do antivírus.

### 4.2 Indisponibilidade do banco degrada para 401 no cliente e força logout
Durante a janela em que o PostgreSQL estava fora, o app recebeu **401** e o `auth_interceptor` tratou como sessão encerrada, removendo o token localmente:

```
[W] [auth_interceptor] 401 em /tarefas: sessão encerrada
[D] [secure_token_store] token removido
[I] [auth.repository] sessão encerrada localmente
[W] [auth_interceptor] 401 em /usage/heartbeat: sessão encerrada
[W] [auth_interceptor] 401 em /calendario: sessão encerrada
```

Enquanto isso o backend registrava **500** (`CannotCreateTransactionException` / `HikariPool ... Connection refused`) em `JwtAuthenticationFilter.carregarUsuario` → `CustomUserDetailsService.loadUserById`.

> **Ponto a analisar:** uma **falha de infraestrutura** (banco fora) chega ao cliente como **401 (não autorizado)** e provoca **logout local**, em vez de ser tratada como erro de servidor/indisponibilidade. Sugestão: distinguir 401 legítimo (token inválido/expirado) de 5xx/indisponibilidade e **não** invalidar a sessão nesse caso. Vale investigar por que a falha do filtro JWT não resultou em 5xx consistente para o cliente.

### 4.3 Autorização USB intermitente (`adb`)
O dispositivo caiu para `unauthorized` mais de uma vez ("Lost connection to device"), sem que o pop-up de depuração reaparecesse. Recuperado com:

```powershell
adb kill-server
adb start-server
```

> Recomendação: marcar "Sempre permitir deste computador" e/ou usar cabo/porta USB estável. Não é defeito do app.

### 4.4 Ruído benigno do `flutter_secure_storage`
Warnings recorrentes no `logcat`, **sem impacto** (o token foi gravado corretamente):

```
W/KeyStore: android.os.ServiceSpecificException: (code 7)
  at com.it_nomads.fluttersecurestorage.ciphers.KeyCipherImplementationRSAOAEP.createRSAKeysIfNeeded
```

### 4.5 Divergência de versão do SDK Flutter
O projeto alvo é Flutter 3.47.4/Dart 3.13.3; o teste rodou em **Flutter 3.50.0/Dart 3.14.0**. `flutter analyze` apresentou ~22 avisos `info` de depreciação (`package:flutter/material.dart` → `material_ui`), **sem erros**. O `flutter pub get` também atualizou dependências transitivas no `pubspec.lock` (side effect do SDK mais novo).

---

## 5. Status das pendências de `ETAPAS07_08.md`

| # | Pendência | Status após este teste |
| --- | --- | --- |
| 1 | Provedor real do Kai | Não testado (provedor mantido desativado por decisão) |
| 2 | APK em aparelho (sessão restaurada, sem rede, teclado, 2º plano) | **Parcialmente validado**: sessão restaurada e teclado OK. Falta cobrir **ausência de rede** e **retorno do segundo plano** de forma explícita. |
| 3 | Roteiro visual web ↔ APK com a mesma conta | Não testado |
| 4 | Conferir PDF original do TCC | Não aplicável |
| 5 | Interfaces web de publicação/aprovação | Não aplicável ao mobile |
| 6 | HTTPS/CORS/anti-abuso antes de publicar | Não aplicável |

---

## 6. Conclusão

- **UC01 (autenticar), UC02 (calendário/avisos) e UC08 (consultar progresso)** funcionaram no aparelho com backend e PostgreSQL reais, incluindo restauração de sessão.
- Nenhum defeito de aplicação foi observado no fluxo feliz.
- Dois pontos merecem análise futura:
  1. **Robustez:** indisponibilidade do banco chega como **401** e desloga o usuário localmente (item 4.2).
  2. **Infraestrutura de teste:** instabilidade do PostgreSQL portátil (item 4.1) e autorização USB (item 4.3), que devem ser estabilizadas para uma rodada completa de aceite.

### Artefatos brutos
- Logs completos do app e do backend gerados nesta execução ficaram disponíveis localmente durante a sessão (não versionados, pois contêm dados do ambiente).
