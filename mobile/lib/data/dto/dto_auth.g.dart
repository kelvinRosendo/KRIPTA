// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto_auth.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CadastroRequestDto _$CadastroRequestDtoFromJson(Map<String, dynamic> json) =>
    CadastroRequestDto(
      nome: json['nome'] as String,
      email: json['email'] as String,
      senha: json['senha'] as String,
      tipo: json['tipo'] as String,
    );

Map<String, dynamic> _$CadastroRequestDtoToJson(CadastroRequestDto instance) =>
    <String, dynamic>{
      'nome': instance.nome,
      'email': instance.email,
      'senha': instance.senha,
      'tipo': instance.tipo,
    };

CadastroResponseDto _$CadastroResponseDtoFromJson(Map<String, dynamic> json) =>
    CadastroResponseDto(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      email: json['email'] as String,
      tipo: json['tipo'] as String,
    );

Map<String, dynamic> _$CadastroResponseDtoToJson(
  CadastroResponseDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'nome': instance.nome,
  'email': instance.email,
  'tipo': instance.tipo,
};

LoginRequestDto _$LoginRequestDtoFromJson(Map<String, dynamic> json) =>
    LoginRequestDto(
      email: json['email'] as String,
      senha: json['senha'] as String,
    );

Map<String, dynamic> _$LoginRequestDtoToJson(LoginRequestDto instance) =>
    <String, dynamic>{'email': instance.email, 'senha': instance.senha};

LoginResponseDto _$LoginResponseDtoFromJson(Map<String, dynamic> json) =>
    LoginResponseDto(
      token: json['token'] as String,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: (json['expiresIn'] as num).toInt(),
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      email: json['email'] as String,
      tipo: json['tipo'] as String,
    );

Map<String, dynamic> _$LoginResponseDtoToJson(LoginResponseDto instance) =>
    <String, dynamic>{
      'token': instance.token,
      'tokenType': instance.tokenType,
      'expiresIn': instance.expiresIn,
      'id': instance.id,
      'nome': instance.nome,
      'email': instance.email,
      'tipo': instance.tipo,
    };

UsuarioResponseDto _$UsuarioResponseDtoFromJson(Map<String, dynamic> json) =>
    UsuarioResponseDto(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      email: json['email'] as String,
      tipo: json['tipo'] as String,
    );

Map<String, dynamic> _$UsuarioResponseDtoToJson(UsuarioResponseDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nome': instance.nome,
      'email': instance.email,
      'tipo': instance.tipo,
    };

AtualizarPerfilRequestDto _$AtualizarPerfilRequestDtoFromJson(
  Map<String, dynamic> json,
) => AtualizarPerfilRequestDto(
  nome: json['nome'] as String,
  email: json['email'] as String,
);

Map<String, dynamic> _$AtualizarPerfilRequestDtoToJson(
  AtualizarPerfilRequestDto instance,
) => <String, dynamic>{'nome': instance.nome, 'email': instance.email};

TrocarSenhaRequestDto _$TrocarSenhaRequestDtoFromJson(
  Map<String, dynamic> json,
) => TrocarSenhaRequestDto(
  senhaAtual: json['senhaAtual'] as String,
  novaSenha: json['novaSenha'] as String,
);

Map<String, dynamic> _$TrocarSenhaRequestDtoToJson(
  TrocarSenhaRequestDto instance,
) => <String, dynamic>{
  'senhaAtual': instance.senhaAtual,
  'novaSenha': instance.novaSenha,
};
