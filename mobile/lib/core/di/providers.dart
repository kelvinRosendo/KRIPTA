/// Injeção de dependências do KRIPTA Mobile, com Riverpod 3.
///
/// ## Riverpod 3, sem API legada
///
/// O projeto usa apenas `Provider`, `Notifier` e `AsyncNotifier`.
///
/// As APIs `StateProvider` e `StateNotifierProvider`, que existiam no
/// Riverpod 1/2, foram removidas no 3.x e **não** são usadas aqui. Além de
/// estarem ausentes, o modelo `Notifier` é melhor para o caso do KRIPTA:
/// o estado da sessão e das listas é sempre derivado de uma operação de
/// rede, e não de um `setState` avulso.
///
/// ## Ordem de construção
///
/// ```
/// AppConfig ──▶ TokenStore ──▶ AuthInterceptor ──▶ ApiClient
///                                                       │
///                    ┌──────────────────────────────────┴──────┐
///                    ▼                                         ▼
///           AuthRepository                            DashboardRepository
/// ```
///
/// O [AuthInterceptor] recebe um callback ([refProvider]) para que o 401
/// consiga invalidar o estado de sessão sem criar dependência circular.
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/repositories.dart';
import '../../domain/repositories/repositories.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../network/auth_interceptor.dart';
import '../storage/secure_token_store.dart';

/// Configuração do build, lida dos `--dart-define`.
///
/// Pode ser sobrescrita em teste com `ProviderScope(overrides: [...])`,
/// para apontar a API para um servidor local.
final Provider<AppConfig> appConfigProvider = Provider<AppConfig>(
  (Ref ref) => AppConfig.fromEnvironment(),
  name: 'appConfig',
);

/// Armazenamento seguro do token.
///
/// Em teste, sobrescreva com um dublê em memória — assim nada toca o
/// Keychain nem o EncryptedSharedPreferences.
final Provider<TokenStore> tokenStoreProvider = Provider<TokenStore>(
  (Ref ref) => SecureTokenStore(),
  name: 'tokenStore',
);

/// Fonte de conectividade do dispositivo.
final Provider<Connectivity> connectivityProvider = Provider<Connectivity>(
  (Ref ref) => Connectivity(),
  name: 'connectivity',
);

/// Notificação de sessão expirada, emitida pelo [AuthInterceptor].
///
/// É um `Provider` que guarda apenas o callback: o interceptor não
/// conhece o `AuthController`, e o `AuthController` não conhece o
/// interceptor. Sem isso haveria um ciclo de dependência.
final Provider<SessionExpiredCallback> sessionExpiredProvider =
    Provider<SessionExpiredCallback>(
      (Ref ref) => () {
        // Preenchido em `main.dart` após o ProviderContainer existir, para
        // que o callback consiga invalidar providers já inicializados.
        ref.read(sessionExpiredBridgeProvider).call();
      },
      name: 'sessionExpired',
    );

/// Ponte entre o interceptor e o container de providers.
///
/// Permite que `main.dart` registre o callback real depois de criar o
/// container, sem o interceptor depender do `Ref` no momento da construção.
final Provider<VoidCallback> sessionExpiredBridgeProvider =
    Provider<VoidCallback>((Ref ref) => () {}, name: 'sessionExpiredBridge');

/// Interceptor de autenticação.
final Provider<AuthInterceptor> authInterceptorProvider =
    Provider<AuthInterceptor>(
      (Ref ref) => AuthInterceptor(
        tokenStore: ref.watch(tokenStoreProvider),
        onSessionExpired: ref.watch(sessionExpiredProvider),
      ),
      name: 'authInterceptor',
    );

/// Cliente HTTP compartilhado por todos os repositórios.
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>(
  (Ref ref) => ApiClient(
    config: ref.watch(appConfigProvider),
    authInterceptor: ref.watch(authInterceptorProvider),
    connectivity: ref.watch(connectivityProvider),
  ),
  name: 'apiClient',
);

/// Acesso à autenticação e à sessão.
final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>(
      (Ref ref) => AuthRepositoryImpl(
        dio: ref.watch(apiClientProvider).dio,
        tokenStore: ref.watch(tokenStoreProvider),
      ),
      name: 'authRepository',
    );

/// Acesso às disciplinas.
final Provider<DisciplinaRepository> disciplinaRepositoryProvider =
    Provider<DisciplinaRepository>(
      (Ref ref) =>
          DisciplinaRepositoryImpl(dio: ref.watch(apiClientProvider).dio),
      name: 'disciplinaRepository',
    );

/// Acesso às unidades.
final Provider<UnidadeRepository> unidadeRepositoryProvider =
    Provider<UnidadeRepository>(
      (Ref ref) => UnidadeRepositoryImpl(dio: ref.watch(apiClientProvider).dio),
      name: 'unidadeRepository',
    );

/// Acesso aos materiais.
final Provider<MaterialRepository> materialRepositoryProvider =
    Provider<MaterialRepository>(
      (Ref ref) =>
          MaterialRepositoryImpl(dio: ref.watch(apiClientProvider).dio),
      name: 'materialRepository',
    );

/// Acesso às tarefas.
final Provider<TarefaRepository> tarefaRepositoryProvider =
    Provider<TarefaRepository>(
      (Ref ref) => TarefaRepositoryImpl(dio: ref.watch(apiClientProvider).dio),
      name: 'tarefaRepository',
    );

/// Acesso ao calendário.
final Provider<CalendarioRepository> calendarioRepositoryProvider =
    Provider<CalendarioRepository>(
      (Ref ref) =>
          CalendarioRepositoryImpl(dio: ref.watch(apiClientProvider).dio),
      name: 'calendarioRepository',
    );

/// Acesso aos avisos.
final Provider<AvisoRepository> avisoRepositoryProvider =
    Provider<AvisoRepository>(
      (Ref ref) => AvisoRepositoryImpl(dio: ref.watch(apiClientProvider).dio),
      name: 'avisoRepository',
    );

/// Acesso à gamificação.
final Provider<GamificacaoRepository> gamificacaoRepositoryProvider =
    Provider<GamificacaoRepository>(
      (Ref ref) =>
          GamificacaoRepositoryImpl(dio: ref.watch(apiClientProvider).dio),
      name: 'gamificacaoRepository',
    );

/// Acesso ao dashboard da Home.
final Provider<DashboardRepository> dashboardRepositoryProvider =
    Provider<DashboardRepository>(
      (Ref ref) =>
          DashboardRepositoryImpl(dio: ref.watch(apiClientProvider).dio),
      name: 'dashboardRepository',
    );

/// Acesso ao agente de IA (Kai).
final Provider<KaiRepository> kaiRepositoryProvider = Provider<KaiRepository>(
  (Ref ref) => KaiRepositoryImpl(dio: ref.watch(apiClientProvider).dio),
  name: 'kaiRepository',
);
