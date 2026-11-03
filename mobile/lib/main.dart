/// Ponto de entrada de produção do KRIPTA Mobile.
///
/// Conecta na API real. Para explorar o aplicativo sem backend, use
/// `main_debug.dart` (veja `README.md`).
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/di/providers.dart';
import 'core/utils/app_date_format.dart';

/// Inicia o aplicativo.
///
/// O [ProviderContainer] é criado **manualmente** em vez de usar
/// [ProviderScope] por causa do [sessionExpiredBridgeProvider]: o
/// interceptor de autenticação precisa avisar o [AuthController] quando o
/// servidor responde 401, e esse callback só pode ser registrado por
/// `overrideWithValue` — que só existe no momento da criação do container.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Antes de qualquer `runApp`: sem os símbolos de `pt_BR` carregados, o
  // primeiro `DateFormat` da Home derruba a tela inteira.
  await AppDateFormat.inicializar();

  final ponte = PonteDeSessaoExpirada();

  final container = ProviderContainer(
    overrides: [sessionExpiredBridgeProvider.overrideWithValue(ponte.chamar)],
  );

  conectarPonteDeSessao(container, ponte);

  iniciarApp(container);
}
