/// Widgets de estado reutilizáveis: carregando, erro, vazio e conteúdo.
///
/// ## Por que existe esta camada
///
/// Toda tela do KRIPTA passa pelos mesmos quatro estados — carregando,
/// erro, vazio e conteúdo. Centralizar isso aqui garante que:
///
/// - a mensagem de erro seja sempre a mesma, vinda do [Failure];
/// - a ação "tentar novamente" apareça sempre que [Failure.isRetryable]
///   for `true`, sem cada tela decidir por conta própria;
/// - o layout não "pule" ao alternar entre os estados.
library;

import 'package:flutter/material.dart';

import '../../core/error/failure.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Exibe um indicador de carregamento com mensagem opcional.
class CarregandoView extends StatelessWidget {
  /// Cria a visão de carregamento.
  const CarregandoView({super.key, this.mensagem});

  /// Texto exibido abaixo do indicador.
  final String? mensagem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(strokeWidth: 3),
          if (mensagem case final String texto) ...<Widget>[
            const SizedBox(height: 16),
            Text(texto, style: AppTypography.body),
          ],
        ],
      ),
    );
  }
}

/// Exibe uma falha com ação opcional de "tentar novamente".
///
/// O botão de nova tentativa só aparece quando a falha é retentável —
/// repetir um erro de validação ou de contrato só gasta bateria.
class ErroView extends StatelessWidget {
  /// Cria a visão de erro.
  const ErroView({
    super.key,
    required this.falha,
    this.aoTentarNovamente,
    this.textoAcao,
  });

  /// Falha a exibir.
  final Failure falha;

  /// Disparado pelo botão de nova tentativa.
  final VoidCallback? aoTentarNovamente;

  /// Rótulo do botão. Padrão: "Tentar novamente".
  final String? textoAcao;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.crimsonLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 36,
                color: AppColors.crimson,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              falha.message,
              textAlign: TextAlign.center,
              style: AppTypography.screenTitle,
            ),
            if (falha.statusCode case final int codigo) ...<Widget>[
              const SizedBox(height: 6),
              Text('Erro $codigo', style: AppTypography.itemMeta),
            ],
            if (aoTentarNovamente != null && falha.isRetryable) ...<Widget>[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: aoTentarNovamente,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(textoAcao ?? 'Tentar novamente'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Exibe um estado vazio com ícone, texto e ação opcional.
class VazioView extends StatelessWidget {
  /// Cria a visão de estado vazio.
  const VazioView({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.icone = Icons.inbox_rounded,
    this.acao,
    this.textoAcao,
  });

  /// Título do estado vazio.
  final String titulo;

  /// Explicação abaixo do título.
  final String? subtitulo;

  /// Ícone ilustrativo.
  final IconData icone;

  /// Callback do botão de ação.
  final VoidCallback? acao;

  /// Rótulo do botão de ação.
  final String? textoAcao;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(icone, size: 36, color: AppColors.textLow),
            ),
            const SizedBox(height: 20),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: AppTypography.screenTitle,
            ),
            if (subtitulo case final String texto) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                texto,
                textAlign: TextAlign.center,
                style: AppTypography.itemMeta,
              ),
            ],
            if (acao != null && textoAcao != null) ...<Widget>[
              const SizedBox(height: 24),
              FilledButton(onPressed: acao, child: Text(textoAcao!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Aviso não bloqueante exibido no topo da tela.
///
/// Usado para falhas de recurso-secundário (gamificação indisponível
/// enquanto a Home carrega) sem tomar a tela inteira.
class FaixaAviso extends StatelessWidget {
  /// Cria a faixa de aviso.
  const FaixaAviso({
    super.key,
    required this.mensagem,
    this.icone,
    this.aoFechar,
  });

  /// Texto do aviso.
  final String mensagem;

  /// Ícone à esquerda. Padrão: [Icons.info_outline_rounded].
  final IconData? icone;

  /// Callback do botão de fechar.
  final VoidCallback? aoFechar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.orangeLight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            Icon(
              icone ?? Icons.info_outline_rounded,
              size: 20,
              color: AppColors.orange,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(mensagem, style: AppTypography.itemMeta)),
            if (aoFechar != null)
              IconButton(
                onPressed: aoFechar,
                icon: const Icon(Icons.close_rounded, size: 18),
                visualDensity: VisualDensity.compact,
                tooltip: 'Fechar aviso',
              ),
          ],
        ),
      ),
    );
  }
}
