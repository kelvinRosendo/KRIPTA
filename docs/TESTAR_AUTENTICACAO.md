# Testar autenticação

Implementado: cadastro de ALUNO com RM e PROFESSOR, login JWT, mapeamento dos campos web/API, retorno ao login após cadastro, validação da sessão na abertura e CORS para localhost:5173. Cadastro público de ADMIN é rejeitado. Perfis legados USUARIO continuam compatíveis. Professores novos não recebem autorização de aprovação.

## Testes automatizados

No backend, selecionar JDK 21 e executar `mvnw.cmd test`. No frontend executar `node --test tests/auth.test.cjs`.
Os testes Java usam H2, sem executar migrations PostgreSQL. O teste web verifica o contrato e o armazenamento/remoção da sessão com API simulada.

## Teste manual com dados persistentes

1. Iniciar PostgreSQL 16+ e criar o banco vazio `kripta`.
2. No PowerShell, na pasta backend, configurar:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Java\jdk-21.0.10'
$env:DB_USERNAME = 'postgres'
$env:DB_PASSWORD = '<senha do seu PostgreSQL>'
$env:JWT_SECRET = [Convert]::ToBase64String([Security.Cryptography.RandomNumberGenerator]::GetBytes(48))
.\mvnw.cmd spring-boot:run
```

Manter o mesmo JWT_SECRET entre reinícios se quiser preservar a validade dos tokens. O arquivo `.env` não é carregado automaticamente pelo Spring.

3. Em outro terminal, na pasta frontend, executar `npm.cmd run serve`.
4. Abrir http://localhost:5173/?mock=off, cadastrar um aluno com RM e senha de pelo menos seis caracteres. O cadastro deve levar ao login.
5. Entrar com senha errada: deve exibir erro. Entrar com a correta: deve abrir a área do aluno.
6. Atualizar a página: a sessão deve ser validada na API. Sair: deve voltar ao login.
7. Tentar cadastrar novamente o mesmo e-mail: deve exibir conflito.
8. Reiniciar o backend e entrar com a mesma conta: confirma persistência PostgreSQL.

Outros módulos ainda não estão integrados: erros de tarefas, progresso ou calendário não significam falha de login. Não foi validado o fluxo visual no navegador nem a migration V3 em PostgreSQL nesta entrega.
