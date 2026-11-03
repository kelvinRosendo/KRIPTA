/// Ponto de entrada único da camada `data`.
///
/// A camada de apresentação injeta **estas** classes, nunca as
/// implementações diretamente — assim um dublê em memória substitui a
/// rede inteira em teste.
///
/// ```dart
/// final provider = Provider<AuthRepository>(
///   (Ref ref) => AuthRepositoryImpl(
///     dio: ref.watch(apiClientProvider).dio,
///     tokenStore: ref.watch(tokenStoreProvider),
///   ),
/// );
/// ```
library;

export 'api_repository_base.dart';
export 'auth_repository_impl.dart';
export 'repositorio_conteudo.dart';
export 'repositorio_gamificacao.dart';
