# KRIPTA — Roadmap Solo de Finalização Definitiva

> **Atualizado em:** 03/11/2026  
> **Fonte principal de escopo:** `KRIPTA.pdf`  
> **Repositório:** https://github.com/kelvinRosendo/KRIPTA  
> **Objetivo:** integrar e finalizar o software existente, deixando uma versão demonstrável, persistente e testada, que depois precise apenas de ajustes e melhorias.

## 1. Regras deste roadmap

1. **Não recomeçar do zero.** Reaproveitar backend Java, frontend web e mobile Flutter existentes.
2. **O `KRIPTA.pdf` prevalece sobre os roadmaps antigos.** O escopo funcional segue os 12 requisitos funcionais (RF01–RF12), as nove regras de negócio (RN01–RN09) e os oito casos de uso (UC01–UC08).
3. **Concluir um fluxo vertical de cada vez:** banco de dados → API → interface → teste → commit.
4. **Não confundir tela funcionando em mock com funcionalidade concluída.** A aprovação exige API e autorização reais; a gamificação exige dados persistidos e regras no backend.
5. **Proteger a branch `main`.** Integrar em branch de trabalho, testar e só então propor merge.
6. **Não adicionar recursos fora do MVP antes dos obrigatórios.** Voz do Kai, relatórios automáticos, alertas de IA e personalização avançada ficam para depois, conforme UC04.

## 2. Estado inicial confirmado no GitHub

| Área | Branch / evidência | Situação |
| --- | --- | --- |
| Backend | `feature/backend-users` | Spring Boot, autenticação JWT, usuários, disciplinas, Flyway e testes existentes |
| Frontend web | `feature---frontend` | Telas e serviços para autenticação, matérias, tarefas, conteúdo, calendário, gamificação e Kai; utiliza mocks no modo de desenvolvimento |
| Mobile | `feature/mobile` | Projeto Flutter, telas, repositórios, DTOs e testes; várias APIs ainda dependem de implementação |
| `main` | Branch principal | Backend nela possui arquivos fundamentais vazios; não representa o estágio real do projeto |
| Integração | Branches separadas | Nenhum pull request encontrado na consulta de 03/11/2026 |

**Problemas já identificados:**

- Frontend usa `/api/subjects` enquanto o backend usa `/api/disciplinas`.
- Frontend usa campos como `name` e `color`, enquanto o backend usa `nome` e `cor`.
- Backend usa perfis `ADMIN`/`USUARIO`; o TCC prevê `Aluno`/`Professor` e autorização específica para aprovação.
- Cadastro do aluno deve exigir **RM** (RN01).
- `frontend/services/config.js` contém `DEV_MODE: true` na configuração de desenvolvimento.
- Endpoints de conteúdo, tarefas, calendário, notificações, gamificação e Kai não estão integralmente implementados no backend analisado.
- O cadastro real do backend retorna resposta de registro, mas não autentica automaticamente; o frontend deve encaminhar ao login após cadastrar, ou a API deve ter contrato alterado de forma explícita.

## 3. Sequência de execução

```text
01. Consolidar repositório
      ↓
02. Banco + autenticação + contratos
      ↓
03. Organização acadêmica + professores + aprovação + tarefas
      ↓
04. Calendário + notificações
      ↓
05. Gamificação (streak, XP, níveis, insígnias)
      ↓
06. Kai com IA real
      ↓
07. Integração Flutter
      ↓
08. Testes, segurança, documentação técnica e entrega
```

---

## ETAPA 01 — Consolidar o repositório

**Objetivo:** reunir a versão mais avançada do backend, do frontend e do mobile no mesmo ponto de desenvolvimento sem prejudicar branches originais.

### Passos

No diretório de trabalho desejado:

```bash
git clone https://github.com/kelvinRosendo/KRIPTA.git
cd KRIPTA
git fetch --all --prune

git switch feature/backend-users
git switch -c integration/kripta-final

git restore --source=feature---frontend -- frontend
git restore --source=feature/mobile -- mobile

git add frontend mobile
git commit -m "chore: consolidate web and mobile clients"
```

> **Atenção:** execute isso em clone limpo. Se estiver trabalhando em um clone existente, faça `git status` e preserve alterações não commitadas. A importação por `git restore` copia o estado das pastas e **não preserva o histórico independente** das branches importadas; os originais permanecem nas respectivas branches.

### Estrutura desejada

```text
KRIPTA/
├── backend/
│   ├── pom.xml
│   ├── mvnw
│   └── src/
├── frontend/
│   ├── index.html
│   ├── package.json
│   └── services/
├── mobile/
│   ├── pubspec.yaml
│   └── lib/
└── README.md
```

### Checklist

- [ ] Fazer backup/confirmar `git status` limpo.
- [ ] Criar `integration/kripta-final` a partir de `feature/backend-users`.
- [ ] Importar `frontend/` de `feature---frontend`.
- [ ] Importar `mobile/` de `feature/mobile`.
- [ ] Conferir dependências e arquivos de configuração.
- [ ] Rodar os testes existentes e registrar eventuais falhas.

**Teste inicial backend (Windows/PowerShell):**

```powershell
cd backend
.\mvnw.cmd test
```

**Critério para avançar:** código unificado em uma branch e estado inicial de compilação/testes documentado.

---

## ETAPA 02 — Banco, autenticação e contratos

**Objetivo:** cadastro/login reais, sessão JWT, perfis corretos e disciplinas persistidas no PostgreSQL.

### Trabalho a realizar

1. Usar **JDK 21** e **PostgreSQL 16+**, conforme o `backend/README.md` existente.
2. Configurar variáveis do `backend/.env.example`, especialmente banco e `JWT_SECRET`; **não versionar segredos**.
3. Criar banco vazio `kripta` e deixar o **Flyway** executar as migrations.
4. Testar `GET /api/health`, `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/users/me` e CRUD de disciplinas.
5. Definir **um contrato de API** para web/mobile/backend (rotas, parâmetros, corpo, resposta, erros e papéis).
6. Padronizar diferenças entre `/subjects` e `/disciplinas`, `name` e `nome`, etc. A recomendação é aproveitar a API Java e adaptar consumidores, usando mapeadores onde for necessário.
7. Migrar o modelo de usuários para contemplar `ALUNO` e `PROFESSOR`; adicionar **RM obrigatório para alunos** via migration e validação.
8. Definir mecanismo **seguro e administrado pelo servidor** para autorizar professores a aprovar conteúdo. Não confiar em `authorized: true` enviado pelo cliente.
9. Resolver fluxo de cadastro da web: o backend registra sem token; a interface deve direcionar para login ou ambos devem adotar um novo contrato formal.
10. Verificar CORS, logout, tratamento de token expirado, acesso negado e erros de validação.

### Arquivos-base

- `backend/src/main/java/com/kripta/model/User.java`
- `backend/src/main/java/com/kripta/dto/RegisterRequest.java`
- `backend/src/main/java/com/kripta/config/SecurityConfig.java`
- `backend/src/main/java/com/kripta/controller/AuthController.java`
- `backend/src/main/java/com/kripta/controller/UserController.java`
- `frontend/services/auth.js`
- `frontend/services/subjects.js`
- `frontend/services/api.js`
- `frontend/services/config.js`

### Checklist

- [ ] PostgreSQL funcionando, Flyway aplicando migrations.
- [ ] Cadastro com RM e perfil validado.
- [ ] Login real e JWT válido.
- [ ] Autorização de aprovação controlada no backend.
- [ ] Contratos de disciplinas e usuários compatíveis com a web.
- [ ] Sessão expirada/sem token tratada corretamente.
- [ ] Dados persistem após reiniciar a aplicação.

**Critério para avançar:** cadastrar aluno, entrar, criar disciplina, reiniciar o backend e confirmar que os dados continuam lá; outro aluno não pode acessá-los.

---

## ETAPA 03 — Núcleo acadêmico completo

**Objetivo:** professor publica conteúdo, professor autorizado aprova, aluno consulta o que foi aprovado e gerencia atividades/tarefas.

### Modelagem sugerida

Aproveitar `User` e `Disciplina` existentes, mas avaliar a diferença entre disciplinas pessoais e componentes curriculares acadêmicos compartilhados.

| Entidade sugerida | Responsabilidade |
| --- | --- |
| `ComponenteCurricular` | Matéria/disciplina acadêmica à qual o conteúdo pertence |
| `ConteudoAcademico` | Conteúdo criado pelo professor, autor, componente e status |
| `Unidade` | Agrupamento de materiais, caso necessário ao fluxo já desenhado |
| `MaterialEstudo` | Material vinculado a uma unidade |
| `Atividade` | Tarefa/demanda acadêmica, prazo, descrição, responsável e estado |
| `RegistroConclusao` | Conclusão ou envio válido de atividade por aluno |

> Os nomes acima são uma **proposta de implementação**, não classes obrigatoriamente nomeadas assim no PDF.

### Fluxo de publicação obrigatório

```text
Professor autenticado
   ↓ cadastra conteúdo ligado a componente curricular
AGUARDANDO_APROVACAO
   ↓ análise por professor responsável autorizado
   ├── APROVADO → aluno pode consultar
   └── REJEITADO → aluno não pode consultar
```

O servidor deve impedir que usuários não autorizados aprovem e que alunos obtenham conteúdo pendente/rejeitado, inclusive por URL direta.

### Contratos-alvo propostos

```http
GET    /api/disciplinas
POST   /api/disciplinas
GET    /api/disciplinas/{id}/unidades
POST   /api/disciplinas/{id}/unidades
GET    /api/unidades/{id}/materiais
POST   /api/unidades/{id}/materiais
GET    /api/conteudos
POST   /api/conteudos
GET    /api/conteudos/pendentes
PATCH  /api/conteudos/{id}/aprovar
PATCH  /api/conteudos/{id}/rejeitar
GET    /api/tarefas
POST   /api/tarefas
PUT    /api/tarefas/{id}
DELETE /api/tarefas/{id}
PATCH  /api/tarefas/{id}/concluir
```

Essas rotas são **propostas**, não uma lista de funcionalidades já implementadas. Formalize os DTOs e alinhe as chamadas do frontend e mobile antes de codificar.

### Checklist

- [ ] Formalizar componente curricular e vínculos dos alunos/professores.
- [ ] Implementar migrations, entidades, repositórios, serviços e controladores de conteúdos.
- [ ] Implementar status inicial `AGUARDANDO_APROVACAO`.
- [ ] Implementar aprovação/rejeição com autorização real.
- [ ] Listar somente conteúdos aprovados para o aluno.
- [ ] Implementar unidades/materiais necessários às interfaces.
- [ ] Implementar CRUD e conclusão/envio de atividades/tarefas.
- [ ] Integrar `frontend/services/content.js`, `tasks.js`, `subjects.js`, `units.js` e `materials.js`.
- [ ] Criar testes de autorização, validação e persistência.

**Critério para avançar:** professor registra conteúdo; aprovador autorizado aprova; aluno visualiza; conteúdo pendente/rejeitado permanece indisponível. Aluno também consegue criar/acompanhar/concluir atividades conforme o escopo definido.

---

## ETAPA 04 — Calendário e notificações

**Objetivo:** calendário pessoal e escolar persistentes com notificações relacionadas aos eventos (RF06, RF07, RN05).

### Trabalho a realizar

1. Criar entidade `EventoCalendario` com título, descrição, data/hora, categoria pessoal/escolar e relações de acesso.
2. Implementar consultas por intervalo de datas e tratamento consistente de timezone.
3. Implementar criação/alteração/exclusão de eventos pessoais autorizados.
4. Criar notificações **vinculadas a eventos**; uma central de notificações interna atende ao requisito inicial, sem exigir push.
5. Integrar `frontend/services/calendar.js`, `notifications.js` e `announcements.js`.

### Contratos-alvo propostos

```http
GET    /api/calendario?inicio=2026-11-01&fim=2026-11-30
POST   /api/calendario/eventos
PUT    /api/calendario/eventos/{id}
DELETE /api/calendario/eventos/{id}
GET    /api/notificacoes
PATCH  /api/notificacoes/{id}/ler
```

### Checklist

- [ ] Persistir eventos pessoais e escolares.
- [ ] Consultar intervalos de calendário corretamente.
- [ ] Controlar acesso e visibilidade por usuário.
- [ ] Vincular notificações aos eventos.
- [ ] Conectar visualizações de dia, semana e mês à API real.
- [ ] Testar eventos sem registros, datas e sessão expirada.

**Critério para avançar:** aluno cria evento, vê evento e aviso associado, reinicia sessão e continua visualizando os dados; outro aluno não acessa seus eventos privados.

---

## ETAPA 05 — Gamificação funcional

**Objetivo:** streak, XP, níveis, conquistas e insígnias calculados e persistidos no backend (RF09–RF12, RN07–RN09).

### Estruturas sugeridas

| Estrutura | Responsabilidade |
| --- | --- |
| `ProgressoAluno` | XP total, nível e sequência |
| `UsoDiario` | Tempo de uso autenticado no dia |
| `HistoricoXP` | Registro de evento que concedeu pontos |
| `Conquista` | Tipo e critérios de conquista |
| `ConquistaAluno` | Insígnias desbloqueadas por usuário |

### Regras inegociáveis

- **Streak:** avançar no máximo uma vez ao dia após pelo menos **600 segundos** de utilização autenticada. Controlar o tempo no servidor e não confiar cegamente nos valores enviados pelo cliente.
- **XP:** uma mesma atividade não gera XP duas vezes para o mesmo aluno. Usar transações e restrição de unicidade para evitar duplicações concorrentes.
- **Conquistas:** critérios definidos e desbloqueios armazenados persistentemente.
- **Perfil:** mostrar os valores atuais vindos do banco, sem números fixos.

### Contratos-alvo

```http
POST /api/usage/heartbeat
GET  /api/progresso
GET  /api/gamificacao/estatisticas
GET  /api/gamificacao/conquistas
```

### Checklist

- [ ] Modelar e migrar tabelas de progresso e conquistas.
- [ ] Implementar registro seguro de tempo autenticado.
- [ ] Garantir um avanço diário no streak.
- [ ] Atribuir XP por conclusão/envio válido, sem duplicidade.
- [ ] Calcular níveis e registrar conquistas.
- [ ] Integrar `frontend/services/streak.js` e `gamification.js`.
- [ ] Testar repetição, concorrência e virada de dia.

**Critério para avançar:** concluir uma atividade dá XP uma vez; repetir não dá; dez minutos de uso avançam o streak uma única vez; todos os dados permanecem após novo login.

---

## ETAPA 06 — Kai com IA real

**Objetivo:** usuário autenticado envia mensagem e recebe resposta de um serviço real de IA (RF08, RN06, UC04).

### Trabalho a realizar

1. Criar endpoint `POST /api/ai/chat` protegido por JWT.
2. Criar `AiController`, serviço do Kai e cliente do provedor escolhido.
3. Configurar chave do provedor **somente no backend**, por variável de ambiente.
4. Aplicar validação de entrada, limite de tamanho/uso e timeout.
5. Tratar indisponibilidade da IA sem expor stack trace ou segredos.
6. Integrar `frontend/services/kai.js`.

Fluxo:

```text
Usuário → Frontend/Mobile → API Spring Boot → Provedor de IA
                                        ← resposta ←
```

**Fora do MVP obrigatório:** voz, relatórios automáticos, alertas inteligentes e personalização avançada, conforme UC04 do PDF.

### Checklist

- [ ] Escolher provedor e formalizar custos/limites.
- [ ] Implementar endpoint protegido.
- [ ] Integrar provedor real com segredo no backend.
- [ ] Tratar erros, timeout e respostas vazias.
- [ ] Integrar chat web com a API.
- [ ] Testar usuário autenticado, anônimo e provedor indisponível.

**Critério para avançar:** pergunta enviada no navegador obtém resposta real; acesso sem token falha; erro da IA é mostrado de forma controlada.

---

## ETAPA 07 — Finalizar integração Flutter

**Objetivo:** web e mobile compartilham o mesmo backend, contas, dados e regras.

### Arquivos principais

- `mobile/lib/core/config/api_endpoints.dart`
- `mobile/lib/core/config/app_config.dart`
- `mobile/lib/data/repositories/`
- `mobile/lib/features/`

### Trabalho a realizar

1. Alinhar rotas e DTOs do Flutter com o contrato definitivo da API.
2. Verificar login, logout, persistência de sessão e expiração JWT.
3. Integrar matérias, conteúdos, tarefas, calendário, notificações, gamificação e Kai.
4. Eliminar dependência de repositórios falsos no modo final.
5. Validar estados de carregamento, vazio, sem conexão e erro.

### Comandos

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Para emulador Android padrão:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
```

> Em dispositivo físico, usar endereço do servidor acessível pela rede; `10.0.2.2` é específico do emulador Android padrão.

### Checklist

- [ ] Alinhar endpoints e campos dos DTOs.
- [ ] Testar autenticação real.
- [ ] Testar matérias, conteúdos, tarefas e calendário.
- [ ] Testar perfil, XP, streak, conquistas e Kai.
- [ ] Executar análise estática e testes Flutter.
- [ ] Gerar APK de debug e testar em dispositivo/emulador.
- [ ] Testar sincronização web ↔ mobile.

**Critério para avançar:** criar tarefa no navegador, visualizar no Flutter, concluir no Flutter e observar atualização no navegador com a mesma conta.

---

## ETAPA 08 — Testes, segurança e entrega

**Objetivo:** projeto reproduzível, sem mock no modo final, testado contra os oito casos de uso.

### Matriz de aceitação do TCC

| Caso de uso | Teste obrigatório |
| --- | --- |
| UC01 — Autenticar usuário | Login válido, inválido, expiração de sessão e acesso restrito |
| UC02 — Calendário e notificações | Eventos e avisos reais vinculados e persistidos |
| UC03 — Consultar conteúdos | Aluno visualiza apenas conteúdos aprovados |
| UC04 — Interagir com IA | Resposta real e tratamento de indisponibilidade |
| UC05 — Cadastrar conteúdo | Professor cria conteúdo com status pendente |
| UC06 — Aprovar conteúdo | Somente professor autorizado aprova/rejeita |
| UC07 — Registrar progresso | Streak e XP aplicam regras sem duplicação |
| UC08 — Consultar progresso | XP, nível e insígnias persistidos e exibidos |

### Qualidade adicional

- [ ] Desabilitar `DEV_MODE` e bypass de demonstração no ambiente de entrega.
- [ ] Executar `mvnw test` no backend.
- [ ] Executar `flutter analyze` e `flutter test` no mobile.
- [ ] Testar acessos a dados de outro usuário (proteção contra IDOR).
- [ ] Testar entradas inválidas, erros HTTP e ausência de rede.
- [ ] Verificar responsividade, navegação por teclado e acessibilidade básica.
- [ ] Criar workflow GitHub Actions para testes automatizados.
- [ ] Documentar instalação, variáveis, migrações e execução de cada aplicação.
- [ ] Opcionalmente adicionar `docker-compose.yml` para ambiente reproduzível com PostgreSQL.
- [ ] Preparar contas/dados de demonstração seguros, sem hardcode de segredo.
- [ ] Abrir pull request da integração e fazer merge na `main` somente após validação.

**Critério de conclusão:** todos os oito casos de uso executáveis sem mocks, regressões críticas resolvidas e instruções suficientes para outra pessoa iniciar o projeto.

---

## 4. Rotina de trabalho solo

Para **cada tarefa**, siga este ciclo:

1. Escolha uma única pendência.
2. Implemente a persistência e a regra de negócio no backend.
3. Exponha/ajuste a API e documente seu contrato.
4. Conecte a interface web existente.
5. Execute teste automatizado e um fluxo manual real.
6. Faça commit pequeno com descrição objetiva.
7. Prossiga somente após o fluxo funcionar sem mock.

Exemplo:

```bash
git add .
git commit -m "feat: add academic content approval"
```

Não misture mudanças grandes de frontend, backend e mobile em um único commit quando elas puderem ser revisadas separadamente.

## 5. O que não fazer agora

- [ ] **Não** migrar o frontend para React/Next.js sem necessidade real.
- [ ] **Não** trocar Spring Boot por outra stack.
- [ ] **Não** trocar PostgreSQL por outro banco sem motivo validado.
- [ ] **Não** reconstruir as interfaces web e Flutter já existentes.
- [ ] **Não** priorizar voz, relatórios e recursos extras de IA antes do chat obrigatório.
- [ ] **Não** aprovar conteúdo apenas pela interface; a autorização precisa existir no backend.
- [ ] **Não** considerar dados de demonstração como prova de persistência.
- [ ] **Não** fazer merge direto em `main` sem testar a integração.

## 6. Critério para declarar o KRIPTA pronto

- [ ] RF01–RF12 implementados e validados.
- [ ] RN01–RN09 impostas pelo servidor onde aplicável.
- [ ] UC01–UC08 testados ponta a ponta.
- [ ] Frontend web e Flutter compartilham a mesma API e base de dados.
- [ ] Conteúdos dependem de aprovação autorizada.
- [ ] Kai responde por um serviço real de IA.
- [ ] Streak, XP, nível e insígnias persistem sem duplicação indevida.
- [ ] Sem bugs críticos conhecidos impedindo a demonstração.
- [ ] Repositório possui instruções de configuração e execução.
- [ ] Branch integrada foi revisada e pode ser incorporada à `main`.

## 7. Próxima ação objetiva

**Comece pela Etapa 01.** Crie `integration/kripta-final`, incorpore frontend e mobile, rode os testes existentes e registre o estado inicial. Depois corrija a integração da autenticação e os contratos de API antes de desenvolver novos módulos.

**Sequência definitiva:** integração → autenticação → conteúdo/tarefas → calendário/notificações → gamificação → Kai → Flutter → testes e entrega.

---

*Este documento é um plano de execução baseado no KRIPTA.pdf e nas branches consultadas em 03/11/2026. Não significa que as alterações já foram aplicadas ao repositório.*
