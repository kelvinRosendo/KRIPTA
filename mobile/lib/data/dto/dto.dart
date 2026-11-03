/// DTOs (Data Transfer Objects) do KRIPTA.
///
/// São a **única** camada que conhece o formato do JSON do backend.
/// Cada DTO:
///
/// - é gerado por `json_serializable` (`*.g.dart`, via `build_runner`);
/// - declara explicitamente o que vem do servidor e o que é opcional,
///   com `@JsonKey(name: ...)` quando o campo diverge do nome Dart;
/// - é convertido em entidade por `data/mappers/dto_mapper.dart`.
///
/// Nenhum DTO é usado direto pela UI.
///
/// ## Convenções de mapeamento
///
/// - Datas chegam como `Instant` ISO-8601 (`2026-09-28T12:00:00Z`) e são
///   convertidas para `DateTime` local no mapper.
/// - O backend usa nomes em **português** (`nome`, `email`, `senha`,
///   `disciplinas`); o DTO respeita isso e só a entidade usa português,
///   também. Não traduzir para inglês: quebraria a paridade com a API e
///   com o restante do projeto.
/// - Campos ausentes viram `null`, nunca exceção: um campo novo no backend
///   não pode derrubar o app.
library;

export 'dto_auth.dart';
export 'dto_conteudo.dart';
export 'dto_gamificacao.dart';
export 'dto_ia.dart';
export 'dto_resposta.dart';
