import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/di/providers.dart';
import '../../core/error/failure.dart';
import '../../core/widgets/state_views.dart';
import '../tarefas/application/listas_controller.dart';

/// Publicações aprovadas, carregadas da API.
final approvedProvider = FutureProvider(
  (ref) => obter(() => ref.watch(academicRepositoryProvider).approved()),
);

/// Catálogo de leitura dos conteúdos acadêmicos.
class ConteudosScreen extends ConsumerWidget {
  /// Cria a tela de catálogo.
  const ConteudosScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(approvedProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conteúdos aprovados'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(approvedProvider),
          ),
        ],
      ),
      body: data.when(
        loading: () => const CarregandoView(),
        error: (e, _) => ErroView(
          falha: e is Failure
              ? e
              : const UnexpectedFailure(
                  message: 'Não foi possível carregar os conteúdos.',
                ),
          aoTentarNovamente: () => ref.invalidate(approvedProvider),
        ),
        data: (items) => items.isEmpty
            ? const VazioView(
                titulo: 'Nenhum conteúdo aprovado',
                subtitulo: 'Publicações aprovadas aparecem aqui.',
                icone: Icons.menu_book,
              )
            : ListView(
                children: items
                    .map(
                      (item) => Card(
                        child: ListTile(
                          title: Text(item['title'] as String),
                          subtitle: Text(item['description'] as String? ?? ''),
                          trailing: item['url'] == null
                              ? null
                              : const Icon(Icons.open_in_new),
                          onTap: () async {
                            final uri = Uri.tryParse(
                              item['url'] as String? ?? '',
                            );
                            if (uri == null ||
                                !['http', 'https'].contains(uri.scheme)) {
                              return;
                            }
                            try {
                              if (await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              )) {
                                return;
                              }
                            } catch (_) {}
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Não foi possível abrir o link.',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
      ),
    );
  }
}
