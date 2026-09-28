/// Estado da conversa com o agente Kai.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/entities.dart';

/// Conversa com o Kai.
///
/// A lista completa mora no controller — não só a última mensagem — para
/// que a conversa inteira sobreviva ao `ref.invalidate` que o pull-to-
/// refresh dispara. O estado é `List<MensagemKai>` e não `AsyncValue`
/// porque uma falha **nunca** invalida a conversa: uma resposta perdida
/// é mostrada como falha no lugar, e as mensagens anteriores continuam
/// legíveis. Envolver tudo em `AsyncValue` deixaria o histórico inteiro
/// sob um único estado de carregamento.
class KaiController extends Notifier<List<MensagemKai>> {
  /// Perguntas em voo, para o botão desabilitar durante o envio.
  int _emVoo = 0;

  @override
  List<MensagemKai> build() => <MensagemKai>[];

  /// Envia uma pergunta ao agente.
  ///
  /// Insere a mensagem com `pendente: true` para o balão aparecer
  /// imediatamente; o placeholder é removido quando a resposta chega.
  Future<void> enviar(String pergunta) async {
    final texto = pergunta.trim();
    if (texto.isEmpty || _emVoo > 0) return;

    // Guarda a **instância** do placeholder, não o texto: duas perguntas
    // idênticas seguidas são mensagens distintas, e comparar por valor
    // (o `==` do Equatable) removeria a errada.
    final placeholder = MensagemKai.usuario(texto).copyWith(pendente: true);
    state = <MensagemKai>[...state, placeholder];
    _emVoo++;

    final resultado = await ref.read(kaiRepositoryProvider).enviar(texto);
    _emVoo--;

    // `identical` (e não `==`) garante que só este placeholder saia,
    // mesmo que o aluno tenha mandado a mesma frase duas vezes.
    final base = state
        .where((MensagemKai m) => !identical(m, placeholder))
        .toList();

    switch (resultado) {
      case Success<RespostaKai>(:final value):
        state = <MensagemKai>[...base, MensagemKai.kai(value.texto)];
      case FailureResult<RespostaKai>(:final failure):
        // A mensagem de falha entra no lugar da resposta, com a mensagem
        // do mapper: o aluno vê o que houve em vez de um silêncio.
        state = <MensagemKai>[...base, MensagemKai.falha(failure.message)];
    }
  }

  /// Limpa a conversa inteira.
  void limpar() {
    if (state.isEmpty) return;
    state = <MensagemKai>[];
  }
}

/// Conversa com o Kai, para a tela consumir.
final NotifierProvider<KaiController, List<MensagemKai>> kaiControllerProvider =
    NotifierProvider<KaiController, List<MensagemKai>>(
      KaiController.new,
      name: 'kaiController',
    );

/// `true` enquanto alguma mensagem aguarda resposta.
final Provider<bool> kaiOcupadoProvider = Provider<bool>(
  (Ref ref) => ref.watch(
    kaiControllerProvider.select(
      (List<MensagemKai> m) => m.any((MensagemKai x) => x.pendente),
    ),
  ),
  name: 'kaiOcupado',
);
