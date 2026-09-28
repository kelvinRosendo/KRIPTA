/// Ponto de entrada do aplicativo KRIPTA Mobile.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_controller.dart';

/// Inicia o aplicativo.
///
/// O [ProviderContainer] é criado **manualmente** em vez de usar
/// [ProviderScope] por causa do [sessionExpiredBridgeProvider]: o
/// interceptor de autenticação precisa avisar o [AuthController] quando o
/// servidor responde 401, e esse callback só pode ser registrado por
/// `overrideWithValue` — que só existe no momento da criação do container.
///
/// A sessão é restaurada aqui, antes do primeiro `runApp`, para que a
/// primeira tela já seja a correta. Sem isso, o `redirect` do
/// `go_router` veria [StatusSessao.desconhecido] e mandaria para o login
/// um usuário que já estava autenticado — o "flash" de login a cada
/// abertura do app.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // `late` permite que o callback capture a variável antes de ela
  // receber o valor: ele só é executado após o 401, bem depois de
  // `container` existir.
  late final ProviderContainer container;

  container = ProviderContainer(
    overrides: [
      sessionExpiredBridgeProvider.overrideWithValue(() {
        container.read(authControllerProvider.notifier).encerrarSessao();
      }),
    ],
  );

  container.read(authControllerProvider.notifier).restaurarSessao();

  runApp(
    UncontrolledProviderScope(container: container, child: const KriptaApp()),
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
  const KriptaApp({super.key});

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
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
