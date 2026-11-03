/// Base dos repositórios que falam com o backend via `dio`.
///
/// ## Por que uma classe base
///
/// Dez repositórios precisam das mesmas três coisas:
///
/// 1. converter exceção técnica em [Failure] ([ApiErrorMapper]);
/// 2. não deixar `FormatException`/`TypeError` do `json_serializable`
///    vazar para a UI — isso é [ContractFailure], bug de integração;
/// 3. decodificar listas tolerando itens quebrados.
///
/// Centralizar isso aqui garante que **nenhuma** `DioException` escape de
/// um repositório, que é a regra da camada `data`.
///
/// ## O que a base não faz
///
/// Ela não conhece nenhum endpoint. Rotas ficam em
/// `core/config/api_endpoints.dart` e a conversão de DTO em entidade fica
/// em `data/mappers/dto_mapper.dart` — assim a base continua genérica e o
/// comportamento de cada recurso fica explícito na sua implementação.
library;

import 'package:dio/dio.dart';

import '../../core/error/api_error_mapper.dart';
import '../../core/error/failure.dart';
import '../../core/logging/app_logger.dart';
import '../../core/utils/result.dart';

/// Utilitários compartilhados pelas implementações de repositório.
abstract class ApiRepositoryBase {
  /// Cria a base com a instância do `dio` compartilhada.
  ApiRepositoryBase({required this.dio});

  /// Cliente HTTP injetado. Compartilhado por todos os repositórios para
  /// aproveitar a mesma cadeia de interceptadores.
  final Dio dio;

  /// Logger do repositório, com a tag do módulo.
  ///
  /// Cada implementação declara o seu (`AppLogger('tarefa.repository')`),
  /// para que cada linha do log diga de onde veio.
  AppLogger get log;

  // ── Execução protegida ────────────────────────────────────────────

  /// Executa [acao] e embrulha o resultado em [Result].
  ///
  /// É o único ponto onde uma exceção vira [Failure]. Nenhum outro
  /// `try`/`catch` é necessário nos repositórios.
  Future<Result<T>> guard<T>(Future<T> Function() acao) async {
    try {
      return Success<T>(await acao());
    } on DioException catch (erro) {
      // Já mapeado com o corpo do servidor: 401, 400, 409, 404, 5xx etc.
      return FailureResult<T>(ApiErrorMapper.fromDioException(erro));
    } on FormatException catch (erro, pilha) {
      // JSON malformado ou campo com tipo inesperado.
      log.error('resposta fora do contrato', error: erro, stackTrace: pilha);
      return FailureResult<T>(contratoInvalido(erro));
    } on TypeError catch (erro, pilha) {
      // `json_serializable` jogando `TypeError` ao ler um campo com tipo
      // diferente do esperado — exatamente o cenário "backend mudou".
      log.error('campo com tipo inesperado', error: erro, stackTrace: pilha);
      return FailureResult<T>(contratoInvalido(erro));
    } on Object catch (erro, pilha) {
      // Rede, disco, plataforma: qualquer coisa fora das categorias acima.
      log.error('falha inesperada', error: erro, stackTrace: pilha);
      return FailureResult<T>(
        const UnexpectedFailure(
          message: 'Não foi possível concluir a operação.',
        ),
      );
    }
  }

  /// Converte falha de decodificação em [ContractFailure].
  ContractFailure contratoInvalido(Object erro) => ContractFailure(
    message: 'O servidor retornou um formato inesperado.',
    rawBody: ApiErrorMapper.safeStringify(erro),
  );

  // ── Decodificação ─────────────────────────────────────────────────

  /// Lê o corpo JSON de uma resposta, garantindo que é um mapa.
  ///
  /// Listas usam [decodificarLista]; qualquer outro tipo (ou `null`)
  /// indica quebra de contrato.
  Map<String, dynamic> corpoJson(Response<dynamic> resposta) {
    final dados = resposta.data;
    if (dados is Map<String, dynamic>) return dados;
    if (dados is Map) return dados.cast<String, dynamic>();
    throw FormatException(
      'esperado um objeto JSON, recebido ${dados.runtimeType}',
    );
  }

  /// Lê um corpo JSON que é uma lista de objetos.
  ///
  /// Aceita tanto o array puro (`[...]`) quanto o envelope
  /// `{"content": [...]}`, que é o formato do Spring Data.
  List<Map<String, dynamic>> corpoLista(Response<dynamic> resposta) {
    final dados = resposta.data;
    if (dados is List) return _objetos(dados);

    if (dados is Map) {
      final envelope = dados.cast<String, dynamic>();
      // O Spring Data pagina com estes nomes; o backend do KRIPTA ainda
      // não pagina, mas aceitar ambos evita uma quebra futura.
      const chaves = <String>['content', 'items', 'data', 'results'];
      for (final chave in chaves) {
        final lista = envelope[chave];
        if (lista is List) return _objetos(lista);
      }
    }
    throw FormatException(
      'esperado uma lista JSON, recebido ${dados.runtimeType}',
    );
  }

  /// Converte um `List<dynamic>` do JSON em `List<Map<String, dynamic>>`.
  ///
  /// O `cast` explícito é necessário: sem ele, `item` continua `dynamic` e
  /// o `.map` inferiria `List<dynamic>`, que não casa com o retorno.
  List<Map<String, dynamic>> _objetos(List<dynamic> itens) => itens
      .map((dynamic item) {
        if (item is Map) return item.cast<String, dynamic>();
        throw const FormatException('item da lista não é um objeto JSON');
      })
      .toList(growable: false);

  /// Decodifica uma lista de [T] pulando os itens ilegíveis.
  ///
  /// Um único registro com campo inesperado não pode esvaziar a tela
  /// inteira: o item é descartado e o resto é entregue. Os descarts vão
  /// para o log com o índice, para o time ver o que o backend mandou.
  List<T> decodificarLista<T>(
    Response<dynamic> resposta,
    T Function(Map<String, dynamic> json) construir,
  ) {
    final itens = corpoLista(resposta);
    final saida = <T>[];
    for (var i = 0; i < itens.length; i++) {
      try {
        saida.add(construir(itens[i]));
      } on Object catch (erro, pilha) {
        log.warning(
          'item $i da lista descartado: ${erro.runtimeType}',
          stackTrace: pilha,
        );
      }
    }
    return saida;
  }

  /// Converte um `204 No Content` — ou qualquer resposta sem corpo — em
  /// [T] usando [criar].
  ///
  /// Endpoints de exclusão e de troca de senha respondem `204`; o backend
  /// pode responder `200` com corpo em ambientes diferentes, então o
  /// repositório precisa lidar com os dois.
  T corpoVazioOu<T>(Response<dynamic> resposta, T Function() criar) {
    final dados = resposta.data;
    if (dados == null || (dados is String && dados.isEmpty)) return criar();
    throw FormatException(
      'esperado corpo vazio, recebido ${dados.runtimeType}',
    );
  }
}
