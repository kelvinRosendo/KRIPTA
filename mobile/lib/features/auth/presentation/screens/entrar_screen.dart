/// Tela de entrada (RF01, RN01).
///
/// Tela mais simples do app e, por isso, a melhor referência de estilo
/// para o restante: `Scaffold` + `AppSpacing.screenH` nas laterais,
/// `AppTypography.screenTitle` no título e os campos do tema.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../core/widgets/state_views.dart';
import '../../application/auth_controller.dart';

/// Formulário de entrada do KRIPTA.
class EntrarScreen extends ConsumerStatefulWidget {
  /// Cria a tela de entrada.
  const EntrarScreen({super.key});

  @override
  ConsumerState<EntrarScreen> createState() => _EntrarScreenState();
}

class _EntrarScreenState extends ConsumerState<EntrarScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  bool _senhaVisivel = false;
  bool _enviando = false;

  @override
  void dispose() {
    // Sem `dispose`, os controllers vazam memória e o analyzer acusa
    // `close_sinks`/`cancel_subscriptions` em produção.
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_enviando) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _enviando = true);

    final ok = await ref
        .read(authControllerProvider.notifier)
        .entrar(email: _emailController.text, senha: _senhaController.text);

    // `mounted` verifica se a tela ainda existe: o usuário pode ter
    // voltado enquanto a requisição estava em voo, e chamar `setState`
    // nesse caso estoura.
    if (!mounted) return;
    setState(() => _enviando = false);

    // Em caso de sucesso não há `go()`: quem navega é o `redirect` do
    // `go_router`, ao ver `StatusSessao.autenticado`. Isso mantém a
    // sessão como única fonte de verdade sobre para onde o usuário vai.
    if (!ok) {
      final falha = ref.read(authControllerProvider).falha;
      if (falha != null) _mostrarErro(falha);
    }
  }

  void _mostrarErro(Failure falha) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(falha.message),
          backgroundColor: AppColors.crimson,
          behavior: SnackBarBehavior.floating,
        ),
      );
    // Limpa a falha depois de exibi-la, para o mesmo erro não reaparecer
    // ao voltar da tela de cadastro.
    ref.read(authControllerProvider.notifier).limparFalha();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.maxContentWidth,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: AppSpacing.xxl),
                    const _Marca(),
                    const SizedBox(height: AppSpacing.xxl),

                    const Text('Entrar', style: AppTypography.screenTitle),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Acompanhe seus estudos e continue de onde parou.',
                      style: AppTypography.itemMeta,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enabled: !_enviando,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      validator: (String? value) => AppValidators.email(value),
                    ),
                    const SizedBox(height: AppSpacing.fieldGap),

                    TextFormField(
                      controller: _senhaController,
                      obscureText: !_senhaVisivel,
                      textInputAction: TextInputAction.done,
                      enabled: !_enviando,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _senhaVisivel = !_senhaVisivel),
                          icon: Icon(
                            _senhaVisivel
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          tooltip: _senhaVisivel
                              ? 'Ocultar senha'
                              : 'Mostrar senha',
                        ),
                      ),
                      validator: (String? value) =>
                          AppValidators.password(value),
                      onFieldSubmitted: (_) => _enviar(),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // `enviando` trava o botão para impedir duplo toque:
                    // duas requisições de login simultâneas produziriam
                    // duas escritas no Keychain.
                    if (_enviando)
                      const CarregandoView(mensagem: 'Entrando...')
                    else
                      FilledButton(
                        onPressed: _enviar,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                        ),
                        child: const Text(
                          'Entrar',
                          style: AppTypography.button,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text(
                          'Ainda não tem conta?',
                          style: AppTypography.itemMeta,
                        ),
                        TextButton(
                          onPressed: _enviando
                              ? null
                              : () => context.pushNamed('cadastro'),
                          child: const Text('Criar conta'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Logotipo textual do KRIPTA, usado nas telas de autenticação.
class _Marca extends StatelessWidget {
  const _Marca();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.indigoLight,
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
          child: const Icon(
            Icons.auto_stories_rounded,
            size: 40,
            color: AppColors.indigo,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text('KRIPTA', style: AppTypography.screenTitle),
      ],
    );
  }
}
