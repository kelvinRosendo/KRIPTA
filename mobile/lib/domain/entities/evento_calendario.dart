/// Entidade do calendário acadêmico (RN05).
library;

import 'package:equatable/equatable.dart';

/// Tipo de ocorrência no calendário.
enum TipoEvento {
  /// Prazo de uma tarefa.
  tarefa('TASK', 'Tarefa'),

  /// Prova ou avaliação.
  prova('EXAM', 'Prova'),

  /// Evento escolar (reunião, feira, atividade).
  evento('EVENT', 'Evento');

  const TipoEvento(this.wire, this.rotulo);

  /// Valor exato serializado pelo backend.
  final String wire;

  /// Texto exibido na lista do dia.
  final String rotulo;

  /// Converte o valor do JSON; cai em [evento] quando desconhecido.
  static TipoEvento fromWire(String? value) {
    for (final t in TipoEvento.values) {
      if (t.wire == value) return t;
    }
    return TipoEvento.evento;
  }
}

/// Ocorrência em um dia do calendário.
///
/// O endpoint `/calendario` devolve apenas `date` (sem hora), então
/// [dia] é sempre meia-noite local — suficiente para localizar a entrada
/// na grade do mês.
class EventoCalendario extends Equatable {
  /// Cria o evento.
  const EventoCalendario({
    required this.dia,
    required this.titulo,
    this.tipo = TipoEvento.evento,
  });

  /// Dia da ocorrência, à meia-noite local.
  final DateTime dia;

  /// Título do compromisso.
  final String titulo;

  /// Natureza da ocorrência.
  final TipoEvento tipo;

  @override
  List<Object?> get props => <Object?>[dia, titulo, tipo];
}
