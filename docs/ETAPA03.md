# Etapa 03 — núcleo acadêmico

## Modelo e acesso

`componentes_curriculares` é o catálogo acadêmico compartilhado da instituição: todos os usuários autenticados podem consultar; professores podem criar componentes e publicar conteúdo vinculado a eles. `disciplinas` continuam sendo matérias pessoais, com unidades e materiais privados. Não há turmas ou matrículas em componentes nesta versão. A consulta da web associa a matéria pessoal ao componente pelo mesmo nome, ignorando maiúsculas; nomes diferentes precisam ser alinhados. Uma futura associação por ID evita essa dependência.

Publicação inicia em `AGUARDANDO_APROVACAO`. Só professor com `pode_aprovar` persistido pode aprovar/rejeitar. A decisão é final neste fluxo; nova decisão retorna 409. O versionamento otimista impede duas decisões concorrentes de sobrescrever o resultado. Alunos consultam apenas aprovados, inclusive por ID. Autor consulta seus próprios pendentes/rejeitados; aprovadores consultam a fila.

O cadastro de conteúdo oferece criar o primeiro componente quando o catálogo está vazio. Unidades pessoais não são vinculadas aos conteúdos acadêmicos compartilhados.

## Rotas

- GET/POST `/api/componentes`: catálogo (POST exclusivo para professor).
- GET/POST `/api/conteudos`: aprovados/publicação. Entrada: subjectId (componente), title, description, url HTTP(S) opcional, type.
- GET `/api/conteudos/meus`, `/api/conteudos/pendentes`, `/api/conteudos/{id}`.
- PATCH `/api/conteudos/{id}/aprovar` ou `/rejeitar` (corpo `reason`).
- GET/POST `/api/tarefas`, GET/PUT/DELETE `/api/tarefas/{id}`, PATCH `/api/tarefas/{id}/concluir`. Entrada: title, description, dueDate ISO 8601, priority LOW/MEDIUM/HIGH, subjectId pessoal opcional. Conclusão é idempotente e ainda não concede XP (Etapa 05).
- GET/POST `/api/disciplinas/{id}/unidades`; PUT/DELETE `/api/unidades/{id}`.
- GET/POST `/api/unidades/{id}/materiais`; PUT/DELETE `/api/materiais/{id}`; PATCH `/api/materiais/{id}/concluir`.
- Unidade: name, description. Material: title, description, url HTTP(S), type.

## Validação

`AcademicFlowTest` cobre professor publicando, aluno impedido de publicar, aprovador autorizado, decisão repetida, rejeição e consulta direta, isolamento de tarefas/unidades/materiais e conclusão repetida. Workflow executa também com PostgreSQL 16 e migrations V5–V7. Os testes locais usam H2.

## Pendências de aceitação

- Conferir os requisitos contra o KRIPTA.pdf, que não foi fornecido nesta sessão.
- Teste visual no navegador e dispositivos.
- Substituir associação de componentes por nome por vínculo explícito antes de considerar a modelagem acadêmica definitiva.
- Testar edição/exclusão e concorrência com cobertura adicional, além dos fluxos principais já automatizados.

Esta entrega implementa o núcleo, mas essas pendências impedem declarar a Etapa 03 integralmente validada.
