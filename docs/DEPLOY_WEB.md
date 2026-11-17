# Deploy do KRIPTA Web

1. No Netlify, importe o repositório do GitHub e selecione a branch `main`. O arquivo `netlify.toml` define a pasta base `frontend` e publica somente a pasta `dist`. Anote a origem HTTPS atribuída ao site. O primeiro build precisa da URL da API, definida no passo 3.
2. No Render, crie um Blueprint a partir da branch `main` com o arquivo `render.yaml`. Informe a origem anotada em `CORS_ALLOWED_ORIGINS`, por exemplo `https://seu-site.netlify.app`, sem barra no final. O Blueprint cria a API e o PostgreSQL gratuitos na mesma região, liga o banco pela rede privada e gera `JWT_SECRET`. O Flyway cria o esquema e carrega os currículos no primeiro boot.
3. Quando `https://SEU-BACKEND.onrender.com/api/health` responder, defina `KRIPTA_API_URL` no Netlify com `https://SEU-BACKEND.onrender.com/api` e rode um novo deploy. Esse endereço é público e vai no código entregue ao navegador. As credenciais do banco e a chave JWT ficam no Render.
4. No link público do Netlify, confirme que os cinco cursos aparecem no login. Com contas de teste, crie uma sala como professor, publique uma atividade com prazo e confirme que ela chega em Tarefas e na Agenda do aluno que entrar com o código.

O PostgreSQL do Render começa com a estrutura e os currículos. Contas e atividades criadas no banco local continuam no banco local. O plano gratuito da API pode demorar no primeiro acesso após inatividade, e o banco gratuito expira em 30 dias.
