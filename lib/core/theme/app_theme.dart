import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Seed color for M3 palette fallback
  static const Color seedPink = Color(0xFFE91E63);

  // AMOLED-compatible surface tokens (mirror M3 dark scheme)
  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color surfaceHigh = Color(0xFF2A2A2A);
  static const Color cardDark = Color(0xFF1C1C2E);
  static const Color accentPurple = Color(0xFF9C27B0);

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color textMuted = Color(0xFF6B6B80);

  // Functional
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color success = Color(0xFF2ED573);
  static const Color error = Color(0xFFFF4757);
  static const Color warning = Color(0xFFFFA502);

  // Gradients (for decorative elements)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [seedPink, Color(0xFF9C27B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData amoledDark(ColorScheme? dynamicColorScheme) {
    final scheme = dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: AppColors.seedPink,
          brightness: Brightness.dark,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme.copyWith(
        // AMOLED: force pure black background
        surface: const Color(0xFF000000),
        // Override surface variants for AMOLED depth
      ),

      scaffoldBackgroundColor: const Color(0xFF000000),

      // ─── M3 Surface Container Tokens ─────────────────────────
      // Applied via component themes below since ThemeData doesn't
      // expose surfaceContainerLow/High directly.

      // ─── Navigation Bar ──────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF111111),
        indicatorColor: scheme.primary.withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: scheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(color: scheme.onSurfaceVariant, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.primary, size: 24);
          }
          return IconThemeData(color: scheme.onSurfaceVariant, size: 24);
        }),
      ),

      // ─── Card ────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1A1A),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ─── Bottom Sheet ────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: const Color(0xFF1A1A1A),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        dragHandleColor: scheme.onSurfaceVariant.withValues(alpha: 0.4),
        dragHandleSize: const Size(32, 4),
        showDragHandle: false,
      ),

      // ─── App Bar ─────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
        ),
      ),

      // ─── Buttons ────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ─── Input Fields ────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),

      // ─── Dialog ──────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1A1A1A),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),

      // ─── Snack Bar ───────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2A2A2A),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ─── List Tile ───────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ─── Switch ──────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withValues(alpha: 0.3);
          }
          return scheme.onSurfaceVariant.withValues(alpha: 0.2);
        }),
      ),

      // ─── Divider ────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.3),
        thickness: 1,
      ),

      // ─── Chip ────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1A1A1A),
        selectedColor: scheme.primary.withValues(alpha: 0.2),
        labelStyle: TextStyle(color: scheme.onSurface),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // ─── Floating Action Button ──────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),

      // ─── Typography ──────────────────────────────────────────
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: scheme.onSurface,
          fontSize: 48,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
        headlineLarge: TextStyle(
          color: scheme.onSurface,
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: scheme.onSurface,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: scheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 14,
        ),
        labelLarge: TextStyle(
          color: scheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}