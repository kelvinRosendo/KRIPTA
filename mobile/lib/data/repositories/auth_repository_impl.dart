/// Implementação de [AuthRepository] sobre a API real do KRIPTA.
///
/// ## Particularidades do contrato de autenticação
///
/// Este repositório é o único que **escreve** no armazenamento seguro, e
/// os motivos não são óbvios:
///
/// 1. **`register` não devolve token.** O `RegisterResponse` do backend tem
///    só `{id, nome, email, tipo}`. Usar a resposta do cadastro para abrir
///    sessão quebraria o fluxo. Por isso [cadastrar] faz o login em seguida,
///    com as mesmas credenciais.
/// 2. **O backend é stateless** (`SessionCreationPolicy.STATELESS`): não
///    existe revogação de token no servidor, então [sair] só apaga o token
///    local — e isso é o logout completo, não uma limitação do app.
/// 3. **Um `401` no login é "senha errada", não "sessão morta".** O
///    [AuthInterceptor] já isenta `/auth/login` e `/auth/register` do
///    logout automático, então nenhuma marcação extra é necessária aqui —
///    mas isso é frágil: se algum dia o login passar a ser feito por outra
///    rota, o efeito colateral volta. O teste `login com senha errada não
///    apaga a sessão` cobre essa garantia.
library;

import '../../core/config/api_endpoints.dart';
import '../../core/logging/app_logger.dart';
import '../../core/storage/secure_token_store.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../dto/dto.dart';
import '../mappers/dto_mapper.dart';
import 'api_repository_base.dart';

/// Repositório de autenticação e sessão.
class AuthRepositoryImpl extends ApiRepositoryBase implements AuthRepository {
  /// Cria o repositório com o cliente HTTP e o armazenamento de token.
  AuthRepositoryImpl({required super.dio, required this._tokenStore});

  final TokenStore _tokenStore;

  @override
  final AppLogger log = AppLogger('auth.repository');

  @override
  Future<Result<Usuario>> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required PerfilUsuario perfil,
  }) async {
    // Passo 1 — cria a conta.
    final cadastro = await guard<void>(() async {
      final resposta = await dio.post<Object>(
        ApiEndpoints.register,
        data: CadastroRequestDto.fromForm(
          nome: nome,
          email: email,
          senha: senha,
          tipo: perfil.wire,
        ).toJson(),
      );
      // Valida o formato da resposta: se o backend mudar o
      // `RegisterResponse`, o erro aparece aqui, como ContractFailure.
      corpoJson(resposta);
    });

    // Passo 2 — o cadastro não autentica. Se falhou, devolve a falha do
    // próprio cadastro; não há conta para logar.
    if (cadastro case FailureResult<void>(:final failure)) {
      return FailureResult<Usuario>(failure);
    }

    log.info('conta criada; iniciando sessão');

    // Passo 3 — autentica com as mesmas credenciais. A falha do login
    // (e-mail com caixa diferente, backend indisponível) chega como está,
    // preservando `ValidationFailure`/`NetworkFailure` para a UI decidir.
    return entrar(email: email, senha: senha);
  }

  @override
  Future<Result<Usuario>> entrar({
    required String email,
    required String senha,
  }) {
    return guard<Usuario>(() async {
      final resposta = await dio.post<Object>(
        ApiEndpoints.login,
        data: LoginRequestDto.fromForm(email: email, senha: senha).toJson(),
      );

      final dto = LoginResponseDto.fromJson(corpoJson(resposta));

      // Grava o token **antes** de devolver: se a escrita no Keychain
      // falhar, o erro entra por `guard` e o app não entra numa sessão
      // que não consegue persistir.
      await _tokenStore.write(dto.token);
      log.info('sessão iniciada (expira em ${dto.expiresIn}s)');

      return DtoMapper.usuarioFromLogin(dto);
    });
  }

  @override
  Future<Result<Usuario>> usuarioAtual() {
    return guard<Usuario>(() async {
      final resposta = await dio.get<Object>(ApiEndpoints.currentUser);
      return DtoMapper.usuarioFromResponse(
        UsuarioResponseDto.fromJson(corpoJson(resposta)),
      );
    });
  }

  @override
  Future<Result<Usuario>> atualizarPerfil({
    required String nome,
    required String email,
  }) {
    return guard<Usuario>(() async {
      final resposta = await dio.put<Object>(
        ApiEndpoints.updateCurrentUser,
        data: AtualizarPerfilRequestDto(
          nome: nome.trim(),
          email: email.trim(),
        ).toJson(),
      );
      return DtoMapper.usuarioFromResponse(
        UsuarioResponseDto.fromJson(corpoJson(resposta)),
      );
    });
  }

  @override
  Future<Result<void>> trocarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) {
    return guard<void>(() async {
      final resposta = await dio.put<Object>(
        ApiEndpoints.changePassword,
        data: TrocarSenhaRequestDto(
          senhaAtual: senhaAtual,
          novaSenha: novaSenha,
        ).toJson(),
      );
      // O endpoint responde 204; `200 {}` também é aceito.
      corpoVazioOu<void>(resposta, () {});
    });
  }

  @override
  Future<void> sair() async {
    // Sem revogação no servidor (JWT stateless), limpar o token local é o
    // logout completo. Falha ao apagar é logged e não propagada: um erro
    // de escrita no Keychain não pode impedir o usuário de sair do app.
    try {
      await _tokenStore.clear();
      log.info('sessão encerrada localmente');
    } on Object catch (erro) {
      log.warning('não foi possível apagar o token', error: erro);
    }
  }

  @override
  Future<bool> temSessaoAtiva() async {
    final token = await _tokenStore.read();
    return token != null && token.isNotEmpty;
  }
}
