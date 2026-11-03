/// Entidades do agente de IA do KRIPTA — o **Kai**.
///
/// Requisito do TCC (2.8 e RF06): o agente é alimentado pelos conteúdos das
/// matérias, tira dúvidas, gera listas de atividade, alertas e relatórios,
/// e conversa **por voz** com o usuário.
///
/// ## Estado atual da API
///
/// Ainda **não existe** controller de IA no backend. O frontend web já
/// consome `POST /api/ai/chat` com `{ "message": "..." }` e espera
/// `{ "reply": "..." }` (`services/kai.js`). O mobile chama o mesmo
/// contrato; enquanto o endpoint não existir, a implementação devolve um
/// [FalhaDeServicoIndisponivel] com mensagem amigável, e a interface
/// permanece navegável.
library;

import 'package:equatable/equatable.dart';

/// Remetente de uma mensagem do chat.
enum AutorMensagem {
  /// O aluno.
  usuario,

  /// O agente Kai.
  kai,
}

/// Uma mensagem da conversa com o Kai.
class MensagemKai extends Equatable {
  /// Cria a mensagem.
  const MensagemKai({
    required this.texto,
    required this.autor,
    this.enviadaEm,
    this.pendente = false,
    this.erro = false,
  });

  /// Cria a mensagem do aluno.
  const MensagemKai.usuario(this.texto)
    : autor = AutorMensagem.usuario,
      enviadaEm = null,
      pendente = false,
      erro = false;

  /// Cria a mensagem do Kai, já recebida da API.
  MensagemKai.kai(this.texto, {DateTime? enviadaEm})
    : autor = AutorMensagem.kai,
      enviadaEm = enviadaEm ?? DateTime.now(),
      pendente = false,
      erro = false;

  /// Cria a mensagem do Kai que falhou (endpoint ausente ou erro de rede).
  MensagemKai.falha(this.texto)
    : autor = AutorMensagem.kai,
      enviadaEm = DateTime.now(),
      pendente = false,
      erro = true;

  /// Conteúdo da mensagem.
  final String texto;

  /// Quem escreveu.
  final AutorMensagem autor;

  /// Momento do envio, quando aplicável.
  final DateTime? enviadaEm;

  /// `true` enquanto aguarda resposta — a interface mostra o "digitando…".
  final bool pendente;

  /// `true` quando a mensagem representa uma falha, e não uma resposta.
  final bool erro;

  /// Copia a mensagem com os campos alterados.
  MensagemKai copyWith({String? texto, bool? pendente, bool? erro}) =>
      MensagemKai(
        texto: texto ?? this.texto,
        autor: autor,
        enviadaEm: enviadaEm,
        pendente: pendente ?? this.pendente,
        erro: erro ?? this.erro,
      );

  @override
  List<Object?> get props => <Object?>[texto, autor, enviadaEm, pendente, erro];
}

/// Resposta do agente a uma pergunta.
class RespostaKai extends Equatable {
  /// Cria a resposta.
  const RespostaKai({required this.texto});

  /// Texto da resposta, já pronto para exibição.
  final String texto;

  @override
  List<Object?> get props => <Object?>[texto];
}

/// Sugestões rápidas exibidas como atalhos no chat.
///
/// Vêm do design do protótipo web (as duas pílulas "Roteiro de hoje" e
/// "Minhas pendências") e não dependem de endpoint.
class SugestaoKai extends Equatable {
  /// Cria a sugestão.
  const SugestaoKai({required this.rotulo, required this.pergunta});

  /// Texto do botão.
  final String rotulo;

  /// Pergunta enviada ao clicar.
  final String pergunta;

  /// Atalhos padrão do Kai.
  static const List<SugestaoKai> padroes = <SugestaoKai>[
    SugestaoKai(
      rotulo: '📋 Roteiro de hoje',
      pergunta: 'Monte um roteiro de estudos para hoje',
    ),
    SugestaoKai(
      rotulo: '📊 Minhas pendências',
      pergunta: 'Quais são minhas pendências?',
    ),
  ];

  @override
  List<Object?> get props => <Object?>[rotulo, pergunta];
}
