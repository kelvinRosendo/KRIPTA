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
import '../../../core/utils/app_number_format.dart';
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
        child: _BlocoGamificacao(
          gamificacao: dashboard.gamificacao,
          totalConquistas: dashboard.totalConquistas,
        ),
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

/// Cabeçalho com saudação, data e o atalho de avisos.
///
/// O sino vive no mesmo lugar do web (`screen-home`): à direita da
/// saudação, no mesmo tamanho dos demais botões de ícone do app.
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.primeiroNome});

  final String primeiroNome;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
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
          ),
          IconButton(
            onPressed: () => context.goNamed('avisos'),
            icon: const Icon(Icons.notifications_none_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textMid,
              side: const BorderSide(color: AppColors.border),
              fixedSize: const Size(
                AppLayout.iconButtonSize,
                AppLayout.iconButtonSize,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bloco de gamificação da Home, espelhando `screen-home` do protótipo.
///
/// São três partes, na mesma ordem do web: o "foguinho" com o anel de
/// progresso do dia e, abaixo, os cards de XP, nível e insígnias. Fica tudo
/// em um único sliver para rolar junto com as tarefas.
class _BlocoGamificacao extends StatelessWidget {
  const _BlocoGamificacao({
    required this.gamificacao,
    required this.totalConquistas,
  });

  final ResumoGamificacao gamificacao;
  final int totalConquistas;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Column(
        children: <Widget>[
          _CardFoguinho(gamificacao: gamificacao),
          const SizedBox(height: AppSpacing.listGap),
          Row(
            children: <Widget>[
              Expanded(
                child: _CardNumero(
                  valor: AppNumberFormat.milhar(gamificacao.xp),
                  rotulo: 'XP TOTAL',
                ),
              ),
              const SizedBox(width: AppSpacing.listGap),
              Expanded(
                child: _CardNumero(
                  valor: 'NÍVEL ${gamificacao.nivel}',
                  rotulo: gamificacao.tituloNivel.toUpperCase(),
                ),
              ),
              const SizedBox(width: AppSpacing.listGap),
              Expanded(
                child: _CardNumero(
                  valor: '$totalConquistas',
                  rotulo: 'INSÍGNIAS',
                  descricao: 'Ver minhas insígnias',
                  aoTocar: () => context.goNamed('perfil'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card do "foguinho": anel de progresso do dia e a frase que convida a
/// voltar amanhã.
class _CardFoguinho extends StatelessWidget {
  const _CardFoguinho({required this.gamificacao});

  final ResumoGamificacao gamificacao;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.orange, width: 1.5),
      ),
      child: Row(
        children: <Widget>[
          _AnelFoguinho(gamificacao: gamificacao),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${gamificacao.sequenciaDias} '
                  '${gamificacao.sequenciaDias == 1 ? 'dia seguido' : 'dias seguidos'}!',
                  style: AppTypography.highlightTitle,
                ),
                const SizedBox(height: 2),
                Text(_chamada(), style: AppTypography.itemMeta),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// O texto muda conforme a meta de hoje: ou falta um pouco, ou já foi
  /// batida e o quebra-foguinho de amanhã é que conta.
  String _chamada() {
    if (gamificacao.metaBatida) {
      return 'Foguinho mantido hoje! Volte amanhã para não perder a sequência.';
    }
    return 'Faltam ${gamificacao.minutosRestantes} min hoje '
        'pra manter o foguinho';
  }
}

/// Anel de progresso da meta diária, com o emoji no centro.
class _AnelFoguinho extends StatelessWidget {
  const _AnelFoguinho({required this.gamificacao});

  final ResumoGamificacao gamificacao;

  @override
  Widget build(BuildContext context) {
    final minutos = AppGamificacao.metaMinutosDiarios;

    return Semantics(
      label: gamificacao.metaBatida
          ? 'Meta diária de $minutos minutos concluída'
          : '${gamificacao.minutosHoje} de $minutos minutos de estudo hoje',
      excludeSemantics: true,
      child: SizedBox(
        width: 58,
        height: 58,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            CircularProgressIndicator(
              // `value` nulo seria indeterminado; aqui é sempre 0 a 1, e o
              // 0 mostra só o trilho, que é o estado honesto enquanto o
              // backend não mandar `minutesToday`.
              value: gamificacao.progressoHoje,
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
              color: AppColors.orange,
              backgroundColor: AppColors.orangeLight,
            ),
            const Text('🔥', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}

/// Card de estatística: número grande e rótulo em caixa alta.
class _CardNumero extends StatelessWidget {
  const _CardNumero({
    required this.valor,
    required this.rotulo,
    this.aoTocar,
    this.descricao,
  });

  final String valor;
  final String rotulo;
  final VoidCallback? aoTocar;
  final String? descricao;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  valor,
                  style: AppTypography.statValue,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  rotulo,
                  style: AppTypography.statLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: <Widget>[
            // Faixa colorida na esquerda, como o `border-l-[3px]` do web.
            // Fica dentro do `IntrinsicHeight` para acompanhar a altura do
            // conteúdo, que muda entre uma linha e duas.
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: tarefa.concluida ? AppColors.textLow : cor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadii.md),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: <Widget>[
                    // Marcador de situação. Tarefa concluída aparece riscada
                    // e esmaecida, sem sumir da lista — a Home mostra também
                    // o histórico do dia.
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            tarefa.titulo,
                            style: AppTypography.itemTitle.copyWith(
                              decoration: tarefa.concluida
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: tarefa.concluida
                                  ? AppColors.textLow
                                  : null,
                            ),
                          ),
                          if (_rodape != null) ...<Widget>[
                            const SizedBox(height: 2),
                            Text(_rodape!, style: AppTypography.itemMeta),
                          ],
                        ],
                      ),
                    ),
                    if (_pill != null) ...<Widget>[
                      const SizedBox(width: AppSpacing.xs),
                      _Pill(rotulo: _pill!, cor: cor),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Rótulo do prazo, como no web: `hoje`, `amanhã`, `atrasada` ou a data.
  ///
  /// Não aparece em tarefa sem prazo — a pílula é o que dá o senso de
  /// urgência, e uma pílula com a data repetida no metadado só duplicaria.
  String? get _pill {
    final prazo = tarefa.prazo;
    if (prazo == null || tarefa.concluida) return null;
    return switch (AppDateFormat.daysFromToday(prazo)) {
      final int d when d < 0 => 'atrasada',
      0 => 'hoje',
      1 => 'amanhã',
      _ => AppDateFormat.shortDate(prazo),
    };
  }

  /// Linha de metadados: disciplina e horário, como `Matemática · 23h59`.
  String? get _rodape {
    final partes = <String>[
      if (tarefa.disciplinaNome != null) tarefa.disciplinaNome!,
      if (tarefa.prazo case final DateTime p) AppDateFormat.dateTime(p),
    ];
    return partes.isEmpty ? null : partes.join(' · ');
  }
}

/// Pílula colorida com o rótulo do prazo (`hoje`, `amanhã`, `atrasada`).
class _Pill extends StatelessWidget {
  const _Pill({required this.rotulo, required this.cor});

  final String rotulo;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        // O web usa os tons claros do par (`bg-orange-light text-orange`).
        // A cor da linha é a chave: quem manda no fundo é a família da cor,
        // não a cor em si, o que mantém o mesmo visual para os três grupos.
        color: _fundoClaro,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        rotulo,
        style: AppTypography.pill.copyWith(color: cor, fontSize: 10.5),
      ),
    );
  }

  /// Versão clara da cor da linha, casada com o `*-Light` do design system.
  Color get _fundoClaro => switch (cor) {
    AppColors.orange => AppColors.orangeLight,
    AppColors.teal => AppColors.tealLight,
    AppColors.crimson => AppColors.crimsonLight,
    AppColors.lilac => AppColors.lilacLight,
    AppColors.indigo => AppColors.indigoLight,
    _ => AppColors.surfaceAlt,
  };
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
