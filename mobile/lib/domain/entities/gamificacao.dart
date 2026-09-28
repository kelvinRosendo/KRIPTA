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
  String get tituloNivel => tituloDoNivel(nivel);

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

/// Título que corresponde a [nivel], com os extremos travados.
///
/// A escala foi definida no protótipo do frontend (`levelTitle` em
/// `services/gamification.js`). Níveis acima de 10 repetem "Lenda" em vez
/// de estourar a lista — um aluno não deve ver um `RangeError` por estudar
/// demais. Um `nivel` abaixo de 1 cai em "Iniciante" pelo mesmo motivo.
String tituloDoNivel(int nivel) =>
    nivelTitulos[(nivel - 1).clamp(0, nivelTitulos.length - 1)];

/// Regras de gamificação fixas do KRIPTA.
abstract final class AppGamificacao {
  /// Meta de minutos de uso por dia para manter o "foguinho" aceso.
  ///
  /// Vem do TCC (2.7): a sequência de dias só continua quando o aluno
  /// usa o app por pelo menos 10 minutos naquele dia.
  ///
  /// Fica no cliente de propósito: é regra de produto, não dado do usuário,
  /// então não precisa viajar no [ResumoGamificacao] nem virar campo do
  /// contrato com o backend. Se um dia a meta virar configurável por
  /// turma, aí sim ela passa a ser campo da API.
  static const int metaMinutosDiarios = 10;
}

/// Resumo compacto usado nos cards da Home.
class ResumoGamificacao extends Equatable {
  /// Cria o resumo.
  const ResumoGamificacao({
    required this.xp,
    required this.nivel,
    required this.sequenciaDias,
    this.minutosHoje = 0,
  });

  /// XP total.
  final int xp;

  /// Nível atual.
  final int nivel;

  /// Sequência de dias de estudo (o "foguinho" da Home).
  final int sequenciaDias;

  /// Minutos de uso já registrados hoje, contra
  /// [AppGamificacao.metaMinutosDiarios].
  ///
  /// O backend ainda não expõe esse campo (ver RELATORIO.md); enquanto isso o
  /// mapper devolve 0 e o anel da Home mostra a meta zerada, em vez de
  /// mentir um progresso que não existe.
  final int minutosHoje;

  /// Título do nível atual ("Nível 6 · Exploradora").
  ///
  /// Derivado de [nivel] em vez de vir pronto da API: o dashboard já traz
  /// o número, e a escala é uma tabela local.
  String get tituloNivel => tituloDoNivel(nivel);

  /// Fração de 0 a 1 do progresso do dia, para desenhar o anel.
  double get progressoHoje =>
      (minutosHoje / AppGamificacao.metaMinutosDiarios).clamp(0.0, 1.0);

  /// Minutos que faltam para o foguinho não quebrar hoje.
  int get minutosRestantes => (AppGamificacao.metaMinutosDiarios - minutosHoje)
      .clamp(0, AppGamificacao.metaMinutosDiarios);

  /// Se a meta de hoje já foi batida.
  bool get metaBatida => minutosHoje >= AppGamificacao.metaMinutosDiarios;

  @override
  List<Object?> get props => <Object?>[xp, nivel, sequenciaDias, minutosHoje];
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
