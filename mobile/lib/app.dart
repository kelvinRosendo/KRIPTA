/// Bootstrap compartilhado entre os pontos de entrada do aplicativo.
///
/// O [main.dart] e o [main_debug.dart] diferem apenas nos `overrides`
/// passados ao [ProviderContainer]; todo o resto — tema, router, restauração
/// de sessão e widget raiz — vive aqui para não duplicar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_date_format.dart';
import 'features/auth/application/auth_controller.dart';

/// Liga o interceptor de autenticação ao [AuthController].
///
/// O callback que o interceptor dispara precisa acessar o
/// [AuthController] — que por sua vez só existe **depois** que o
/// [ProviderContainer] foi construído. Como um override só pode ser
/// aplicado na construção do container, o interceptor recebe
/// [chamar] (que pode ser capturing) e o container real é registrado
/// logo em seguida, via [registrar].
///
/// O ciclo é seguro porque [chamar] só é invocado em resposta a um 401 da
/// API, o que pressupõe que a aplicação já esteja rodando.
class PonteDeSessaoExpirada {
  VoidCallback _callback = _nada;

  static void _nada() {}

  /// Registra o callback que encerra a sessão.
  void registrar(VoidCallback callback) => _callback = callback;

  /// Encerra a sessão. Chamado pelo interceptor em resposta a um 401.
  void chamar() => _callback();
}

/// Cria o container do KRIPTA e conecta a [PonteDeSessaoExpirada].
///
/// Deve ser chamada logo após a construção do container, antes de
/// [iniciarApp].
void conectarPonteDeSessao(
  ProviderContainer container,
  PonteDeSessaoExpirada ponte,
) {
  ponte.registrar(
    () => container.read(authControllerProvider.notifier).encerrarSessao(),
  );
}

/// Sobe a interface a partir de um [ProviderContainer] pronto.
///
/// A sessão é restaurada **antes** do primeiro `runApp`, para que a
/// primeira tela já seja a correta. Sem isso, o `redirect` do `go_router`
/// veria [StatusSessao.desconhecido] e mandaria para o login um usuário
/// que já estava autenticado — o "flash" de login a cada abertura do app.
///
/// [mostrarBannerDebug] exibe o banner "DEBUG" do Flutter, usado apenas
/// pelo `main_debug.dart` para deixar evidente que os dados exibidos não
/// vêm de uma API real.
void iniciarApp(
  ProviderContainer container, {
  bool mostrarBannerDebug = false,
}) {
  container.read(authControllerProvider.notifier).restaurarSessao();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: KriptaApp(mostrarBannerDebug: mostrarBannerDebug),
    ),
  );
}

/// Widget raiz do KRIPTA.
///
/// `UncontrolledProviderScope` já garante o [ProviderScope] (o
/// [ProviderScope] explícito aqui duplicaria o container). O router é
/// criado com o mesmo container do pai para que o `redirect` leia a
/// sessão real e não uma cópia.
class KriptaApp extends ConsumerStatefulWidget {
  /// Cria o widget raiz.
  const KriptaApp({super.key, this.mostrarBannerDebug = false});

  /// Quando `true`, exibe o banner "DEBUG" do Flutter.
  final bool mostrarBannerDebug;

  @override
  ConsumerState<KriptaApp> createState() => _KriptaAppState();
}

class _KriptaAppState extends ConsumerState<KriptaApp> {
  /// Cria uma vez por app: um router novo a cada `build` perderia a
  /// pilha de navegação.
  late final _router = criarRouter(
    ProviderScope.containerOf(context, listen: false),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KRIPTA',
      debugShowCheckedModeBanner: widget.mostrarBannerDebug,
      theme: AppTheme.light,
      routerConfig: _router,
      // Traduções dos widgets Material. `delegates` traz de uma vez
      // Material, Widgets e Cupertino; sem eles o date picker, os menus e
      // os campos de texto aparece em inglês dentro de um app todo em
      // português. Isso é diferente de `AppDateFormat.inicializar()`, que
      // carrega os símbolos do `intl` para os nossos próprios formatos.
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      locale: AppDateFormat.localePtBr,
      supportedLocales: const <Locale>[AppDateFormat.localePtBr, Locale('en')],
    );
  }
}
