/// Estado de autenticação e sessão, com o [AuthController] que o produz.
///
/// ## Por que um [Notifier] e não um [AsyncNotifier]
///
/// A sessão tem **três** estados que a UI precisa distinguir, e o
/// `AsyncValue` do Riverpod expressa só dois (carregando/dado):
///
/// - `desconhecido` — ainda não verificamos o token (splash);
/// - `autenticado` — há usuário;
/// - `anonimo` — não há token, ou o token foi recusado pelo servidor.
///
/// `desconhecido` e `anonimo` precisam ser diferentes porque o primeiro
/// **não** deve mandar o usuário para a tela de login: é o intervalo entre
/// abrir o app e ler o Keychain, e um redirect aí produziria um "flash" de
/// login em quem já está autenticado.
library;

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/repositories.dart';

/// Situação da sessão no aplicativo.
enum StatusSessao {
  /// O token ainda não foi lido do armazenamento seguro.
  ///
  /// Estado inicial; a UI mostra o splash.
  desconhecido,

  /// Há usuário autenticado.
  autenticado,

  /// Não há sessão válida.
  anonimo,
}

/// Estado imutável da sessão.
class EstadoSessao extends Equatable {
  /// Cria o estado com a situação e o usuário atuais.
  const EstadoSessao({
    this.status = StatusSessao.desconhecido,
    this.usuario,
    this.falha,
  });

  /// Estado inicial: nada verificado ainda.
  static const EstadoSessao inicial = EstadoSessao();

  /// Situação da sessão.
  final StatusSessao status;

  /// Usuário autenticado, quando [status] é [StatusSessao.autenticado].
  final Usuario? usuario;

  /// Última falha de login/cadastro, para exibir no formulário.
  ///
  /// Vive no estado (e não no `TextEditingState` do formulário) porque o
  /// `router` precisa reagir a ela em alguns casos e porque o erro de
  /// validação por campo do backend precisa chegar ao `TextField`.
  final Failure? falha;

  /// `true` quando há usuário autenticado.
  bool get autenticado => status == StatusSessao.autenticado && usuario != null;

  /// Copia o estado alterando os campos indicados.
  ///
  /// Os `?? this` são intencionais: `falha` é sobrescrita explicitamente
  /// com `null` quando um novo login começa, o que o `copyWith` padrão não
  /// permitiria. Por isso o parâmetro é `Failure?` com um sentinela.
  EstadoSessao copyWith({
    StatusSessao? status,
    Usuario? usuario,
    Object? falha = _manter,
  }) {
    return EstadoSessao(
      status: status ?? this.status,
      usuario: usuario ?? this.usuario,
      falha: falha == _manter ? this.falha : falha as Failure?,
    );
  }

  /// Sentinela que distingue "não informado" de "informado como null".
  static const Object _manter = Object();

  @override
  List<Object?> get props => <Object?>[status, usuario, falha];
}

/// Controla o ciclo de vida da sessão.
///
/// Todas as operações de rede usam o [Result] dos repositórios e **nunca**
/// deixam escapar exceção: o estado final é sempre um [EstadoSessao].
class AuthController extends Notifier<EstadoSessao> {
  @override
  EstadoSessao build() => EstadoSessao.inicial;

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Verifica o token salvo e reidrata a sessão.
  ///
  /// Chamada uma vez, no `build` do app, antes de resolver a rota inicial.
  /// Sem token, não há requisição: vai direto para [StatusSessao.anonimo].
  Future<void> restaurarSessao() async {
    final temToken = await _repository.temSessaoAtiva();
    if (!temToken) {
      state = const EstadoSessao(status: StatusSessao.anonimo);
      return;
    }

    // Há token: o servidor é a autoridade. Se recusar (expirado, revogado,
    // banco recriado em desenvolvimento), o `AuthInterceptor` já limpou o
    // token e o usuário volta para a tela de login sem erro — não houve
    // ação dele a preservar.
    final resultado = await _repository.usuarioAtual();
    if (!ref.mounted) return;

    state = switch (resultado) {
      Success<Usuario>(:final value) => EstadoSessao(
        status: StatusSessao.autenticado,
        usuario: value,
      ),
      FailureResult<Usuario>() => const EstadoSessao(
        status: StatusSessao.anonimo,
      ),
    };
  }

  /// Autentica com e-mail e senha.
  ///
  /// Devolve `true` em caso de sucesso, para o formulário navegar. A falha
  /// fica em [EstadoSessao.falha] para a tela exibir, e o retorno permite
  /// decidir a navegação sem precisar ler o estado.
  Future<bool> entrar({required String email, required String senha}) async {
    state = state.copyWith(falha: null);

    final resultado = await _repository.entrar(email: email, senha: senha);
    if (!ref.mounted) return false;

    return switch (resultado) {
      Success<Usuario>(:final value) => () {
        state = EstadoSessao(status: StatusSessao.autenticado, usuario: value);
        return true;
      }(),
      FailureResult<Usuario>(:final failure) => () {
        state = EstadoSessao(status: StatusSessao.anonimo, falha: failure);
        return false;
      }(),
    };
  }

  /// Cria a conta e já abre sessão.
  Future<bool> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) async {
    state = state.copyWith(falha: null);

    final resultado = await _repository.cadastrar(
      nome: nome,
      email: email,
      senha: senha,
      // O app não expõe escolha de perfil: quem se cadastra pelo KRIPTA
      // é aluno. Ver `RELATORIO.md` sobre a divergência ADMIN/USUARIO do
      // TCC (Aluno/Professor).
      perfil: PerfilUsuario.usuario,
    );
    if (!ref.mounted) return false;

    return switch (resultado) {
      Success<Usuario>(:final value) => () {
        state = EstadoSessao(status: StatusSessao.autenticado, usuario: value);
        return true;
      }(),
      FailureResult<Usuario>(:final failure) => () {
        state = EstadoSessao(status: StatusSessao.anonimo, falha: failure);
        return false;
      }(),
    };
  }

  /// Limpa a sessão local e volta para `anonimo`.
  Future<void> sair() async {
    await _repository.sair();
    // Invalida o cache do interceptor: se o usuário entrar de novo, a
    // próxima requisição precisa ler o token novo, não o antigo.
    ref.read(authInterceptorProvider).invalidateTokenCache();
    if (!ref.mounted) return;
    state = const EstadoSessao(status: StatusSessao.anonimo);
  }

  /// Encerra a sessão local após o servidor recusar o token (401).
  ///
  /// Diferente de [sair], **não** chama o backend: o logout é inútil
  /// quando o servidor já recusou a credencial, e a requisição falharia
  /// com outro 401. Também é idempotente — várias requisições em voo
  /// podem receber 401 ao mesmo tempo, e todas chamam isto.
  ///
  /// A [UnauthorizedFailure] vira a mensagem do login, então o aluno
  /// entende por que foi deslogado em vez de ver a tela recarregar.
  void encerrarSessao() {
    // Ignora se já está anônima: evita reconstruir o estado — e portanto
    // disparar um redirect do router — a cada 401 subsequente.
    if (state.status == StatusSessao.anonimo) return;

    state = EstadoSessao(
      status: StatusSessao.anonimo,
      falha: const UnauthorizedFailure(
        message: 'Sua sessão expirou. Entre novamente.',
      ),
    );
  }

  /// Atualiza o usuário em memória após uma edição de perfil.
  ///
  /// Não refaz `GET /api/auth/me`: o `PATCH` já devolve o registro
  /// atualizado, e a Home e o cabeçalho precisam refletir a mudança sem
  /// uma requisição extra.
  ///
  /// Ignora a chamada se não há sessão ativa — sem usuário carregado não
  /// há o que atualizar, e sobrescrever o estado deixaria o perfil em
  /// branco na próxima abertura.
  void atualizarUsuario(Usuario usuario) {
    if (state.status != StatusSessao.autenticado) return;
    state = state.copyWith(usuario: usuario);
  }

  /// Limpa a mensagem de erro após a tela exibi-la.
  void limparFalha() {
    if (state.falha == null) return;
    state = state.copyWith(falha: null);
  }
}

/// Usuário da sessão atual, ou `null` se não houver.
///
/// Atalho de leitura: várias telas precisam só do usuário, não do estado
/// completo de autenticação. `select` evita que a Home e o Perfil sejam
/// reconstruídos quando muda o *status* da sessão.
final Provider<Usuario?> usuarioAtualProvider = Provider<Usuario?>(
  (Ref ref) =>
      ref.watch(authControllerProvider.select((EstadoSessao s) => s.usuario)),
  name: 'usuarioAtual',
);

/// Estado da sessão, exposto para a UI e para o `router`.
final NotifierProvider<AuthController, EstadoSessao> authControllerProvider =
    NotifierProvider<AuthController, EstadoSessao>(
      AuthController.new,
      name: 'authController',
    );

/// Atalho booleano: a UI só precisa saber "tem sessão?".
///
/// Usado pelo `refreshListenable` do `go_router`, que exige um
/// `Listenable` e não um provider.
final Provider<bool> estaAutenticadoProvider = Provider<bool>(
  (Ref ref) => ref.watch(
    authControllerProvider.select((EstadoSessao s) => s.autenticado),
  ),
  name: 'estaAutenticado',
);
