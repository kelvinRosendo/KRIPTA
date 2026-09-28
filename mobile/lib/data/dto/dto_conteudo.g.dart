// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto_conteudo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DisciplinaRequestDto _$DisciplinaRequestDtoFromJson(
  Map<String, dynamic> json,
) => DisciplinaRequestDto(
  nome: json['nome'] as String,
  cor: json['cor'] as String,
);

Map<String, dynamic> _$DisciplinaRequestDtoToJson(
  DisciplinaRequestDto instance,
) => <String, dynamic>{'nome': instance.nome, 'cor': instance.cor};

DisciplinaResponseDto _$DisciplinaResponseDtoFromJson(
  Map<String, dynamic> json,
) => DisciplinaResponseDto(
  id: (json['id'] as num).toInt(),
  nome: json['nome'] as String,
  cor: json['cor'] as String,
  docente: json['teacher'] as String?,
  descricao: json['descricao'] as String?,
  pendencias: (json['pendingCount'] as num?)?.toInt(),
  icone: json['icon'] as String?,
  favorita: json['isFavorite'] as bool?,
);

Map<String, dynamic> _$DisciplinaResponseDtoToJson(
  DisciplinaResponseDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'nome': instance.nome,
  'cor': instance.cor,
  'teacher': instance.docente,
  'descricao': instance.descricao,
  'pendingCount': instance.pendencias,
  'icon': instance.icone,
  'isFavorite': instance.favorita,
};

UnidadeResponseDto _$UnidadeResponseDtoFromJson(Map<String, dynamic> json) =>
    UnidadeResponseDto(
      id: (json['id'] as num).toInt(),
      subjectId: (json['subjectId'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      materialsCount: (json['materialsCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UnidadeResponseDtoToJson(UnidadeResponseDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subjectId': instance.subjectId,
      'name': instance.name,
      'description': instance.description,
      'materialsCount': instance.materialsCount,
    };

UnidadeRequestDto _$UnidadeRequestDtoFromJson(Map<String, dynamic> json) =>
    UnidadeRequestDto(
      name: json['name'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$UnidadeRequestDtoToJson(UnidadeRequestDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
    };

MaterialResponseDto _$MaterialResponseDtoFromJson(Map<String, dynamic> json) =>
    MaterialResponseDto(
      id: (json['id'] as num).toInt(),
      unitId: (json['unitId'] as num).toInt(),
      title: json['title'] as String,
      type: json['type'] as String,
      url: json['url'] as String?,
      description: json['description'] as String?,
      completed: json['completed'] as bool? ?? false,
    );

Map<String, dynamic> _$MaterialResponseDtoToJson(
  MaterialResponseDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'unitId': instance.unitId,
  'title': instance.title,
  'type': instance.type,
  'url': instance.url,
  'description': instance.description,
  'completed': instance.completed,
};

MaterialRequestDto _$MaterialRequestDtoFromJson(Map<String, dynamic> json) =>
    MaterialRequestDto(
      title: json['title'] as String,
      type: json['type'] as String,
      url: json['url'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$MaterialRequestDtoToJson(MaterialRequestDto instance) =>
    <String, dynamic>{
      'title': instance.title,
      'type': instance.type,
      'url': instance.url,
      'description': instance.description,
    };

TarefaResponseDto _$TarefaResponseDtoFromJson(Map<String, dynamic> json) =>
    TarefaResponseDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['dueDate'] as String?,
      priority: json['priority'] as String?,
      completed: json['completed'] as bool?,
      status: json['status'] as String?,
      subjectId: (json['subjectId'] as num?)?.toInt(),
      subject: json['subject'] as Map<String, dynamic>?,
      gamification: json['gamification'] == null
          ? null
          : XpConquistadoDto.fromJson(
              json['gamification'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$TarefaResponseDtoToJson(TarefaResponseDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'dueDate': instance.dueDate,
      'priority': instance.priority,
      'completed': instance.completed,
      'status': instance.status,
      'subjectId': instance.subjectId,
      'subject': instance.subject,
      'gamification': instance.gamification,
    };

XpConquistadoDto _$XpConquistadoDtoFromJson(Map<String, dynamic> json) =>
    XpConquistadoDto(xpEarned: (json['xpEarned'] as num?)?.toInt() ?? 0);

Map<String, dynamic> _$XpConquistadoDtoToJson(XpConquistadoDto instance) =>
    <String, dynamic>{'xpEarned': instance.xpEarned};

TarefaRequestDto _$TarefaRequestDtoFromJson(Map<String, dynamic> json) =>
    TarefaRequestDto(
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['dueDate'] as String?,
      priority: json['priority'] as String?,
      subjectId: (json['subjectId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TarefaRequestDtoToJson(TarefaRequestDto instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'dueDate': instance.dueDate,
      'priority': instance.priority,
      'subjectId': instance.subjectId,
    };

AvisoResponseDto _$AvisoResponseDtoFromJson(Map<String, dynamic> json) =>
    AvisoResponseDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: json['createdAt'] as String,
      subject: json['subject'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AvisoResponseDtoToJson(AvisoResponseDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'message': instance.message,
      'createdAt': instance.createdAt,
      'subject': instance.subject,
    };

EventoCalendarioDto _$EventoCalendarioDtoFromJson(Map<String, dynamic> json) =>
    EventoCalendarioDto(
      date: json['date'] as String,
      title: json['title'] as String,
      type: json['type'] as String?,
    );

Map<String, dynamic> _$EventoCalendarioDtoToJson(
  EventoCalendarioDto instance,
) => <String, dynamic>{
  'date': instance.date,
  'title': instance.title,
  'type': instance.type,
};
