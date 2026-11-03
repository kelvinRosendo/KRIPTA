/// Mapeamento de exceções técnicas do `dio` para o modelo [Failure].
///
/// Ponto único de tradução. Nenhum outro arquivo deve conhecer
/// `DioException` — assim, se o cliente HTTP for trocado, só este arquivo
/// muda.
///
/// ## Formato de erro do backend
///
/// `GlobalExceptionHandler` (branch `feature/backend-users`) responde:
/// ```json
/// { "timestamp": "...", "status": "error",
///   "error": "VALIDACAO", "message": "Dados inválidos",
///   "errors": { "email": "Email deve ser válido" } }
/// ```
library;

import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/api_endpoints.dart';
import '../error/api_error_codes.dart';
import '../error/failure.dart';
import '../logging/app_logger.dart';

/// Converte qualquer erro vindo do cliente HTTP em [Failure].
abstract final class ApiErrorMapper {
  /// Log do mapper, para diagnóstico de contrato.
  static final AppLogger _log = AppLogger('api_error_mapper');

  /// Converte uma [DioException].
  ///
  /// A ordem das checagens importa: é preciso testar o `response` antes
  /// do `type`, porque `DioExceptionType.badResponse` carrega o corpo do
  /// servidor, que tem a informação mais específica.
  static Failure fromDioException(DioException error) {
    final response = error.response;
    if (response == null) return _fromTransportError(error);

    final status = response.statusCode ?? 0;
    final envelope = _parseErrorBody(response.data, status);

    // Um 401 fora das rotas de login/cadastro significa token expirado:
    // o AuthInterceptor dispara o logout, mas o erro ainda precisa
    // chegar ao chamador com a mensagem do servidor.
    if (status == 401) {
      return UnauthorizedFailure(
        message: envelope.message,
        code: envelope.code,
        statusCode: status,
      );
    }

    return switch (status) {
      400 || 422 => ValidationFailure(
        message: envelope.message,
        code: envelope.code,
        statusCode: status,
        fieldErrors: envelope.fieldErrors,
      ),
      403 => ForbiddenFailure(
        message: envelope.message,
        code: envelope.code,
        statusCode: status,
      ),
      404 => NotFoundFailure(
        message: envelope.message,
        code: envelope.code,
        statusCode: status,
      ),
      409 => ConflictFailure(
        message: envelope.message,
        code: envelope.code,
        statusCode: status,
      ),
      _ => UnexpectedFailure(
        message: envelope.message,
        code: envelope.code,
        statusCode: status,
      ),
    };
  }

  /// Erros sem resposta do servidor: DNS, TLS, socket, timeout, cancelamento.
  static Failure _fromTransportError(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const NetworkFailure(
        message: 'O servidor demorou para responder. Verifique sua conexão.',
      ),
      DioExceptionType.connectionError => const NetworkFailure(
        message:
            'Não foi possível conectar ao servidor. Verifique sua conexão.',
      ),
      DioExceptionType.cancel => const NetworkFailure(
        message: 'Requisição cancelada.',
      ),
      // `unknown` cobre erro de TLS, corpo ilegível e falha de socket em
      // plataforma específica: tratar como rede é o mais seguro para a UI.
      _ => const NetworkFailure(
        message: 'Não foi possível falar com o servidor. Tente novamente.',
      ),
    };
  }

  /// Erro de desserialização: o JSON não bate com o DTO.
  ///
  /// Sinaliza bug de contrato. Loga o corpo para diagnóstico, mas a
  /// mensagem exibida é genérica.
  static Failure fromParseError(
    Object error,
    StackTrace stackTrace, {
    String? rawBody,
  }) {
    _log.error(
      'falha ao desserializar resposta',
      error: error,
      stackTrace: stackTrace,
    );
    return ContractFailure(
      message: 'Recebemos uma resposta inesperada do servidor.',
      rawBody: rawBody,
    );
  }

  /// Extrai `error`, `message` e `errors` do corpo de resposta.
  ///
  /// Devolve o envelope do backend quando reconhecível; caso contrário,
  /// cai na mensagem genérica do [httpStatus]. Nunca lança: um corpo
  /// inesperado não pode mascarar o erro original.
  static _ErrorEnvelope _parseErrorBody(Object? data, int httpStatus) {
    if (data is! Map) {
      return _ErrorEnvelope(
        message: HttpStatusMessages.forStatus(httpStatus),
        code: ApiErrorCode.desconhecido,
      );
    }
    final map = data.map(
      (Object? key, Object? value) => MapEntry('$key', value),
    );
    final rawMessage = map['message']?.toString();
    final code = ApiErrorCode.fromWire(map['error']?.toString());
    final fallback = HttpStatusMessages.forStatus(httpStatus);

    return _ErrorEnvelope(
      message: (rawMessage == null || rawMessage.isEmpty)
          ? fallback
          : rawMessage,
      code: code,
      fieldErrors: _parseFieldErrors(map['errors']),
    );
  }

  /// Converte o mapa `errors` do `VALIDACAO` em `Map<String, String>`.
  static Map<String, String> _parseFieldErrors(Object? raw) {
    if (raw is! Map) return const <String, String>{};
    return <String, String>{
      for (final entry in raw.entries) '${entry.key}': '${entry.value}',
    };
  }

  /// Converte o corpo de um erro em texto legível, para log.
  ///
  /// Nunca lança, mesmo com corpo não-serializável.
  static String? safeStringify(Object? data) {
    if (data == null) return null;
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } on JsonUnsupportedObjectError {
      return data.toString();
    } on FormatException {
      return data.toString();
    }
  }
}

/// Conteúdo útil do corpo de erro devolvido pelo backend.
class _ErrorEnvelope {
  const _ErrorEnvelope({
    required this.message,
    required this.code,
    this.fieldErrors = const <String, String>{},
  });

  /// Mensagem exibível, já com fallback por status HTTP.
  final String message;

  /// Código de negócio do backend.
  final ApiErrorCode code;

  /// Erros por campo, só presente em `VALIDACAO`.
  final Map<String, String> fieldErrors;
}
