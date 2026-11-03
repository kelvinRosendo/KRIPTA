/// Entidade agregada do dashboard exibido na Home.
library;

import 'package:equatable/equatable.dart';

import 'gamificacao.dart';

/// Visão agregada da Home.
///
/// Reúne o que o aluno precisa ver ao abrir o app: sequência, XP, nível,
/// total de insígnias e as listas de tarefas por prazo.
///
/// Não há controller de dashboard no backend ainda; o formato segue o
/// `devMock` de `services/dev-data.js`:
///
/// ```json
/// { "stats": { "xp": 1240, "level": 4, "streak": 7 },
///   "badgesCount": 3,
///   "tasksToday": [ ... ], "tasksTomorrow": [ ... ], "overdueTasks": [ ... ] }
/// ```
class Dashboard extends Equatable {
  /// Cria o dashboard.
  const Dashboard({
    required this.gamificacao,
    required this.totalConquistas,
    this.tarefasHoje = const <TarefaRef>[],
    this.tarefasAmanha = const <TarefaRef>[],
    this.tarefasAtrasadas = const <TarefaRef>[],
  });

  /// Números de gamificação do topo.
  final ResumoGamificacao gamificacao;

  /// Quantidade de insígnias já conquistadas.
  final int totalConquistas;

  /// Tarefas com prazo hoje.
  final List<TarefaRef> tarefasHoje;

  /// Tarefas com prazo amanhã.
  final List<TarefaRef> tarefasAmanha;

  /// Tarefas com prazo vencido e ainda abertas.
  final List<TarefaRef> tarefasAtrasadas;

  /// Total de tarefas abertas nas três listas.
  ///
  /// Decide se a Home mostra a seção de tarefas ou o estado vazio.
  int get totalAbertas =>
      tarefasHoje.length + tarefasAmanha.length + tarefasAtrasadas.length;

  @override
  List<Object?> get props => <Object?>[
    gamificacao,
    totalConquistas,
    tarefasHoje,
    tarefasAmanha,
    tarefasAtrasadas,
  ];
}

/// Referência enxuta de tarefa usada pelo dashboard.
///
/// O endpoint `/dashboard` devolve a tarefa completa, mas a Home só
/// precisa de `id`, `titulo`, `prazo` e `disciplina`. Manter o tipo
/// separado evita acoplar a Home à entidade completa e deixa a porta
/// aberta para o backend passar a devolver só o resumo.
class TarefaRef extends Equatable {
  /// Cria a referência.
  const TarefaRef({
    required this.id,
    required this.titulo,
    this.prazo,
    this.disciplinaNome,
    this.prioridade,
    this.concluida = false,
  });

  /// Identificador da tarefa (para concluir/excluir sem refetch).
  final int id;

  /// Título da atividade.
  final String titulo;

  /// Prazo, em hora local.
  final DateTime? prazo;

  /// Nome da disciplina.
  final String? disciplinaNome;

  /// Prioridade declarada.
  final String? prioridade;

  /// Se já foi concluída.
  final bool concluida;

  @override
  List<Object?> get props => <Object?>[
    id,
    titulo,
    prazo,
    disciplinaNome,
    prioridade,
    concluida,
  ];
}
