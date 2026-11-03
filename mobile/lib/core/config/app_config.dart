/// Configuração de ambiente do aplicativo KRIPTA Mobile.
///
/// Todos os valores chegam por `--dart-define` em tempo de build, o que
/// evita compilar arquivos de configuração diferentes por ambiente e
/// mantém segredos (chaves de API) fora do controle de versão.
///
/// ```sh
/// flutter run \
///   --dart-define=API_BASE_URL=http://10.0.2.2:8080/api \
///   --dart-define=APP_ENV=dev
/// ```
///
/// Referência: a base URL e a chave `DEV_ACCESS_KEY` espelham
/// `frontend/services/config.js` (branch `feature---frontend`), para que
/// mobile e web falem com o mesmo backend Spring Boot.
library;

import 'package:flutter/foundation.dart';

/// Ambientes suportados pelo aplicativo.
enum AppEnvironment {
  /// Desenvolvimento local. A API roda na máquina do desenvolvedor.
  ///
  /// O emulador Android não enxerga `localhost` do host: use
  /// `http://10.0.2.2:8080/api` (Android AVD) ou o IP da máquina na LAN.
  dev,

  /// Homologação/staging.
  staging,

  /// Produção.
  prod,
}

/// Configuração imutável resolvida em tempo de build.
@immutable
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.sendTimeout,
    required this.enableNetworkLog,
    required this.kaiSpeechLocaleId,
  });

  /// Ambiente ativo.
  final AppEnvironment environment;

  /// Raiz da API, sempre terminada em `/` (ex.: `http://localhost:8080/api/`).
  final String apiBaseUrl;

  /// Tempo limite para estabelecer a conexão.
  final Duration connectTimeout;

  /// Tempo limite para receber a resposta completa.
  final Duration receiveTimeout;

  /// Tempo limite para enviar o corpo da requisição.
  final Duration sendTimeout;

  /// Quando `true`, o cliente HTTP registra headers (token mascarado) e o
  /// corpo das requisições. Nunca ativar em produção.
  final bool enableNetworkLog;

  /// Locale preferido para o reconhecimento de voz do Kai.
  ///
  /// `null` deixa o `speech_to_text` escolher o locale do dispositivo,
  /// que é o comportamento desejado na maioria dos casos.
  final String? kaiSpeechLocaleId;

  /// `true` quando o build é de produção.
  bool get isProd => environment == AppEnvironment.prod;

  /// Constrói a configuração lendo os `--dart-define`.
  ///
  /// Lê de [String.fromEnvironment] (e não de `Platform.environment`)
  /// porque o valor precisa ser constante em tempo de compilação para o
  /// *tree shaking* eliminar código de debug do bundle de produção.
  factory AppConfig.fromEnvironment() {
    const rawEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    const rawBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8080/api',
    );
    const rawConnect = String.fromEnvironment(
      'CONNECT_TIMEOUT_SECONDS',
      defaultValue: '15',
    );
    const rawReceive = String.fromEnvironment(
      'RECEIVE_TIMEOUT_SECONDS',
      defaultValue: '20',
    );
    const rawSend = String.fromEnvironment(
      'SEND_TIMEOUT_SECONDS',
      defaultValue: '20',
    );
    const rawLog = bool.fromEnvironment(
      'ENABLE_NETWORK_LOG',
      defaultValue: false,
    );
    const rawLocale = String.fromEnvironment('KAI_SPEECH_LOCALE_ID');

    return AppConfig(
      environment: switch (rawEnv) {
        'prod' || 'production' => AppEnvironment.prod,
        'staging' || 'homolog' => AppEnvironment.staging,
        _ => AppEnvironment.dev,
      },
      // Garante barra final para concatenação segura de caminhos em
      // `api_endpoints.dart`.
      apiBaseUrl: rawBaseUrl.endsWith('/') ? rawBaseUrl : '$rawBaseUrl/',
      connectTimeout: Duration(seconds: int.tryParse(rawConnect) ?? 15),
      receiveTimeout: Duration(seconds: int.tryParse(rawReceive) ?? 20),
      sendTimeout: Duration(seconds: int.tryParse(rawSend) ?? 20),
      enableNetworkLog: rawLog && kDebugMode,
      kaiSpeechLocaleId: rawLocale.isEmpty ? null : rawLocale,
    );
  }
}
