/// Lista de tarefas com filtro por status e conclusão otimista.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/entities.dart';
import '../application/listas_controller.dart';

/// Tela de tarefas.
///
/// Filtra por **status** (e não por concluída/não concluída) porque o
/// contrato expõe `StatusTarefa`; o filtro é estado local de UI, não do
/// servidor, e a lista completa já vem carregada — pedir tudo e filtrar no
/// cliente evita uma ida e volta por mudança de aba.
class TarefasScreen extends ConsumerStatefulWidget {
  /// Cria a tela de tarefas.
  const TarefasScreen({super.key});

  @override
  ConsumerState<TarefasScreen> createState() => _TarefasScreenState();
}

class _TarefasScreenState extends ConsumerState<TarefasScreen> {
  /// Aba selecionada: "Todas", "Abertas" ou "Concluídas".
  ///
  /// Nulo = todas.
  bool? _somenteAbertas;

  @override
  Widget build(BuildContext context) {
    final tarefas = ref.watch(tarefasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarefas', style: AppTypography.screenTitle),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(tarefasProvider.notifier).recarregar(),
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
              _FiltroTarefas(
                somenteAbertas: _somenteAbertas,
                aoSelecionar: (bool? valor) =>
                    setState(() => _somenteAbertas = valor),
              ),
              Expanded(
                child: switch (tarefas) {
                  AsyncError<List<Tarefa>>(:final error) => ErroView(
                    falha: error is Failure
                        ? error
                        : const UnexpectedFailure(
                            message: 'Falha ao carregar tarefas.',
                          ),
                    aoTentarNovamente: () => ref.invalidate(tarefasProvider),
                  ),
                  AsyncData<List<Tarefa>>(:final value) when value.isEmpty =>
                    const VazioView(
                      titulo: 'Nenhuma tarefa',
                      subtitulo: 'Crie sua primeira tarefa para começar.',
                      icone: Icons.checklist_rounded,
                    ),
                  AsyncData<List<Tarefa>>(:final value) => _Lista(
                    tarefas: _filtrar(value),
                    aoAlternar: (int id) => ref
                        .read(tarefasProvider.notifier)
                        .alternarConclusao(id),
                  ),
                  _ => const CarregandoView(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Aplica o filtro local sobre a lista completa.
  List<Tarefa> _filtrar(List<Tarefa> tarefas) {
    final somenteAbertas = _somenteAbertas;
    if (somenteAbertas == null) return tarefas;
    return somenteAbertas
        ? tarefas.where((Tarefa t) => !t.concluida).toList(growable: false)
        : tarefas.where((Tarefa t) => t.concluida).toList(growable: false);
  }
}

/// Filtro de status, com três estados.
class _FiltroTarefas extends StatelessWidget {
  /// Cria o filtro.
  const _FiltroTarefas({
    required this.somenteAbertas,
    required this.aoSelecionar,
  });

  /// Estado atual: nulo, `true` (abertas) ou `false` (concluídas).
  final bool? somenteAbertas;

  /// Notifica a troca de filtro.
  final ValueChanged<bool?> aoSelecionar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        0,
        AppSpacing.screenH,
        AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          _Chip(
            rotulo: 'Todas',
            selecionado: somenteAbertas == null,
            aoTocar: () => aoSelecionar(null),
          ),
          const SizedBox(width: AppSpacing.xs),
          _Chip(
            rotulo: 'Abertas',
            selecionado: somenteAbertas == true,
            aoTocar: () => aoSelecionar(true),
          ),
          const SizedBox(width: AppSpacing.xs),
          _Chip(
            rotulo: 'Concluídas',
            selecionado: somenteAbertas == false,
            aoTocar: () => aoSelecionar(false),
          ),
        ],
      ),
    );
  }
}

/// Chip de filtro.
class _Chip extends StatelessWidget {
  /// Cria o chip.
  const _Chip({
    required this.rotulo,
    required this.selecionado,
    required this.aoTocar,
  });

  /// Texto exibido.
  final String rotulo;

  /// Se está ativo.
  final bool selecionado;

  /// Notifica o toque.
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: aoTocar,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selecionado ? AppColors.indigo : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionado ? AppColors.indigo : AppColors.border,
          ),
        ),
        child: Text(
          rotulo,
          style: AppTypography.pill.copyWith(
            color: selecionado ? Colors.white : AppColors.textMid,
          ),
        ),
      ),
    );
  }
}

/// Lista rolável de tarefas.
class _Lista extends StatelessWidget {
  /// Cria a lista.
  const _Lista({required this.tarefas, required this.aoAlternar});

  /// Tarefas já filtradas.
  final List<Tarefa> tarefas;

  /// Notifica a conclusão.
  final ValueChanged<int> aoAlternar;

  @override
  Widget build(BuildContext context) {
    if (tarefas.isEmpty) {
      return const VazioView(
        titulo: 'Nada por aqui',
        subtitulo: 'Nenhuma tarefa neste filtro.',
        icone: Icons.filter_alt_off_rounded,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        0,
        AppSpacing.screenH,
        AppSpacing.lg,
      ),
      itemCount: tarefas.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.listGap),
      itemBuilder: (BuildContext context, int index) {
        final tarefa = tarefas[index];
        return _CardTarefa(tarefa: tarefa, aoAlternar: aoAlternar);
      },
    );
  }
}

/// Card de uma tarefa.
class _CardTarefa extends StatelessWidget {
  /// Cria o card.
  const _CardTarefa({required this.tarefa, required this.aoAlternar});

  /// Tarefa exibida.
  final Tarefa tarefa;

  /// Notifica a conclusão.
  final ValueChanged<int> aoAlternar;

  @override
  Widget build(BuildContext context) {
    final cor = _corPrioridade(tarefa.prioridade);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => aoAlternar(tarefa.id),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Checkbox(
                  value: tarefa.concluida,
                  onChanged: (_) => aoAlternar(tarefa.id),
                  activeColor: AppColors.success,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        tarefa.titulo,
                        style: AppTypography.itemTitle.copyWith(
                          decoration: tarefa.concluida
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: tarefa.concluida
                              ? AppColors.textLow
                              : AppColors.textHigh,
                        ),
                      ),
                      if (tarefa.descricao != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          tarefa.descricao!,
                          style: AppTypography.itemMeta,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xxs,
                        children: <Widget>[
                          _Selo(
                            texto: tarefa.prioridade.rotulo,
                            cor: cor,
                            fundo: cor.withValues(alpha: 0.12),
                          ),
                          if (tarefa.disciplinaNome != null)
                            _Selo(
                              texto: tarefa.disciplinaNome!,
                              cor: AppColors.textMid,
                              fundo: AppColors.surfaceAlt,
                            ),
                          if (tarefa.prazo != null)
                            _Selo(
                              texto: _prazo(tarefa),
                              cor: tarefa.atrasada
                                  ? AppColors.crimson
                                  : AppColors.textMid,
                              fundo: tarefa.atrasada
                                  ? AppColors.crimsonLight
                                  : AppColors.surfaceAlt,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Rótulo do prazo, com destaque quando atrasado ou vencendo hoje.
  String _prazo(Tarefa t) {
    if (t.atrasada) return 'Atrasada';
    if (t.venceHoje) return 'Hoje';
    final prazo = t.prazo!.toLocal();
    return '${prazo.day.toString().padLeft(2, '0')}/${prazo.month.toString().padLeft(2, '0')}';
  }

  /// Cor de cada prioridade (RN de gamificação).
  Color _corPrioridade(PrioridadeTarefa p) => switch (p) {
    PrioridadeTarefa.baixa => AppColors.textLow,
    PrioridadeTarefa.media => AppColors.indigo,
    PrioridadeTarefa.alta => AppColors.crimson,
  };
}

/// Selo colorido de metadado.
class _Selo extends StatelessWidget {
  /// Cria o selo.
  const _Selo({required this.texto, required this.cor, required this.fundo});

  /// Texto do selo.
  final String texto;

  /// Cor do texto.
  final Color cor;

  /// Cor de fundo.
  final Color fundo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(texto, style: AppTypography.pill.copyWith(color: cor)),
    );
  }
}
