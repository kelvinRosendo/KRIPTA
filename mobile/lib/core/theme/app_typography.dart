/// Espaçamentos, tipografia e tokens de layout do KRIPTA.
///
/// Os valores espelham as utilitárias arbitrárias do Tailwind
/// (`px-app` = 20 px, gaps de 9/13 px, etc.) para que o mobile e o web
/// tenham a mesma densidade visual. Qualquer ajuste aqui deve ser
/// refletido no frontend para não quebrar a paridade entre plataformas.
library;

import 'package:flutter/material.dart';

/// Escala de espaçamento em múltiplos de 4 px (base do Tailwind).
abstract final class AppSpacing {
  /// 4 px.
  static const double xxs = 4;

  /// 8 px — gap entre elementos relacionados.
  static const double xs = 8;

  /// 12 px.
  static const double sm = 12;

  /// 16 px — padding interno padrão de card.
  static const double md = 16;

  /// 20 px — padding horizontal das telas (`px-app` no Tailwind).
  static const double lg = 20;

  /// 24 px.
  static const double xl = 24;

  /// 32 px — separação entre seções.
  static const double xxl = 32;

  /// Margem horizontal padrão do conteúdo de uma tela.
  static const double screenH = 20;

  /// Gap vertical padrão entre cards listados.
  static const double listGap = 9;

  /// Gap vertical padrão entre blocos de formulário.
  static const double fieldGap = 13;
}

/// Famílias e tamanhos de fonte.
///
/// Display usa **Nunito** (títulos, números, rótulos) e body usa **Inter**
/// (parágrafos, formulários) — exatamente o par do `tailwind.config.js`.
///
/// As fontes são carregadas via `google_fonts`, que baixa em runtime por
/// padrão. Em produção, prefira empacotar os `.ttf` em `assets/fonts/` e
/// trocar por `fontFamily` (ver README, seção "Fontes").
abstract final class AppTypography {
  /// Título de tela (22 px / bold).
  static const TextStyle screenTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: Color(0xFF1A1A2E),
  );

  /// Título de seção dentro da tela (15 px / bold).
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Color(0xFF1A1A2E),
  );

  /// Título do card de destaque (17 px / bold).
  static const TextStyle highlightTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: Color(0xFF1A1A2E),
  );

  /// Número de estatística (17 px / bold).
  static const TextStyle statValue = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: Color(0xFF1A1A2E),
  );

  /// Rótulo de estatística (10 px / bold, caixa alta, espaçado).
  static const TextStyle statLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: Color(0xFFA8ABBD),
  );

  /// Rótulo de seção (11 px / bold, caixa alta, muito espaçado).
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: Color(0xFFA8ABBD),
  );

  /// Título de item de lista (14 px / semibold).
  static const TextStyle itemTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1A1A2E),
  );

  /// Metadado de item de lista (11,5 px).
  static const TextStyle itemMeta = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    color: Color(0xFF6B6F8E),
  );

  /// Texto de formulário e corpo de parágrafo (13,5 px).
  static const TextStyle body = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: Color(0xFF1A1A2E),
  );

  /// Texto de botão principal (15 px / bold).
  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  /// Rótulo dentro de pílula/chip (11 px / bold).
  static const TextStyle pill = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: Color(0xFF6B6F8E),
  );
}

/// Métricas de componentes reutilizadas pelas telas.
abstract final class AppLayout {
  /// Largura máxima do conteúdo em telas grandes (tablets/desktop).
  static const double maxContentWidth = 600;

  /// Altura da barra de navegação inferior.
  static const double bottomNavHeight = 68;

  /// Tamanho do botão de ícone quadrado.
  static const double iconButtonSize = 38;

  /// Tamanho do botão flutuante de ação.
  static const double fabSize = 50;

  /// Tempo da animação de transição de tela.
  static const Duration routeTransition = Duration(milliseconds: 220);
}
