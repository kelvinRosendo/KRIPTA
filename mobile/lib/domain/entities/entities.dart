/// Entidades do domínio do KRIPTA.
///
/// Imutáveis e independentes de Flutter e de JSON: a camada `data/`
/// converte DTO em entidade, e a UI lê apenas entidades. Nenhuma entidade
/// conhece `DioException`, `BuildContext` ou `Color`.
library;

export 'conteudo.dart';
export 'dashboard.dart';
export 'evento_calendario.dart';
export 'gamificacao.dart';
export 'kai.dart';
export 'usuario.dart';
