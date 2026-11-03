/// DTOs de autenticação e usuário.
///
/// Espelham, campo a campo, os records do backend
/// (branch `feature/backend-auth`, `feature/backend-jwt` e
/// `feature/backend-users`):
///
/// ```java
/// public class RegisterRequest  { String nome, email, senha; UserType tipo; }
/// public class RegisterResponse { Long id; String nome, email; UserType tipo; }
/// public class LoginRequest     { String email, senha; }
/// public class LoginResponse    { String token, tokenType; Long expiresIn, id;
///                                 String nome, email; UserType tipo; }
/// public class UserResponse     { Long id; String nome, email; UserType tipo; }
/// ```
library;

import 'package:json_annotation/json_annotation.dart';

part 'dto_auth.g.dart';

/// Corpo de `POST /api/auth/register`.
///
/// O campo `tipo` é obrigatório pelo `@NotNull` do backend, mas o
/// formulário de cadastro do KRIPTA não expõe escolha de perfil: o app
/// envia [PerfilPadrao] sempre. A decisão de permitir escolher é do
/// backend e da equipe (ver `RELATORIO.md`).
@JsonSerializable(fieldRename: FieldRename.none, createToJson: true)
class CadastroRequestDto {
  /// Cria o corpo de cadastro.
  const CadastroRequestDto({
    required this.nome,
    required this.email,
    required this.senha,
    required this.tipo,
  });

  /// Converte os campos do formulário no corpo esperado pelo backend.
  factory CadastroRequestDto.fromForm({
    required String nome,
    required String email,
    required String senha,
    required String tipo,
  }) {
    return CadastroRequestDto(
      nome: nome.trim(),
      email: email.trim().toLowerCase(),
      senha: senha,
      tipo: tipo,
    );
  }

  /// Nome do usuário. `@NotBlank`, `@Size(max = 100)`.
  final String nome;

  /// E-mail de acesso. `@NotBlank`, `@Email`, `@Size(max = 150)`.
  final String email;

  /// Senha. `@NotBlank`, `@Size(min = 6, max = 72)`.
  final String senha;

  /// Perfil: `ADMIN` ou `USUARIO`.
  final String tipo;

  /// Perfil enviado pelo app quando o aluno cria a própria conta.
  static const String perfilPadrao = 'USUARIO';

  /// Conversão a partir do JSON.
  factory CadastroRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CadastroRequestDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$CadastroRequestDtoToJson(this);
}

/// Resposta de `POST /api/auth/register` (HTTP 201).
///
/// Repare que **não há token**: o cadastro não autentica. A tela de
/// cadastro faz o login em seguida, ou manda o usuário para a tela de
/// entrada com um aviso.
@JsonSerializable(fieldRename: FieldRename.none)
class CadastroResponseDto {
  /// Cria a resposta de cadastro.
  const CadastroResponseDto({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipo,
  });

  /// Identificador do novo usuário.
  final int id;

  /// Nome cadastrado.
  final String nome;

  /// E-mail cadastrado.
  final String email;

  /// Perfil atribuído.
  final String tipo;

  /// Conversão a partir do JSON.
  factory CadastroResponseDto.fromJson(Map<String, dynamic> json) =>
      _$CadastroResponseDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$CadastroResponseDtoToJson(this);
}

/// Corpo de `POST /api/auth/login`.
@JsonSerializable(fieldRename: FieldRename.none, createToJson: true)
class LoginRequestDto {
  /// Cria o corpo de login.
  const LoginRequestDto({required this.email, required this.senha});

  /// Converte os campos do formulário no corpo esperado pelo backend.
  factory LoginRequestDto.fromForm({
    required String email,
    required String senha,
  }) {
    return LoginRequestDto(email: email.trim().toLowerCase(), senha: senha);
  }

  /// E-mail informado.
  final String email;

  /// Senha informada.
  final String senha;

  /// Conversão a partir do JSON.
  factory LoginRequestDto.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$LoginRequestDtoToJson(this);
}

/// Resposta de `POST /api/auth/login` (HTTP 200).
///
/// Atenção ao shape: o `LoginResponse` do backend é **plano** — o token e
/// os dados do usuário vêm no mesmo objeto, e não em `{ token, user }`
/// como o frontend web manipula. O [JsonKey] abaixo mapeia o nome real.
@JsonSerializable(fieldRename: FieldRename.none)
class LoginResponseDto {
  /// Cria a resposta de login.
  const LoginResponseDto({
    required this.token,
    required this.tokenType,
    required this.expiresIn,
    required this.id,
    required this.nome,
    required this.email,
    required this.tipo,
  });

  /// JWT de acesso. Vai no header `Authorization: Bearer <token>`.
  final String token;

  /// Tipo do token. Sempre `Bearer` no backend atual.
  @JsonKey(defaultValue: 'Bearer')
  final String tokenType;

  /// Validade do token, em **segundos** (o backend divide por 1000).
  final int expiresIn;

  /// Identificador do usuário autenticado.
  final int id;

  /// Nome do usuário autenticado.
  final String nome;

  /// E-mail do usuário autenticado.
  final String email;

  /// Perfil do usuário.
  final String tipo;

  /// Conversão a partir do JSON.
  factory LoginResponseDto.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$LoginResponseDtoToJson(this);
}

/// Resposta de `GET /api/users/me` e de `PUT /api/users/me`.
@JsonSerializable(fieldRename: FieldRename.none)
class UsuarioResponseDto {
  /// Cria a resposta de usuário.
  const UsuarioResponseDto({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipo,
  });

  /// Identificador do usuário.
  final int id;

  /// Nome de exibição.
  final String nome;

  /// E-mail de acesso.
  final String email;

  /// Perfil do usuário.
  final String tipo;

  /// Conversão a partir do JSON.
  factory UsuarioResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UsuarioResponseDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$UsuarioResponseDtoToJson(this);
}

/// Corpo de `PUT /api/users/me`.
///
/// O backend **não** aceita campos parciais: `nome` e `email` são ambos
/// `@NotBlank`. Por isso a tela de perfil envia os dois.
@JsonSerializable(fieldRename: FieldRename.none, createToJson: true)
class AtualizarPerfilRequestDto {
  /// Cria o corpo de atualização.
  const AtualizarPerfilRequestDto({required this.nome, required this.email});

  /// Novo nome.
  final String nome;

  /// Novo e-mail.
  final String email;

  /// Conversão a partir do JSON.
  factory AtualizarPerfilRequestDto.fromJson(Map<String, dynamic> json) =>
      _$AtualizarPerfilRequestDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$AtualizarPerfilRequestDtoToJson(this);
}

/// Corpo de `PUT /api/users/me/senha`.
@JsonSerializable(fieldRename: FieldRename.none, createToJson: true)
class TrocarSenhaRequestDto {
  /// Cria o corpo de troca de senha.
  const TrocarSenhaRequestDto({
    required this.senhaAtual,
    required this.novaSenha,
  });

  /// Senha atual, conferida pelo backend (`SENHA_ATUAL_INCORRETA`).
  final String senhaAtual;

  /// Nova senha, com as mesmas restrições de [CadastroRequestDto.senha].
  final String novaSenha;

  /// Conversão a partir do JSON.
  factory TrocarSenhaRequestDto.fromJson(Map<String, dynamic> json) =>
      _$TrocarSenhaRequestDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$TrocarSenhaRequestDtoToJson(this);
}
