/// Regressão do crash que derrubava a Home inteira na primeira abertura.
///
/// A saudação é o primeiro sliver do `CustomScrollView` e já formatava a
/// data em pt-BR. Sem os símbolos do locale carregados, o `intl` lançava
/// `LocaleDataException` ali dentro, a exceção subia pelo `build` e matava
/// a tela — inclusive o card de gamificação, que nunca chegava a pintar.
///
/// Este é o primeiro teste de widget do projeto, então ele monta só o
/// container mínimo que a Home lê (sessão + dashboard) em vez do
/// `main_debug.dart` inteiro.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kripta_mobile/core/di/providers.dart';
import 'package:kripta_mobile/core/utils/app_date_format.dart';
import 'package:kripta_mobile/dev/dados_de_exemplo.dart';
import 'package:kripta_mobile/dev/repositorios_falsos.dart';
import 'package:kripta_mobile/features/auth/application/auth_controller.dart';
import 'package:kripta_mobile/features/home/presentation/home_screen.dart';

void main() {
  // O mesmo passo que os entrypoints fazem. Sem ele a Home estoura aqui
  // mesmo, e o teste falha pelo motivo certo.
  setUpAll(AppDateFormat.inicializar);

  /// Monta a Home com o cenário pedido e espera os dublês responderem.
  ///
  /// Os 300 ms de [atrasoLeitura] viram `pump` real, para o teste percorrer
  /// o mesmo caminho de carregamento do aparelho.
  Future<void> mostrarHome(WidgetTester tester, Cenario cenario) async {
    final banco = BancoFalso(cenario: cenario);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(AuthRepositoryFalso(banco)),
        dashboardRepositoryProvider.overrideWithValue(
          DashboardRepositoryFalso(banco),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Sem `await`, de propósito: o dublê de autenticação tem atraso e o
    // relógio do `testWidgets` só anda com `pump`, então esperar aqui
    // travaria o teste. `iniciarApp` também dispara e segue.
    container.read(authControllerProvider.notifier).restaurarSessao();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    // Pumps explícitos, sem `pumpAndSettle`: enquanto o dashboard carrega a
    // tela mostra um indicador indeterminado, que anima para sempre e faz o
    // `pumpAndSettle` estourar o tempo limite.
    await tester.pump(); // primeiro frame, estado de carregamento
    await tester.pump(atrasoLeitura); // os dublês respondem
    await tester.pump(); // reconstrói com o dashboard
  }

  testWidgets('Home monta sem exceção de locale e mostra a saudação', (
    WidgetTester tester,
  ) async {
    await mostrarHome(tester, Cenario.cheio);

    // Se o `DateFormat` tivesse estourado, o `pumpWidget` já teria lançado e
    // nada abaixo existiria. A data por extenso é a prova direta.
    expect(find.textContaining('Ana'), findsOneWidget);
    expect(find.textContaining('de 20'), findsOneWidget);
  });

  testWidgets('Home mostra o foguinho, os três cards e o sino', (
    WidgetTester tester,
  ) async {
    await mostrarHome(tester, Cenario.cheio);

    // O sino de avisos, novo no cabeçalho.
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

    // Card do foguinho: sequência e a frase que depende dos minutos.
    expect(find.text('7 dias seguidos!'), findsOneWidget);
    expect(
      find.text('Faltam 3 min hoje pra manter o foguinho'),
      findsOneWidget,
    );

    // Os três cards de estatística. O seed tem nível 4, 1.240 XP e 3
    // insígnias conquistadas.
    expect(find.text('1.240'), findsOneWidget);
    expect(find.text('XP TOTAL'), findsOneWidget);
    expect(find.text('NÍVEL 4'), findsOneWidget);
    // Nível 4 na escala de títulos é "Curioso".
    expect(find.text('CURIOSO'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('INSÍGNIAS'), findsOneWidget);
  });

  // Não há teste de widget para [Cenario.erro] de propósito: quando o
  // provider lança, o Riverpod 3 agenda uma retentativa automática com
  // backoff de 400 ms, e `testWidgets` falha no teardown com "A Timer is
  // still pending even after the widget tree was disposed". Desligar o
  // retry exigiria mexer na criação de `homeProvider` no código de produção
  // por causa de um teste. O caminho de falha continua coberto em
  // `repositorios_falsos_test.dart`, no nível do repositório.
}
