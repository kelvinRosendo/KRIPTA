/// Contratos (interfaces) dos repositórios do KRIPTA.
///
/// Esta é a **fronteira arquitetural** do projeto:
///
/// ```
/// presentation  ──depende──▶  domain (estas interfaces)
///                                 ▲
///                                 │ implementa
///                          data/ (Dio + DTO)
/// ```
///
/// A UI nunca importa `dio`, `json_annotation` nem `DioException`. Isso
/// permite trocar o backend, usar um dublê em teste, ou rodar a interface
/// contra dados locais sem tocar nas telas.
///
/// ## Regra de ouro
///
/// Conforme `PLANO DE DESENVOLVIMENTO` (§7, área Mobile): **a IA não cria
/// endpoints**. Se uma informação necessária não existe na API, o
/// responsável mobile comunica o backend em vez de improvisar um contrato.
/// As assinaturas abaixo que ainda não têm controller correspondente estão
/// marcadas com ⚠️.
library;

import '../../core/utils/result.dart';
import '../entities/entities.dart';

/// Acesso à autenticação e à sessão (RF01, RF02, RN01, RN02).
abstract interface class AuthRepository {
  /// Cadastra um novo usuário.
  ///
  /// `POST /api/auth/register` → **201** com `RegisterResponse`
  /// (`id`, `nome`, `email`, `tipo`). O backend **não** devolve token no
  /// cadastro: o usuário precisa chamar [entrar] em seguida.
  ///
  /// Erros esperados: `VALIDACAO` (400) e `EMAIL_JA_CADASTRADO` (409).
  Future<Result<Usuario>> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required PerfilUsuario perfil,
  });

  /// Autentica um usuário e persiste o token.
  ///
  /// `POST /api/auth/login` → **200** com `LoginResponse`
  /// (`token`, `tokenType`, `expiresIn` + dados do usuário).
  ///
  /// Erro esperado: `CREDENCIAIS_INVALIDAS` (401) — que **não** encerra
  /// a sessão, pois é falha de credencial e não de token.
  Future<Result<Usuario>> entrar({
    required String email,
    required String senha,
  });

  /// Busca o usuário da sessão atual.
  ///
  /// `GET /api/users/me` → **200** com `UserResponse`.
  /// Usado ao abrir o app para reidratar a sessão a partir do token salvo.
  Future<Result<Usuario>> usuarioAtual();

  /// Atualiza nome e e-mail do perfil.
  ///
  /// `PUT /api/users/me` → **200** com `UserResponse` atualizado.
  Future<Result<Usuario>> atualizarPerfil({
    required String nome,
    required String email,
  });

  /// Troca a senha do usuário logado.
  ///
  /// `PUT /api/users/me/senha` → **204** sem corpo.
  /// Erro esperado: `SENHA_ATUAL_INCORRETA` (400).
  Future<Result<void>> trocarSenha({
    required String senhaAtual,
    required String novaSenha,
  });

  /// Encerra a sessão localmente.
  ///
  /// O backend é *stateless* (`SessionCreationPolicy.STATELESS`), então
  /// não há revogação de token no servidor: "sair" é apagar o token do
  /// armazenamento seguro.
  Future<void> sair();

  /// `true` quando há token salvo no armazenamento seguro.
  ///
  /// Não valida o token: apenas verifica se existe um. A validação real
  /// acontece na primeira requisição autenticada, via `GET /users/me`.
  Future<bool> temSessaoAtiva();
}

/// Acesso às disciplinas (componente curricular) — RN03.
///
/// Rotas de leitura já implementadas no backend (`GET /api/disciplinas`,
/// `GET|PUT|DELETE /api/disciplinas/{id}`). A criação depende de o backend
/// liberar escrita para o perfil `USUARIO` (o aluno), que ainda é
/// indefinido — ver `RELATORIO.md`, lacunas de contrato.
abstract interface class DisciplinaRepository {
  /// Lista as disciplinas do usuário autenticado.
  ///
  /// `GET /api/disciplinas` → **200** com `List<DisciplinaResponse>`.
  Future<Result<List<Disciplina>>> listar();

  /// Busca uma disciplina pelo identificador.
  ///
  /// `GET /api/disciplinas/{id}`.
  Future<Result<Disciplina>> buscar(int id);

  /// Cria uma disciplina.
  ///
  /// `POST /api/disciplinas` → **201**.
  /// `cor` deve estar em `#RRGGBB` (`@Pattern` do backend).
  Future<Result<Disciplina>> criar({required String nome, required String cor});

  /// Atualiza nome e cor de uma disciplina.
  ///
  /// `PUT /api/disciplinas/{id}` → **200**.
  Future<Result<Disciplina>> atualizar({
    required int id,
    required String nome,
    required String cor,
  });

  /// Exclui uma disciplina.
  ///
  /// `DELETE /api/disciplinas/{id}` → **204** sem corpo.
  Future<Result<void>> excluir(int id);
}

/// Acesso às unidades de uma disciplina.
///
/// ⚠️ **Requisito em aberto no backend**: não há `UnidadeController`.
/// A rota segue a convenção de nomenclatura do backend (português) e
/// precisa de validação de quem responde pelo servidor.
abstract interface class UnidadeRepository {
  /// Lista as unidades de uma disciplina.
  ///
  /// `GET /api/disciplinas/{id}/unidades`.
  Future<Result<List<Unidade>>> listar(int disciplinaId);

  /// Cria uma unidade em uma disciplina.
  ///
  /// `POST /api/disciplinas/{id}/unidades` → **201**.
  Future<Result<Unidade>> criar({
    required int disciplinaId,
    required String nome,
    String? descricao,
  });

  /// Atualiza uma unidade.
  ///
  /// `PUT /api/unidades/{id}` → **200**.
  Future<Result<Unidade>> atualizar({
    required int id,
    required String nome,
    String? descricao,
  });

  /// Exclui uma unidade.
  ///
  /// `DELETE /api/unidades/{id}` → **204**.
  Future<Result<void>> excluir(int id);
}

/// Acesso aos materiais de estudo (RN03).
///
/// ⚠️ **Requisito em aberto no backend**: não há `MaterialController`.
/// Rotas conforme a convenção do backend.
abstract interface class MaterialRepository {
  /// Lista os materiais de uma unidade.
  ///
  /// `GET /api/unidades/{id}/materiais`.
  Future<Result<List<MaterialEstudo>>> listarPorUnidade(int unidadeId);

  /// Cadastra um material em uma unidade.
  ///
  /// `POST /api/unidades/{id}/materiais` → **201**.
  Future<Result<MaterialEstudo>> criar({
    required int unidadeId,
    required String titulo,
    required TipoMaterial tipo,
    String? url,
    String? descricao,
  });

  /// Atualiza um material.
  ///
  /// `PUT /api/materiais/{id}` → **200**.
  Future<Result<MaterialEstudo>> atualizar({
    required int id,
    required String titulo,
    required TipoMaterial tipo,
    String? url,
    String? descricao,
  });

  /// Marca o material como estudado (ou desmarca).
  ///
  /// `PATCH /api/materiais/{id}/concluir` → **200** com o material
  /// atualizado. É a ação que gera XP no protótipo.
  Future<Result<MaterialEstudo>> alternarConclusao(int id);

  /// Exclui um material.
  ///
  /// `DELETE /api/materiais/{id}` → **204**.
  Future<Result<void>> excluir(int id);
}

/// Acesso às tarefas (RF de organização de prazos).
///
/// ⚠️ **Requisito em aberto no backend**: não há `TaskController`.
/// Rotas conforme a convenção do backend.
abstract interface class TarefaRepository {
  /// Lista tarefas, opcionalmente filtrando por situação.
  ///
  /// `GET /api/tarefas?status=PENDING|COMPLETED`.
  /// Sem `status`, o backend deve devolver todas.
  Future<Result<List<Tarefa>>> listar({StatusTarefa? status});

  /// Busca uma tarefa pelo identificador.
  ///
  /// `GET /api/tarefas/{id}`.
  Future<Result<Tarefa>> buscar(int id);

  /// Cria uma tarefa.
  ///
  /// `POST /api/tarefas` → **201**.
  /// `prazo` é enviado em ISO-8601 UTC (o Spring desserializa para
  /// `Instant`, que exige offset).
  Future<Result<Tarefa>> criar({
    required String titulo,
    String? descricao,
    DateTime? prazo,
    PrioridadeTarefa prioridade = PrioridadeTarefa.media,
    int? disciplinaId,
  });

  /// Atualiza uma tarefa.
  ///
  /// `PUT /api/tarefas/{id}` → **200**.
  Future<Result<Tarefa>> atualizar({
    required int id,
    required String titulo,
    String? descricao,
    DateTime? prazo,
    required PrioridadeTarefa prioridade,
    int? disciplinaId,
  });

  /// Marca a tarefa como concluída (ou desmarca).
  ///
  /// `PATCH /api/tarefas/{id}/concluir` → **200** com a tarefa atualizada
  /// e `gamification.xpEarned`, usado para animar o ganho de XP.
  Future<Result<Tarefa>> alternarConclusao(int id);

  /// Exclui uma tarefa.
  ///
  /// `DELETE /api/tarefas/{id}` → **204**.
  Future<Result<void>> excluir(int id);
}

/// Filtro de situação aplicado a [TarefaRepository.listar].
enum StatusTarefa {
  /// Apenas tarefas abertas.
  pendente('PENDING'),

  /// Apenas tarefas concluídas.
  concluida('COMPLETED');

  const StatusTarefa(this.wire);

  /// Valor exato serializado na query string.
  final String wire;
}

/// Acesso ao calendário (RF05, RN05).
///
/// ⚠️ **Requisito em aberto no backend**: não há `CalendarController`.
abstract interface class CalendarioRepository {
  /// Lista os eventos de um intervalo fechado.
  ///
  /// `GET /api/calendario?inicio=YYYY-MM-DD&fim=YYYY-MM-DD`.
  /// O backend só precisa devolver o dia (`date`); a ordenação e o
  /// agrupamento por dia são feitos no cliente.
  Future<Result<List<EventoCalendario>>> listarPeriodo({
    required DateTime inicio,
    required DateTime fim,
  });
}

/// Acesso aos avisos e comunicados (RN05).
///
/// ⚠️ **Requisito em aberto no backend**: não há `AnnouncementController`.
abstract interface class AvisoRepository {
  /// Lista os avisos do usuário, do mais recente para o mais antigo.
  ///
  /// `GET /api/avisos`.
  Future<Result<List<Aviso>>> listar();
}

/// Acesso à gamificação: XP, nível, insígnias e progresso.
///
/// ⚠️ **Requisito em aberto no backend**: não há controller de
/// gamificação. Rotas conforme a convenção do backend.
abstract interface class GamificacaoRepository {
  /// Números de nível e XP.
  ///
  /// `GET /api/gamificacao/estatisticas` → **200** com
  /// `{ level, xp, xpToNextLevel, levelProgress }`.
  Future<Result<EstatisticasGamificacao>> estatisticas();

  /// Insígnias do usuário, conquistadas ou não.
  ///
  /// `GET /api/gamificacao/conquistas`.
  Future<Result<List<Conquista>>> conquistas();

  /// Progresso geral na plataforma.
  ///
  /// `GET /api/progresso` → **200** com `{ overallProgress }`.
  Future<Result<Progresso>> progresso();
}

/// Acesso à visão agregada da Home.
///
/// ⚠️ **Requisito em aberto no backend**: não há `DashboardController`.
abstract interface class DashboardRepository {
  /// Carrega a visão da Home em uma requisição.
  ///
  /// `GET /api/dashboard`. agregar num só endpoint evita as quatro
  /// chamadas paralelas que a Home faria sem ele (`/gamificacao/stats`,
  /// `/gamification/achievements`, `/tasks?status=PENDING`, ...).
  Future<Result<Dashboard>> carregar();
}

/// Acesso ao agente de IA do KRIPTA (RF06, RN06).
///
/// ⚠️ **Requisito em aberto no backend**: não há controller de IA.
///
/// Ponto de projeto mais importante: o mobile **nunca** chama
/// OpenAI/Gemini diretamente. A chave da API fica no servidor, que também
/// aplica os limites de uso e o filtro de conteúdo (RN06). O frontend web
/// segue a mesma regra (`services/kai.js`).
abstract interface class KaiRepository {
  /// Envia uma mensagem ao agente e recebe a resposta.
  ///
  /// `POST /api/ai/chat` com `{ "message": "..." }` → **200** com
  /// `{ "reply": "..." }`.
  Future<Result<RespostaKai>> enviar(String mensagem);

  /// Verifica se o serviço de IA está disponível.
  ///
  /// Usado pela tela para mostrar o aviso "em breve" em vez de um erro
  /// genérico quando o endpoint ainda não existe.
  Future<Result<bool>> disponivel();
}
