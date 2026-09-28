/// Estado da Home, alimentado por `GET /api/dashboard`.
///
/// Um único [AsyncNotifier] para toda a tela: a Home mostra gamificação,
/// total de insígnias e três listas de tarefas no mesmo `Sliver`. Se cada
/// bloco tivesse seu provider, a tela precisaria de três `AsyncValue`
/// separados e três estados de carregamento — e um bloco poderia mostrar
/// "erro" ao lado de outro mostrando "carregando", o que parece quebrado.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/entities.dart';
import '../../auth/application/auth_controller.dart';

/// Carrega e expõe o dashboard da Home.
class HomeController extends AsyncNotifier<Dashboard> {
  @override
  Future<Dashboard> build() async {
    final resultado = await ref.watch(dashboardRepositoryProvider).carregar();

    // `Result` → `AsyncValue`: o repositório já tradutou a exceção, então
    // aqui só falta escolher entre sucesso e erro.
    return switch (resultado) {
      Success<Dashboard>(:final value) => value,
      FailureResult<Dashboard>(:final failure) => throw failure,
    };
  }

  /// Recarrega mantendo os dados atuais visíveis durante a requisição.
  ///
  /// `refresh` do `AsyncNotifier` faz exatamente isso: o estado passa a
  /// `AsyncLoading` com o valor anterior preservado, então a tela não
  /// pisca um spinner cheio. É o que o *pull-to-refresh* deve usar.
  Future<void> recarregar() async {
    state = const AsyncValue<Dashboard>.loading();
    state = await AsyncValue.guard(
      () => ref.read(dashboardRepositoryProvider).carregar().then((
        Result<Dashboard> r,
      ) {
        return switch (r) {
          Success<Dashboard>(:final value) => value,
          FailureResult<Dashboard>(:final failure) => throw failure,
        };
      }),
    );
  }
}

/// Dashboard da Home, para a tela consumir.
final AsyncNotifierProvider<HomeController, Dashboard> homeProvider =
    AsyncNotifierProvider<HomeController, Dashboard>(
      HomeController.new,
      name: 'home',
    );

/// Saudação com o primeiro nome do usuário.
///
/// Provider separado porque a barra superior precisa do nome mesmo quando
/// o dashboard falha — os dois carregam de fontes diferentes (sessão e
/// rede), e acoplar os dois deixaria o nome sumir junto com a API.
final Provider<String> primeiroNomeProvider = Provider<String>((Ref ref) {
  final usuario = ref.watch(authControllerProvider).usuario;
  if (usuario == null) return 'estudante';
  final partes = usuario.nome.trim().split(RegExp(r'\s+'));
  return partes.isEmpty ? 'estudante' : partes.first;
}, name: 'primeiroNome');
