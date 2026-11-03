import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kripta_mobile/core/router/app_router.dart';

void main() {
  test('rotas do catálogo e unidades são resolvidas sem duplicar materias', () {
    final container = ProviderContainer();
    final router = criarRouter(container);
    addTearDown(router.dispose);
    addTearDown(container.dispose);
    expect(
      router.configuration
          .findMatch(Uri.parse('/materias/1/unidades/2'))
          .isError,
      false,
    );
    expect(
      router.configuration.findMatch(Uri.parse('/conteudos')).isError,
      false,
    );
    expect(Routes.ehPrivada('/conteudos'), true);
  });
}
