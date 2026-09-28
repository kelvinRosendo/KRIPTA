/// Home do aluno: saudação, sequência, atalhos e tarefas por prazo.
///
/// A tela é um único [CustomScrollView] com slivers, para que a lista de
/// tarefas role junto com o cabeçalho em vez de ter duas áreas roláveis
/// competindo pelo mesmo gesto.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_date_format.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/entities.dart';
import '../application/home_controller.dart';

/// Tela inicial do aplicativo.
class HomeScreen extends ConsumerWidget {
  /// Cria a Home.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(homeProvider);
    final primeiroNome = ref.watch(primeiroNomeProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(homeProvider.notifier).recarregar(),
          child: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(child: _Cabecalho(primeiroNome: primeiroNome)),

              // `when` do AsyncValue resolve os quatro estados sem
              // aninhamento de if/else no build.
              ...switch (dashboard) {
                AsyncError(:final error) => <Widget>[
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErroView(
                      falha: error is Failure ? error : _falhaGenerica(error),
                      aoTentarNovamente: () =>
                          ref.read(homeProvider.notifier).recarregar(),
                    ),
                  ),
                ],
                AsyncData(:final value) => _corpo(context, ref, value),
                // `isLoading` com valor preservado (refresh): mostra a
                // faixa de progresso e mantém o conteúdo.
                AsyncLoading(hasValue: true) => <Widget>[
                  const SliverToBoxAdapter(
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                  ..._corpo(context, ref, dashboard.requireValue),
                ],
                _ => const <Widget>[
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: CarregandoView(),
                  ),
                ],
              },
            ],
          ),
        ),
      ),
    );
  }

  /// Slivers do conteúdo carregado.
  List<Widget> _corpo(
    BuildContext context,
    WidgetRef ref,
    Dashboard dashboard,
  ) {
    return <Widget>[
      SliverToBoxAdapter(
        child: _CardGamificacao(gamificacao: dashboard.gamificacao),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

      if (dashboard.totalAbertas > 0) ...<Widget>[
        SliverToBoxAdapter(
          child: _SectionLabel(
            titulo: 'Tarefas',
            acao: 'Ver todas',
            aoTocar: () => context.goNamed('tarefas'),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

        if (dashboard.tarefasAtrasadas.isNotEmpty) ...<Widget>[
          _GrupoTarefas(
            titulo: 'Atrasadas',
            cor: AppColors.crimson,
            tarefas: dashboard.tarefasAtrasadas,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        ],
        if (dashboard.tarefasHoje.isNotEmpty) ...<Widget>[
          _GrupoTarefas(
            titulo: 'Hoje',
            cor: AppColors.orange,
            tarefas: dashboard.tarefasHoje,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        ],
        if (dashboard.tarefasAmanha.isNotEmpty) ...<Widget>[
          _GrupoTarefas(
            titulo: 'Amanhã',
            cor: AppColors.teal,
            tarefas: dashboard.tarefasAmanha,
          ),
        ],
      ] else
        const SliverToBoxAdapter(
          child: VazioView(
            titulo: 'Tudo em dia',
            subtitulo: 'Nenhuma tarefa pendente para hoje ou amanhã.',
            icone: Icons.celebration_rounded,
          ),
        ),

      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
      SliverToBoxAdapter(child: _Atalhos()),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
    ];
  }

  /// Converte um erro inesperado em [Failure], para o [ErroView] poder
  /// tratá-lo sem `is` espalhado.
  Failure _falhaGenerica(Object erro) => switch (erro) {
    Failure f => f,
    _ => const UnexpectedFailure(message: 'Não foi possível carregar a Home.'),
  };
}

/// Cabeçalho com saudação e data.
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.primeiroNome});

  final String primeiroNome;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.lg,
        AppSpacing.screenH,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${AppDateFormat.greeting()}, $primeiroNome',
            style: AppTypography.screenTitle,
          ),
          const SizedBox(height: 2),
          Text(
            AppDateFormat.fullDate(DateTime.now()),
            style: AppTypography.itemMeta,
          ),
        ],
      ),
    );
  }
}

/// Card de destaque com XP, nível e sequência de dias.
class _CardGamificacao extends StatelessWidget {
  const _CardGamificacao({required this.gamificacao});

  final ResumoGamificacao gamificacao;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[AppColors.indigo, AppColors.lilac],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _Stat(valor: '${gamificacao.xp}', rotulo: 'XP'),
          _Stat(valor: 'Nv ${gamificacao.nivel}', rotulo: 'Nível'),
          _Stat(valor: '${gamificacao.sequenciaDias}', rotulo: 'Dias seguidos'),
        ],
      ),
    );
  }
}

/// Número em destaque com rótulo abaixo.
class _Stat extends StatelessWidget {
  const _Stat({required this.valor, required this.rotulo});

  final String valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          valor,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          rotulo,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

/// Rótulo de seção com ação opcional à direita.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.titulo, this.acao, this.aoTocar});

  final String titulo;
  final String? acao;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(titulo, style: AppTypography.sectionTitle),
          if (acao != null && aoTocar != null)
            TextButton(onPressed: aoTocar, child: Text(acao!)),
        ],
      ),
    );
  }
}

/// Grupo de tarefas com um cabeçalho colorido.
class _GrupoTarefas extends StatelessWidget {
  const _GrupoTarefas({
    required this.titulo,
    required this.cor,
    required this.tarefas,
  });

  final String titulo;
  final Color cor;
  final List<TarefaRef> tarefas;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
        // A primeira posição é o cabeçalho do grupo.
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.xs,
              AppSpacing.screenH,
              AppSpacing.xs,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: cor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(titulo, style: AppTypography.statLabel),
              ],
            ),
          );
        }
        return _CardTarefa(tarefa: tarefas[index - 1], cor: cor);
      }, childCount: tarefas.length + 1),
    );
  }
}

/// Card de uma tarefa resumida.
class _CardTarefa extends StatelessWidget {
  const _CardTarefa({required this.tarefa, required this.cor});

  final TarefaRef tarefa;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        0,
        AppSpacing.screenH,
        AppSpacing.listGap,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          // Marcador de situação. Tarefa concluída aparece riscada e
          // esmaecida, sem sumir da lista — a Home mostra também o
          // histórico do dia.
          Icon(
            tarefa.concluida
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: tarefa.concluida ? AppColors.success : cor,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  tarefa.titulo,
                  style: AppTypography.itemTitle.copyWith(
                    decoration: tarefa.concluida
                        ? TextDecoration.lineThrough
                        : null,
                    color: tarefa.concluida ? AppColors.textLow : null,
                  ),
                ),
                if (tarefa.disciplinaNome != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(tarefa.disciplinaNome!, style: AppTypography.itemMeta),
                ],
              ],
            ),
          ),
          if (tarefa.prazo case final DateTime prazo) ...<Widget>[
            const SizedBox(width: AppSpacing.xs),
            Text(
              AppDateFormat.daysFromToday(prazo) == 0
                  ? 'hoje'
                  : AppDateFormat.shortDate(prazo),
              style: AppTypography.itemMeta,
            ),
          ],
        ],
      ),
    );
  }
}

/// Atalhos para as outras abas.
class _Atalhos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: <Widget>[
          _Atalho(
            icone: Icons.school_rounded,
            rotulo: 'Matérias',
            cor: AppColors.teal,
            aoTocar: () => context.goNamed('materias'),
          ),
          _Atalho(
            icone: Icons.checklist_rounded,
            rotulo: 'Tarefas',
            cor: AppColors.orange,
            aoTocar: () => context.goNamed('tarefas'),
          ),
          _Atalho(
            icone: Icons.auto_awesome_rounded,
            rotulo: 'Kai',
            cor: AppColors.lilac,
            aoTocar: () => context.goNamed('kai'),
          ),
          _Atalho(
            icone: Icons.campaign_rounded,
            rotulo: 'Avisos',
            cor: AppColors.indigo,
            aoTocar: () => context.goNamed('avisos'),
          ),
        ],
      ),
    );
  }
}

/// Botão de atalho com ícone colorido.
class _Atalho extends StatelessWidget {
  const _Atalho({
    required this.icone,
    required this.rotulo,
    required this.cor,
    required this.aoTocar,
  });

  final IconData icone;
  final String rotulo;
  final Color cor;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: aoTocar,
      avatar: Icon(icone, size: 18, color: cor),
      label: Text(rotulo),
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
    );
  }
}
