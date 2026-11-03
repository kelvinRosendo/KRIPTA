/// DTOs da visão agregada da Home (`GET /api/dashboard`).
///
/// ## Por que existe um endpoint agregado
///
/// A Home precisa de gamificação, total de insígnias e três listas de
/// tarefas. Sem agregação no servidor, a tela dispararia quatro requisições
/// a cada abertura — e o mock do frontend web já assume um único
/// `/dashboard` (`services/dev-data.js`).
///
/// ```json
/// { "stats": { "xp": 1240, "level": 4, "streak": 7 },
///   "badgesCount": 3,
///   "tasksToday": [ ... ], "tasksTomorrow": [ ... ], "overdueTasks": [ ... ] }
/// ```
library;

import 'package:json_annotation/json_annotation.dart';

import 'dto_gamificacao.dart';

part 'dto_resposta.g.dart';

/// Resposta de `GET /api/dashboard`.
@JsonSerializable(fieldRename: FieldRename.none)
class DashboardDto {
  /// Cria o dashboard.
  const DashboardDto({
    this.stats,
    this.badgesCount = 0,
    this.tasksToday = const <TarefaResumoDto>[],
    this.tasksTomorrow = const <TarefaResumoDto>[],
    this.overdueTasks = const <TarefaResumoDto>[],
  });

  /// Números do topo: XP, nível e sequência de dias.
  ///
  /// Anulável de propósito: `json_serializable` não aceita um objeto
  /// aninhado como `defaultValue`, e o padrão (`xp: 0, level: 1,
  /// streak: 0`) é uma decisão de apresentação, não de transporte. O
  /// [DtoMapper] aplica o fallback.
  @JsonKey(name: 'stats')
  final ResumoGamificacaoDto? stats;

  /// Quantidade de insígnias já conquistadas.
  @JsonKey(name: 'badgesCount', defaultValue: 0)
  final int badgesCount;

  /// Tarefas com prazo hoje.
  @JsonKey(name: 'tasksToday')
  final List<TarefaResumoDto> tasksToday;

  /// Tarefas com prazo amanhã.
  @JsonKey(name: 'tasksTomorrow')
  final List<TarefaResumoDto> tasksTomorrow;

  /// Tarefas com prazo vencido e ainda abertas.
  @JsonKey(name: 'overdueTasks')
  final List<TarefaResumoDto> overdueTasks;

  /// Conversão a partir do JSON.
  factory DashboardDto.fromJson(Map<String, dynamic> json) =>
      _$DashboardDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$DashboardDtoToJson(this);
}

/// Tarefa enxuta usada nas listas do dashboard.
///
/// Separada de `TarefaResponseDto` de propósito: a Home só precisa de
/// `id`, título, prazo, disciplina, prioridade e situação. Se o backend
/// passar a devolver o resumo real, o tipo já está pronto.
@JsonSerializable(fieldRename: FieldRename.none)
class TarefaResumoDto {
  /// Cria o resumo de tarefa.
  const TarefaResumoDto({
    required this.id,
    this.title = '',
    this.dueDate,
    this.subjectName,
    this.priority,
    this.completed = false,
  });

  /// Identificador da tarefa, para concluir/excluir sem refetch.
  final int id;

  /// Título da atividade.
  @JsonKey(name: 'title', defaultValue: '')
  final String title;

  /// Prazo em ISO-8601 UTC.
  @JsonKey(name: 'dueDate')
  final String? dueDate;

  /// Nome da disciplina.
  @JsonKey(name: 'subjectName')
  final String? subjectName;

  /// `LOW`, `MEDIUM` ou `HIGH`.
  final String? priority;

  /// Se já foi concluída.
  @JsonKey(name: 'completed', defaultValue: false)
  final bool completed;

  /// Conversão a partir do JSON.
  factory TarefaResumoDto.fromJson(Map<String, dynamic> json) =>
      _$TarefaResumoDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$TarefaResumoDtoToJson(this);
}
