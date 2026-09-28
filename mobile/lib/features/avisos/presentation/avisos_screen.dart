/// Lista de avisos por disciplina, do mais recente para o mais antigo.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/entities.dart';
import '../../tarefas/application/listas_controller.dart';

/// Tela de avisos.
///
/// Avisos não têm paginação no contrato, então a lista inteira cabe em
/// memória: agrupar por dia aqui evita outra ida ao servidor só para
/// montar as seções.
class AvisosScreen extends ConsumerWidget {
  /// Cria a tela de avisos.
  const AvisosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avisos = ref.watch(avisosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avisos', style: AppTypography.screenTitle),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(avisosProvider.notifier).recarregar(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayout.maxContentWidth,
          ),
          child: switch (avisos) {
            AsyncError<List<Aviso>>(:final error) => ErroView(
              falha: error is Failure
                  ? error
                  : const UnexpectedFailure(
                      message: 'Falha ao carregar avisos.',
                    ),
              aoTentarNovamente: () => ref.invalidate(avisosProvider),
            ),
            AsyncData<List<Aviso>>(:final value) when value.isEmpty =>
              const VazioView(
                titulo: 'Nenhum aviso',
                subtitulo: 'Quando houver comunicados, eles aparecem aqui.',
                icone: Icons.campaign_rounded,
              ),
            AsyncData<List<Aviso>>(:final value) => _ListaAgrupada(
              avisos: value,
            ),
            _ => const CarregandoView(),
          },
        ),
      ),
    );
  }
}

/// Avisos agrupados por data de publicação.
class _ListaAgrupada extends StatelessWidget {
  /// Cria a lista agrupada.
  const _ListaAgrupada({required this.avisos});

  /// Avisos recebidos do servidor.
  final List<Aviso> avisos;

  @override
  Widget build(BuildContext context) {
    // Agrupa preservando a ordem do servidor: Map mantém a ordem de
    // inserção das chaves, então a primeira ocorrência de cada dia define
    // a posição da seção.
    final porDia = <DateTime, List<Aviso>>{};
    for (final aviso in avisos) {
      final publicado = aviso.criadoEm.toLocal();
      final dia = DateTime(publicado.year, publicado.month, publicado.day);
      porDia.putIfAbsent(dia, () => <Aviso>[]).add(aviso);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        0,
        AppSpacing.screenH,
        AppSpacing.lg,
      ),
      children: <Widget>[
        for (final MapEntry(key: dia, value: lista)
            in porDia.entries) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(_rotuloDia(dia), style: AppTypography.sectionLabel),
          ),
          for (final Aviso aviso in lista) ...<Widget>[
            _CardAviso(aviso: aviso),
            const SizedBox(height: AppSpacing.listGap),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  /// Rótulo do dia, com "Hoje"/"Ontem" para os dois casos mais comuns.
  static String _rotuloDia(DateTime dia) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final diferenca = hoje.difference(dia).inDays;

    if (diferenca == 0) return 'HOJE';
    if (diferenca == 1) return 'ONTEM';

    const meses = <String>[
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];

    if (dia.year == hoje.year) {
      return '${dia.day.toString().padLeft(2, '0')}/${dia.month.toString().padLeft(2, '0')} · ${meses[dia.month - 1].toUpperCase()}';
    }
    return '${dia.day.toString().padLeft(2, '0')}/${dia.month.toString().padLeft(2, '0')}/${dia.year}';
  }
}

/// Card de um aviso.
class _CardAviso extends StatelessWidget {
  /// Cria o card.
  const _CardAviso({required this.aviso});

  /// Aviso exibido.
  final Aviso aviso;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.campaign_rounded,
                size: 20,
                color: AppColors.orange,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(aviso.titulo, style: AppTypography.highlightTitle),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(aviso.mensagem, style: AppTypography.body),
          if (aviso.disciplinaNome != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.book_rounded,
                  size: 13,
                  color: AppColors.textLow,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(aviso.disciplinaNome!, style: AppTypography.itemMeta),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
