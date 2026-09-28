/// Modelo de erro da camada de domínio.
///
/// A regra do projeto é: **nenhuma `DioException`, `JsonException` ou
/// `Exception` crua atravessa a fronteira de um repositório**. Tudo vira
/// [Failure], que é agnóstico de rede e comparável — assim a UI decide o
/// que exibir e os testes comparam erros sem depender de HTTP.
///
/// Organização:
/// - [core/error/api_error_mapper.dart] converte exceções técnicas em
///   [Failure];
/// - [data/repositories/] converte [Failure] em erro de domínio da feature;
/// - `features/*/presentation` só enxerga [Failure].
library;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'api_error_codes.dart';

/// Categoria do erro, usada para decidir a ação da UI.
enum FailureKind {
  /// Não houve resposta do servidor: sem rede, DNS, TLS, timeout.
  ///
  /// Ação típica da UI: botão "Tentar novamente".
  rede,

  /// O servidor respondeu 401: token ausente, inválido ou expirado.
  naoAutenticado,

  /// Resposta 403: autenticado, porém sem permissão (RN04).
  naoAutorizado,

  /// Recurso inexistente (404).
  ///
  /// Sinal típico de endpoint ainda não implementado no backend — a UI
  /// deve tratar como "funcionalidade em breve", não como bug.
  naoEncontrado,

  /// Erro de validação de campos (HTTP 400 com `error: VALIDACAO`).
  ///
  /// [Failure.fieldErrors] associa o nome do campo à mensagem do backend,
  /// para exibir o erro embaixo do `TextField` correspondente.
  validacao,

  /// Conflito de estado (409): e-mail ou disciplina já existe.
  conflito,

  /// O payload não corresponde ao contrato do DTO.
  ///
  /// Bug de integração entre mobile e backend. Aparece em log, mas a
  /// mensagem mostrada ao usuário é genérica.
  contratoInvalido,

  /// Falha inesperada não classificada.
  inesperado,
}

/// Erro de domínio, imutável e comparável.
///
/// Selada: `switch` sobre [kind] obriga o analyzer a apontar todo novo
/// tipo de falha sem tratamento.
@immutable
sealed class Failure extends Equatable {
  const Failure({
    required this.message,
    this.code = ApiErrorCode.desconhecido,
    this.statusCode,
  });

  /// Texto pronto para exibição, vindo do campo `message` do backend ou
  /// de uma mensagem padrão escolhida pelo mapeador.
  final String message;

  /// Código de negócio do backend, quando presente.
  final ApiErrorCode code;

  /// Status HTTP, quando a falha veio de resposta do servidor.
  final int? statusCode;

  /// Categoria do erro para decisão de UI.
  FailureKind get kind;

  /// Erros por campo vindos de `VALIDACAO` (chave = nome do campo no DTO).
  Map<String, String> get fieldErrors => const <String, String>{};

  /// `true` quando repetir a mesma requisição pode funcionar.
  ///
  /// Só falhas transitórias são retentáveis: erro de contrato e erro de
  /// validação repetem igualmente, então insistir só gasta bateria e banda.
  bool get isRetryable =>
      kind == FailureKind.rede || kind == FailureKind.inesperado;

  @override
  List<Object?> get props => <Object?>[runtimeType, message, code, statusCode];
}

/// Não foi possível falar com o servidor.
///
/// Cobre: sem conexão, timeout de conexão/recepção/envio e erro de socket.
final class NetworkFailure extends Failure {
  /// Cria a falha de rede.
  const NetworkFailure({required super.message, super.statusCode, super.code});

  @override
  FailureKind get kind => FailureKind.rede;
}

/// Sessão inválida ou expirada (HTTP 401).
///
/// O [AuthInterceptor] dispara o logout automático ao ver este código; a
/// UI não precisa tratar 401 manualmente.
final class UnauthorizedFailure extends Failure {
  /// Cria a falha de sessão expirada.
  const UnauthorizedFailure({
    required super.message,
    super.statusCode,
    super.code,
  });

  @override
  FailureKind get kind => FailureKind.naoAutenticado;
}

/// Autenticado, porém sem permissão (HTTP 403).
final class ForbiddenFailure extends Failure {
  /// Cria a falha de autorização.
  const ForbiddenFailure({
    required super.message,
    super.statusCode,
    super.code,
  });

  @override
  FailureKind get kind => FailureKind.naoAutorizado;
}

/// Recurso inexistente (HTTP 404).
final class NotFoundFailure extends Failure {
  /// Cria a falha de recurso ausente.
  const NotFoundFailure({required super.message, super.statusCode, super.code});

  @override
  FailureKind get kind => FailureKind.naoEncontrado;
}

/// Campos inválidos (HTTP 400 / `VALIDACAO`).
final class ValidationFailure extends Failure {
  /// Cria a falha com o mapa de erros por campo.
  const ValidationFailure({
    required super.message,
    super.statusCode,
    super.code,
    this._fieldErrors = const <String, String>{},
  });

  /// Mapa de campo para mensagem, exatamente como o backend envia.
  ///
  /// Fica privado porque [Failure] é selada: assim nenhum outro subtipo
  /// pode declarar `fieldErrors` e quebrar o `switch` do `kind`.
  final Map<String, String> _fieldErrors;

  @override
  Map<String, String> get fieldErrors => _fieldErrors;

  @override
  FailureKind get kind => FailureKind.validacao;

  @override
  List<Object?> get props => <Object?>[
    ...super.props,
    // Ordenar as chaves torna a comparação determinística em teste,
    // independentemente da ordem de inserção.
    (_fieldErrors.keys.toList()..sort()).join(','),
    _fieldErrors.values.join('|'),
  ];
}

/// Conflito de unicidade (HTTP 409).
final class ConflictFailure extends Failure {
  /// Cria a falha de conflito.
  const ConflictFailure({required super.message, super.statusCode, super.code});

  @override
  FailureKind get kind => FailureKind.conflito;
}

/// Payload incompatível com o contrato do DTO.
///
/// Bug de integração: o backend mudou o JSON e o mobile ainda espera o
/// formato antigo. Sempre logar com o corpo da resposta.
final class ContractFailure extends Failure {
  /// Cria a falha de contrato.
  const ContractFailure({
    required super.message,
    super.statusCode,
    super.code,
    this.rawBody,
  });

  /// Corpo bruto recebido, só para diagnóstico. Nunca exibido ao usuário.
  final String? rawBody;

  @override
  FailureKind get kind => FailureKind.contratoInvalido;

  @override
  List<Object?> get props => <Object?>[...super.props, rawBody];
}

/// Erro não classificado.
final class UnexpectedFailure extends Failure {
  /// Cria a falha inesperada.
  const UnexpectedFailure({
    required super.message,
    super.statusCode,
    super.code,
  });

  @override
  FailureKind get kind => FailureKind.inesperado;
}
