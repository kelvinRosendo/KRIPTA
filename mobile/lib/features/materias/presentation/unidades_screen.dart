/// Unidades de uma disciplina e seus materiais.
///
/// Tela de duas listas encadeadas: unidades no topo, materiais da unidade
/// selecionada abaixo. O [unidadeId] chega pela rota; `0` significa
/// "nenhima selecionada ainda", e nesse caso só a lista de unidades
/// aparece.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/entities.dart';
import '../application/materias_controller.dart';

/// Detalhe de unidades e materiais.
class UnidadesScreen extends ConsumerWidget {
  /// Cria a tela de unidades.
  const UnidadesScreen({
    super.key,
    required this.disciplinaId,
    required this.unidadeId,
  });

  /// Disciplina dona das unidades.
  final int disciplinaId;

  /// Unidade selecionada, ou `0` para nenhuma.
  final int unidadeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unidades = ref.watch(unidadesProvider(disciplinaId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unidades', style: AppTypography.screenTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: switch (unidades) {
        AsyncError(:final error) => ErroView(
          falha: _comoFalha(error),
          aoTentarNovamente: () =>
              ref.invalidate(unidadesProvider(disciplinaId)),
        ),
        AsyncData(:final value) when value.isEmpty => const VazioView(
          titulo: 'Sem unidades',
          subtitulo: 'Esta disciplina ainda não tem unidades cadastradas.',
          icone: Icons.folder_open_rounded,
        ),
        AsyncData(:final value) => _Conteudo(
          disciplinaId: disciplinaId,
          unidadeId: unidadeId,
          unidades: value,
        ),
        _ => const CarregandoView(),
      },
    );
  }

  Failure _comoFalha(Object erro) => switch (erro) {
    Failure f => f,
    _ => const UnexpectedFailure(
      message: 'Não foi possível carregar as unidades.',
    ),
  };
}

/// Lista de unidades e, abaixo, os materiais da selecionada.
class _Conteudo extends ConsumerWidget {
  const _Conteudo({
    required this.disciplinaId,
    required this.unidadeId,
    required this.unidades,
  });

  final int disciplinaId;
  final int unidadeId;
  final List<Unidade> unidades;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materiais = unidadeId == 0
        ? null
        : ref.watch(materiaisProvider(unidadeId));

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.sm,
        AppSpacing.screenH,
        AppSpacing.xxl,
      ),
      children: <Widget>[
        const Text('UNIDADES', style: AppTypography.sectionLabel),
        const SizedBox(height: AppSpacing.xs),
        ...unidades.map(
          (Unidade u) => _CardUnidade(
            unidade: u,
            selecionada: u.id == unidadeId,
            // Tocar navega para a rota da própria unidade. O `unidadeId: 0`
            // chega da grade de matérias, onde ainda não há seleção.
            aoTocar: () => context.goNamed(
              'unidades',
              pathParameters: <String, String>{
                'disciplinaId': '$disciplinaId',
                'unidadeId': '${u.id}',
              },
            ),
          ),
        ),

        // Só existe seção de materiais quando há unidade selecionada.
        if (unidadeId != 0) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          const Text('MATERIAIS', style: AppTypography.sectionLabel),
          const SizedBox(height: AppSpacing.xs),
          ...switch (materiais) {
            null => const <Widget>[CarregandoView()],
            AsyncError<List<MaterialEstudo>>(:final error) => <Widget>[
              ErroView(
                falha: error is Failure
                    ? error
                    : const UnexpectedFailure(
                        message: 'Falha ao carregar materiais.',
                      ),
                aoTentarNovamente: () =>
                    ref.invalidate(materiaisProvider(unidadeId)),
              ),
            ],
            AsyncData<List<MaterialEstudo>>(:final value) when value.isEmpty =>
              const <Widget>[
                VazioView(
                  titulo: 'Sem materiais',
                  subtitulo: 'Esta unidade ainda não tem materiais.',
                  icone: Icons.description_outlined,
                ),
              ],
            AsyncData<List<MaterialEstudo>>(:final value) =>
              value
                  .map(
                    (MaterialEstudo m) => _CardMaterial(
                      material: m,
                      aoAlternar: () => ref
                          .read(materiaisProvider(unidadeId).notifier)
                          .alternarConclusao(m.id),
                    ),
                  )
                  .toList(growable: false),
            // `AsyncLoading`: a família devolve `null` enquanto a primeira
            // carga não termina, mas um `invalidate` posterior passa por
            // aqui com o valor antigo preservado.
            _ => const <Widget>[CarregandoView()],
          },
        ],
      ],
    );
  }
}

/// Card de uma unidade.
class _CardUnidade extends StatelessWidget {
  const _CardUnidade({
    required this.unidade,
    required this.selecionada,
    required this.aoTocar,
  });

  final Unidade unidade;
  final bool selecionada;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.listGap),
      decoration: BoxDecoration(
        color: selecionada ? AppColors.indigoLight : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(
          color: selecionada ? AppColors.indigo : AppColors.border,
        ),
      ),
      child: ListTile(
        onTap: aoTocar,
        title: Text(unidade.nome, style: AppTypography.itemTitle),
        subtitle: unidade.descricao == null
            ? null
            : Text(
                unidade.descricao!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.itemMeta,
              ),
        trailing: Text(
          '${unidade.totalMateriais}',
          style: AppTypography.itemMeta,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
      ),
    );
  }
}

/// Card de um material, com caixa de seleção.
class _CardMaterial extends StatelessWidget {
  /// Cria o card.
  const _CardMaterial({required this.material, required this.aoAlternar});

  /// Material exibido.
  final MaterialEstudo material;

  /// Notifica a conclusão.
  final VoidCallback aoAlternar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.listGap),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Checkbox(
            value: material.concluido,
            onChanged: (_) => aoAlternar(),
            activeColor: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(material.tipo.icone),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              material.titulo,
              style: AppTypography.itemTitle.copyWith(
                decoration: material.concluido
                    ? TextDecoration.lineThrough
                    : null,
                color: material.concluido ? AppColors.textLow : null,
              ),
            ),
          ),
          Text(material.tipo.rotulo, style: AppTypography.itemMeta),
        ],
      ),
    );
  }
}
