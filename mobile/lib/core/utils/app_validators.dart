/// Validadores de formulário reutilizáveis.
///
/// As regras espelham as anotações `jakarta.validation` dos DTOs do
/// backend, para o usuário ver o erro **antes** de gastar uma requisição:
///
/// | Campo   | Regra no backend (`RegisterRequest`)         |
/// |---------|----------------------------------------------|
/// | nome    | `@NotBlank`, `@Size(max = 100)`               |
/// | email   | `@NotBlank`, `@Email`, `@Size(max = 150)`      |
/// | senha   | `@NotBlank`, `@Size(min = 6, max = 72)`       |
/// | cor     | `@Pattern("^#[0-9A-Fa-f]{6}$")`                |
///
/// Manter as duas pontas em sincronia é regra do projeto: se o backend
/// mudar um limite, o mobile muda junto (ver `ai/rules.md`).
library;

/// Funções de validação e seus retornos.
///
/// Cada método devolve `null` quando o valor é válido, ou a mensagem de
/// erro pronta para exibir — exatamente o contrato de
/// `TextFormField.validator`.
abstract final class AppValidators {
  /// Tamanho mínimo da senha (BCrypt trunca em 72 bytes).
  static const int minPasswordLength = 6;

  /// Tamanho máximo da senha.
  static const int maxPasswordLength = 72;

  /// Tamanho máximo do nome.
  static const int maxNameLength = 100;

  /// Tamanho máximo do e-mail.
  static const int maxEmailLength = 150;

  /// Valida campo obrigatório.
  ///
  /// Usa [label] no mensagem, ex.: `'Nome é obrigatório'`.
  static String? required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label é obrigatório';
    return null;
  }

  /// Valida tamanho máximo, espelhando `@Size(max = ...)`.
  static String? maxLength(String? value, int max, String label) {
    if (value == null || value.isEmpty) return null;
    if (value.trim().length > max)
      return '$label deve ter no máximo $max caracteres';
    return null;
  }

  /// Valida tamanho mínimo, espelhando `@Size(min = ...)`.
  static String? minLength(String? value, int min, String label) {
    if (value == null || value.isEmpty) return null;
    if (value.trim().length < min)
      return '$label deve ter no mínimo $min caracteres';
    return null;
  }

  /// Valida formato de e-mail.
  ///
  /// A expressão é deliberadamente permissiva (o que o `jakarta.validation`
  /// também é): o objetivo é pegar erro de digitação, e o servidor continua
  /// sendo a autoridade. Note que `\s` também é rejeitado, evitando
  /// `"a b@x.com"`, que o Hibernate Aceita.
  static final RegExp _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  /// Valida e-mail, opcionalmente exigindo-o.
  static String? email(String? value, {bool requiredField = true}) {
    final base = required(value, 'Email');
    if (base != null) return requiredField ? base : null;

    final trimmed = value!.trim();
    if (trimmed.length > maxEmailLength) {
      return 'Email deve ter no máximo $maxEmailLength caracteres';
    }
    if (!_emailPattern.hasMatch(trimmed)) return 'Email deve ser válido';
    return null;
  }

  /// Valida senha (tamanho mínimo e máximo).
  static String? password(String? value, {String label = 'Senha'}) {
    final base = required(value, label);
    if (base != null) return base;
    if (value!.length < minPasswordLength) {
      return '$label deve ter entre $minPasswordLength e $maxPasswordLength caracteres';
    }
    if (value.length > maxPasswordLength) {
      return '$label deve ter entre $minPasswordLength e $maxPasswordLength caracteres';
    }
    return null;
  }

  /// Valida cor hexadecimal de disciplina (`DisciplinaRequest.cor`).
  ///
  /// A cor é usada no card da matéria; um valor malformado quebraria o
  /// `Color` do Flutter.
  static final RegExp _hexColorPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

  /// Valida `#RRGGBB`.
  static String? hexColor(String? value, {bool requiredField = false}) {
    if (value == null || value.isEmpty) {
      return requiredField ? 'Cor é obrigatória' : null;
    }
    if (!_hexColorPattern.hasMatch(value)) {
      return 'Cor deve estar no formato hexadecimal (ex.: #FF5733)';
    }
    return null;
  }

  /// Confirma que os dois campos de senha coincidem.
  static String? passwordsMatch(String? first, String? second) {
    if (first == null || second == null) return 'Confirme a nova senha';
    if (first != second) return 'As senhas não conferem';
    return null;
  }

  /// Valida um título de tarefa/material (limite do `TaskRequest` do backend).
  static String? title(String? value, {int max = 150}) {
    final base = required(value, 'Título');
    if (base != null) return base;
    return maxLength(value, max, 'Título');
  }
}
