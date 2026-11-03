/// Tema do Material 3 derivado do Design System do KRIPTA.
///
/// A paleta e a tipografia vêm de `app_colors.dart` e `app_typography.dart`,
/// que por sua vez espelham o `tailwind.config.js` do frontend web.
///
/// Apenas o **light** está definido: o TCC não prevê tema escuro e o
/// Design System é definido pela equipe de design, não pela IA. Para
/// adicionar depois, criei um segundo `ThemeData` e estenda
/// [AppTheme.of] com um seletor.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Constrói os `ThemeData` do aplicativo.
abstract final class AppTheme {
  /// Família de fonte de títulos e números.
  static String get _displayFont => GoogleFonts.nunito().fontFamily!;

  /// Família de fonte de corpo e formulários.
  static String get _bodyFont => GoogleFonts.inter().fontFamily!;

  /// Tema claro — único tema suportado no MVP.
  static ThemeData get light {
    // ── Esquema de cores ────────────────────────────────────────────
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.indigo,
      onPrimary: Colors.white,
      primaryContainer: AppColors.indigoLight,
      onPrimaryContainer: AppColors.indigo,
      secondary: AppColors.teal,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.tealLight,
      onSecondaryContainer: AppColors.teal,
      tertiary: AppColors.lilac,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.lilacLight,
      onTertiaryContainer: AppColors.lilac,
      error: AppColors.crimson,
      onError: Colors.white,
      errorContainer: AppColors.crimsonLight,
      onErrorContainer: AppColors.crimson,
      surface: AppColors.surface,
      onSurface: AppColors.textHigh,
      surfaceContainerHighest: AppColors.surfaceAlt,
      onSurfaceVariant: AppColors.textMid,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      inverseSurface: AppColors.textHigh,
      onInverseSurface: AppColors.surface,
      inversePrimary: AppColors.indigoLight,
      scrim: Colors.black54,
      shadow: Colors.black26,
    );

    // ── Textos ──────────────────────────────────────────────────────
    final textTheme = TextTheme(
      headlineLarge: AppTypography.screenTitle.copyWith(
        fontFamily: _displayFont,
      ),
      titleLarge: AppTypography.sectionTitle.copyWith(fontFamily: _displayFont),
      titleMedium: AppTypography.itemTitle.copyWith(fontFamily: _bodyFont),
      bodyLarge: AppTypography.body.copyWith(fontFamily: _bodyFont),
      bodyMedium: AppTypography.body.copyWith(fontFamily: _bodyFont),
      bodySmall: AppTypography.itemMeta.copyWith(fontFamily: _bodyFont),
      labelLarge: AppTypography.button.copyWith(fontFamily: _bodyFont),
      labelSmall: AppTypography.statLabel.copyWith(fontFamily: _displayFont),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      fontFamily: _bodyFont,
      splashFactory: InkSparkle.splashFactory,

      // ── AppBar ─────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textHigh,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.screenTitle.copyWith(
          fontFamily: _displayFont,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),

      // ── Cartão ─────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      // ── Botões ─────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.indigo,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          textStyle: AppTypography.button.copyWith(fontFamily: _bodyFont),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textHigh,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.border),
          textStyle: AppTypography.button.copyWith(
            fontFamily: _displayFont,
            color: AppColors.textHigh,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.indigo),
      ),

      // ── Campos de entrada ──────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        hintStyle: AppTypography.body.copyWith(
          fontFamily: _bodyFont,
          color: AppColors.textLow,
        ),
        labelStyle: AppTypography.itemMeta.copyWith(fontFamily: _bodyFont),
        errorStyle: AppTypography.itemMeta.copyWith(
          fontFamily: _bodyFont,
          color: AppColors.crimson,
        ),
        border: _inputBorder(AppColors.border),
        enabledBorder: _inputBorder(AppColors.border),
        focusedBorder: _inputBorder(AppColors.indigo, width: 1.5),
        errorBorder: _inputBorder(AppColors.crimson),
        focusedErrorBorder: _inputBorder(AppColors.crimson, width: 1.5),
      ),

      // ── Chips e pílulas ────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.border),
        labelStyle: AppTypography.pill.copyWith(fontFamily: _displayFont),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      ),

      // ── Diálogos e folhas ──────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        titleTextStyle: AppTypography.highlightTitle.copyWith(
          fontFamily: _displayFont,
        ),
        contentTextStyle: AppTypography.body.copyWith(fontFamily: _bodyFont),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.lg),
          ),
        ),
      ),

      // ── Navegação inferior ─────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.indigoLight,
        elevation: 0,
        height: AppLayout.bottomNavHeight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: _displayFont,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected)
                ? AppColors.indigo
                : AppColors.textLow,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? AppColors.indigo
                : AppColors.textLow,
          ),
        ),
      ),

      // ── SnackBar (feedback de ação) ────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textHigh,
        contentTextStyle: AppTypography.body.copyWith(
          fontFamily: _bodyFont,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),

      // ── Divisores ──────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // ── Indicador de progresso ─────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.indigo,
        linearTrackColor: AppColors.surfaceAlt,
      ),

      // ── Listas ─────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textMid,
        textColor: AppColors.textHigh,
      ),
    );
  }

  /// Monta a borda dos campos, respeitando a espessura por estado.
  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
