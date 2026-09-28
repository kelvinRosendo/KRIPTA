/// Cliente HTTP do KRIPTA (`dio`).
///
/// Cadeia de construção do [Dio], em ordem:
/// 1. [AppConfig] fornece base URL e timeouts;
/// 2. [AuthInterceptor] injeta o JWT e detecta sessão expirada;
/// 3. [ConnectivityInterceptor] falha rápido quando não há rede, evitando
///    esperar o timeout do socket em todo aparelho sem sinal;
/// 4. `LogInterceptor` registra o tráfego (apenas em debug).
///
/// ## Tratamento de erro
///
/// O cliente **não** converte erro: propaga a `DioException`. Quem traduz
/// para o modelo de domínio é [ApiErrorMapper], chamado nos repositórios.
/// Manter essa separação permite trocar o `dio` sem tocar na UI.
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../logging/app_logger.dart';
import 'auth_interceptor.dart';

/// Cliente HTTP configurado e pronto para uso.
class ApiClient {
  /// Cria o cliente e monta a cadeia de interceptadores.
  ///
  /// [authInterceptor] injeta o JWT e avisa quando a sessão morre.
  /// [connectivity] é opcional: quando `null`, a verificação de rede
  /// anterior é omitida (útil em teste, onde não há plataforma real).
  factory ApiClient({
    required AppConfig config,
    required AuthInterceptor authInterceptor,
    Connectivity? connectivity,
  }) {
    final dio = Dio(_baseOptions(config));

    dio.interceptors.add(authInterceptor);
    if (connectivity != null) {
      dio.interceptors.add(ConnectivityInterceptor(connectivity));
    }
    if (config.enableNetworkLog) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (Object? object) =>
              AppLogger('http').debug(object.toString()),
        ),
      );
    }
    return ApiClient._(dio);
  }

  ApiClient._(this.dio);

  /// Instância do `dio` injetada nos repositórios.
  final Dio dio;

  /// Opções base do cliente.
  ///
  /// `validateStatus` fica **fora** do padrão (`status < 500`) de propósito:
  /// com ele, respostas 4xx não virariam `DioException`, o `errorHandler`
  /// seria bypassado e o corpo de erro do backend — que é justamente o
  /// que o `ValidationFailure` precisa — seria perdido.
  static BaseOptions _baseOptions(AppConfig config) {
    return BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      sendTimeout: config.sendTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: <String, Object>{'Accept': 'application/json'},
    );
  }
}

/// Aborta a requisição quando o dispositivo está sem rede.
///
/// Lança [DioExceptionType.connectionError], de modo que o
/// `ApiErrorMapper` produza um `NetworkFailure` com a mensagem certa,
/// sem precisar de um tipo de erro novo.
class ConnectivityInterceptor extends Interceptor {
  /// Cria o interceptador com a fonte de conectividade.
  ConnectivityInterceptor(this._connectivity);

  final Connectivity _connectivity;
  final AppLogger _log = AppLogger('connectivity');

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!await _isOnline()) {
      _log.warning(
        'requisição abortada: dispositivo sem rede (${options.path})',
      );
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: const OfflineFailure(),
          message: 'Sem conexão com a internet.',
        ),
        true,
      );
      return;
    }
    handler.next(options);
  }

  /// `true` quando há ao menos uma interface de rede utilizável.
  ///
  /// `connectivity_plus` devolve uma lista; `null`/`vazio` é tratado como
  /// offline porque, no Android, uma rede de captive portal sem internet é
  /// reportada como conectada — nesse caso o socket falharia do mesmo jeito.
  Future<bool> _isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.any((ConnectivityResult r) => r != ConnectivityResult.none);
    } on Exception catch (error) {
      // Se a plataforma não souber responder, deixa a requisição passar:
      // o socket ainda tem chance de funcionar (ex.: VPN, plano de dados).
      _log.warning(
        'não foi possível ler conectividade; assumindo online',
        error: error,
      );
      return true;
    }
  }
}

/// Marcador de falha por ausência de rede, sem colisão com tipos do `dio`.
class OfflineFailure implements Exception {
  /// Cria o marcador.
  const OfflineFailure();

  @override
  String toString() => 'OfflineFailure: dispositivo sem conexão';
}
