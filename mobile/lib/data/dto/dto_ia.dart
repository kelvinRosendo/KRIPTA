/// DTOs do agente de IA — o **Kai**.
///
/// ## Regra de arquitetura (RF06 / RN06)
///
/// O mobile **nunca** chama OpenAI, Gemini ou qualquer provedor de LLM
/// diretamente. A chamada vai sempre para `POST /api/ai/chat`, porque é o
/// servidor que detém a chave da API, aplica o limite de uso por usuário e
/// executa o filtro de conteúdo previsto na RN06. Manter a chave no
/// aplicativo a tornaria extraível por qualquer pessoa que tenha o APK —
/// o frontend web segue a mesma regra (`services/kai.js`).
///
/// ## Estado atual
///
/// Ainda não existe controller de IA no backend. O contrato abaixo é o
/// mesmo que o frontend web já consome, o que evita retrabalho quando o
/// endpoint for publicado.
library;

import 'package:json_annotation/json_annotation.dart';

part 'dto_ia.g.dart';

/// Corpo de `POST /api/ai/chat`.
///
/// ```json
/// { "message": "Monte um roteiro de estudos para hoje" }
/// ```
///
/// Note a chave `message` (inglês) — é o que o frontend web envia, apesar
/// de todo o resto da API ser em português.
@JsonSerializable(fieldRename: FieldRename.none, createToJson: true)
class KaiChatRequestDto {
  /// Cria o corpo da mensagem.
  const KaiChatRequestDto({required this.message});

  /// Texto digitado pelo aluno (ou transcrito por voz).
  final String message;

  /// Conversão a partir do JSON.
  factory KaiChatRequestDto.fromJson(Map<String, dynamic> json) =>
      _$KaiChatRequestDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$KaiChatRequestDtoToJson(this);
}

/// Resposta de `POST /api/ai/chat`.
///
/// ```json
/// { "reply": "Hoje foque em: 1) ..." }
/// ```
///
/// A chave também é `reply`, e não `response` ou `message`. O campo
/// opcional [usage] existe para uma futura contabilização de tokens e já
/// está tipado, mas **não** é lido pela interface: se o backend começar a
/// enviá-lo, nenhum consumidor precisa mudar.
@JsonSerializable(fieldRename: FieldRename.none)
class KaiChatResponseDto {
  /// Cria a resposta do Kai.
  const KaiChatResponseDto({this.reply = '', this.usage});

  /// Texto da resposta, pronto para exibição.
  @JsonKey(name: 'reply', defaultValue: '')
  final String reply;

  /// Contadores de tokens, quando o backend os fornecer.
  final KaiUsageDto? usage;

  /// Conversão a partir do JSON.
  factory KaiChatResponseDto.fromJson(Map<String, dynamic> json) =>
      _$KaiChatResponseDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$KaiChatResponseDtoToJson(this);
}

/// Uso de tokens de uma resposta do agente.
@JsonSerializable(fieldRename: FieldRename.none)
class KaiUsageDto {
  /// Cria o bloco de uso.
  const KaiUsageDto({
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.totalTokens = 0,
  });

  /// Tokens consumidos pela pergunta.
  @JsonKey(name: 'promptTokens', defaultValue: 0)
  final int promptTokens;

  /// Tokens gerados pela resposta.
  @JsonKey(name: 'completionTokens', defaultValue: 0)
  final int completionTokens;

  /// Soma dos dois.
  @JsonKey(name: 'totalTokens', defaultValue: 0)
  final int totalTokens;

  /// Conversão a partir do JSON.
  factory KaiUsageDto.fromJson(Map<String, dynamic> json) =>
      _$KaiUsageDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$KaiUsageDtoToJson(this);
}
