/// Tela de criação de conta (RF01, RN01).
///
/// ## Limites aplicados no formulário
///
/// Os mesmos do backend (`RegisterRequest`), para o aluno receber o erro
/// sem_round trip:
///
/// - nome: obrigatório, até [AppValidators.maxNameLength];
/// - e-mail: obrigatório, formato válido, até [AppValidators.maxEmailLength];
/// - senha: obrigatória, de [AppValidators.minPasswordLength] a
///   [AppValidators.maxPasswordLength];
/// - confirmação: precisa bater com a senha.
///
/// `senha` tem teto de 72 porque é o limite do BCrypt — passar de 72 faz
/// o backend truncar silenciosamente, e o usuário descobriria o problema
/// só no primeiro login depois de trocar a senha.
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

/// Formulário de criação de conta do KRIPTA.
class CadastroScreen extends ConsumerStatefulWidget {
  /// Cria a tela de cadastro.
  const CadastroScreen({super.key});

  @override
  ConsumerState<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends ConsumerState<CadastroScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarController = TextEditingController();

  bool _senhaVisivel = false;
  bool _enviando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (_enviando) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _enviando = true);

    final ok = await ref
        .read(authControllerProvider.notifier)
        .cadastrar(
          nome: _nomeController.text,
          email: _emailController.text,
          senha: _senhaController.text,
        );

    if (!mounted) return;
    setState(() => _enviando = false);

    // Sucesso: o `redirect` do router leva para a Home, já que o
    // controller faz o login automático após criar a conta.
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
    ref.read(authControllerProvider.notifier).limparFalha();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              0,
              AppSpacing.screenH,
              AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.maxContentWidth,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text('Criar conta', style: AppTypography.screenTitle),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Leva menos de um minuto. Você entra e já sai autenticado.',
                      style: AppTypography.itemMeta,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    TextFormField(
                      controller: _nomeController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      enabled: !_enviando,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo',
                      ),
                      validator: (String? value) => AppValidators.maxLength(
                        AppValidators.required(value, 'o nome'),
                        AppValidators.maxNameLength,
                        'o nome',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.fieldGap),

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
                      textInputAction: TextInputAction.next,
                      enabled: !_enviando,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        helperText:
                            'Mínimo de ${AppValidators.minPasswordLength} caracteres',
                        helperMaxLines: 2,
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
                    ),
                    const SizedBox(height: AppSpacing.fieldGap),

                    TextFormField(
                      controller: _confirmarController,
                      obscureText: !_senhaVisivel,
                      textInputAction: TextInputAction.done,
                      enabled: !_enviando,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar senha',
                      ),
                      validator: (String? value) =>
                          AppValidators.passwordsMatch(
                            _senhaController.text,
                            value,
                          ),
                      onFieldSubmitted: (_) => _cadastrar(),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    if (_enviando)
                      const CarregandoView(mensagem: 'Criando sua conta...')
                    else
                      FilledButton(
                        onPressed: _cadastrar,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                        ),
                        child: const Text(
                          'Criar conta',
                          style: AppTypography.button,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text(
                          'Já tem conta?',
                          style: AppTypography.itemMeta,
                        ),
                        TextButton(
                          onPressed: _enviando ? null : () => context.pop(),
                          child: const Text('Entrar'),
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
