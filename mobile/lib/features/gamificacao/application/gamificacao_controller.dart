/// Gamificação do Perfil: nível, progresso e grade de insígnias.
///
/// Um único [AsyncNotifier] para os dois repositories, pelo mesmo motivo
/// do [HomeController]: a barra de nível e a grade de insígnias aparecem
/// lado a lado, e dois providers separados deixariam um bloco em
/// "carregando" ao lado do outro em "erro" — parece interface quebrada.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/entities.dart';

/// Números de nível e insígnias do usuário, já desembrulhados do [Result].
class GamificacaoDoPerfil {
  /// Cria o agregado.
  const GamificacaoDoPerfil({
    required this.estatisticas,
    required this.conquistas,
  });

  /// Nível, XP e progresso dentro do nível.
  final EstatisticasGamificacao estatisticas;

  /// Insígnias, conquistadas ou não.
  final List<Conquista> conquistas;

  /// Quantidade de insígnias já desbloqueadas.
  int get conquistadas =>
      conquistas.where((Conquista c) => c.conquistada).length;
}

/// Carrega os dados de gamificação exibidos no Perfil.
///
/// ⚠️ **Requisito em aberto no backend**: `estatisticas()` e `conquistas()`
/// ainda não têm controller no servidor (ver
/// `GamificacaoRepository`). Enquanto isso, contra a API real a tela mostra
/// o estado de erro com opção de tentar de novo — que é o comportamento
/// honesto, em vez de mostrar zeros como se fossem os números do aluno.
///
/// `progresso()` não é chamado: nenhum elemento do protótipo web mostra o
/// percentual geral, então buscá-lo seria uma requisição sem uso.
class GamificacaoPerfilController extends AsyncNotifier<GamificacaoDoPerfil> {
  @override
  Future<GamificacaoDoPerfil> build() async {
    final repositorio = ref.watch(gamificacaoRepositoryProvider);

    // O `.wait` de record do Dart 3 dispara as duas requisições juntas e
    // espera a mais lenta, preservando o tipo de cada resultado — diferente
    // de um `Future.wait` com `Result<Object?>`, que exigiria rebaixar tudo
    // para `Object` e adivinhar o tipo de volta no `switch`.
    final (resultadoEstatisticas, resultadoConquistas) = await (
      repositorio.estatisticas(),
      repositorio.conquistas(),
    ).wait;

    // A primeira falha derruba o par inteiro. Aceita: a tela exibe os dois
    // blocos juntos, então um deles sem o outro não helparia ninguém.
    return GamificacaoDoPerfil(
      estatisticas: _valor(resultadoEstatisticas),
      conquistas: _valor(resultadoConquistas),
    );
  }

  /// Recarrega mantendo o conteúdo atual visível, como no *pull-to-refresh*.
  Future<void> recarregar() async {
    state = const AsyncValue<GamificacaoDoPerfil>.loading();
    state = await AsyncValue.guard(build);
  }

  /// Converte um [Result] em valor ou falha, para o `AsyncValue` assumir.
  static T _valor<T>(Result<T> resposta) => switch (resposta) {
    Success<T>(:final value) => value,
    FailureResult<T>(:final failure) => throw failure,
  };
}

/// Gamificação do Perfil, para a tela consumir.
final AsyncNotifierProvider<GamificacaoPerfilController, GamificacaoDoPerfil>
gamificacaoPerfilProvider =
    AsyncNotifierProvider<GamificacaoPerfilController, GamificacaoDoPerfil>(
      GamificacaoPerfilController.new,
      name: 'gamificacaoPerfil',
    );
