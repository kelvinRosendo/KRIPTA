/// Perfil do usuário: dados, papel, edição de nome/e-mail e saída.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/result.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/entities.dart';
import '../../auth/application/auth_controller.dart';

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

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.xl,
      ),
      children: <Widget>[
        _Cabecalho(usuario: usuario),
        const SizedBox(height: AppSpacing.xl),
        _CartaoDados(usuario: usuario),
        const SizedBox(height: AppSpacing.md),
        const _CartaoKai(),
        const SizedBox(height: AppSpacing.md),
        const _CartaoAcoes(),
      ],
    );
  }
}

/// Avatar, nome e papel.
class _Cabecalho extends StatelessWidget {
  /// Cria o cabeçalho.
  const _Cabecalho({required this.usuario});

  /// Usuário exibido.
  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    // A inicial do primeiro nome serve de avatar sem pedir imagem ao
    // servidor, que não expõe avatar no MVP.
    final iniciais = usuario.nome.trim().isEmpty
        ? '?'
        : usuario.nome.trim().substring(0, 1).toUpperCase();

    return Column(
      children: <Widget>[
        Container(
          width: 84,
          height: 84,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.indigo,
            shape: BoxShape.circle,
          ),
          child: Text(
            iniciais,
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
        const SizedBox(height: AppSpacing.xxs),
        Text(usuario.email, style: AppTypography.itemMeta),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: AppColors.indigoLight,
            borderRadius: BorderRadius.circular(20),
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
        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.lilacLight,
            borderRadius: BorderRadius.circular(16),
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
