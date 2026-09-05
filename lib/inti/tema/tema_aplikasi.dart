import 'package:flutter/material.dart';
import 'design_tokens.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  APP THEME — Light & Dark (Material 3)
//  Semua nilai berasal dari design_tokens.dart.
//  Tidak ada hardcoded warna di layar — gunakan token semantic.
// ═══════════════════════════════════════════════════════════════════════════════

class AppTheme {
  // ── Light ───────────────────────────────────────────────────────────────────
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.surfaceBg,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryTint,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.accentTint,
        surface: AppColors.surfaceContainer,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceSecondary,
        error: AppColors.error,
        onError: Colors.white,
      ),

      fontFamily: 'Poppins',

      textTheme: _buildTextTheme(AppColors.textPrimary,
          AppColors.textSecondary, AppColors.textMuted, false),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceBg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppTypography.appBarTitleSize,
          fontWeight: AppTypography.appBarTitleWeight,
          color: AppColors.textPrimary,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textSecondary,
          size: AppTypography.iconDefault,
        ),
      ),

      // ── Bottom Navigation ──────────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainer,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        elevation: 0,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),

      // ── Card ───────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainer,
        elevation: 0,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ComponentSpec.cardRadius),
          side: BorderSide(
              color: AppColors.surfaceTertiary,
              width: ComponentSpec.dividerThick),
        ),
      ),

      // ── Divider ────────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: AppColors.surfaceTertiary,
        thickness: ComponentSpec.dividerThick,
        space: 0,
        indent: ComponentSpec.dividerInset,
        endIndent: 0,
      ),

      // ── Elevated Button (Primary) ──────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
              horizontal: ComponentSpec.btnPaddingH,
              vertical: 14),
          minimumSize: const Size(double.infinity, ComponentSpec.btnHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ComponentSpec.btnRadiusClean),
          ),
          textStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: AppTypography.buttonWeight,
            fontSize: AppTypography.buttonSize,
            letterSpacing: AppTypography.buttonLetterSpacing,
            height: 1.0,
          ),
        ),
      ),

      // ── Filled Button ──────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
              horizontal: ComponentSpec.btnPaddingH,
              vertical: 14),
          minimumSize: const Size(double.infinity, ComponentSpec.btnHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ComponentSpec.btnRadiusClean),
          ),
          textStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: AppTypography.buttonWeight,
            fontSize: AppTypography.buttonSize,
            letterSpacing: AppTypography.buttonLetterSpacing,
            height: 1.0,
          ),
        ),
      ),

      // ── Outlined Button ────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(
              color: AppColors.primary, width: ComponentSpec.btnOutlinedWidth),
          padding: const EdgeInsets.symmetric(
              horizontal: ComponentSpec.btnPaddingH,
              vertical: 14),
          minimumSize: const Size(double.infinity, ComponentSpec.btnHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ComponentSpec.btnRadiusClean),
          ),
          textStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: AppTypography.buttonWeight,
            fontSize: AppTypography.buttonSize,
            letterSpacing: AppTypography.buttonLetterSpacing,
            height: 1.0,
          ),
        ),
      ),

      // ── Text Button ────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
              horizontal: ComponentSpec.btnPaddingH,
              vertical: 14),
          minimumSize: const Size(double.infinity, ComponentSpec.btnHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ComponentSpec.btnRadiusClean),
          ),
          textStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: AppTypography.buttonWeight,
            fontSize: AppTypography.buttonSize,
            letterSpacing: AppTypography.buttonLetterSpacing,
            height: 1.0,
          ),
        ),
      ),

      // ── Input / Text Field ─────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ComponentSpec.inputPaddingH,
          vertical: ComponentSpec.inputPaddingV,
        ),
        hintStyle: TextStyle(
          color: AppColors.textMuted,
          fontSize: ComponentSpec.inputFontSize,
          fontFamily: 'Poppins',
          height: AppTypography.body2Lh,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ComponentSpec.inputRadius),
          borderSide: BorderSide(
              color: AppColors.inputBorderDefault, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ComponentSpec.inputRadius),
          borderSide: BorderSide(
              color: AppColors.inputBorderDefault, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ComponentSpec.inputRadius),
          borderSide: BorderSide(
              color: AppColors.inputBorderFocused, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ComponentSpec.inputRadius),
          borderSide: BorderSide(
              color: AppColors.inputBorderError, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ComponentSpec.inputRadius),
          borderSide: BorderSide(
              color: AppColors.inputBorderError, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ComponentSpec.inputRadius),
          borderSide: BorderSide(
              color: AppColors.disabled, width: 1),
        ),
        errorMaxLines: 2,
        helperStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: AppTypography.captionSize,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
        errorStyle: const TextStyle(
          color: AppColors.error,
          fontSize: AppTypography.captionSize,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),

      // ── Icon ───────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: AppTypography.iconDefault,
      ),

      // ── Checkbox & Switch ──────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(
            color: AppColors.inputBorderDefault, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.compact,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return const Color(0xFFD1D5DB);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.5);
          }
          return AppColors.inputBorderDefault.withValues(alpha: 0.3);
        }),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),

      // ── Progress Indicator ─────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceTertiary,
        circularTrackColor: AppColors.surfaceTertiary,
        strokeWidth: 4.0,
      ),

      // ── Snackbar ───────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.toastBackground,
        contentTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: AppTypography.body2Size,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ComponentSpec.toastRadius),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      extensions: const [
        AppThemeExtension(
          gradientPrimary: AppColors.gradientPrimary,
          gradientAccent: AppColors.gradientAccent,
          gradientCard: AppColors.gradientCard,
          success: AppColors.success,
          info: AppColors.info,
          warning: AppColors.warning,
        ),
      ],
    );
  }

  // ── Dark ────────────────────────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.darkSurfaceAlt,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.accentTint,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        surfaceContainerHighest: AppColors.darkBorder,
        error: AppColors.error,
        onError: Colors.white,
      ),

      fontFamily: 'Poppins',

      textTheme: _buildTextTheme(AppColors.darkTextPrimary,
          AppColors.darkTextSecondary, AppColors.darkTextMuted, true),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBg,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppTypography.appBarTitleSize,
          fontWeight: AppTypography.appBarTitleWeight,
          color: AppColors.darkTextPrimary,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(
          color: AppColors.darkTextSecondary,
          size: AppTypography.iconDefault,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.darkPrimaryBright,
        unselectedItemColor: AppColors.darkTextMuted,
        elevation: 0,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),

      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ComponentSpec.cardRadius),
          side: BorderSide(
              color: AppColors.darkBorder, width: ComponentSpec.dividerThick),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.darkBorder,
        thickness: ComponentSpec.dividerThick,
        space: 0,
        indent: ComponentSpec.dividerInset,
        endIndent: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
              horizontal: ComponentSpec.btnPaddingH,
              vertical: 14),
          minimumSize: const Size(double.infinity, ComponentSpec.btnHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ComponentSpec.btnRadiusClean),
          ),
          textStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: AppTypography.buttonWeight,
            fontSize: AppTypography.buttonSize,
            letterSpacing: AppTypography.buttonLetterSpacing,
            height: 1.0,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
              horizontal: ComponentSpec.btnPaddingH,
              vertical: 14),
          minimumSize: const Size(double.infinity, ComponentSpec.btnHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ComponentSpec.btnRadiusClean),
          ),
          textStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: AppTypography.buttonWeight,
            fontSize: AppTypography.buttonSize,
            letterSpacing: AppTypography.buttonLetterSpacing,
            height: 1.0,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPrimaryBright,
          side: const BorderSide(
              color: AppColors.darkPrimaryBright,
              width: ComponentSpec.btnOutlinedWidth),
          padding: const EdgeInsets.symmetric(
              horizontal: ComponentSpec.btnPaddingH,
              vertical: 14),
          minimumSize: const Size(double.infinity, ComponentSpec.btnHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ComponentSpec.btnRadiusClean),
          ),
          textStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: AppTypography.buttonWeight,
            fontSize: AppTypography.buttonSize,
            letterSpacing: AppTypography.buttonLetterSpacing,
            height: 1.0,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkPrimaryBright,
          padding: const EdgeInsets.symmetric(
              horizontal: ComponentSpec.btnPaddingH,
              vertical: 14),
          minimumSize: const Size(double.infinity, ComponentSpec.btnHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ComponentSpec.btnRadiusClean),
          ),
          textStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: AppTypography.buttonWeight,
            fontSize: AppTypography.buttonSize,
            letterSpacing: AppTypography.buttonLetterSpacing,
            height: 1.0,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ComponentSpec.inputPaddingH,
          vertical: ComponentSpec.inputPaddingV,
        ),
        hintStyle: TextStyle(
          color: AppColors.darkTextMuted,
          fontSize: ComponentSpec.inputFontSize,
          fontFamily: 'Poppins',
          height: AppTypography.body2Lh,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ComponentSpec.inputRadius),
          borderSide: BorderSide(
              color: AppColors.darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ComponentSpec.inputRadius),
          borderSide: BorderSide(
              color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ComponentSpec.inputRadius),
          borderSide: BorderSide(
              color: AppColors.inputBorderFocused, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ComponentSpec.inputRadius),
          borderSide: BorderSide(
              color: AppColors.inputBorderError, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ComponentSpec.inputRadius),
          borderSide: BorderSide(
              color: AppColors.inputBorderError, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ComponentSpec.inputRadius),
          borderSide: BorderSide(
              color: AppColors.disabled, width: 1),
        ),
        errorMaxLines: 2,
        helperStyle: const TextStyle(
          color: AppColors.darkTextMuted,
          fontSize: AppTypography.captionSize,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
        errorStyle: const TextStyle(
          color: AppColors.error,
          fontSize: AppTypography.captionSize,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),

      iconTheme: const IconThemeData(
        color: AppColors.darkTextSecondary,
        size: AppTypography.iconDefault,
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(
            color: AppColors.darkBorder, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.compact,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return AppColors.darkTextMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.5);
          }
          return AppColors.darkBorder.withValues(alpha: 0.4);
        }),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.darkBorder,
        circularTrackColor: AppColors.darkBorder,
        strokeWidth: 4.0,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurface,
        contentTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: AppTypography.body2Size,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ComponentSpec.toastRadius),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      extensions: const [
        AppThemeExtension(
          gradientPrimary: AppColors.gradientPrimary,
          gradientAccent: AppColors.gradientAccent,
          gradientCard: AppColors.darkGradientCard,
          success: Color(0xFF34D399),
          info: Color(0xFF38BDF8),
          warning: Color(0xFFFBBF24),
        ),
      ],
    );
  }

  // ── Internal: bangun TextTheme dari warna yang diberikan ───────────────────
  static TextTheme _buildTextTheme(
    Color textColor,
    Color secondaryColor,
    Color mutedColor,
    bool isDark,
  ) {
    final ff = 'Poppins';
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: ff,
        fontSize: AppTypography.displayTitleSize,
        fontWeight: AppTypography.displayTitleWeight,
        height: AppTypography.displayTitleLh,
        color: textColor,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontFamily: ff,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.20,
        color: textColor,
      ),
      displaySmall: TextStyle(
        fontFamily: ff,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: textColor,
      ),
      headlineLarge: TextStyle(
        fontFamily: ff,
        fontSize: AppTypography.h1Size,
        fontWeight: AppTypography.h1Weight,
        height: AppTypography.h1Lh,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: ff,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: AppTypography.h2Lh,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontFamily: ff,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.30,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontFamily: ff,
        fontSize: AppTypography.h2Size,
        fontWeight: AppTypography.h2Weight,
        height: AppTypography.h2Lh,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontFamily: ff,
        fontSize: AppTypography.h3Size,
        fontWeight: AppTypography.h3Weight,
        height: AppTypography.h3Lh,
        color: textColor,
      ),
      titleSmall: TextStyle(
        fontFamily: ff,
        fontSize: AppTypography.captionSize,
        fontWeight: FontWeight.w600,
        height: AppTypography.captionLh,
        color: secondaryColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: ff,
        fontSize: AppTypography.body1Size,
        fontWeight: AppTypography.body1Weight,
        height: AppTypography.body1Lh,
        color: textColor,
        letterSpacing: 0.1,
      ),
      bodyMedium: TextStyle(
        fontFamily: ff,
        fontSize: AppTypography.body2Size,
        fontWeight: AppTypography.body2Weight,
        height: AppTypography.body2Lh,
        color: secondaryColor,
      ),
      bodySmall: TextStyle(
        fontFamily: ff,
        fontSize: AppTypography.captionSize - 1,
        fontWeight: FontWeight.w400,
        height: 1.40,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
      ),
      labelLarge: TextStyle(
        fontFamily: ff,
        fontSize: AppTypography.buttonSize,
        fontWeight: FontWeight.w600,
        height: 1.20,
        color: textColor,
      ),
      labelMedium: TextStyle(
        fontFamily: ff,
        fontSize: AppTypography.captionSize,
        fontWeight: FontWeight.w500,
        height: AppTypography.captionLh,
        color: secondaryColor,
      ),
      labelSmall: TextStyle(
        fontFamily: ff,
        fontSize: AppTypography.captionSize,
        fontWeight: FontWeight.w500,
        height: AppTypography.captionLh,
        color: mutedColor,
      ),
    );
  }
}
