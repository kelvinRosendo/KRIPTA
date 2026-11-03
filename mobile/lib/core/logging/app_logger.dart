/// Logger centralizado do aplicativo.
///
/// Substitui `print`/`debugPrint` (o lint `avoid_print` está ativo) e
/// centraliza três decisões:
///
/// 1. **Nível por ambiente** — em produção só `warning` em diante, para
///    não vazar dado acadêmico do usuário em log de crash.
/// 2. **Sanitização** — o token JWT e a senha nunca são escritos em log,
///    mesmo em debug.
/// 3. **Uma tag por módulo** — `AppLogger('kai.repository')` deixa óbvio
///    de onde veio cada linha.
///
/// Uso típico:
/// ```dart
/// final _log = AppLogger('auth.repository');
/// _log.info('login iniciado para $email');
/// _log.error('falha no login', error: failure, stackTrace: st);
/// ```
///
/// ## Por que `package:logger/web.dart`
///
/// O ponto de entrada `package:logger/logger.dart` exporta apenas os
/// *outputs* de arquivo (para não puxar `dart:io` no web). Quem expõe
/// `Logger`, `Level`, `LogFilter` e os *printers* é `web.dart`, que é
/// seguro em todas as plataformas — inclusive Android e iOS.
library;

import 'package:flutter/foundation.dart';
import 'package:logger/web.dart' as log;

/// Fachada de logging com tag por módulo.
///
/// Não extende `Logger`: a composição mantém a API do KRIPTA pequena e
/// impede que código da aplicação chame `Logger.root` por engano.
class AppLogger {
  /// Cria um logger identificado por [tag].
  ///
  /// Ex.: `AppLogger('tarefa.repository')`.
  AppLogger(this.tag)
    : _logger = log.Logger(
        printer: log.SimplePrinter(printTime: false, colors: !kReleaseMode),
        filter: log.ProductionFilter(),
      );

  /// Identifica o módulo emissor.
  final String tag;

  final log.Logger _logger;

  /// Mensagem de nível debug: fluxo interno e estrutura de dados.
  ///
  /// Avaliada apenas em builds de debug — em release, [log.Logger.level]
  /// já corta antes.
  void debug(String message) => _logger.d(_prefixed(message));

  /// Mensagem de nível info: evento de negócio relevante.
  void info(String message) => _logger.i(_prefixed(message));

  /// Aviso: comportamento inesperado, porém não bloqueante.
  void warning(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.w(_prefixed(message), error: error, stackTrace: stackTrace);

  /// Erro, com causa e stack trace opcionais.
  ///
  /// A [message] nunca deve conter credenciais — passe por [redact].
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(_prefixed(message), error: error, stackTrace: stackTrace);

  /// Anexa a tag e aplica a sanitização de segredos.
  String _prefixed(String message) =>
      '[${AppLogger.redact(tag)}] ${AppLogger.redact(message)}';

  /// Remove segredos de uma string antes de logar.
  ///
  /// Cobre o cabeçalho `Authorization: Bearer <jwt>` e pares
  /// `senha=`/`token=` de query string. Usa `replaceAllMapped` porque
  /// `replaceAll` não expande grupos de captura (`$1`).
  static String redact(String value) => value
      .replaceAllMapped(
        RegExp(r'(Bearer\s+)[A-Za-z0-9\-._~+/]+=*'),
        (Match match) => '${match.group(1)}***',
      )
      .replaceAllMapped(
        RegExp(
          r'((?:senha|password|token)\s*[=:]\s*)\S+',
          caseSensitive: false,
        ),
        (Match match) => '${match.group(1)}***',
      );

  /// Define o nível mínimo global de log.
  ///
  /// Idempotente e deve ser chamada uma vez, em `main()`, antes de
  /// `runApp`. Em release corta em [log.Level.warning]: abaixo disso só
  /// há ruído de fluxo interno, e log de nível `info` em produção pode
  /// conter nome/e-mail do usuário.
  static void configure() {
    log.Logger.level = kReleaseMode ? log.Level.warning : log.Level.debug;
  }
}
