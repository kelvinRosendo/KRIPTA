/// DTOs de gamificação e do dashboard da Home.
///
/// Não há controller de gamificação nem de dashboard no backend ainda.
/// Os formatos abaixo espelham o que o frontend web consome em
/// `services/gamification.js` e no `devMock` de `services/dev-data.js`.
library;

import 'package:json_annotation/json_annotation.dart';

part 'dto_gamificacao.g.dart';

/// Resposta de `GET /api/gamificacao/estatisticas`.
///
/// ```json
/// { "level": 4, "xp": 1240, "xpToNextLevel": 260, "levelProgress": 76 }
/// ```
@JsonSerializable(fieldRename: FieldRename.none)
class EstatisticasGamificacaoDto {
  /// Cria as estatísticas de gamificação.
  const EstatisticasGamificacaoDto({
    this.level = 1,
    this.xp = 0,
    this.xpToNextLevel = 0,
    this.levelProgress = 0,
  });

  /// Nível atual (começa em 1).
  @JsonKey(name: 'level', defaultValue: 1)
  final int level;

  /// XP acumulado desde a criação da conta.
  @JsonKey(name: 'xp', defaultValue: 0)
  final int xp;

  /// XP que falta para o próximo nível.
  @JsonKey(name: 'xpToNextLevel', defaultValue: 0)
  final int xpToNextLevel;

  /// Progresso dentro do nível atual, de 0 a 100.
  @JsonKey(name: 'levelProgress', defaultValue: 0)
  final int levelProgress;

  /// Conversão a partir do JSON.
  factory EstatisticasGamificacaoDto.fromJson(Map<String, dynamic> json) =>
      _$EstatisticasGamificacaoDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$EstatisticasGamificacaoDtoToJson(this);
}

/// Resumo compacto dos números exibidos nos cards da Home.
@JsonSerializable(fieldRename: FieldRename.none)
class ResumoGamificacaoDto {
  /// Cria o resumo.
  const ResumoGamificacaoDto({this.xp = 0, this.level = 1, this.streak = 0});

  /// XP total.
  @JsonKey(name: 'xp', defaultValue: 0)
  final int xp;

  /// Nível atual.
  @JsonKey(name: 'level', defaultValue: 1)
  final int level;

  /// Sequência de dias de estudo (o "foguinho").
  @JsonKey(name: 'streak', defaultValue: 0)
  final int streak;

  /// Conversão a partir do JSON.
  factory ResumoGamificacaoDto.fromJson(Map<String, dynamic> json) =>
      _$ResumoGamificacaoDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$ResumoGamificacaoDtoToJson(this);
}

/// Resposta de `GET /api/gamificacao/conquistas`.
///
/// `unlockedAt` chega como `null` enquanto a insígnia não foi conquistada,
/// então é `String?` e vira `DateTime` só no mapper.
@JsonSerializable(fieldRename: FieldRename.none)
class ConquistaDto {
  /// Cria a conquista.
  const ConquistaDto({
    required this.id,
    this.icon = '🏅',
    this.title = '',
    this.description = '',
    this.unlocked = false,
    this.unlockedAt,
  });

  /// Identificador da insígnia.
  final int id;

  /// Emoji da insígnia.
  @JsonKey(name: 'icon', defaultValue: '🏅')
  final String icon;

  /// Nome da insígnia.
  @JsonKey(name: 'title', defaultValue: '')
  final String title;

  /// Como conquistar.
  @JsonKey(name: 'description', defaultValue: '')
  final String description;

  /// Se o aluno já desbloqueou.
  @JsonKey(name: 'unlocked', defaultValue: false)
  final bool unlocked;

  /// Data do desbloqueio, em ISO-8601 UTC.
  @JsonKey(name: 'unlockedAt')
  final String? unlockedAt;

  /// Conversão a partir do JSON.
  factory ConquistaDto.fromJson(Map<String, dynamic> json) =>
      _$ConquistaDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$ConquistaDtoToJson(this);
}

/// Resposta de `GET /api/progresso`.
///
/// ```json
/// { "overallProgress": 42 }
/// ```
@JsonSerializable(fieldRename: FieldRename.none)
class ProgressoDto {
  /// Cria o progresso.
  const ProgressoDto({this.overallProgress = 0});

  /// Percentual de conclusão geral, de 0 a 100.
  @JsonKey(name: 'overallProgress', defaultValue: 0)
  final int overallProgress;

  /// Conversão a partir do JSON.
  factory ProgressoDto.fromJson(Map<String, dynamic> json) =>
      _$ProgressoDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$ProgressoDtoToJson(this);
}
