/// Grade de disciplinas (RN03), o "cardápio" do KRIPTA.
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

/// Grade de disciplinas do usuário.
class MateriasScreen extends ConsumerWidget {
  /// Cria a grade de matérias.
  const MateriasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materias = ref.watch(materiasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matérias', style: AppTypography.screenTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(materiasProvider.notifier).recarregar(),
        child: switch (materias) {
          AsyncError(:final error) => ListView(
            // Um `ListView` vazio é obrigatório dentro do
            // `RefreshIndicator`: sem área rolável, o pull-to-refresh não
            // funciona e a tela fica sem como se recuperar do erro.
            children: <Widget>[
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.6,
                child: _erro(context, ref, error),
              ),
            ],
          ),
          AsyncData(:final value) when value.isEmpty => ListView(
            children: <Widget>[
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.6,
                child: const VazioView(
                  titulo: 'Nenhuma disciplina cadastrada',
                  subtitulo: 'Quando o professor criar as matérias, elas aparecem aqui.',
                  icone: Icons.school_outlined,
                ),
              ),
            ],
          ),
          AsyncData(:final value) => _Grade(materias: value),
          _ => const CarregandoView(),
        },
      ),
    );
  }

  Widget _erro(BuildContext context, WidgetRef ref, Object erro) => ErroView(
    falha: _comoFalha(erro),
    aoTentarNovamente: () => ref.read(materiasProvider.notifier).recarregar(),
  );

  /// Converte o erro do `AsyncValue` em [Failure] para o [ErroView].
  Failure _comoFalha(Object erro) => switch (erro) {
    Failure f => f,
    _ => const UnexpectedFailure(
      message: 'Não foi possível carregar as matérias.',
    ),
  };
}

/// Grade de cards, duas colunas em telas largas.
class _Grade extends StatelessWidget {
  const _Grade({required this.materias});

  final List<Disciplina> materias;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.sm,
        AppSpacing.screenH,
        AppSpacing.xxl,
      ),
      // `SliverGridDelegateWithMaxCrossAxisExtent` se adapta à largura
      // em vez de fixar 2 colunas: em tablet, 2 colunas deixariam cards
      // gigantes e em tela pequena, 3 colunas apertariam o texto.
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.85,
      ),
      itemCount: materias.length,
      itemBuilder: (BuildContext context, int index) =>
          _CardMateria(disciplina: materias[index]),
    );
  }
}

/// Card de uma disciplina, colorido com a cor vinda do backend.
class _CardMateria extends StatelessWidget {
  const _CardMateria({required this.disciplina});

  final Disciplina disciplina;

  @override
  Widget build(BuildContext context) {
    // A cor vem do usuário (campo `cor` do backend, `#RRGGBB`). Parse
    // pode falhar se o valor vier malformado, então há fallback para o
    // indigo — um card cinza por dado inválido seria pior que perder a
    // cor personalizada.
    final cor = _parseCor(disciplina.cor);

    return InkWell(
      onTap: () => context.goNamed(
        'unidades',
        pathParameters: <String, String>{
          'disciplinaId': '${disciplina.id}',
          'unidadeId': '0',
        },
      ),
      borderRadius: BorderRadius.circular(AppSpacing.lg),
      child: Ink(
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(AppSpacing.lg),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(disciplina.icone, style: const TextStyle(fontSize: 24)),
                if (disciplina.favorita)
                  const Icon(Icons.star_rounded, color: Colors.white, size: 18),
              ],
            ),
            const Spacer(),
            Text(
              disciplina.nome,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (disciplina.pendencias > 0) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
                child: Text(
                  '${disciplina.pendencias} pendente${disciplina.pendencias == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Converte `#RRGGBB` em [Color], com fallback para o indigo.
  static Color _parseCor(String hex) {
    final valor = hex.replaceFirst('#', '');
    if (valor.length != 6) return AppColors.indigo;
    final parsed = int.tryParse('FF$valor', radix: 16);
    return parsed == null ? AppColors.indigo : Color(parsed);
  }
}
