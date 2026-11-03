/// Repositórios de gamificação, dashboard e do agente de IA (Kai).
library;

import 'package:dio/dio.dart';

import '../../core/config/api_endpoints.dart';
import '../../core/error/failure.dart';
import '../../core/logging/app_logger.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../dto/dto.dart';
import '../mappers/dto_mapper.dart';
import 'api_repository_base.dart';

/// Repositório de gamificação: nível, XP, insígnias e progresso.
class GamificacaoRepositoryImpl extends ApiRepositoryBase
    implements GamificacaoRepository {
  /// Cria o repositório.
  GamificacaoRepositoryImpl({required super.dio});

  @override
  final AppLogger log = AppLogger('gamificacao.repository');

  @override
  Future<Result<EstatisticasGamificacao>> estatisticas() {
    return guard<EstatisticasGamificacao>(() async {
      final resposta = await dio.get<Object>(ApiEndpoints.gamificationStats);
      return DtoMapper.estatisticas(
        EstatisticasGamificacaoDto.fromJson(corpoJson(resposta)),
      );
    });
  }

  @override
  Future<Result<List<Conquista>>> conquistas() {
    return guard<List<Conquista>>(() async {
      final resposta = await dio.get<Object>(ApiEndpoints.achievements);
      return DtoMapper.conquistas(
        decodificarLista(resposta, ConquistaDto.fromJson),
      );
    });
  }

  @override
  Future<Result<Progresso>> progresso() {
    return guard<Progresso>(() async {
      final resposta = await dio.get<Object>(ApiEndpoints.progress);
      return DtoMapper.progresso(ProgressoDto.fromJson(corpoJson(resposta)));
    });
  }
}

/// Repositório da visão agregada da Home.
class DashboardRepositoryImpl extends ApiRepositoryBase
    implements DashboardRepository {
  /// Cria o repositório.
  DashboardRepositoryImpl({required super.dio});

  @override
  final AppLogger log = AppLogger('dashboard.repository');

  @override
  Future<Result<Dashboard>> carregar() {
    return guard<Dashboard>(() async {
      final resposta = await dio.get<Object>(ApiEndpoints.dashboard);
      return DtoMapper.dashboard(DashboardDto.fromJson(corpoJson(resposta)));
    });
  }
}

/// Repositório do agente de IA — o **Kai**.
///
/// ## Decisões de projeto
///
/// - O mobile **nunca** fala com OpenAI/Gemini direto: a chave fica no
///   servidor, que aplica os limites de uso e o filtro de conteúdo (RN06).
///   O frontend web segue a mesma regra (`services/kai.js`).
/// - Não existe controller de IA no backend ainda. Um `404` aqui é
///   **esperado**, não é bug: a tela do chat mostra "o Kai chega em breve"
///   e continua navegável. Por isso [enviar] traduz o
///   [FailureKind.naoEncontrado] em uma falha de serviço indisponível, com
///   mensagem própria, em vez de um genérico "recurso não encontrado".
class KaiRepositoryImpl extends ApiRepositoryBase implements KaiRepository {
  /// Cria o repositório.
  KaiRepositoryImpl({required super.dio});

  @override
  final AppLogger log = AppLogger('kai.repository');

  /// Mensagem mostrada enquanto o endpoint de IA não existe no backend.
  static const String mensagemIndisponivel =
      'O Kai ainda está em construção. Estamos preparando essa conversa.';

  @override
  Future<Result<RespostaKai>> enviar(String mensagem) async {
    final resultado = await guard<RespostaKai>(() async {
      final resposta = await dio.post<Object>(
        ApiEndpoints.kaiChat,
        data: KaiChatRequestDto(message: mensagem.trim()).toJson(),
      );

      final dto = KaiChatResponseDto.fromJson(corpoJson(resposta));
      final entidade = DtoMapper.respostaKai(dto);
      if (entidade == null) {
        // `reply` vazio: tratar como falha evita um balão em branco.
        throw const FormatException('resposta do Kai sem conteúdo');
      }
      return entidade;
    });

    return resultado.mapFailure(_traduzirEndpointInexistente);
  }

  @override
  Future<Result<bool>> disponivel() async {
    final resultado = await guard<bool>(() async {
      // Não existe endpoint de "health" do Kai. A checagem usa o próprio
      // chat com uma pergunta mínima: se responder 200, o serviço está de
      // pé. Uma chamada de verdade é melhor que adivinhar por status de
      // outro endpoint, que pode estar no ar enquanto a IA não está.
      final resposta = await dio.post<Object>(
        ApiEndpoints.kaiChat,
        data: const KaiChatRequestDto(message: 'ping').toJson(),
        // Uma chamada de diagnóstico não deve ficar na tela do aluno como
        // mensagem enviada: o chat ignora respostas sem `reply` útil.
        options: Options(
          extra: const <String, Object>{'kripta.silencioso': true},
        ),
      );
      return corpoJson(resposta).isNotEmpty;
    });

    return resultado.mapFailure(_traduzirEndpointInexistente);
  }

  /// Converte "endpoint de IA não existe" em falha com mensagem de
  /// functionality em breve.
  ///
  /// Só o [FailureKind.naoEncontrado] é convertido: rede, validação e
  /// 401 continuam reporting o que realmente aconteceu, senão o aluno
  /// receberia "o Kai está em breve" quando o problema é senha expirada.
  Failure _traduzirEndpointInexistente(Failure falha) {
    if (falha.kind != FailureKind.naoEncontrado) return falha;

    log.info('endpoint de IA ainda não publicado no backend');
    return NotFoundFailure(
      message: mensagemIndisponivel,
      statusCode: falha.statusCode,
      code: falha.code,
    );
  }
}
