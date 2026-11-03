# Executar a versão integrada

## Backend e banco

Instale JDK 21 e PostgreSQL 16+. Crie uma base vazia `kripta` com um usuário de desenvolvimento. No terminal que inicia o backend, configure `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` e `JWT_SECRET` seguindo `backend/.env.example`. O exemplo não contém segredos; não publique valores reais.

No PowerShell, variáveis são definidas com `$env:NOME='valor'`. O Spring lê as variáveis do processo; copiar `.env.example` para `.env` sozinho não as carrega.

Dentro de `backend`, execute `./mvnw.cmd spring-boot:run`. As migrations Flyway são automáticas. `http://localhost:8080/api/health` deve responder. Mantenha `AI_PROVIDER=disabled` até haver um adaptador real configurado no servidor.

## Web

Dentro de `frontend`, execute `npm ci`, `npm run build` e `npm run serve`. Abra `http://localhost:5173`. A URL da API fica em `frontend/services/config.js`; o padrão usa o servidor local, com mocks desativados.

Cadastre um aluno informando RM e entre com a conta. Para professor/aprovação, consulte `CONTRATO_API_ETAPA02.md` e `ETAPA03.md`. A autorização para aprovar é administrada no banco, nunca escolhida no cadastro público.

## Android

Instale Flutter 3.47.4, Android SDK e aceite as licenças. Dentro de `mobile`:

```sh
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
```

`10.0.2.2` só vale para o emulador Android padrão. Em aparelho físico, use o IP local da máquina e libere o acesso na rede. HTTP é permitido apenas no manifesto debug; uma entrega release precisa de HTTPS. Não use `main_debug.dart` para validar a integração: ele usa dados falsos.

APK local: `mobile/build/app/outputs/flutter-apk/app-debug.apk`. No GitHub, abra Actions → KRIPTA acceptance tests → execução aprovada → Artifacts → `kripta-debug-apk`.

## Conferência manual com a mesma conta

1. Entre na web e no APK com o mesmo aluno.
2. Crie uma tarefa na web; no APK, toque em Atualizar na aba Tarefas.
3. Conclua no APK; atualize a web e confira a tarefa concluída e 25 XP. Repetir não concede novos pontos.
4. Crie evento pessoal na agenda do APK para o dia selecionado; confira na web e marque seu aviso como lido.
5. Saia e entre novamente; dados devem permanecer. Entre com outro aluno e confira o isolamento.
6. Desligue a rede: deve aparecer erro, sem conteúdo fictício. Restaure a rede e tente novamente.
7. Abra Kai: enquanto não houver provedor, a mensagem de indisponibilidade é o resultado esperado.

Consulte `ETAPAS07_08.md` para a matriz de evidências e pendências. A demonstração visual e a resposta real de IA ainda são critérios de aceite separados.

## Onde estão as alterações e PRs

Código: `backend/`, `frontend/`, `mobile/`. Contratos e relatórios: `docs/`. Automação: `.github/workflows/auth-tests.yml`.

- [PR 1 — consolidação/autenticação](https://github.com/kelvinRosendo/KRIPTA/pull/1)
- [PR 2 — banco, perfis e contratos](https://github.com/kelvinRosendo/KRIPTA/pull/2)
- [PR 3 — núcleo acadêmico](https://github.com/kelvinRosendo/KRIPTA/pull/3)
- [PR 4 — calendário e notificações](https://github.com/kelvinRosendo/KRIPTA/pull/4)
- [PR 5 — gamificação](https://github.com/kelvinRosendo/KRIPTA/pull/5)
- [PR 6 — estrutura de provedores Kai](https://github.com/kelvinRosendo/KRIPTA/pull/6)
- [PR 7 — Flutter e revisão de entrega](https://github.com/kelvinRosendo/KRIPTA/pull/7)
- [Todas as PRs, inclusive encerradas](https://github.com/kelvinRosendo/KRIPTA/pulls?q=is%3Apr)

No GitHub, a aba Files changed de cada PR mostra o que foi alterado; Conversation mostra os testes e o merge.
