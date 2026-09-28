/// Chat com o agente Kai, com atalhos de sugestão.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/entities.dart';
import '../application/kai_controller.dart';

/// Tela de conversa com o Kai.
///
/// Sem histórico persistido: o backend `POST /api/ai/chat` é
/// stateless (envia uma mensagem, devolve uma resposta), então a
/// conversa vive só em memória enquanto a tela está aberta.
class KaiScreen extends ConsumerStatefulWidget {
  /// Cria a tela do Kai.
  const KaiScreen({super.key});

  @override
  ConsumerState<KaiScreen> createState() => _KaiScreenState();
}

class _KaiScreenState extends ConsumerState<KaiScreen> {
  /// Controlador do campo de texto.
  final TextEditingController _campo = TextEditingController();

  /// Chave da lista, para rolar até a última mensagem.
  final ScrollController _rolagem = ScrollController();

  @override
  void dispose() {
    _campo.dispose();
    _rolagem.dispose();
    super.dispose();
  }

  /// Envia o conteúdo do campo e limpa a caixa.
  Future<void> _enviar() async {
    final texto = _campo.text;
    if (texto.trim().isEmpty) return;

    _campo.clear();
    await ref.read(kaiControllerProvider.notifier).enviar(texto);

    // `postFrameCallback`: a mensagem só entra na lista depois do
    // `await`; rolar dentro do mesmo frame buscaria um tamanho velho.
    WidgetsBinding.instance.addPostFrameCallback((_) => _rolarAoFim());
  }

  /// Envia uma sugestão pronta.
  Future<void> _enviarSugestao(SugestaoKai sugestao) async {
    await ref.read(kaiControllerProvider.notifier).enviar(sugestao.pergunta);
    WidgetsBinding.instance.addPostFrameCallback((_) => _rolarAoFim());
  }

  /// Rola até o fim da conversa.
  void _rolarAoFim() {
    if (!_rolagem.hasClients) return;
    _rolagem.animateTo(
      _rolagem.position.maxScrollExtent,
      duration: AppLayout.routeTransition,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mensagens = ref.watch(kaiControllerProvider);
    final ocupado = ref.watch(kaiOcupadoProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Row(
          children: <Widget>[
            Icon(Icons.auto_awesome_rounded, color: AppColors.lilac),
            SizedBox(width: AppSpacing.xs),
            Text('Kai', style: AppTypography.screenTitle),
          ],
        ),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: <Widget>[
          if (mensagens.isNotEmpty)
            IconButton(
              tooltip: 'Limpar conversa',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: ocupado
                  ? null
                  : () => ref.read(kaiControllerProvider.notifier).limpar(),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayout.maxContentWidth,
          ),
          child: Column(
            children: <Widget>[
              Expanded(
                child: mensagens.isEmpty
                    ? _Vazio(aoSugerir: ocupado ? null : _enviarSugestao)
                    : ListView.builder(
                        controller: _rolagem,
                        padding: const EdgeInsets.all(AppSpacing.screenH),
                        itemCount: mensagens.length,
                        itemBuilder: (BuildContext context, int i) {
                          final mensagem = mensagens[i];
                          return _Balao(
                            mensagem: mensagem,
                            // Só o último placeholder mostra "digitando…";
                            // os anteriores já foram respondidos ou falharam.
                            digitando:
                                mensagem.pendente && i == mensagens.length - 1,
                          );
                        },
                      ),
              ),
              _Composer(campo: _campo, ocupado: ocupado, aoEnviar: _enviar),
            ],
          ),
        ),
      ),
    );
  }
}

/// Estado inicial com as sugestões prontas.
class _Vazio extends StatelessWidget {
  /// Cria o estado inicial.
  const _Vazio({required this.aoSugerir});

  /// Envia a sugestão escolhida; `null` enquanto o agente está ocupado.
  final Future<void> Function(SugestaoKai)? aoSugerir;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      children: <Widget>[
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Column(
            children: <Widget>[
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.lilacLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 34,
                  color: AppColors.lilac,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text('Olá! Sou o Kai', style: AppTypography.screenTitle),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Pergunte sobre suas matérias, monte um roteiro de estudos\n'
                'ou peça uma lista de atividades.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: AppColors.textMid),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text('Sugestões', style: AppTypography.sectionLabel),
        const SizedBox(height: AppSpacing.xs),
        for (final SugestaoKai sugestao in SugestaoKai.padroes) ...<Widget>[
          _CardSugestao(
            sugestao: sugestao,
            aoTocar: aoSugerir == null ? null : () => aoSugerir!(sugestao),
          ),
          const SizedBox(height: AppSpacing.listGap),
        ],
      ],
    );
  }
}

/// Cartão de sugestão clicável.
class _CardSugestao extends StatelessWidget {
  /// Cria o cartão.
  const _CardSugestao({required this.sugestao, required this.aoTocar});

  /// Sugestão exibida.
  final SugestaoKai sugestao;

  /// Notifica o toque; `null` desabilita.
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(sugestao.rotulo, style: AppTypography.itemTitle),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppColors.textLow,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Balão de uma mensagem.
class _Balao extends StatelessWidget {
  /// Cria o balão.
  const _Balao({required this.mensagem, required this.digitando});

  /// Mensagem exibida.
  final MensagemKai mensagem;

  /// Se mostra o indicador "digitando".
  final bool digitando;

  @override
  Widget build(BuildContext context) {
    final doUsuario = mensagem.autor == AutorMensagem.usuario;

    // Falha usa vermelho e não lilac: é a única mensagem do Kai que não é
    // uma resposta dele, e precisa se destacar da conversa normal.
    final corFundo = doUsuario
        ? AppColors.indigo
        : mensagem.erro
        ? AppColors.crimsonLight
        : AppColors.lilacLight;
    final corTexto = doUsuario
        ? Colors.white
        : mensagem.erro
        ? AppColors.crimson
        : AppColors.textHigh;

    return Align(
      alignment: doUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.listGap),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: corFundo,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(doUsuario ? 16 : 4),
            bottomRight: Radius.circular(doUsuario ? 4 : 16),
          ),
        ),
        child: digitando
            ? const _Digitando()
            : Text(
                mensagem.texto,
                style: AppTypography.body.copyWith(color: corTexto),
              ),
      ),
    );
  }
}

/// Indicador "digitando…".
class _Digitando extends StatelessWidget {
  /// Cria o indicador.
  const _Digitando();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < 3; i++) ...<Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.lilac,
              shape: BoxShape.circle,
            ),
          ),
          if (i < 2) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

/// Campo de texto e botão de envio.
class _Composer extends StatelessWidget {
  /// Cria o compositor.
  const _Composer({
    required this.campo,
    required this.ocupado,
    required this.aoEnviar,
  });

  /// Controlador do campo.
  final TextEditingController campo;

  /// Se há envio em andamento.
  final bool ocupado;

  /// Notifica o envio.
  final Future<void> Function() aoEnviar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.screenH,
        right: AppSpacing.screenH,
        top: AppSpacing.sm,
        // `viewInsets.bottom` sobe o campo junto com o teclado.
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: campo,
              enabled: !ocupado,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => aoEnviar(),
              decoration: InputDecoration(
                hintText: ocupado
                    ? 'Kai está pensando...'
                    : 'Pergunte algo ao Kai',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // Desabilitado enquanto responde: enviar várias perguntas em
          // paralelo misturaria as respostas na ordem de chegada, não na
          // ordem de envio.
          IconButton.filled(
            onPressed: ocupado ? null : aoEnviar,
            style: IconButton.styleFrom(backgroundColor: AppColors.lilac),
            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
