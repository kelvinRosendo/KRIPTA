/// Paleta de cores do KRIPTA.
///
/// Fonte única: `frontend/tailwind.config.js` (branch `feature---frontend`).
/// Manter este arquivo em sincronia com o Tailwind — a identidade visual
/// do KRIPTA é definida pela equipe (Murylo/Design), não pela IA, e o
/// mobile precisa reproduzir exatamente a paleta do web.
library;

import 'package:flutter/material.dart';

/// Cores do Design System KRIPTA.
abstract final class AppColors {
  // ── Marca / ação primária ──────────────────────────────────────────
  /// Indigo — cor primária do app (`indigo` no Tailwind).
  static const Color indigo = Color(0xFF3D3DB4);

  /// Versão clara do indigo, usada em fundos e realces.
  static const Color indigoLight = Color(0xFFEEEEF9);

  // ── Apoio: matérias e unidades ────────────────────────────────────
  /// Teal — ação da aba Matérias.
  static const Color teal = Color(0xFF4ECDC4);

  /// Variante clara do teal, para fundos de chip e selo.
  static const Color tealLight = Color(0xFFE6F9F8);

  // ── Apoio: agente de IA ───────────────────────────────────────────
  /// Lilac — ação da aba Kai e da gamificação no perfil.
  static const Color lilac = Color(0xFFA78BFA);

  /// Variante clara do lilac, para fundos de chip e selo.
  static const Color lilacLight = Color(0xFFF0EBFF);

  // ── Apoio: tarefas e prazos ───────────────────────────────────────
  /// Laranja — ação da aba Tarefas, prazos de hoje e sequência (streak).
  static const Color orange = Color(0xFFFF6B35);

  /// Variante clara do laranja, para fundos de chip e selo.
  static const Color orangeLight = Color(0xFFFFF0EB);

  // ── Alerta ────────────────────────────────────────────────────────
  /// Crimson — atrasadas, exclusão e mensagens destrutivas.
  static const Color crimson = Color(0xFFC0392B);

  /// Variante clara do crimson, para fundos de aviso e erro.
  static const Color crimsonLight = Color(0xFFFDECEA);

  // ── Superfícies ───────────────────────────────────────────────────
  /// Fundo dos cards e da barra inferior.
  static const Color surface = Color(0xFFFFFFFF);

  /// Estado "hover"/"pressed" de superfícies e trilhos de progresso.
  static const Color surfaceAlt = Color(0xFFF0F1F8);

  /// Fundo do app.
  static const Color background = Color(0xFFF6F7FB);

  // ── Bordas ────────────────────────────────────────────────────────
  /// Cor de borda padrão de cards e divisores.
  static const Color border = Color(0xFFE2E4F0);

  // ── Texto ─────────────────────────────────────────────────────────
  /// Texto de alto contraste (títulos).
  static const Color textHigh = Color(0xFF1A1A2E);

  /// Texto secundário (metadados).
  static const Color textMid = Color(0xFF6B6F8E);

  /// Texto terciário (rótulos, placeholders).
  static const Color textLow = Color(0xFFA8ABBD);

  // ── Suporte ───────────────────────────────────────────────────────
  /// Verde de sucesso (tarefa concluída, material visto).
  static const Color success = Color(0xFF2E9E6B);

  /// Fundo translúcido do campo de entrada.
  static const Color inputFill = Color(0xFFF6F7FB);
}

/// Raios de arredondamento do Design System (`borderRadius` do Tailwind).
abstract final class AppRadii {
  /// 20 px — componentes grandes (modais, folhas).
  static const double lg = 20;

  /// 14 px — cards, campos, botões. Valor padrão do app.
  static const double md = 14;

  /// 10 px — botões de ícone, chips pequenos.
  static const double sm = 10;

  /// 999 — pílulas e avatais (círculo completo).
  static const double pill = 999;
}
