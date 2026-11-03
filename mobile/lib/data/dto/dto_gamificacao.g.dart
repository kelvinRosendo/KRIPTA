// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto_gamificacao.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EstatisticasGamificacaoDto _$EstatisticasGamificacaoDtoFromJson(
  Map<String, dynamic> json,
) => EstatisticasGamificacaoDto(
  level: (json['level'] as num?)?.toInt() ?? 1,
  xp: (json['xp'] as num?)?.toInt() ?? 0,
  xpToNextLevel: (json['xpToNextLevel'] as num?)?.toInt() ?? 0,
  levelProgress: (json['levelProgress'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$EstatisticasGamificacaoDtoToJson(
  EstatisticasGamificacaoDto instance,
) => <String, dynamic>{
  'level': instance.level,
  'xp': instance.xp,
  'xpToNextLevel': instance.xpToNextLevel,
  'levelProgress': instance.levelProgress,
};

ResumoGamificacaoDto _$ResumoGamificacaoDtoFromJson(
  Map<String, dynamic> json,
) => ResumoGamificacaoDto(
  xp: (json['xp'] as num?)?.toInt() ?? 0,
  level: (json['level'] as num?)?.toInt() ?? 1,
  streak: (json['streak'] as num?)?.toInt() ?? 0,
  minutesToday: (json['minutesToday'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ResumoGamificacaoDtoToJson(
  ResumoGamificacaoDto instance,
) => <String, dynamic>{
  'xp': instance.xp,
  'level': instance.level,
  'streak': instance.streak,
  'minutesToday': instance.minutesToday,
};

ConquistaDto _$ConquistaDtoFromJson(Map<String, dynamic> json) => ConquistaDto(
  id: (json['id'] as num).toInt(),
  icon: json['icon'] as String? ?? '🏅',
  title: json['title'] as String? ?? '',
  description: json['description'] as String? ?? '',
  unlocked: json['unlocked'] as bool? ?? false,
  unlockedAt: json['unlockedAt'] as String?,
);

Map<String, dynamic> _$ConquistaDtoToJson(ConquistaDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'icon': instance.icon,
      'title': instance.title,
      'description': instance.description,
      'unlocked': instance.unlocked,
      'unlockedAt': instance.unlockedAt,
    };

ProgressoDto _$ProgressoDtoFromJson(Map<String, dynamic> json) => ProgressoDto(
  overallProgress: (json['overallProgress'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ProgressoDtoToJson(ProgressoDto instance) =>
    <String, dynamic>{'overallProgress': instance.overallProgress};
