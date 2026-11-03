# KRIPTA — Estado inicial da integração

Data: 03/11/2026.

## Consolidação

- Clone novo em `C:\Users\rosen\Projetos\Kripta`, inicialmente sem alterações.
- Branch local: `integration/kripta-final`.
- Backend/base: `origin/feature/backend-users`, commit `959d7c61413c3d3a3d567ee70c8105a26f34a5d0`.
- Web: `origin/feature---frontend`, commit `06757b02d4387e65a62114da5a7a6cd4699a5792`.
- Mobile: `origin/feature/mobile`, commit `113884da3646111bdd6758ff66439aaaa0fce3f9`.
- Commit da importação: `a124f36` (`chore: consolidate web and mobile clients`).
- As pastas `frontend/` e `mobile/` foram comparadas com as respectivas branches de origem: nenhuma diferença após a importação.
- As branches originais e a `main` foram preservadas. Nenhum push ou merge realizado.

## Verificações

| Área | Verificação | Resultado |
| --- | --- | --- |
| Backend | `mvnw.cmd test`, JDK 21.0.10 | 75 testes, nenhuma falha, erro ou teste ignorado |
| Web | `npm ci --ignore-scripts --no-audit` | Dependências instaladas conforme lockfile |
| Web | `npm run build` | CSS compilado, idêntico ao arquivo da branch original |
| Web | `node --check` nos arquivos de `services/` e `scripts/` | Sem erros de sintaxe |
| Mobile | Flutter 3.47.4 / Dart 3.13.3, `flutter pub get` | Dependências resolvidas sem alterar o lockfile |
| Mobile | `flutter analyze` | 5 apontamentos: 1 warning de lint obsoleto e 4 infos; nenhum erro de compilação reportado |
| Mobile | `flutter test` | 53 testes: 51 passaram, 2 falharam por datas fixas descritas abaixo |

### Pendências encontradas no Flutter

Dois testes em `mobile/test/entidades_test.dart` pressupõem que a data atual seja 28/09/2026, enquanto os getters `atrasada` e `venceHoje` usam `DateTime.now()`. Em 03/11/2026, falham as expectativas de que a tarefa de setembro vença hoje e ainda não esteja atrasada. Corrigir os testes para controlar a referência temporal antes de exigir uma suíte verde.

A análise aponta `unnecessary_await_in_return` obsoleto em `analysis_options.yaml`, documentação ausente em `app_config.dart`, dois blocos `if` sem chaves em `app_validators.dart` e oportunidade de usar `const` em `auth_controller.dart`.

### Correção para execução no Windows

O Maven Wrapper acessava `.Target[0]` mesmo quando a pasta `.m2` não era um link e `Target` era nulo. Isso impedia o Maven de iniciar. O script agora verifica o destino antes de acessar seu primeiro elemento. Com a correção, o wrapper baixou o Maven 3.9.16 e executou os 75 testes com sucesso.

O Java padrão da máquina é 25. Para executar o backend, selecionar o JDK 21 na sessão PowerShell:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Java\jdk-21.0.10'
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
cd backend
.\mvnw.cmd test
```

## Limites e próxima etapa

- Os testes backend usam H2; ainda não validam as migrations e a persistência em PostgreSQL.
- A web mantém `DEV_MODE: true` e uma entrada de demonstração; a consolidação não comprova integração real com a API.
- Compilação do CSS e sintaxe JavaScript não substituem testes no navegador.
- Não foi gerado APK nem realizado teste em dispositivo nesta etapa.
- O `KRIPTA.pdf` citado pelo roadmap não está no clone. Requisitos específicos do PDF precisam ser conferidos com o documento antes da implementação correspondente.
- Próxima entrega: Etapa 02, contrato de autenticação e disciplinas, cadastro com RM, perfis e autorização do servidor, seguido de validação real com PostgreSQL.

Roadmap recebido: [ROADMAP_SOLO_KRIPTA_FINAL.md](ROADMAP_SOLO_KRIPTA_FINAL.md).
