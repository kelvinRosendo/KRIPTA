/// Estado da grade de disciplinas e do detalhe de unidades.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/entities.dart';

/// Grade de disciplinas do usuário.
class MateriasController extends AsyncNotifier<List<Disciplina>> {
  @override
  Future<List<Disciplina>> build() => _carregar();

  Future<List<Disciplina>> _carregar() async {
    final resultado = await ref.watch(disciplinaRepositoryProvider).listar();
    return switch (resultado) {
      Success<List<Disciplina>>(:final value) => value,
      FailureResult<List<Disciplina>>(:final failure) => throw failure,
    };
  }

  /// Recarrega a grade mantendo os cards visíveis durante a requisição.
  Future<void> recarregar() async {
    state = const AsyncValue<List<Disciplina>>.loading();
    state = await AsyncValue.guard(_carregar);
  }
}

/// Grade de disciplinas, para a tela consumir.
final AsyncNotifierProvider<MateriasController, List<Disciplina>>
materiasProvider = AsyncNotifierProvider<MateriasController, List<Disciplina>>(
  MateriasController.new,
  name: 'materias',
);

/// Unidades de uma disciplina inteira.
///
/// `.family` é o certo aqui: cada disciplina tem seu próprio conjunto de
/// unidades, e um provider compartilhado trocaria de estado ao navegar de
/// uma disciplina para outra.
///
/// No Riverpod 3 o argumento chega pelo **construtor** do notifier — não
/// existe uma classe `FamilyAsyncNotifier` separada, e o tipo de retorno
/// de `.family` não precisa (e não deve) ser anotado.
final unidadesProvider =
    AsyncNotifierProvider.family<UnidadesController, List<Unidade>, int>(
      UnidadesController.new,
      name: 'unidades',
    );

/// Carrega as unidades de uma disciplina.
class UnidadesController extends AsyncNotifier<List<Unidade>> {
  /// Cria o notifier já vinculado a uma disciplina.
  UnidadesController(this.disciplinaId);

  /// Disciplina cujas unidades serão carregadas.
  final int disciplinaId;

  @override
  Future<List<Unidade>> build() async {
    final resultado = await ref
        .watch(unidadeRepositoryProvider)
        .listar(disciplinaId);
    return switch (resultado) {
      Success<List<Unidade>>(:final value) => value,
      FailureResult<List<Unidade>>(:final failure) => throw failure,
    };
  }
}

/// Materiais de uma unidade.
///
/// Outra família: o id da unidade é o argumento, e cada unidade carrega
/// seus materiais sob demanda — baixar os materiais de uma disciplina
/// inteira para achar uma unidade seria desperdício.
final materiaisProvider =
    AsyncNotifierProvider.family<
      MateriaisController,
      List<MaterialEstudo>,
      int
    >(MateriaisController.new, name: 'materiais');

/// Carrega os materiais de uma unidade.
class MateriaisController extends AsyncNotifier<List<MaterialEstudo>> {
  /// Cria o notifier já vinculado a uma unidade.
  MateriaisController(this.unidadeId);

  /// Unidade cujos materiais serão carregados.
  final int unidadeId;

  @override
  Future<List<MaterialEstudo>> build() async {
    final resultado = await ref
        .watch(materialRepositoryProvider)
        .listarPorUnidade(unidadeId);
    return switch (resultado) {
      Success<List<MaterialEstudo>>(:final value) => value,
      FailureResult<List<MaterialEstudo>>(:final failure) => throw failure,
    };
  }

  /// Marca/desmarca um material, atualizando a lista sem recarregar.
  ///
  /// O *patch* otimista entra **antes** da resposta: o botão responde na
  /// hora e volta atrás se o servidor recusar. Em lista de estudo, esperar
  /// a ida e a volta na rede só para riscar um item é perceptível.
  Future<void> alternarConclusao(int materialId) async {
    // `AsyncValue.value` é anulável em Riverpod 3 (substituiu o antigo
    // `valueOrNull`) e devolve `null` enquanto não há dado.
    final atual = state.value;
    if (atual == null) return;

    state = AsyncValue<List<MaterialEstudo>>.data(
      atual
          .map(
            (MaterialEstudo m) =>
                m.id == materialId ? m.copyWith(concluido: !m.concluido) : m,
          )
          .toList(growable: false),
    );

    final resultado = await ref
        .read(materialRepositoryProvider)
        .alternarConclusao(materialId);

    switch (resultado) {
      case Success<MaterialEstudo>(:final value):
        // Reconcilia com o servidor: o `concluido` oficial vale mais que a
        // estimativa local.
        final atual2 = state.value;
        if (atual2 == null) return;
        state = AsyncValue<List<MaterialEstudo>>.data(
          atual2
              .map((MaterialEstudo m) => m.id == value.id ? value : m)
              .toList(growable: false),
        );
      case FailureResult<MaterialEstudo>():
        // Reverte: a resposta do servidor é a autoridade.
        state = AsyncValue<List<MaterialEstudo>>.data(atual);
    }
  }
}
