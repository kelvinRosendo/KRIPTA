/// Entidades de gamificação: progresso, estatísticas e conquistas.
///
/// Requisito do TCC (2.7): o KRIPTA usa **XP**, **níveis**, **conquistas**
/// (insígnias) e **sequências de uso** (*streaks*) para estimular
/// constância. A sequência exige pelo menos 10 minutos de uso por dia.
///
/// Nenhum controller de gamificação existe no backend ainda; os formatos
/// seguem o que o frontend web consome (`services/gamification.js`).
library;

import 'package:equatable/equatable.dart';

/// Progresso geral do aluno na plataforma.
class Progresso extends Equatable {
  /// Cria o progresso.
  const Progresso({required this.percentualGeral});

  /// Percentual de conclusão (0 a 100), exibido na barra do perfil.
  final int percentualGeral;

  @override
  List<Object?> get props => <Object?>[percentualGeral];
}

/// Números de nível e XP do usuário.
class EstatisticasGamificacao extends Equatable {
  /// Cria as estatísticas.
  const EstatisticasGamificacao({
    required this.nivel,
    required this.xp,
    required this.xpParaProximoNivel,
    required this.progressoNivel,
  });

  /// Nível atual (começa em 1).
  final int nivel;

  /// XP acumulado desde a criação da conta.
  final int xp;

  /// XP que falta para o próximo nível.
  final int xpParaProximoNivel;

  /// Progresso dentro do nível atual, de 0 a 100.
  final int progressoNivel;

  /// Título do nível, usado como elogio na Home e no perfil.
  ///
  /// A escala foi definida no protótipo do frontend
  /// (`levelTitle` em `services/gamification.js`).
  String get tituloNivel =>
      nivelTitulos[(nivel - 1).clamp(0, nivelTitulos.length - 1)];

  @override
  List<Object?> get props => <Object?>[
    nivel,
    xp,
    xpParaProximoNivel,
    progressoNivel,
  ];
}

/// Títulos por nível, do 1 ao 10.
const List<String> nivelTitulos = <String>[
  'Iniciante',
  'Estudante',
  'Aprendiz',
  'Curioso',
  'Dedicado',
  'Exploradora',
  'Determinado',
  'Mestrando',
  'Referência',
  'Lenda',
];

/// Resumo compacto usado nos cards da Home.
class ResumoGamificacao extends Equatable {
  /// Cria o resumo.
  const ResumoGamificacao({
    required this.xp,
    required this.nivel,
    required this.sequenciaDias,
  });

  /// XP total.
  final int xp;

  /// Nível atual.
  final int nivel;

  /// Sequência de dias de estudo (o "foguinho" da Home).
  final int sequenciaDias;

  @override
  List<Object?> get props => <Object?>[xp, nivel, sequenciaDias];
}

/// Insígnia desbloqueada (ou não) pelo aluno.
class Conquista extends Equatable {
  /// Cria a conquista.
  const Conquista({
    required this.id,
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.conquistada,
    this.conquistadaEm,
  });

  /// Identificador da conquista.
  final int id;

  /// Emoji da insígnia.
  final String icone;

  /// Nome da insígnia (ex.: "Estudante dedicado").
  final String titulo;

  /// Como conquistar (ex.: "7 dias seguidos de estudo").
  final String descricao;

  /// Se o aluno já desbloqueou.
  final bool conquistada;

  /// Data do desbloqueio, quando houver.
  final DateTime? conquistadaEm;

  @override
  List<Object?> get props => <Object?>[
    id,
    icone,
    titulo,
    descricao,
    conquistada,
    conquistadaEm,
  ];
}
