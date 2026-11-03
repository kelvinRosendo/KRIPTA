# Contrato compartilhado — Etapa 02

Base: `/api`. JSON UTF-8; JWT em `Authorization: Bearer <token>`.

| Método e rota | Corpo | Resposta |
| --- | --- | --- |
| GET /health | — | 200, saúde da API |
| POST /auth/register | nome, email, senha, tipo (ALUNO ou PROFESSOR), rm obrigatório para ALUNO | 201, id/nome/email/tipo; sem token |
| POST /auth/login | email, senha | 200, token/tokenType/expiresIn (segundos), id/nome/email/tipo/rm/podeAprovar |
| GET /users/me | — | 200, id/nome/email/tipo/rm/podeAprovar |
| PUT /users/me | nome, email | 200, perfil atualizado |
| PUT /users/me/senha | senhaAtual, novaSenha | senha alterada |
| GET /disciplinas | — | 200, lista de id/nome/cor do usuário |
| GET /disciplinas/{id} | — | 200, id/nome/cor |
| POST /disciplinas | nome, cor opcional (#RRGGBB) | 201, id/nome/cor |
| PUT /disciplinas/{id} | nome, cor opcional | 200, id/nome/cor |
| DELETE /disciplinas/{id} | — | 204 sem corpo |

Cadastro público rejeita ADMIN e USUARIO. Contas legadas USUARIO continuam podendo entrar; migrá-las exige coletar RM real, sem inventar matrículas. Professor cadastrado começa sem permissão de aprovação. Campos de autorização enviados pelo cliente não concedem privilégios.

Erros: 400 validação (`errors` por campo), 401 token/credenciais inválidos, 403 sem permissão, 404 disciplina ausente ou pertencente a outro usuário, 409 duplicidade. Envelope: `timestamp`, `status`, `error`, `message`, opcional `errors`.

A web traduz nome/cor/tipo/podeAprovar para name/color/role/authorized. O Flutter deve adotar este contrato na Etapa 07. Logout remove a sessão local; o JWT já emitido permanece válido até expirar. Ao abrir a web, `/users/me` confirma a sessão; 401 em rota protegida limpa o token.

## Administração de professores

Nesta etapa a concessão/revogação é uma operação restrita ao administrador do banco, sem endpoint público. Identifique e confirme o professor por ID antes de executar, usando uma conta administrativa PostgreSQL:

```sql
SELECT id, nome, email, tipo, pode_aprovar FROM users WHERE id = :professor_id;
UPDATE users SET pode_aprovar = TRUE
WHERE id = :professor_id AND tipo = 'PROFESSOR';
-- Revogar:
UPDATE users SET pode_aprovar = FALSE WHERE id = :professor_id;
```

`:professor_id` representa um parâmetro a substituir pelo ID conferido; não é SQL executável literalmente. A constraint proíbe aprovação por outros perfis. A API recarrega o usuário a cada requisição e só atribui `APROVAR_CONTEUDO` a PROFESSOR com permissão persistida. Revogações valem inclusive com JWT anterior.

As rotas de pendências/aprovação/rejeição já exigem essa permissão no filtro de segurança. O processamento de conteúdo nessas rotas será implementado na Etapa 03.

## Evidências e limites

O workflow do PR #2 validou PostgreSQL 16, migrations, cadastro/login, CRUD e isolamento de disciplinas e persistência após reinício. As alterações finais desta etapa adicionam testes de cadastro sem escalada de privilégio, concessão/revogação e sessão expirada. O teste visual no navegador ainda não foi realizado; não confundir os testes HTTP com uma validação visual.
