/// Definição das rotas do KRIPTA Mobile, com `go_router`.
///
/// ## Estrutura de navegação
///
/// ```
///  /entrar          ─┐
///  /cadastro        ─┴─ (públicas) ─┐
///  /splash                         │ redirect
///  /home            ─┐             │
///  /materias        │             │
///  /tarefas         ├─ (shell) ────┘
///  /calendario      │
///  /avisos          │
///  /perfil          │
///  /kai             │
///  /materias/:id/unidades/:unidadeId  (detalhe, fora do shell)
///  /kai/chat
/// ```
///
/// ## Redirect de sessão
///
/// [redirect] é a **única** fonte de decisão sobre "usuário pode ver esta
/// tela?". Nenhum widget checa sessão manualmente, e nenhuma tela chama
/// `Navigator.push` para sair do login — o redirect faz isso, o que
/// elimina a classe de bugs "tela de login apareceu por cima do app".
///
/// A distinção crucial é entre [StatusSessao.desconhecido] e
/// [StatusSessao.anonimo]: enquanto o token não foi lido do Keychain, o
/// router **não redireciona** — caso contrário, quem já estava autenticado
/// veria um flash da tela de login a cada abertura do app.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/screens/cadastro_screen.dart';
import '../../features/auth/presentation/screens/entrar_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/avisos/presentation/avisos_screen.dart';
import '../../features/calendario/presentation/calendario_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/kai/presentation/kai_screen.dart';
import '../../features/materias/presentation/materias_screen.dart';
import '../../features/materias/presentation/unidades_screen.dart';
import '../../features/perfil/presentation/perfil_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/tarefas/presentation/tarefas_screen.dart';

/// Nomes de rota em um único lugar.
///
/// Centralizar evita literais espalhados: `context.go('/materias')` num
/// arquivo e `go('/materias/')` em outro quebram sem aviso de compilador.
abstract final class Routes {
  const Routes._();

  /// Tela de splash, exibida enquanto a sessão é verificada.
  static const String splash = '/splash';

  /// Tela de entrada.
  static const String entrar = '/entrar';

  /// Tela de criação de conta.
  static const String cadastro = '/cadastro';

  /// Home do aluno.
  static const String home = '/home';

  /// Grade de disciplinas.
  static const String materias = '/materias';

  /// Lista de tarefas.
  static const String tarefas = '/tarefas';

  /// Calendário.
  static const String calendario = '/calendario';

  /// Avisos e comunicados.
  static const String avisos = '/avisos';

  /// Perfil do aluno.
  static const String perfil = '/perfil';

  /// Chat com o agente de IA.
  static const String kai = '/kai';

  /// Unidades de uma disciplina: `/materias/12/unidades/7`.
  static String unidades(int disciplinaId, int unidadeId) =>
      '/materias/$disciplinaId/unidades/$unidadeId';

  /// Caminho do detalhe de unidades, para comparação de rota.
  static const String unidadesPrefixo =
      '/materias/:disciplinaId/unidades/:unidadeId';

  /// Prefixo literal do detalhe de unidades já com os ids preenchidos.
  ///
  /// Precisa ser separado de [unidadesPrefixo] porque o redirect compara
  /// com a URL **concreta** (`/materias/12/unidades/7`), e não com o
  /// padrão com `:`.
  static const String unidadesPrefixoReal = '/materias/';

  /// `true` quando [local] é uma tela que exige sessão.
  ///
  /// Inclui o detalhe de unidades, que fica sob `/materias/` mas é uma
  /// rota filha, e por isso não aparece em [_rotasPrivadas].
  static bool ehPrivada(String local) =>
      _rotasPrivadas.contains(local) || local.startsWith(unidadesPrefixoReal);
}

/// Telas que exigem sessão.
const Set<String> _rotasPrivadas = <String>{
  Routes.home,
  Routes.materias,
  Routes.tarefas,
  Routes.calendario,
  Routes.avisos,
  Routes.perfil,
  Routes.kai,
};

/// Constrói o [GoRouter] da aplicação.
///
/// [container] é o [ProviderContainer] do `ProviderScope`, lido dentro do
/// [redirect] para observar a sessão. Usar o container explícito (e não
/// `ref.watch` em um widget) é o que permite ao router reagir à mudança de
/// estado sem recriar o router — recriá-lo a cada mudança de sessão
/// derrubaria a pilha de navegação.
GoRouter criarRouter(ProviderContainer container) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: _SessaoListenable(container),
    debugLogDiagnostics: false,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        path: Routes.entrar,
        name: 'entrar',
        builder: (BuildContext context, GoRouterState state) =>
            const EntrarScreen(),
      ),
      GoRoute(
        path: Routes.cadastro,
        name: 'cadastro',
        builder: (BuildContext context, GoRouterState state) =>
            const CadastroScreen(),
      ),

      // ── Shell com barra inferior ────────────────────────────────────
      // `StatefulShellRoute.indexedStack` mantém o estado de cada aba ao
      // alternar entre elas: voltar das Matérias para a Home não recria a
      // Home, preservando scroll e dados já carregados. Um `ShellRoute`
      // comum (sem índice) perderia isso.
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell shell,
        ) => AppShell(shell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.home,
                name: 'home',
                builder: (BuildContext context, GoRouterState state) =>
                    const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.materias,
                name: 'materias',
                builder: (BuildContext context, GoRouterState state) =>
                    const MateriasScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: Routes.unidadesPrefixo,
                    name: 'unidades',
                    builder: (BuildContext context, GoRouterState state) {
                      final disciplinaId =
                          int.tryParse(
                            state.pathParameters['disciplinaId'] ?? '',
                          ) ??
                          0;
                      final unidadeId =
                          int.tryParse(
                            state.pathParameters['unidadeId'] ?? '',
                          ) ??
                          0;
                      return UnidadesScreen(
                        disciplinaId: disciplinaId,
                        unidadeId: unidadeId,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.tarefas,
                name: 'tarefas',
                builder: (BuildContext context, GoRouterState state) =>
                    const TarefasScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.calendario,
                name: 'calendario',
                builder: (BuildContext context, GoRouterState state) =>
                    const CalendarioScreen(),
              ),
              GoRoute(
                path: Routes.avisos,
                name: 'avisos',
                builder: (BuildContext context, GoRouterState state) =>
                    const AvisosScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.perfil,
                name: 'perfil',
                builder: (BuildContext context, GoRouterState state) =>
                    const PerfilScreen(),
              ),
              GoRoute(
                path: Routes.kai,
                name: 'kai',
                builder: (BuildContext context, GoRouterState state) =>
                    const KaiScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final sessao = container.read(authControllerProvider);
      final local = state.matchedLocation;

      return switch (sessao.status) {
        // Ainda não verificamos o token: fica no splash, que dispara
        // `restaurarSessao()` e deixa o redirect reavaliar depois.
        StatusSessao.desconhecido =>
          local == Routes.splash ? null : Routes.splash,

        // Sem sessão: telas de autenticação ficam, o resto vai para o
        // login. O destino pretendido não é salvo em `from` de propósito —
        // após o login o usuário cai na Home, que é o comportamento
        // esperado em um app com cinco abas.
        StatusSessao.anonimo => switch (local) {
          Routes.entrar || Routes.cadastro => null,
          Routes.splash => Routes.entrar,
          _ => Routes.entrar,
        },

        // Com sessão: as telas de autenticação viram irrelevantes e o
        // splash já cumpriu seu papel.
        StatusSessao.autenticado => switch (local) {
          Routes.splash => Routes.home,
          Routes.entrar || Routes.cadastro => Routes.home,
          _ => null,
        },
      };
    },
  );
}

/// Converte o estado de sessão em [Listenable] para o `go_router`.
///
/// `go_router` observa isto para reavaliar o [redirect] a cada mudança.
class _SessaoListenable extends ChangeNotifier {
  _SessaoListenable(this._container) {
    _inscrever();
  }

  final ProviderContainer _container;
  ProviderSubscription<EstadoSessao>? _assinatura;

  void _inscrever() {
    _assinatura = _container.listen<EstadoSessao>(
      authControllerProvider,
      (_, _) => notifyListeners(),
      // `fireImmediately: false` evita um `notifyListeners` durante a
      // construção do router, que acontece antes de existir listener.
      fireImmediately: false,
    );
  }

  @override
  void dispose() {
    _assinatura?.close();
    super.dispose();
  }
}
