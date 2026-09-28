/// Armazenamento seguro do token JWT e dos dados de sessão.
///
/// Usa `flutter_secure_storage`, que grava em:
///
/// - **Android**: `EncryptedSharedPreferences` (chave em Android Keystore);
/// - **iOS**: Keychain com `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
///
/// Valores não sensíveis (preferências de UI) ficam em
/// `shared_preferences` — ver `core/storage/local_preferences.dart`.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../logging/app_logger.dart';

/// Repositório do token de sessão.
///
/// Interface em vez de classe concreta para que os testes usem um dublê
/// em memória, sem tocar no Keychain do dispositivo.
abstract interface class TokenStore {
  /// Grava (ou substitui) o token JWT.
  Future<void> write(String token);

  /// Lê o token; `null` quando não há sessão.
  Future<String?> read();

  /// Apaga o token. Idempotente.
  Future<void> clear();
}

/// Implementação com `flutter_secure_storage`.
class SecureTokenStore implements TokenStore {
  /// Cria o store com as opções padrão de segurança.
  ///
  /// A partir da v11 o `flutter_secure_storage` criptografa **sempre** no
  /// Android (o antigo `encryptedSharedPreferences: true` foi removido) e
  /// usa AES no `storageNamespace` dedicated. No iOS, o item fica no
  /// Keychain com `first_unlock_this_device`: legível após o primeiro
  /// desbloqueio e nunca sincronizado para o backup do iCloud.
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(storageNamespace: 'kripta'),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  final FlutterSecureStorage _storage;

  /// Chave da entrada no armazenamento seguro. Espelha `state.js` do web
  /// (`kripta_token`), o que facilita depurar os dois clientes lado a lado.
  static const String tokenKey = 'kripta_token';

  final AppLogger _log = AppLogger('secure_token_store');

  @override
  Future<void> write(String token) async {
    await _storage.write(key: tokenKey, value: token);
    // Nunca logar o valor; só o tamanho, para correlacionar com o log de rede.
    _log.debug('token gravado (${token.length} caracteres)');
  }

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: tokenKey);
    } on Exception catch (error) {
      // Keychain pode estar corrompido (restauração de backup, troca de
      // senha do dispositivo). Tratar como "sem sessão" é mais seguro do
      // que travar o app no splash.
      _log.warning('falha ao ler token; tratando como ausente', error: error);
      return null;
    }
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: tokenKey);
    _log.debug('token removido');
  }
}
