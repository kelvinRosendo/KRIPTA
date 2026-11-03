/// Tipo de retorno das operações de domínio.
///
/// Substitui o par "lança exceção / retorna valor". O controle de fluxo
/// fica explícito no tipo, o analyzer obriga a tratar o caso de erro, e o
/// teste compara sem `try`/`catch`.
///
/// Uso típico:
/// ```dart
/// final result = await repo.listar();
/// return switch (result) {
///   Success(:final value) => value,
///   FailureResult(:final failure) => throw failure,
/// };
/// ```
library;

import 'package:equatable/equatable.dart';

import '../error/failure.dart';

/// Resultado de uma operação que pode falhar.
sealed class Result<T> extends Equatable {
  const Result();

  /// Cria um resultado de sucesso.
  const factory Result.success(T value) = Success<T>;

  /// Cria um resultado de erro.
  const factory Result.failure(Failure failure) = FailureResult<T>;

  /// `true` quando a operação foi bem-sucedida.
  bool get isSuccess => this is Success<T>;

  /// `true` quando a operação falhou.
  bool get isFailure => this is FailureResult<T>;

  /// Valor em caso de sucesso; `null` em caso de falha.
  T? get valueOrNull => switch (this) {
    Success<T>(:final value) => value,
    FailureResult<T>() => null,
  };

  /// Erro em caso de falha; `null` em caso de sucesso.
  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    FailureResult<T>(:final failure) => failure,
  };

  /// Executa um dos dois ramos, com *pattern matching*.
  ///
  /// Os parâmetros se chamam `casoSucesso`/`casoFalha` para não sombrear as
  /// variáveis dos padrões, que precisam usar o nome real dos campos
  /// (`value` e `failure`).
  R when<R>({
    required R Function(T value) casoSucesso,
    required R Function(Failure failure) casoFalha,
  }) => switch (this) {
    Success<T>(:final value) => casoSucesso(value),
    FailureResult<T>(:final failure) => casoFalha(failure),
  };

  /// Transforma o valor de sucesso, preservando o erro.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Success<T>(:final value) => Success<R>(transform(value)),
    FailureResult<T>(:final failure) => FailureResult<R>(failure),
  };

  /// Substitui a [Failure] por outra, sem tocar no valor de sucesso.
  ///
  /// Existe para o caso em que o repositório quer ajustar a *mensagem* de
  /// um erro conhecido sem perder a [Failure] original: o
  /// [KaiRepositoryImpl] usa isto para trocar o 404 genérico por "o Kai
  /// chega em breve", preservando `statusCode` e `code`.
  ///
  /// Diferente de [when], o tipo de retorno é [Result] e não genérico — o
  /// que evita a inferência ambígua do `R` dentro de um método `async`.
  Result<T> mapFailure(Failure Function(Failure failure) transform) =>
      switch (this) {
        Success<T>(:final value) => Success<T>(value),
        FailureResult<T>(:final failure) => FailureResult<T>(
          transform(failure),
        ),
      };

  @override
  List<Object?> get props => switch (this) {
    Success<T>(:final T value) => <Object?>[value],
    FailureResult<T>(:final Failure failure) => <Object?>[failure],
  };
}

/// Ramo de sucesso.
final class Success<T> extends Result<T> {
  /// Cria o sucesso com [value].
  const Success(this.value);

  /// Valor produzido pela operação.
  final T value;

  @override
  String toString() => 'Success($value)';
}

/// Ramo de erro.
final class FailureResult<T> extends Result<T> {
  /// Cria o erro com [failure].
  const FailureResult(this.failure);

  /// Motivo da falha, já traduzido do erro técnico.
  final Failure failure;

  @override
  String toString() => 'FailureResult($failure)';
}
