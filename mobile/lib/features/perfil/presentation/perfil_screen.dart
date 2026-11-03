/// Perfil do usuário: dados, papel, edição de nome/e-mail e saída.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_date_format.dart';
import '../../../core/utils/app_number_format.dart';
import '../../../core/utils/result.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/entities.dart';
import '../../auth/application/auth_controller.dart';
import '../../gamificacao/application/gamificacao_controller.dart';

/// Tela de perfil.
///
/// Reaproveita o usuário já guardado em [AuthController] em vez de buscar
/// `GET /api/auth/me` de novo: o login acabou de fornecer os mesmos dados,
/// e a tela deve abrir instantaneamente mesmo offline.
class PerfilScreen extends ConsumerWidget {
  /// Cria a tela de perfil.
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioAtualProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil', style: AppTypography.screenTitle),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayout.maxContentWidth,
          ),
          child: switch (usuario) {
            final Usuario u => _Corpo(usuario: u),
            null => const VazioView(
              titulo: 'Sem sessão',
              subtitulo: 'Entre novamente para ver seu perfil.',
              icone: Icons.person_off_rounded,
            ),
          },
        ),
      ),
    );
  }
}

/// Conteúdo do perfil.
class _Corpo extends ConsumerStatefulWidget {
  /// Cria o corpo.
  const _Corpo({required this.usuario});

  /// Usuário exibido.
  final Usuario usuario;

  @override
  ConsumerState<_Corpo> createState() => _CorpoState();
}

class _CorpoState extends ConsumerState<_Corpo> {
  @override
  Widget build(BuildContext context) {
    final usuario = widget.usuario;
    final gamificacao = ref.watch(gamificacaoPerfilProvider);

    // A linha "Nível 4 · Curioso · 1.240 XP" fica no cabeçalho, mas só
    // quando os números chegaram: um `Nível 0` inventado durante o
    // carregamento seria pior do que a linha ausente.
    final linhaNivel = switch (gamificacao) {
      AsyncData(:final value) =>
        'Nível ${value.estatisticas.nivel} · '
            '${value.estatisticas.tituloNivel} · '
            '${AppNumberFormat.milhar(value.estatisticas.xp)} XP',
      _ => null,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.xl,
      ),
      children: <Widget>[
        _Cabecalho(usuario: usuario, nivel: linhaNivel),
        const SizedBox(height: AppSpacing.xl),

        // `when` do AsyncValue resolve os três estados sem if/else aninhado.
        // O refresh mantém o conteúdo anterior visível atrás da faixa.
        ...switch (gamificacao) {
          AsyncError() => <Widget>[
            _ErroGamificacao(
              aoTentarNovamente: () =>
                  ref.read(gamificacaoPerfilProvider.notifier).recarregar(),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          AsyncData(hasValue: true) => <Widget>[
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: AppSpacing.md),
            _BarraNivel(estatisticas: gamificacao.requireValue.estatisticas),
            const SizedBox(height: AppSpacing.lg),
            _GradeInsignias(conquistas: gamificacao.requireValue.conquistas),
            const SizedBox(height: AppSpacing.lg),
          ],
          AsyncData(:final value) => <Widget>[
            _BarraNivel(estatisticas: value.estatisticas),
            const SizedBox(height: AppSpacing.lg),
            _GradeInsignias(conquistas: value.conquistas),
            const SizedBox(height: AppSpacing.lg),
          ],
          _ => const <Widget>[
            _EsqueletoGamificacao(),
            SizedBox(height: AppSpacing.lg),
          ],
        },

        _CartaoDados(usuario: usuario),
        const SizedBox(height: AppSpacing.md),
        const _CartaoKai(),
        const SizedBox(height: AppSpacing.md),
        const _CartaoAcoes(),
      ],
    );
  }
}

/// Placeholder da gamificação enquanto os repositories respondem.
class _EsqueletoGamificacao extends StatelessWidget {
  /// Cria o esqueleto.
  const _EsqueletoGamificacao();

  @override
  Widget build(BuildContext context) {
    Widget barra(double altura) => Container(
      height: altura,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
    );

    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: <Widget>[
              barra(14),
              const SizedBox(height: AppSpacing.sm),
              barra(6),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _linhaEsqueleto(),
        const SizedBox(height: AppSpacing.listGap),
        _linhaEsqueleto(),
      ],
    );
  }

  /// Uma linha de quatro quadrados vazios, do formato da grade real.
  Widget _linhaEsqueleto() => Row(
    children: <Widget>[
      for (int coluna = 0; coluna < 4; coluna++) ...<Widget>[
        if (coluna > 0) const SizedBox(width: AppSpacing.listGap),
        Expanded(
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
          ),
        ),
      ],
    ],
  );
}

/// Avatar, nome, papel e a linha de nível.
class _Cabecalho extends StatelessWidget {
  /// Cria o cabeçalho.
  const _Cabecalho({required this.usuario, required this.nivel});

  /// Usuário exibido.
  final Usuario usuario;

  /// Nível e título, quando a gamificação carregou. Fica nulo enquanto a
  /// requisição está em voo ou falhou, e aí a linha simplesmente some.
  final String? nivel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 84,
          height: 84,
          alignment: Alignment.center,
          // O gradiente indigo -> lilac é o mesmo do `bg-gradient-to-br` do
          // protótipo; quadrado com raio 24, não círculo.
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[AppColors.indigo, AppColors.lilac],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.indigo.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            // `Usuario.inicial` pega o primeiro rune, então "Ángela" e
            // "😀 Ana" não viram caractere quebrado.
            usuario.inicial,
            style: AppTypography.statValue.copyWith(
              color: Colors.white,
              fontSize: 32,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          usuario.nome,
          style: AppTypography.screenTitle,
          textAlign: TextAlign.center,
        ),
        if (nivel case final String texto) ...<Widget>[
          const SizedBox(height: 2),
          Text(texto, style: AppTypography.itemMeta),
        ],
        const SizedBox(height: 2),
        Text(usuario.email, style: AppTypography.itemMeta),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: AppColors.indigoLight,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Text(
            usuario.perfil.rotulo,
            style: AppTypography.pill.copyWith(color: AppColors.indigo),
          ),
        ),
      ],
    );
  }
}

/// Barra de progresso do nível, com o XP que falta para o próximo.
class _BarraNivel extends StatelessWidget {
  /// Cria a barra.
  const _BarraNivel({required this.estatisticas});

  /// Nível, XP e progresso.
  final EstatisticasGamificacao estatisticas;

  @override
  Widget build(BuildContext context) {
    // `progressoNivel` vem de 0 a 100; o `clamp` protege contra um backend
    // que mande 120 e encha a barra além do trilho.
    final fracao = (estatisticas.progressoNivel / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Nível ${estatisticas.nivel} · ${estatisticas.tituloNivel}',
                style: AppTypography.sectionTitle,
              ),
              Text(
                '${AppNumberFormat.milhar(estatisticas.xp)} XP',
                style: AppTypography.statLabel,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fracao,
              minHeight: 6,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.indigo),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${AppNumberFormat.milhar(estatisticas.xpParaProximoNivel)} XP '
            'para o Nível ${estatisticas.nivel + 1}',
            style: AppTypography.statLabel,
          ),
        ],
      ),
    );
  }
}

/// Grade de insígnias, com as bloqueadas esmaecidas.
class _GradeInsignias extends StatelessWidget {
  /// Cria a grade.
  const _GradeInsignias({required this.conquistas});

  /// Insígnias do usuário.
  final List<Conquista> conquistas;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Insígnias conquistadas', style: AppTypography.sectionLabel),
        const SizedBox(height: AppSpacing.sm),
        // `shrinkWrap` porque a grade vive dentro de um `ListView`; sem isso
        // o `GridView` tenta ocupar a altura infinita e quebra o layout.
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: conquistas.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: AppSpacing.listGap,
            mainAxisSpacing: AppSpacing.listGap,
            childAspectRatio: 1,
          ),
          itemBuilder: (BuildContext context, int index) {
            final conquista = conquistas[index];
            return _TileInsignia(conquista: conquista);
          },
        ),
      ],
    );
  }
}

/// Uma insígnia: emoji em cima, rótulo em caixa alta embaixo.
class _TileInsignia extends StatelessWidget {
  /// Cria a pílula.
  const _TileInsignia({required this.conquista});

  /// Insígnia exibida.
  final Conquista conquista;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${conquista.titulo}. ${conquista.descricao}',
      button: true,
      child: InkWell(
        onTap: () => _mostrarDetalhe(context),
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: conquista.conquistada
                  ? AppColors.border
                  // Borda tracejada diferencia "bloqueada" de "conquistada"
                  // sem depender só de cor ou só de opacidade.
                  : AppColors.textLow,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Opacity(
            // Esmaecer o conteúdo, não o cartão inteiro, preserva o
            // contraste do texto com o fundo para o leitor de tela.
            opacity: conquista.conquistada ? 1 : 0.28,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxs),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(conquista.icone, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 2),
                  Text(
                    conquista.conquistada
                        ? conquista.titulo.toUpperCase()
                        : 'BLOQUEADA',
                    style: AppTypography.statLabel.copyWith(fontSize: 8),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Abre a folha de detalhe com como conquistar e quando conquistou.
  Future<void> _mostrarDetalhe(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(conquista.icone, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: AppSpacing.sm),
            Text(conquista.titulo, style: AppTypography.highlightTitle),
            const SizedBox(height: AppSpacing.xxs),
            Text(conquista.descricao, style: AppTypography.body),
            if (conquista.conquistadaEm case final DateTime quando) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Conquistada em ${AppDateFormat.mediumDate(quando)}',
                style: AppTypography.itemMeta,
              ),
            ] else ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Ainda não conquistada — ${conquista.descricao.toLowerCase()}.',
                style: AppTypography.itemMeta,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Estado de erro da gamificação, compacto para caber dentro da lista.
///
/// O [ErroView] de tela cheia ficaria desproporcional aqui, no meio de um
/// perfil que já carregou tudo o mais.
class _ErroGamificacao extends StatelessWidget {
  /// Cria o aviso.
  const _ErroGamificacao({required this.aoTentarNovamente});

  /// Callback de nova tentativa.
  final VoidCallback aoTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.crimsonLight,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.emoji_events_outlined,
            color: AppColors.crimson,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Não foi possível carregar suas insígnias.',
              style: AppTypography.itemMeta,
            ),
          ),
          TextButton(
            onPressed: aoTentarNovamente,
            child: const Text('Tentar de novo'),
          ),
        ],
      ),
    );
  }
}

/// Cartão com nome e e-mail, ambos editáveis.
class _CartaoDados extends ConsumerStatefulWidget {
  /// Cria o cartão.
  const _CartaoDados({required this.usuario});

  /// Usuário exibido.
  final Usuario usuario;

  @override
  ConsumerState<_CartaoDados> createState() => _CartaoDadosState();
}

class _CartaoDadosState extends ConsumerState<_CartaoDados> {
  late final TextEditingController _nome = TextEditingController(
    text: widget.usuario.nome,
  );
  late final TextEditingController _email = TextEditingController(
    text: widget.usuario.email,
  );

  /// Erro do último envio, exibido em faixa.
  String? _erro;

  /// Se há alteração ainda não salva.
  bool _sujo = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    super.dispose();
  }

  /// Envia as alterações para `PUT /api/users/me`.
  Future<void> _salvar() async {
    setState(() => _erro = null);

    final resultado = await ref
        .read(authRepositoryProvider)
        .atualizarPerfil(nome: _nome.text.trim(), email: _email.text.trim());

    switch (resultado) {
      case Success<Usuario>():
        // Atualiza o estado global: a Home e o cabeçalho lêem o usuário
        // de lá, então não dependem desta tela para refletir a mudança.
        ref
            .read(authControllerProvider.notifier)
            .atualizarUsuario(resultado.value);
        setState(() => _sujo = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Perfil atualizado.')));
        }
      case FailureResult<Usuario>(:final failure):
        // `Failure.message` já vem pronto para exibição: o
        // `ApiErrorMapper` escolhe um texto amigável por status, então
        // repetir o `switch` de subtipos aqui só criaria dois lugares
        // para manter em sincronia.
        setState(() => _erro = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Meus dados', style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          if (_erro case final String erro?) ...<Widget>[
            FaixaAviso(mensagem: erro),
            const SizedBox(height: AppSpacing.md),
          ],
          TextField(
            controller: _nome,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() => _sujo = true),
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          const SizedBox(height: AppSpacing.fieldGap),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() => _sujo = true),
            decoration: const InputDecoration(labelText: 'E-mail'),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _sujo ? _salvar : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.indigo,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              child: const Text(
                'Salvar alterações',
                style: AppTypography.button,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Atalho para o Kai.
class _CartaoKai extends StatelessWidget {
  /// Cria o cartão.
  const _CartaoKai();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.goNamed('kai'),
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.lilacLight,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.lilac.withValues(alpha: 0.4)),
          ),
          child: const Row(
            children: <Widget>[
              Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.lilac,
                size: 26,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Falar com o Kai',
                      style: AppTypography.highlightTitle,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tire dúvidas sobre suas matérias',
                      style: AppTypography.itemMeta,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textLow),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botão de sair da conta.
class _CartaoAcoes extends ConsumerWidget {
  /// Cria o cartão.
  const _CartaoAcoes();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              // Confirmação: sair apaga o token e leva ao login, e o aluno
              // não deve tropeçar nisso com um toque acidental.
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (BuildContext ctx) => AlertDialog(
                  title: const Text('Sair da conta?'),
                  content: const Text(
                    'Você precisará entrar novamente com e-mail e senha.',
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              );

              if (confirmar ?? false) {
                await ref.read(authControllerProvider.notifier).sair();
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.crimson,
              side: const BorderSide(color: AppColors.crimson),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sair da conta', style: AppTypography.pill),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('KRIPTA · versão 1.0.0', style: AppTypography.statLabel),
      ],
    );
  }
}
