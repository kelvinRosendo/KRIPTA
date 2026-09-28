# KRIPTA Backend

Backend do projeto **KRIPTA** (TCC) — Spring Boot 3.4.2, Java 21, PostgreSQL, JWT.

## Requisitos

- **Java 21** (o projeto é compilado com `source/target 21`)
- **PostgreSQL 16+**
- Maven **não precisa** ser instalado: use o wrapper `./mvnw` (Windows: `mvnw.cmd`)

> Atenção: builds feitos com **JDK 24+** falham nos testes, porque o Byte Buddy
> embarcado no Spring Boot 3.4.2 não reconhece classes Java 25. Use o JDK 21.

## Configuracao

As variaveis sensiveis ficam fora do codigo-fonte. Copie o exemplo e preencha:

```bash
cp .env.example .env
```

Depois exporte as variaveis antes de rodar a aplicacao:

```bash
set JWT_SECRET=<segredo-com-pelo-menos-32-caracteres>
set DB_PASSWORD=<senha-do-postgres>
./mvnw spring-boot:run
```

Sem `JWT_SECRET` a aplicacao **nao sobe** — isso e proposital, para nao existir
chave padrao em ambiente.

## Banco de dados

O schema e gerenciado pelo **Flyway**. Crie apenas o banco vazio:

```sql
CREATE DATABASE kripta;
```

Na primeira execucao o Flyway roda as migrations de
`src/main/resources/db/migration` e o Hibernate valida o schema
(`ddl-auto=validate`) contra as entidades.

| Versao | Arquivo                                   | Descricao                  |
|--------|-------------------------------------------|----------------------------|
| V1     | `V1__criar_tabela_users.sql`              | tabela `users`             |

Para inspecionar o estado:

```sql
SELECT * FROM flyway_schema_history;
```

> O perfil `test` desliga o Flyway (`spring.flyway.enabled=false`) porque as
> migrations sao escritas em SQL do PostgreSQL. Nos testes o schema do H2 e
> criado pelo proprio Hibernate (`create-drop`).

## Endpoints

| Metodo | Rota              | Acesso   | Descricao                    |
|--------|-------------------|----------|------------------------------|
| GET    | `/api/health`     | publico  | verifica se a API esta de pe |
| POST   | `/api/auth/register` | publico | cria um usuario             |
| POST   | `/api/auth/login`    | publico | retorna o token JWT        |
| GET    | `/api/auth/me`       | token   | dados do usuario logado    |

### Exemplos

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"nome":"Joao","email":"joao@email.com","senha":"senha123","tipo":"USUARIO"}'

curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"joao@email.com","senha":"senha123"}'

curl http://localhost:8080/api/auth/me \
  -H "Authorization: Bearer <token>"
```

## Formato de erro

```json
{
  "timestamp": "2026-01-01T12:00:00Z",
  "status": "error",
  "error": "CREDENCIAIS_INVALIDAS",
  "message": "Email ou senha inválidos"
}
```

| `error`               | HTTP | Quando                                 |
|-----------------------|------|----------------------------------------|
| `VALIDACAO`           | 400  | campos invalidos (lista em `errors`)    |
| `NAO_AUTENTICADO`     | 401  | token ausente, invalido ou expirado     |
| `CREDENCIAIS_INVALIDAS` | 401 | email ou senha incorretos no login     |
| `ACESSO_NEGADO`       | 403  | usuario sem permissao                   |
| `EMAIL_JA_CADASTRADO` | 409  | email ja existe                        |

## Testes

```bash
./mvnw test
```

O perfil `test` usa **H2 em memoria**, entao nao depende do PostgreSQL local.
