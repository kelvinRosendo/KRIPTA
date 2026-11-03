import 'package:flutter/material.dart';

import '../utils/result.dart';

/// Formulário curto que preserva o texto quando o servidor recusa.
class CreateItemDialog extends StatefulWidget {
  /// Cria um formulário com salvamento assíncrono.
  const CreateItemDialog({super.key, required this.title, required this.save});

  /// Título mostrado no diálogo.
  final String title;

  /// Persiste o título e retorna a falha exibível.
  final Future<Result<void>> Function(String) save;
  @override
  State<CreateItemDialog> createState() => _CreateItemDialogState();
}

class _CreateItemDialogState extends State<CreateItemDialog> {
  final text = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: text,
      enabled: !busy,
      maxLength: 200,
      autofocus: true,
      decoration: InputDecoration(labelText: 'Título', errorText: error),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: busy
            ? null
            : () async {
                if (text.text.trim().isEmpty) {
                  setState(() => error = 'Informe um título.');
                  return;
                }
                setState(() => busy = true);
                final result = await widget.save(text.text.trim());
                if (!mounted || !context.mounted) return;
                if (result.isSuccess) {
                  Navigator.pop(context, true);
                } else {
                  setState(() {
                    busy = false;
                    error = result.failureOrNull!.message;
                  });
                }
              },
        child: Text(busy ? 'Salvando...' : 'Salvar'),
      ),
    ],
  );
}
