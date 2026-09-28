/// Repositórios de conteúdo acadêmico: disciplinas, unidades, materiais,
/// tarefas, calendário e avisos.
///
/// Todos compartilham a mesma forma:
///
/// ```dart
/// return guard<List<Disciplina>>(() async {
///   final resposta = await dio.get<Object>(ApiEndpoints.disciplines);
///   return DtoMapper.disciplinas(decodificarLista(resposta, (json) => ...));
/// });
/// ```
///
/// Nenhum deles conhece `DioException` nem `json_serializable`: as duas
/// decisões ficam em [ApiRepositoryBase] e em [DtoMapper].
library;

import '../../core/config/api_endpoints.dart';
import '../../core/logging/app_logger.dart';
import '../../core/utils/app_date_format.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../dto/dto.dart';
import '../mappers/dto_mapper.dart';
import 'api_repository_base.dart';

/// Repositório de disciplinas.
///
/// Único repositório de conteúdo com endpoints **já implementados** no
/// backend (branch `feature/backend-users`).
class DisciplinaRepositoryImpl extends ApiRepositoryBase
    implements DisciplinaRepository {
  /// Cria o repositório.
  DisciplinaRepositoryImpl({required super.dio});

  @override
  final AppLogger log = AppLogger('disciplina.repository');

  @override
  Future<Result<List<Disciplina>>> listar() {
    return guard<List<Disciplina>>(() async {
      final resposta = await dio.get<Object>(ApiEndpoints.disciplines);
      return DtoMapper.disciplinas(
        decodificarLista(resposta, DisciplinaResponseDto.fromJson),
      );
    });
  }

  @override
  Future<Result<Disciplina>> buscar(int id) {
    return guard<Disciplina>(() async {
      final resposta = await dio.get<Object>(ApiEndpoints.disciplineById(id));
      return DtoMapper.disciplina(
        DisciplinaResponseDto.fromJson(corpoJson(resposta)),
      );
    });
  }

  @override
  Future<Result<Disciplina>> criar({
    required String nome,
    required String cor,
  }) {
    return guard<Disciplina>(() async {
      final resposta = await dio.post<Object>(
        ApiEndpoints.disciplines,
        data: DisciplinaRequestDto(nome: nome.trim(), cor: cor).toJson(),
      );
      return DtoMapper.disciplina(
        DisciplinaResponseDto.fromJson(corpoJson(resposta)),
      );
    });
  }

  @override
  Future<Result<Disciplina>> atualizar({
    required int id,
    required String nome,
    required String cor,
  }) {
    return guard<Disciplina>(() async {
      final resposta = await dio.put<Object>(
        ApiEndpoints.disciplineById(id),
        data: DisciplinaRequestDto(nome: nome.trim(), cor: cor).toJson(),
      );
      return DtoMapper.disciplina(
        DisciplinaResponseDto.fromJson(corpoJson(resposta)),
      );
    });
  }

  @override
  Future<Result<void>> excluir(int id) {
    return guard<void>(() async {
      final resposta = await dio.delete<Object>(
        ApiEndpoints.disciplineById(id),
      );
      corpoVazioOu<void>(resposta, () {});
    });
  }
}

/// Repositório de unidades curriculares.
class UnidadeRepositoryImpl extends ApiRepositoryBase
    implements UnidadeRepository {
  /// Cria o repositório.
  UnidadeRepositoryImpl({required super.dio});

  @override
  final AppLogger log = AppLogger('unidade.repository');

  @override
  Future<Result<List<Unidade>>> listar(int disciplinaId) {
    return guard<List<Unidade>>(() async {
      final resposta = await dio.get<Object>(
        ApiEndpoints.unitsByDiscipline(disciplinaId),
      );
      return DtoMapper.unidades(
        decodificarLista(resposta, UnidadeResponseDto.fromJson),
      );
    });
  }

  @override
  Future<Result<Unidade>> criar({
    required int disciplinaId,
    required String nome,
    String? descricao,
  }) {
    return guard<Unidade>(() async {
      final resposta = await dio.post<Object>(
        ApiEndpoints.unitsByDiscipline(disciplinaId),
        data: UnidadeRequestDto(
          name: nome.trim(),
          description: descricao?.trim(),
        ).toJson(),
      );
      return DtoMapper.unidade(
        UnidadeResponseDto.fromJson(corpoJson(resposta)),
      );
    });
  }

  @override
  Future<Result<Unidade>> atualizar({
    required int id,
    required String nome,
    String? descricao,
  }) {
    return guard<Unidade>(() async {
      final resposta = await dio.put<Object>(
        ApiEndpoints.unitById(id),
        data: UnidadeRequestDto(
          name: nome.trim(),
          description: descricao?.trim(),
        ).toJson(),
      );
      return DtoMapper.unidade(
        UnidadeResponseDto.fromJson(corpoJson(resposta)),
      );
    });
  }

  @override
  Future<Result<void>> excluir(int id) {
    return guard<void>(() async {
      final resposta = await dio.delete<Object>(ApiEndpoints.unitById(id));
      corpoVazioOu<void>(resposta, () {});
    });
  }
}

/// Repositório de materiais de estudo.
class MaterialRepositoryImpl extends ApiRepositoryBase
    implements MaterialRepository {
  /// Cria o repositório.
  MaterialRepositoryImpl({required super.dio});

  @override
  final AppLogger log = AppLogger('MaterialEstudo.repository');

  @override
  Future<Result<List<MaterialEstudo>>> listarPorUnidade(int unidadeId) {
    return guard<List<MaterialEstudo>>(() async {
      final resposta = await dio.get<Object>(
        ApiEndpoints.materialsByUnit(unidadeId),
      );
      return DtoMapper.materiais(
        decodificarLista(resposta, MaterialResponseDto.fromJson),
      );
    });
  }

  @override
  Future<Result<MaterialEstudo>> criar({
    required int unidadeId,
    required String titulo,
    required TipoMaterial tipo,
    String? url,
    String? descricao,
  }) {
    return guard<MaterialEstudo>(() async {
      final resposta = await dio.post<Object>(
        ApiEndpoints.materialsByUnit(unidadeId),
        data: MaterialRequestDto(
          title: titulo.trim(),
          type: tipo.wire,
          url: url?.trim(),
          description: descricao?.trim(),
        ).toJson(),
      );
      return DtoMapper.material(
        MaterialResponseDto.fromJson(corpoJson(resposta)),
      );
    });
  }

  @override
  Future<Result<MaterialEstudo>> atualizar({
    required int id,
    required String titulo,
    required TipoMaterial tipo,
    String? url,
    String? descricao,
  }) {
    return guard<MaterialEstudo>(() async {
      final resposta = await dio.put<Object>(
        ApiEndpoints.materialById(id),
        data: MaterialRequestDto(
          title: titulo.trim(),
          type: tipo.wire,
          url: url?.trim(),
          description: descricao?.trim(),
        ).toJson(),
      );
      return DtoMapper.material(
        MaterialResponseDto.fromJson(corpoJson(resposta)),
      );
    });
  }

  @override
  Future<Result<MaterialEstudo>> alternarConclusao(int id) {
    return guard<MaterialEstudo>(() async {
      final resposta = await dio.patch<Object>(
        ApiEndpoints.completeMaterial(id),
      );
      return DtoMapper.material(
        MaterialResponseDto.fromJson(corpoJson(resposta)),
      );
    });
  }

  @override
  Future<Result<void>> excluir(int id) {
    return guard<void>(() async {
      final resposta = await dio.delete<Object>(ApiEndpoints.materialById(id));
      corpoVazioOu<void>(resposta, () {});
    });
  }
}

/// Repositório de tarefas.
class TarefaRepositoryImpl extends ApiRepositoryBase
    implements TarefaRepository {
  /// Cria o repositório.
  TarefaRepositoryImpl({required super.dio});

  @override
  final AppLogger log = AppLogger('tarefa.repository');

  @override
  Future<Result<List<Tarefa>>> listar({StatusTarefa? status}) {
    return guard<List<Tarefa>>(() async {
      final resposta = await dio.get<Object>(
        ApiEndpoints.tasks,
        // Sem filtro, a query é omitida em vez de mandar `status=` vazio.
        queryParameters: status == null
            ? null
            : <String, dynamic>{'status': status.wire},
      );
      return DtoMapper.tarefas(
        decodificarLista(resposta, TarefaResponseDto.fromJson),
      );
    });
  }

  @override
  Future<Result<Tarefa>> buscar(int id) {
    return guard<Tarefa>(() async {
      final resposta = await dio.get<Object>(ApiEndpoints.taskById(id));
      return DtoMapper.tarefa(TarefaResponseDto.fromJson(corpoJson(resposta)));
    });
  }

  @override
  Future<Result<Tarefa>> criar({
    required String titulo,
    String? descricao,
    DateTime? prazo,
    PrioridadeTarefa prioridade = PrioridadeTarefa.media,
    int? disciplinaId,
  }) {
    return guard<Tarefa>(() async {
      final resposta = await dio.post<Object>(
        ApiEndpoints.tasks,
        data: _corpo(
          titulo: titulo,
          descricao: descricao,
          prazo: prazo,
          prioridade: prioridade,
          disciplinaId: disciplinaId,
        ),
      );
      return DtoMapper.tarefa(TarefaResponseDto.fromJson(corpoJson(resposta)));
    });
  }

  @override
  Future<Result<Tarefa>> atualizar({
    required int id,
    required String titulo,
    String? descricao,
    DateTime? prazo,
    required PrioridadeTarefa prioridade,
    int? disciplinaId,
  }) {
    return guard<Tarefa>(() async {
      final resposta = await dio.put<Object>(
        ApiEndpoints.taskById(id),
        data: _corpo(
          titulo: titulo,
          descricao: descricao,
          prazo: prazo,
          prioridade: prioridade,
          disciplinaId: disciplinaId,
        ),
      );
      return DtoMapper.tarefa(TarefaResponseDto.fromJson(corpoJson(resposta)));
    });
  }

  @override
  Future<Result<Tarefa>> alternarConclusao(int id) {
    return guard<Tarefa>(() async {
      final resposta = await dio.patch<Object>(ApiEndpoints.completeTask(id));
      return DtoMapper.tarefa(TarefaResponseDto.fromJson(corpoJson(resposta)));
    });
  }

  @override
  Future<Result<void>> excluir(int id) {
    return guard<void>(() async {
      final resposta = await dio.delete<Object>(ApiEndpoints.taskById(id));
      corpoVazioOu<void>(resposta, () {});
    });
  }

  /// Monta o corpo de criação/atualização.
  ///
  /// `dueDate` vai em UTC ISO-8601 porque o Spring desserializa para
  /// `Instant`, que exige offset — mandar data local sem `Z` faz o
  /// backend recusar com `VALIDACAO`.
  Map<String, dynamic> _corpo({
    required String titulo,
    required String? descricao,
    required DateTime? prazo,
    required PrioridadeTarefa prioridade,
    required int? disciplinaId,
  }) {
    return TarefaRequestDto(
      title: titulo.trim(),
      description: descricao?.trim(),
      dueDate: prazo == null ? null : AppDateFormat.toApi(prazo),
      priority: prioridade.wire,
      subjectId: disciplinaId,
    ).toJson();
  }
}

/// Repositório do calendário.
class CalendarioRepositoryImpl extends ApiRepositoryBase
    implements CalendarioRepository {
  /// Cria o repositório.
  CalendarioRepositoryImpl({required super.dio});

  @override
  final AppLogger log = AppLogger('calendario.repository');

  @override
  Future<Result<List<EventoCalendario>>> listarPeriodo({
    required DateTime inicio,
    required DateTime fim,
  }) {
    return guard<List<EventoCalendario>>(() async {
      final resposta = await dio.get<Object>(
        ApiEndpoints.calendar,
        // `inicio`/`fim` em `yyyy-MM-dd`: o endpoint filtra por dia, e
        // mandar horário aqui deslocaria o dia na conversão.
        queryParameters: <String, dynamic>{
          'inicio': AppDateFormat.toApiDate(inicio),
          'fim': AppDateFormat.toApiDate(fim),
        },
      );
      return DtoMapper.eventos(
        decodificarLista(resposta, EventoCalendarioDto.fromJson),
      );
    });
  }
}

/// Repositório de avisos e comunicados.
class AvisoRepositoryImpl extends ApiRepositoryBase implements AvisoRepository {
  /// Cria o repositório.
  AvisoRepositoryImpl({required super.dio});

  @override
  final AppLogger log = AppLogger('aviso.repository');

  @override
  Future<Result<List<Aviso>>> listar() {
    return guard<List<Aviso>>(() async {
      final resposta = await dio.get<Object>(ApiEndpoints.announcements);
      // O mapper já ordena do mais recente para o mais antigo.
      return DtoMapper.avisos(
        decodificarLista(resposta, AvisoResponseDto.fromJson),
      );
    });
  }
}
