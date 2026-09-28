/// Entidade [Usuario] e o perfil de acesso.
library;

import 'package:equatable/equatable.dart';

/// Perfil do usuário, espelhando `User.UserType` do backend.
///
/// ```java
/// public enum UserType { ADMIN, USUARIO }
/// ```
///
/// Observação de escopo: o TCC (RF04) prevê os atores **Aluno** e
/// **Professor**, com o professor aprovando conteúdos. O backend atual
/// trabalha com `ADMIN`/`USUARIO`. Essa divergência está registrada no
/// `RELATORIO.md`; até o backend alinhar, o mobile consome o enum real e
/// **não** inventa os papéis Aluno/Professor.
enum PerfilUsuario {
  /// Administrador do ambiente.
  admin('ADMIN'),

  /// Usuário comum (aluno, no contexto atual do MVP).
  usuario('USUARIO');

  const PerfilUsuario(this.wire);

  /// Valor exato serializado pelo Spring Boot.
  final String wire;

  /// Rótulo exibido na interface.
  String get rotulo => switch (this) {
    PerfilUsuario.admin => 'Administrador',
    PerfilUsuario.usuario => 'Aluno',
  };

  /// Converte o valor do JSON; cai em [usuario] quando desconhecido.
  ///
  /// Um papel novo no backend não pode quebrar o login do app.
  static PerfilUsuario fromWire(String? value) {
    for (final perfil in PerfilUsuario.values) {
      if (perfil.wire == value) return perfil;
    }
    return PerfilUsuario.usuario;
  }
}

/// Usuário autenticado no KRIPTA.
///
/// Espelha `UserResponse` / `LoginResponse` do backend.
///
/// A senha **nunca** faz parte desta entidade: ela é enviada no
/// `LoginRequest` e descartada assim que o `200` volta.
class Usuario extends Equatable {
  /// Cria o usuário.
  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.perfil,
  });

  /// Identificador no banco (RN01).
  final int id;

  /// Nome de exibição. Limite de 100 caracteres (RN01).
  final String nome;

  /// E-mail de acesso, único no banco (RN01). Limite de 150 caracteres.
  final String email;

  /// Perfil de acesso.
  final PerfilUsuario perfil;

  /// Primeira letra do nome, para o avatar textual.
  ///
  /// Usa o primeiro *rune* não-espaaço (e não `substring(0, 1)`) para não
  /// quebrar em emoji ou letra acentuada compostas, como "Á".
  String get inicial {
    final trimmed = nome.trim();
    if (trimmed.isEmpty) return '?';
    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }

  /// Copia a entidade com os campos alterados.
  Usuario copyWith({String? nome, String? email, PerfilUsuario? perfil}) {
    return Usuario(
      id: id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      perfil: perfil ?? this.perfil,
    );
  }

  @override
  List<Object?> get props => <Object?>[id, nome, email, perfil];
}
