/// Ponto de entrada de desenvolvimento: o app inteiro, sem backend.
///
/// Burlar o token não é suficiente — [AuthController.restaurarSessao] chama
/// `GET /users/me` e, sem resposta, devolve o usuário para o login. Aqui os
/// repositories são substituídos por dublês em memória, então controllers,
/// telas, navegação e gamificação são exercitados de verdade.
///
/// ```sh
/// flutter run -t lib/main_debug.dart
/// flutter run -t lib/main_debug.dart --dart-define=CE_NARIO=vazio
/// flutter run -t lib/main_debug.dart --dart-define=CE_NARIO=erro
/// flutter build apk --debug -t lib/main_debug.dart
/// ```
///
/// Só este arquivo importa `dev/`, então o alvo padrão (`main.dart`) não
/// inclui nenhum dublê no APK.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/di/providers.dart';
import 'core/utils/app_date_format.dart';
import 'dev/repositorios_falsos.dart';

/// Inicia o aplicativo com dados locais.
///
/// Os overrides são montados aqui, em vez de numa função
/// `overridesDeDebug()`, por um motivo do Riverpod 3: o tipo `Override` não
/// é exportado por `package:flutter_riverpod/flutter_riverpod.dart`, logo
/// não pode ser escrito numa assinatura. Dentro do literal `overrides:` o
/// tipo é inferido e nada precisa ser nomeado.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mesmo passo do entrypoint de produção: os dublês também devolvem
  // `DateTime`, e a Home formata em pt-BR no primeiro `build`.
  await AppDateFormat.inicializar();

  final banco = BancoFalso();
  final ponte = PonteDeSessaoExpirada();

  final container = ProviderContainer(
    overrides: [
      sessionExpiredBridgeProvider.overrideWithValue(ponte.chamar),
      authRepositoryProvider.overrideWithValue(AuthRepositoryFalso(banco)),
      disciplinaRepositoryProvider.overrideWithValue(
        DisciplinaRepositoryFalso(banco),
      ),
      unidadeRepositoryProvider.overrideWithValue(
        UnidadeRepositoryFalso(banco),
      ),
      materialRepositoryProvider.overrideWithValue(
        MaterialRepositoryFalso(banco),
      ),
      tarefaRepositoryProvider.overrideWithValue(TarefaRepositoryFalso(banco)),
      calendarioRepositoryProvider.overrideWithValue(
        CalendarioRepositoryFalso(banco),
      ),
      avisoRepositoryProvider.overrideWithValue(AvisoRepositoryFalso(banco)),
      gamificacaoRepositoryProvider.overrideWithValue(
        GamificacaoRepositoryFalso(banco),
      ),
      dashboardRepositoryProvider.overrideWithValue(
        DashboardRepositoryFalso(banco),
      ),
      kaiRepositoryProvider.overrideWithValue(KaiRepositoryFalso(banco)),
    ],
  );

  conectarPonteDeSessao(container, ponte);

  iniciarApp(container, mostrarBannerDebug: true);
}
