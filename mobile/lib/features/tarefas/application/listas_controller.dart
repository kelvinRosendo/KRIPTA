/// Estado das listas de tarefas, avisos e calendário.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/entities.dart';

/// Converte um [Result] em [T] lançando a falha.
///
/// Centralizar evita repetir o mesmo `switch` em todo `build` e garante
/// que **toda** falha de repositório vire a mesma exceção — sem isso, uma
/// tela poderia exibir erro e outra ficaria em branco para o mesmo
/// problema. `AsyncNotifier` transforma a exceção em `AsyncValue.error`,
/// que os widgets `ErroView` já sabem renderizar.
Future<T> obter<T>(Future<Result<T>> Function() chamada) async {
  final resultado = await chamada();
  return switch (resultado) {
    Success<T>(:final value) => value,
    FailureResult<T>(:final failure) => throw failure,
  };
}

/// Lista de tarefas do usuário.
class TarefasController extends AsyncNotifier<List<Tarefa>> {
  @override
  Future<List<Tarefa>> build() =>
      obter<List<Tarefa>>(() => ref.watch(tarefaRepositoryProvider).listar());

  /// Recarrega a lista.
  Future<void> recarregar() async {
    state = const AsyncValue<List<Tarefa>>.loading();
    state = await AsyncValue.guard(
      () => obter<List<Tarefa>>(
        () => ref.read(tarefaRepositoryProvider).listar(),
      ),
    );
  }

  /// Conclui ou reabre uma tarefa, com atualização otimista.
  ///
  /// O item muda na hora; se o servidor recusar, volta ao estado anterior.
  /// Sem isso, riscar uma tarefa custaria uma ida e volta na rede.
  Future<void> alternarConclusao(int tarefaId) async {
    final anterior = state.value;
    if (anterior == null) return;

    state = AsyncValue<List<Tarefa>>.data(
      anterior
          .map(
            (Tarefa t) =>
                t.id == tarefaId ? t.copyWith(concluida: !t.concluida) : t,
          )
          .toList(growable: false),
    );

    final resultado = await ref
        .read(tarefaRepositoryProvider)
        .alternarConclusao(tarefaId);

    switch (resultado) {
      case Success<Tarefa>(:final value):
        // Reconcilia com o servidor: o `concluida` e o `xpConquistado`
        // oficiais valem mais que a estimativa local.
        final atual = state.value;
        if (atual == null) return;
        state = AsyncValue<List<Tarefa>>.data(
          atual
              .map((Tarefa t) => t.id == value.id ? value : t)
              .toList(growable: false),
        );
      case FailureResult<Tarefa>():
        // Reverte: a resposta do servidor é a autoridade.
        state = AsyncValue<List<Tarefa>>.data(anterior);
    }
  }
}

/// Lista de tarefas, para a tela consumir.
final tarefasProvider = AsyncNotifierProvider<TarefasController, List<Tarefa>>(
  TarefasController.new,
  name: 'tarefas',
);

/// Lista de avisos, do mais recente para o mais antigo.
class AvisosController extends AsyncNotifier<List<Aviso>> {
  @override
  Future<List<Aviso>> build() =>
      obter<List<Aviso>>(() => ref.watch(avisoRepositoryProvider).listar());

  /// Recarrega a lista.
  Future<void> recarregar() async {
    state = const AsyncValue<List<Aviso>>.loading();
    state = await AsyncValue.guard(
      () =>
          obter<List<Aviso>>(() => ref.read(avisoRepositoryProvider).listar()),
    );
  }
}

/// Avisos, para a tela consumir.
final avisosProvider = AsyncNotifierProvider<AvisosController, List<Aviso>>(
  AvisosController.new,
  name: 'avisos',
);

/// Eventos do calendário agrupados por dia.
class CalendarioController extends AsyncNotifier<List<EventoCalendario>> {
  /// Cria o controller já vinculado a um mês.
  CalendarioController(this.mes);

  /// Primeiro dia do mês exibido.
  ///
  /// Guardado no controller (e não como `.family`) de propósito: como a
  /// família é criada uma vez por mês, `build()` não é reexecutado ao
  /// navegar dentro do mesmo mês, e o `ref` resolve o mês corrente.
  final DateTime mes;

  @override
  Future<List<EventoCalendario>> build() {
    // Carrega o mês com folga de dias nas bordas: um evento do dia 1
    // pertence à grade que começa no mês anterior, e sem a folga ele
    // sumiria da tela.
    final inicio = DateTime(
      mes.year,
      mes.month,
      1,
    ).subtract(const Duration(days: 7));
    final fim = DateTime(
      mes.year,
      mes.month + 1,
      0,
    ).add(const Duration(days: 7));

    return obter<List<EventoCalendario>>(
      () => ref
          .watch(calendarioRepositoryProvider)
          .listarPeriodo(inicio: inicio, fim: fim),
    );
  }
}

/// Eventos de um mês.
///
/// `.family` por mês: trocar de mês recarrega apenas o novo e o anterior
/// permanece em cache enquanto o usuário navega para trás.
final calendarioProvider =
    AsyncNotifierProvider.family<
      CalendarioController,
      List<EventoCalendario>,
      DateTime
    >(CalendarioController.new, name: 'calendario');

/// Mês inicial: o mês corrente, no primeiro dia.
DateTime mesCorrente() => DateTime(DateTime.now().year, DateTime.now().month);

/// Chave estável de provider para um mês.
///
/// [DateTime] não pode ser chave de família diretamente: `==` compara
/// instante, então `10:00` de hoje e `mesCorrente()` gerariam providers
/// diferentes para o mesmo mês e recarregariam à toa. A chave normaliza
/// para dia 1 à meia-noite.
DateTime chaveMes(DateTime mes) => DateTime(mes.year, mes.month);
