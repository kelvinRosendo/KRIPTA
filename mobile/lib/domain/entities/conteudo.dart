/// Entidades de conteúdo acadêmico: disciplina, tarefa, material e aviso.
library;

import 'package:equatable/equatable.dart';

/// Componente curricular (RN03).
///
/// Espelha `DisciplinaResponse` do backend:
/// ```java
/// public class DisciplinaResponse { Long id; String nome; String cor; }
/// ```
///
/// A [cor] é mantida como `String` hexadecimal (`#3D3DB4`) e só vira
/// `Color` na camada de apresentação — a entidade não depende de Flutter.
class Disciplina extends Equatable {
  /// Cria a disciplina.
  const Disciplina({
    required this.id,
    required this.nome,
    required this.cor,
    this.docente,
    this.descricao,
    this.pendencias = 0,
    this.icone = '📚',
    this.favorita = false,
  });

  /// Identificador da disciplina.
  final int id;

  /// Nome da matéria. Limite de 100 caracteres.
  final String nome;

  /// Cor de identificação no formato `#RRGGBB`, validada pelo backend.
  final String cor;

  /// Professor responsável (RN04).
  ///
  /// Ainda não existe em `DisciplinaResponse`; o campo é preenchido
  /// quando o backend enviar. Ver `RELATORIO.md` (lacunas de contrato).
  final String? docente;

  /// Descrição livre da disciplina.
  final String? descricao;

  /// Quantidade de tarefas pendentes associadas.
  ///
  /// Vem agregado no endpoint de lista, para o card mostrar "2 pendências"
  /// sem uma requisição extra por disciplina.
  final int pendencias;

  /// Emoji representativo, exibido no card.
  final String icone;

  /// Marca a disciplina como favorita do usuário.
  final bool favorita;

  /// Copia a entidade com os campos alterados.
  Disciplina copyWith({
    String? nome,
    String? cor,
    String? docente,
    String? descricao,
    int? pendencias,
    String? icone,
    bool? favorita,
  }) {
    return Disciplina(
      id: id,
      nome: nome ?? this.nome,
      cor: cor ?? this.cor,
      docente: docente ?? this.docente,
      descricao: descricao ?? this.descricao,
      pendencias: pendencias ?? this.pendencias,
      icone: icone ?? this.icone,
      favorita: favorita ?? this.favorita,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    nome,
    cor,
    docente,
    descricao,
    pendencias,
    icone,
    favorita,
  ];
}

/// Prioridade de uma tarefa.
enum PrioridadeTarefa {
  /// Baixa — sem urgency.
  baixa('LOW', 'Baixa'),

  /// Média — padrão do formulário.
  media('MEDIUM', 'Média'),

  /// Alta — atrasada ou com prazo próximo.
  alta('HIGH', 'Alta');

  const PrioridadeTarefa(this.wire, this.rotulo);

  /// Valor exato serializado pelo backend.
  final String wire;

  /// Texto exibido no formulário de tarefa.
  final String rotulo;

  /// Converte o valor do JSON; cai em [media] quando desconhecido.
  static PrioridadeTarefa fromWire(String? value) {
    for (final p in PrioridadeTarefa.values) {
      if (p.wire == value) return p;
    }
    return PrioridadeTarefa.media;
  }
}

/// Atividade acadêmica com prazo.
///
/// Não existe controller de tarefas no backend ainda; o formato segue o
/// que o frontend web consome (`services/tasks.js`).
class Tarefa extends Equatable {
  /// Cria a tarefa.
  const Tarefa({
    required this.id,
    required this.titulo,
    this.descricao,
    this.prazo,
    this.prioridade = PrioridadeTarefa.media,
    this.concluida = false,
    this.disciplinaId,
    this.disciplinaNome,
    this.xpConquistado = 0,
  });

  /// Identificador da tarefa.
  final int id;

  /// Título da atividade. Campo obrigatório.
  final String titulo;

  /// Detalhamento opcional.
  final String? descricao;

  /// Data e hora de entrega, em hora local.
  final DateTime? prazo;

  /// Prioridade declarada pelo usuário.
  final PrioridadeTarefa prioridade;

  /// Se a atividade já foi concluída.
  final bool concluida;

  /// Disciplina à qual a tarefa pertence (RN03).
  final int? disciplinaId;

  /// Nome da disciplina, preenchido pelo servidor para evitar N+1.
  final String? disciplinaNome;

  /// XP ganho ao concluir (gamificação).
  ///
  /// Vem preenchido apenas na resposta do `PATCH .../concluir`, o que
  /// permite animar o "+20 XP" na Home.
  final int xpConquistado;

  /// `true` quando o prazo já passou e a tarefa segue aberta.
  ///
  /// Compara por dia inteiro: uma tarefa que vence às 23h de hoje não é
  /// "atrasada" às 10h.
  bool get atrasada {
    if (concluida || prazo == null) return false;
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final alvo = prazo!.toLocal();
    final diaAlvo = DateTime(alvo.year, alvo.month, alvo.day);
    return diaAlvo.isBefore(hoje);
  }

  /// `true` quando o prazo é hoje (ainda não concluída).
  bool get venceHoje {
    if (concluida || prazo == null) return false;
    final agora = DateTime.now();
    return prazo!.toLocal().year == agora.year &&
        prazo!.toLocal().month == agora.month &&
        prazo!.toLocal().day == agora.day;
  }

  /// Copia a tarefa com os campos alterados.
  Tarefa copyWith({
    String? titulo,
    String? descricao,
    DateTime? prazo,
    PrioridadeTarefa? prioridade,
    bool? concluida,
    int? disciplinaId,
    String? disciplinaNome,
    int? xpConquistado,
  }) {
    return Tarefa(
      id: id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      prazo: prazo ?? this.prazo,
      prioridade: prioridade ?? this.prioridade,
      concluida: concluida ?? this.concluida,
      disciplinaId: disciplinaId ?? this.disciplinaId,
      disciplinaNome: disciplinaNome ?? this.disciplinaNome,
      xpConquistado: xpConquistado ?? this.xpConquistado,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    titulo,
    descricao,
    prazo,
    prioridade,
    concluida,
    disciplinaId,
    disciplinaNome,
    xpConquistado,
  ];
}

/// Natureza do material de estudo (RN03).
enum TipoMaterial {
  /// Documento PDF.
  pdf('PDF', 'PDF', '📄'),

  /// Link externo.
  link('LINK', 'Link', '🔗'),

  /// Vídeo.
  video('VIDEO', 'Vídeo', '🎬'),

  /// Documento editável (DOC, DOCX, slides).
  documento('DOCUMENT', 'Documento', '📃'),

  /// Anotação textual.
  nota('NOTE', 'Anotação', '📝'),

  /// Outro formato.
  outro('OTHER', 'Outro', '📎');

  const TipoMaterial(this.wire, this.rotulo, this.icone);

  /// Valor exato serializado pelo backend.
  final String wire;

  /// Texto exibido na lista.
  final String rotulo;

  /// Emoji associado, espelhando `materialIcon` do frontend web.
  final String icone;

  /// Converte o valor do JSON; cai em [outro] quando desconhecido.
  static TipoMaterial fromWire(String? value) {
    for (final t in TipoMaterial.values) {
      if (t.wire == value) return t;
    }
    return TipoMaterial.outro;
  }
}

/// Material de estudo vinculado a uma unidade curricular (RN03).
class MaterialEstudo extends Equatable {
  /// Cria o material de estudo.
  const MaterialEstudo({
    required this.id,
    required this.unidadeId,
    required this.titulo,
    this.tipo = TipoMaterial.outro,
    this.url,
    this.descricao,
    this.concluido = false,
  });

  /// Identificador do material.
  final int id;

  /// Unidade à qual o material pertence.
  final int unidadeId;

  /// Título do material.
  final String titulo;

  /// Formato do conteúdo.
  final TipoMaterial tipo;

  /// Endereço do arquivo ou link externo.
  final String? url;

  /// Observação do professor.
  final String? descricao;

  /// Se o aluno já estudou o material.
  final bool concluido;

  /// Copia o material com os campos alterados.
  MaterialEstudo copyWith({
    String? titulo,
    TipoMaterial? tipo,
    String? url,
    String? descricao,
    bool? concluido,
  }) {
    return MaterialEstudo(
      id: id,
      unidadeId: unidadeId,
      titulo: titulo ?? this.titulo,
      tipo: tipo ?? this.tipo,
      url: url ?? this.url,
      descricao: descricao ?? this.descricao,
      concluido: concluido ?? this.concluido,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    unidadeId,
    titulo,
    tipo,
    url,
    descricao,
    concluido,
  ];
}

/// Comunicado da plataforma ou do corpo docente (RN05).
class Aviso extends Equatable {
  /// Cria o aviso.
  const Aviso({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.criadoEm,
    this.disciplinaId,
    this.disciplinaNome,
  });

  /// Identificador do aviso.
  final int id;

  /// Assunto do comunicado.
  final String titulo;

  /// Corpo do comunicado.
  final String mensagem;

  /// Momento de publicação.
  final DateTime criadoEm;

  /// Disciplina relacionada, quando houver.
  final int? disciplinaId;

  /// Nome da disciplina relacionada.
  final String? disciplinaNome;

  @override
  List<Object?> get props => <Object?>[
    id,
    titulo,
    mensagem,
    criadoEm,
    disciplinaId,
    disciplinaNome,
  ];
}

/// Unidade (módulo) de uma disciplina.
///
/// Agrupa os materiais de um período letivo; é o nível intermediário
/// entre [Disciplina] e [MaterialEstudo] na regra RN03.
class Unidade extends Equatable {
  /// Cria a unidade.
  const Unidade({
    required this.id,
    required this.disciplinaId,
    required this.nome,
    this.descricao,
    this.totalMateriais = 0,
  });

  /// Identificador da unidade.
  final int id;

  /// Disciplina à qual a unidade pertence.
  final int disciplinaId;

  /// Nome da unidade (ex.: "Unidade 1 — Revisão e análise de algoritmos").
  final String nome;

  /// Descrição do conteúdo da unidade.
  final String? descricao;

  /// Quantidade de materiais, agregada pelo servidor.
  final int totalMateriais;

  @override
  List<Object?> get props => <Object?>[
    id,
    disciplinaId,
    nome,
    descricao,
    totalMateriais,
  ];
}
