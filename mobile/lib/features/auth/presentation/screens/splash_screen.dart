/// Tela de splash, exibida enquanto a sessão é verificada.
///
/// Não é decorativa: é o estado [StatusSessao.desconhecido] do
/// [AuthController]. Enquanto o token não foi lido do armazenamento
/// seguro, o `redirect` do router mantém o usuário **aqui** — é o que
/// evita o flash da tela de login para quem já estava autenticado.
///
/// A troca de tela não é feita por este widget: quando
/// `restaurarSessao()` termina, o estado muda, o `go_router` reavalia o
/// redirect e navega. Se esta tela chamasse `context.go()` sozinha, haveria
/// duas fontes de decisão sobre para onde ir.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/auth_controller.dart';

/// Splash com logo e indicador de progresso.
class SplashScreen extends ConsumerStatefulWidget {
  /// Cria o splash.
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // `initState` (e não `build`) dispara a verificação **uma** vez.
    // Chamar em `build` reiniciaria a requisição a cada rebuild.
    // O `Future` é descartado: o resultado chega pelo estado, não aqui.
    Future<void>.microtask(
      () => ref.read(authControllerProvider.notifier).restaurarSessao(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.auto_stories_rounded, size: 64, color: AppColors.indigo),
            SizedBox(height: 16),
            Text(
              'KRIPTA',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: AppColors.indigo,
              ),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
