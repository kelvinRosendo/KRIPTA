/// Registro central de endpoints do backend KRIPTA.
///
/// Este arquivo é a **única** fonte de verdade de rotas HTTP do mobile.
/// Nenhum outro arquivo deve montar string de caminho (ver a regra 4 das
/// `ai/rules.md` do projeto).
///
/// ## Status de implementação
///
/// O backend Spring Boot evolui por branches e nem todo endpoint citado
/// no frontend web existe ainda. Cada constante abaixo carrega o status
/// real, para que a equipe saiba o que já funciona contra a API e o que
/// ainda depende do backend:
///
/// - [EndpointStatus.implementado] — existe no `SecurityConfig`/controller
///   do backend e já é consumido pelo mobile.
/// - [EndpointStatus.pendente] — contrato definido (frontend web já consome),
///   mas o controller ainda não foi escrito. O mobile chama mesmo assim: o
///   erro 404 chega por [ApiFailure] e a tela mostra "recurso indisponível".
/// - [EndpointStatus.contratoProposto] — só existe no TCC. Não há contrato
///   definido; o caminho segue a convenção de nomenclatura do backend
///   (português) e precisa de validação do responsável pelo backend.
library;

import 'package:flutter/foundation.dart';

/// Grau de maturidade de um endpoint, usado na documentação e na UI.
enum EndpointStatus {
  /// Publicado e testável no backend.
  implementado,

  /// Contrato definido no frontend web; controller ainda ausente.
  pendente,

  /// Apenas especificado no TCC; precisa de contrato formal.
  contratoProposto,
}

/// Rutas da API, sempre relativas à raiz definida em `AppConfig.apiBaseUrl`.
///
/// O backend usa o prefixo `/api` (ver `HealthController`), que já está
/// incluído em `apiBaseUrl` — por isso os caminhos abaixo começam em `/`.
@immutable
class ApiEndpoints {
  const ApiEndpoints._();

  // ── Saúde ──────────────────────────────────────────────────────────
  /// `GET /api/health` — público, usado no diagnóstico de conectividade.
  static const String health = '/health';

  // ── Autenticação (branch `feature/backend-jwt`) ─────────────────────
  /// `POST /api/auth/register` — público. Retorna 201 + `RegisterResponse`
  /// (sem token: o usuário precisa autenticar em seguida).
  static const String register = '/auth/register';

  /// `POST /api/auth/login` — público. Retorna 200 + `LoginResponse`
  /// (token JWT, `tokenType`, `expiresIn` e dados do usuário).
  static const String login = '/auth/login';

  // ── Usuário (branch `feature/backend-users`) ───────────────────────
  /// `GET /api/users/me` — autenticado.
  static const String currentUser = '/users/me';

  /// `PUT /api/users/me` — atualiza nome e e-mail.
  static const String updateCurrentUser = '/users/me';

  /// `PUT /api/users/me/senha` — troca de senha. Note o sufixo em
  /// português, conforme o controller real do backend.
  static const String changePassword = '/users/me/senha';

  /// `DELETE /api/users/me` — exclusão da própria conta.
  static const String deleteCurrentUser = '/users/me';

  // ── Disciplinas (branch `feature/backend-users`) ───────────────────
  /// `GET|POST /api/disciplinas` — listagem e criação.
  static const String disciplines = '/disciplinas';

  /// `GET|PUT|DELETE /api/disciplinas/{id}`.
  static String disciplineById(int id) => '/disciplinas/$id';

  // ── Unidades (ainda sem controller no backend) ────────────────────
  /// `GET|POST /api/disciplinas/{id}/unidades`.
  static String unitsByDiscipline(int disciplineId) =>
      '/disciplinas/$disciplineId/unidades';

  /// `PUT|DELETE /api/unidades/{id}`.
  static String unitById(int id) => '/unidades/$id';

  // ── Materiais (ainda sem controller no backend) ───────────────────
  /// `GET|POST /api/unidades/{id}/materiais`.
  static String materialsByUnit(int unitId) => '/unidades/$unitId/materiais';

  /// `PUT|DELETE /api/materiais/{id}`.
  static String materialById(int id) => '/materiais/$id';

  /// `PATCH /api/materiais/{id}/concluir`.
  static String completeMaterial(int id) => '/materiais/$id/concluir';

  // ── Tarefas (ainda sem controller no backend) ─────────────────────
  /// `GET|POST /api/tarefas`.
  static const String tasks = '/tarefas';

  /// `GET|PUT|DELETE /api/tarefas/{id}`.
  static String taskById(int id) => '/tarefas/$id';

  /// `PATCH /api/tarefas/{id}/concluir` — alterna o estado de conclusão
  /// e concede XP (regra de gamificação do TCC).
  static String completeTask(int id) => '/tarefas/$id/concluir';

  // ── Calendário e avisos (ainda sem controller no backend) ─────────
  /// `GET /api/calendario?inicio=YYYY-MM-DD&fim=YYYY-MM-DD`.
  static const String calendar = '/calendario';

  /// `GET /api/avisos`.
  static const String announcements = '/avisos';

  // ── Gamificação (ainda sem controller no backend) ─────────────────
  /// `GET /api/progresso`.
  static const String progress = '/progresso';

  /// `GET /api/gamificacao/estatisticas`.
  static const String gamificationStats = '/gamificacao/estatisticas';

  /// `GET /api/gamificacao/conquistas`.
  static const String achievements = '/gamificacao/conquistas';

  // ── Dashboard (ainda sem controller no backend) ───────────────────
  /// `GET /api/dashboard` — visão agregada usada pela Home.
  static const String dashboard = '/dashboard';

  // ── Kai / IA (ainda sem controller no backend) ────────────────────
  /// `POST /api/ai/chat` — único ponto de entrada do agente.
  ///
  /// O frontend web nunca chama um provedor de IA (OpenAI/Gemini) direto:
  /// tudo passa pelo backend, que fica com a chave da API. O mobile segue
  /// a mesma regra.
  static const String kaiChat = '/ai/chat';
}

/// Rótulos amigáveis para telas de erro, por status HTTP.
@immutable
class HttpStatusMessages {
  const HttpStatusMessages._();

  /// Mensagem padrão exibida ao usuário final.
  ///
  /// O backend nunca deve vazar stack trace; `message` do `ApiError` é
  /// sempre texto pensado para o usuário.
  static String forStatus(int status) => switch (status) {
    400 => 'Dados inválidos. Revise as informações e tente novamente.',
    401 => 'Sessão expirada ou credenciais inválidas.',
    403 => 'Você não tem permissão para acessar este recurso.',
    404 => 'Recurso não encontrado no servidor.',
    409 => 'Conflito: este registro já existe.',
    422 => 'Não foi possível processar os dados enviados.',
    429 => 'Muitas requisições. Aguarde alguns instantes.',
    500 => 'Erro interno no servidor. Tente novamente mais tarde.',
    502 || 503 || 504 => 'O servidor está indisponível no momento.',
    _ => 'Algo deu errado. Tente novamente.',
  };
}
