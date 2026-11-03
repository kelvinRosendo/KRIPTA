/// DTOs de conteúdo acadêmico: disciplina, unidade, material, tarefa e aviso.
///
/// ## Status do contrato
///
/// Apenas `DisciplinaRequestDto`/`DisciplinaResponseDto` estão
/// implementados no backend (branch `feature/backend-users`). Os demais
/// seguem o contrato que o frontend web já consome
/// (`services/tasks.js`, `materials.js`, `announcements.js`), com a
/// nomenclatura em português do backend.
///
/// Os nomes de campo espelham o mock do frontend
/// (`services/dev-data.js`), que é a referência de shape mais completa
/// que temos hoje.
library;

import 'package:json_annotation/json_annotation.dart';

part 'dto_conteudo.g.dart';

// ── Disciplina ────────────────────────────────────────────────────────

/// Corpo de `POST /api/disciplinas`.
///
/// Espelha `DisciplinaRequest`:
/// ```java
/// @NotBlank @Size(max = 100) String nome;
/// @Pattern("^#[0-9A-Fa-f]{6}$")    String cor;
/// ```
@JsonSerializable(fieldRename: FieldRename.none, createToJson: true)
class DisciplinaRequestDto {
  /// Cria o corpo de disciplina.
  const DisciplinaRequestDto({required this.nome, required this.cor});

  /// Nome da matéria.
  final String nome;

  /// Cor em `#RRGGBB`.
  final String cor;

  /// Conversão a partir do JSON.
  factory DisciplinaRequestDto.fromJson(Map<String, dynamic> json) =>
      _$DisciplinaRequestDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$DisciplinaRequestDtoToJson(this);
}

/// Resposta de `/api/disciplinas`.
///
/// O [DisciplinaResponse] do backend só traz `id`, `nome` e `cor`. Os
/// campos agregados abaixo vêm da camada de apresentação do frontend web
/// e são opcionais de propósito: enquanto o backend não os enviar, o app
/// funciona com os padrões.
@JsonSerializable(fieldRename: FieldRename.none)
class DisciplinaResponseDto {
  /// Cria a resposta de disciplina.
  const DisciplinaResponseDto({
    required this.id,
    required this.nome,
    required this.cor,
    this.docente,
    this.descricao,
    this.pendencias,
    this.icone,
    this.favorita,
  });

  /// Identificador da disciplina.
  final int id;

  /// Nome da matéria.
  final String nome;

  /// Cor em `#RRGGBB`.
  final String cor;

  /// Professor responsável. Ainda não enviado pelo backend.
  ///
  /// Lido de `teacher`, o nome usado pelo frontend web. Se o backend
  /// passar a enviar `docente`, basta trocar o `name` da anotação — o
  /// mapper não muda.
  @JsonKey(name: 'teacher')
  final String? docente;

  /// Descrição livre. Ainda não enviada pelo backend.
  final String? descricao;

  /// Tarefas pendentes. Vem como `pendingCount` no frontend web.
  @JsonKey(name: 'pendingCount')
  final int? pendencias;

  /// Emoji do card. Vem como `icon` no frontend web.
  @JsonKey(name: 'icon')
  final String? icone;

  /// Marca de favorita. Vem como `isFavorite` no frontend web.
  @JsonKey(name: 'isFavorite')
  final bool? favorita;

  /// Conversão a partir do JSON.
  factory DisciplinaResponseDto.fromJson(Map<String, dynamic> json) =>
      _$DisciplinaResponseDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$DisciplinaResponseDtoToJson(this);
}

// ── Unidade ───────────────────────────────────────────────────────────

/// Resposta de `/api/disciplinas/{id}/unidades`.
@JsonSerializable(fieldRename: FieldRename.none)
class UnidadeResponseDto {
  /// Cria a resposta de unidade.
  const UnidadeResponseDto({
    required this.id,
    required this.subjectId,
    required this.name,
    this.description,
    this.materialsCount,
  });

  /// Identificador da unidade.
  final int id;

  /// Disciplina dona da unidade. Vem como `subjectId` no frontend web.
  @JsonKey(name: 'subjectId')
  final int subjectId;

  /// Nome da unidade. Vem como `name` no frontend web.
  @JsonKey(name: 'name')
  final String name;

  /// Descrição do conteúdo. Vem como `description` no frontend web.
  @JsonKey(name: 'description')
  final String? description;

  /// Total de materiais. Vem como `materialsCount` no frontend web.
  @JsonKey(name: 'materialsCount')
  final int? materialsCount;

  /// Conversão a partir do JSON.
  factory UnidadeResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UnidadeResponseDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$UnidadeResponseDtoToJson(this);
}

/// Corpo de `POST /api/disciplinas/{id}/unidades`.
@JsonSerializable(fieldRename: FieldRename.none, createToJson: true)
class UnidadeRequestDto {
  /// Cria o corpo de unidade.
  const UnidadeRequestDto({required this.name, this.description});

  /// Nome da unidade.
  final String name;

  /// Descrição opcional.
  final String? description;

  /// Conversão a partir do JSON.
  factory UnidadeRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UnidadeRequestDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$UnidadeRequestDtoToJson(this);
}

// ── Material ──────────────────────────────────────────────────────────

/// Resposta de `/api/unidades/{id}/materiais`.
@JsonSerializable(fieldRename: FieldRename.none)
class MaterialResponseDto {
  /// Cria a resposta de material.
  const MaterialResponseDto({
    required this.id,
    required this.unitId,
    required this.title,
    required this.type,
    this.url,
    this.description,
    this.completed = false,
  });

  /// Identificador do material.
  final int id;

  /// Unidade dona do material. Vem como `unitId` no frontend web.
  @JsonKey(name: 'unitId')
  final int unitId;

  /// Título do material. Vem como `title` no frontend web.
  @JsonKey(name: 'title')
  final String title;

  /// Tipo: `PDF`, `LINK`, `VIDEO`, `DOCUMENT`, `NOTE` ou `OTHER`.
  @JsonKey(name: 'type')
  final String type;

  /// Link externo ou caminho do arquivo.
  final String? url;

  /// Observação do professor.
  final String? description;

  /// Se o aluno já estudou o material.
  @JsonKey(name: 'completed', defaultValue: false)
  final bool completed;

  /// Conversão a partir do JSON.
  factory MaterialResponseDto.fromJson(Map<String, dynamic> json) =>
      _$MaterialResponseDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$MaterialResponseDtoToJson(this);
}

/// Corpo de `POST /api/unidades/{id}/materiais`.
@JsonSerializable(fieldRename: FieldRename.none, createToJson: true)
class MaterialRequestDto {
  /// Cria o corpo de material.
  const MaterialRequestDto({
    required this.title,
    required this.type,
    this.url,
    this.description,
  });

  /// Título do material.
  final String title;

  /// Tipo do conteúdo.
  final String type;

  /// Link externo ou caminho do arquivo.
  final String? url;

  /// Observação.
  final String? description;

  /// Conversão a partir do JSON.
  factory MaterialRequestDto.fromJson(Map<String, dynamic> json) =>
      _$MaterialRequestDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$MaterialRequestDtoToJson(this);
}

// ── Tarefa ────────────────────────────────────────────────────────────

/// Resposta de `/api/tarefas`.
///
/// O backend pode enviar `completed` (bool) ou `status` (`PENDING` /
/// `COMPLETED`); o mock do frontend usa `completed`. O mapper trata os
/// dois, então o DTO guarda os dois campos.
@JsonSerializable(fieldRename: FieldRename.none)
class TarefaResponseDto {
  /// Cria a resposta de tarefa.
  const TarefaResponseDto({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.priority,
    this.completed,
    this.status,
    this.subjectId,
    this.subject,
    this.gamification,
  });

  /// Identificador da tarefa.
  final int id;

  /// Título da atividade.
  final String title;

  /// Detalhamento opcional.
  final String? description;

  /// Prazo em ISO-8601 UTC. Vem como `dueDate` no frontend web.
  @JsonKey(name: 'dueDate')
  final String? dueDate;

  /// `LOW`, `MEDIUM` ou `HIGH`.
  final String? priority;

  /// Situação como booleano (formato do mock).
  final bool? completed;

  /// Situação como enum (`PENDING` / `COMPLETED`), se o backend usar.
  final String? status;

  /// Disciplina dona da tarefa.
  final int? subjectId;

  /// Objeto disciplina embutido na resposta, quando o backend inclui.
  ///
  /// Declarado como `Map<String, dynamic>?` em vez de um DTO próprio
  /// porque só os campos `id` e `name` interessam, e o formato pode variar.
  final Map<String, dynamic>? subject;

  /// Bloco de gamificação devolvido ao concluir uma tarefa.
  final XpConquistadoDto? gamification;

  /// Conversão a partir do JSON.
  factory TarefaResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TarefaResponseDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$TarefaResponseDtoToJson(this);
}

/// XP ganho ao concluir uma tarefa.
///
/// Vem em `task.gamification.xpEarned` no mock do frontend, com 20 XP
/// por conclusão.
@JsonSerializable(fieldRename: FieldRename.none)
class XpConquistadoDto {
  /// Cria o bloco de XP.
  const XpConquistadoDto({this.xpEarned = 0});

  /// Quantidade de XP ganha (ou perdida, se a tarefa foi reaberta).
  @JsonKey(name: 'xpEarned', defaultValue: 0)
  final int xpEarned;

  /// Conversão a partir do JSON.
  factory XpConquistadoDto.fromJson(Map<String, dynamic> json) =>
      _$XpConquistadoDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$XpConquistadoDtoToJson(this);
}

/// Corpo de `POST /api/tarefas` e de `PUT /api/tarefas/{id}`.
@JsonSerializable(fieldRename: FieldRename.none, createToJson: true)
class TarefaRequestDto {
  /// Cria o corpo de tarefa.
  const TarefaRequestDto({
    required this.title,
    this.description,
    this.dueDate,
    this.priority,
    this.subjectId,
  });

  /// Título da atividade.
  final String title;

  /// Detalhamento opcional.
  final String? description;

  /// Prazo em ISO-8601 **UTC** (o Spring desserializa para `Instant`,
  /// que exige offset; enviar data sem `Z` faz o backend recusar).
  @JsonKey(name: 'dueDate')
  final String? dueDate;

  /// `LOW`, `MEDIUM` ou `HIGH`.
  final String? priority;

  /// Disciplina da tarefa.
  final int? subjectId;

  /// Conversão a partir do JSON.
  factory TarefaRequestDto.fromJson(Map<String, dynamic> json) =>
      _$TarefaRequestDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$TarefaRequestDtoToJson(this);
}

// ── Aviso ─────────────────────────────────────────────────────────────

/// Resposta de `GET /api/avisos`.
@JsonSerializable(fieldRename: FieldRename.none)
class AvisoResponseDto {
  /// Cria a resposta de aviso.
  const AvisoResponseDto({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.subject,
  });

  /// Identificador do aviso.
  final int id;

  /// Assunto do comunicado.
  final String title;

  /// Corpo do comunicado.
  final String message;

  /// Momento de publicação, em ISO-8601 UTC.
  @JsonKey(name: 'createdAt')
  final String createdAt;

  /// Disciplina relacionada, quando houver.
  final Map<String, dynamic>? subject;

  /// Conversão a partir do JSON.
  factory AvisoResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AvisoResponseDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$AvisoResponseDtoToJson(this);
}

// ── Calendário ────────────────────────────────────────────────────────

/// Resposta de `GET /api/calendario`.
///
/// O backend devolve um dia sem hora (`"2026-09-28"`), então [date] é
/// `String?`: `DateTime` exigiria timezone e distorceria o dia.
@JsonSerializable(fieldRename: FieldRename.none)
class EventoCalendarioDto {
  /// Cria a resposta de evento.
  const EventoCalendarioDto({
    required this.date,
    required this.title,
    this.type,
  });

  /// Dia da ocorrência, em `yyyy-MM-dd`.
  final String date;

  /// Título do compromisso.
  final String title;

  /// `TASK`, `EXAM` ou `EVENT`.
  final String? type;

  /// Conversão a partir do JSON.
  factory EventoCalendarioDto.fromJson(Map<String, dynamic> json) =>
      _$EventoCalendarioDtoFromJson(json);

  /// Conversão para JSON.
  Map<String, dynamic> toJson() => _$EventoCalendarioDtoToJson(this);
}
