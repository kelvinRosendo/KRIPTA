// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto_ia.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KaiChatRequestDto _$KaiChatRequestDtoFromJson(Map<String, dynamic> json) =>
    KaiChatRequestDto(message: json['message'] as String);

Map<String, dynamic> _$KaiChatRequestDtoToJson(KaiChatRequestDto instance) =>
    <String, dynamic>{'message': instance.message};

KaiChatResponseDto _$KaiChatResponseDtoFromJson(Map<String, dynamic> json) =>
    KaiChatResponseDto(
      reply: json['reply'] as String? ?? '',
      usage: json['usage'] == null
          ? null
          : KaiUsageDto.fromJson(json['usage'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$KaiChatResponseDtoToJson(KaiChatResponseDto instance) =>
    <String, dynamic>{'reply': instance.reply, 'usage': instance.usage};

KaiUsageDto _$KaiUsageDtoFromJson(Map<String, dynamic> json) => KaiUsageDto(
  promptTokens: (json['promptTokens'] as num?)?.toInt() ?? 0,
  completionTokens: (json['completionTokens'] as num?)?.toInt() ?? 0,
  totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$KaiUsageDtoToJson(KaiUsageDto instance) =>
    <String, dynamic>{
      'promptTokens': instance.promptTokens,
      'completionTokens': instance.completionTokens,
      'totalTokens': instance.totalTokens,
    };
