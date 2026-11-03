/// Interceptador que injeta o token JWT e reage a `401`.
///
/// Reproduz o comportamento de `services/api.js` do frontend web, com
/// duas melhorias:
///
/// - o logout automático é idempotente (a web pode disparar duas vezes);
/// - o `401` das rotas públicas (`/auth/login`, `/auth/register`) **não**
///   encerra a sessão, porque ali a resposta é "senha incorreta".
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';
import '../storage/secure_token_store.dart';

/// Assinatura do callback disparado quando a sessão morre.
typedef SessionExpiredCallback = void Function();

/// Adiciona `Authorization: Bearer <token>` e trata expiração de sessão.
class AuthInterceptor extends Interceptor {
  /// Cria o interceptador.
  ///
  /// [_onSessionExpired] é chamado uma única vez por resposta 401 não
  /// relacionada a login/cadastro, para que a camada de estado (Riverpod)
  /// possa limpar o token e redirecionar para a tela de entrada.
  AuthInterceptor({required this._tokenStore, required this._onSessionExpired});

  final TokenStore _tokenStore;
  final SessionExpiredCallback _onSessionExpired;

  final AppLogger _log = AppLogger('auth_interceptor');

  /// Rotas em que `401` significa "credencial errada", não "sessão morta".
  static const List<String> _publicAuthPaths = <String>[
    '/auth/login',
    '/auth/register',
  ];

  /// Guarda o resultado da leitura do token por requisição, para não
  /// awaitar o Keychain em paralelo quando várias requisições disparam.
  String? _cachedToken;
  bool _tokenResolved = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Lê o Keychain só na primeira requisição; depois reaproveita o cache
    // até `invalidateTokenCache` ser chamado.
    if (!_tokenResolved) {
      _cachedToken = await _tokenStore.read();
      _tokenResolved = true;
    }

    final token = _cachedToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final isPublicAuth = _publicAuthPaths.any(err.requestOptions.path.contains);

    if (err.response?.statusCode == 401 && !isPublicAuth) {
      // Invalida o cache: o token guardado não vale mais, e o próximo
      // `onRequest` precisa reler do armazenamento.
      _tokenResolved = true;
      _cachedToken = null;
      _log.warning('401 em ${err.requestOptions.path}: sessão encerrada');
      _onSessionExpired();
    }

    handler.next(err);
  }

  /// Invalida o token em cache após login/logout.
  ///
  /// Chamado pelo `AuthController` para que a próxima requisição já saia
  /// com o token novo, sem precisar esperar a próxima revalidação.
  void invalidateTokenCache() {
    _tokenResolved = false;
    _cachedToken = null;
  }

  @visibleForTesting
  /// Semente o cache do token (usado em teste para não tocar o Keychain).
  void seedTokenCache(String? token) {
    _cachedToken = token;
    _tokenResolved = true;
  }
}
