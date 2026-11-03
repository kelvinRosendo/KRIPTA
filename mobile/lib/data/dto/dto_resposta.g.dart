// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto_resposta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardDto _$DashboardDtoFromJson(Map<String, dynamic> json) => DashboardDto(
  stats: json['stats'] == null
      ? null
      : ResumoGamificacaoDto.fromJson(json['stats'] as Map<String, dynamic>),
  badgesCount: (json['badgesCount'] as num?)?.toInt() ?? 0,
  tasksToday:
      (json['tasksToday'] as List<dynamic>?)
          ?.map((e) => TarefaResumoDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <TarefaResumoDto>[],
  tasksTomorrow:
      (json['tasksTomorrow'] as List<dynamic>?)
          ?.map((e) => TarefaResumoDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <TarefaResumoDto>[],
  overdueTasks:
      (json['overdueTasks'] as List<dynamic>?)
          ?.map((e) => TarefaResumoDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <TarefaResumoDto>[],
);

Map<String, dynamic> _$DashboardDtoToJson(DashboardDto instance) =>
    <String, dynamic>{
      'stats': instance.stats,
      'badgesCount': instance.badgesCount,
      'tasksToday': instance.tasksToday,
      'tasksTomorrow': instance.tasksTomorrow,
      'overdueTasks': instance.overdueTasks,
    };

TarefaResumoDto _$TarefaResumoDtoFromJson(Map<String, dynamic> json) =>
    TarefaResumoDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      dueDate: json['dueDate'] as String?,
      subjectName: json['subjectName'] as String?,
      priority: json['priority'] as String?,
      completed: json['completed'] as bool? ?? false,
    );

Map<String, dynamic> _$TarefaResumoDtoToJson(TarefaResumoDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'dueDate': instance.dueDate,
      'subjectName': instance.subjectName,
      'priority': instance.priority,
      'completed': instance.completed,
    };
