/// Códigos de erro emitidos pelo `GlobalExceptionHandler` do backend.
///
/// Fonte: `backend/src/main/java/com/kripta/exception/GlobalExceptionHandler.java`
/// (branch `feature/backend-users`).
///
/// O backend responde no formato:
/// ```json
/// {
///   "timestamp": "2026-09-28T12:00:00Z",
///   "status": "error",
///   "error": "EMAIL_JA_CADASTRADO",
///   "message": "Já existe um usuário com este e-mail",
///   "errors": { "email": "Email deve ser válido" }   // apenas em VALIDACAO
/// }
/// ```
library;

/// Códigos de negócio known pelo mobile.
///
/// Manter em sincronia com o `GlobalExceptionHandler` do backend. Se o
/// backend passar a emitir um código novo, acrescente aqui e trate em
/// `ApiErrorMapper` — nunca deixe o código "vazar" para a UI crua.
enum ApiErrorCode {
  /// E-mail já cadastrado. HTTP 409.
  emailJaCadastrado('EMAIL_JA_CADASTRADO'),

  /// E-mail ou senha incorretos. HTTP 401.
  credenciaisInvalidas('CREDENCIAIS_INVALIDAS'),

  /// Senha atual não confere na troca de senha. HTTP 400.
  senhaAtualIncorreta('SENHA_ATUAL_INCORRETA'),

  /// Usuário não encontrado. HTTP 404.
  usuarioNaoEncontrado('USUARIO_NAO_ENCONTRADO'),

  /// Disciplina não encontrada. HTTP 404.
  disciplinaNaoEncontrada('DISCIPLINA_NAO_ENCONTRADA'),

  /// Disciplina já cadastrada para o mesmo usuário. HTTP 409.
  disciplinaJaCadastrada('DISCIPLINA_JA_CADASTRADA'),

  /// Falha de validação de campos. HTTP 400, com mapa `errors`. (RN01/RN02)
  validacao('VALIDACAO'),

  /// Erro não mapeado pelo backend.
  desconhecido('ERROR');

  const ApiErrorCode(this.wire);

  /// Valor exato enviado pelo backend no campo `error`.
  final String wire;

  /// Converte o valor do JSON em enum, caindo em [desconhecido].
  ///
  /// Fallar para [desconhecido] (em vez de lançar) é deliberado: um código
  /// novo no backend não pode derrubar o app; ele apenas cai no tratamento
  /// genérico por status HTTP.
  static ApiErrorCode fromWire(String? value) {
    if (value == null || value.isEmpty) return desconhecido;
    for (final code in ApiErrorCode.values) {
      if (code.wire == value) return code;
    }
    return desconhecido;
  }
}
