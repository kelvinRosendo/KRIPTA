/// Casca do aplicativo: barra de navegação inferior + conteúdo da aba.
///
/// ## Por que cinco "abas" com apenas cinco destinos
///
/// A navegação do KRIPTA tem mais de cinco telas, mas agrupá-las evita
/// tabuleiras de ícones ilegíveis em telas estreitas:
///
/// | Aba | Destinos |
/// |-----|----------|
/// | Início | Home |
/// | Matérias | Matérias, Unidades |
/// | Tarefas | Tarefas |
/// | Agenda | Calendário, Avisos |
/// | Perfil | Perfil, Kai |
///
/// [StatefulShellBranch] mantém uma pilha de navegação por grupo, então
/// voltar das Matérias para a Home **não** recria a Home: o scroll e os
/// dados já carregados sobrevivem.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

/// Casca com barra inferior.
class AppShell extends StatelessWidget {
  /// Cria a casca em volta de [shell].
  const AppShell({super.key, required this.shell});

  /// Pilha de navegação multi-aba, fornecida pelo `go_router`.
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _trocarAba,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.indigoLight,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.indigo),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded, color: AppColors.indigo),
            label: 'Matérias',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(
              Icons.checklist_rounded,
              color: AppColors.indigo,
            ),
            label: 'Tarefas',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(
              Icons.event_note_rounded,
              color: AppColors.indigo,
            ),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.indigo),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  /// Troca de aba.
  ///
  /// `goBranch(index: ...)` zera a pilha da aba quando o índice é o mesmo
  /// do atual: tocar duas vezes em "Início" traz a Home ao topo, como em
  /// qualquer app com bottom nav.
  void _trocarAba(int index) {
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }
}
