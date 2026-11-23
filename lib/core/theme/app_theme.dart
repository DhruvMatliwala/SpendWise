import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Semantic fintech status colors exposed via [ThemeData.extensions].
@immutable
class SpendWiseColors extends ThemeExtension<SpendWiseColors> {
  const SpendWiseColors({
    required this.safe,
    required this.warning,
    required this.exceeded,
    required this.cardBorder,
    required this.mutedSurface,
  });

  const SpendWiseColors.dark()
      : safe = const Color(0xFF10B981),
        warning = const Color(0xFFF59E0B),
        exceeded = const Color(0xFFEF4444),
        cardBorder = const Color(0xFF334155),
        mutedSurface = const Color(0xFF0F172A);

  const SpendWiseColors.light()
      : safe = const Color(0xFF059669),
        warning = const Color(0xFFD97706),
        exceeded = const Color(0xFFDC2626),
        cardBorder = const Color(0xFFE2E8F0),
        mutedSurface = const Color(0xFFF1F5F9);

  final Color safe;
  final Color warning;
  final Color exceeded;
  final Color cardBorder;
  final Color mutedSurface;

  /// Helper to read [SpendWiseColors] safely from [BuildContext].
  static SpendWiseColors of(BuildContext context) {
    final extension = Theme.of(context).extension<SpendWiseColors>();
    if (extension != null) return extension;
    return Theme.of(context).brightness == Brightness.dark
        ? const SpendWiseColors.dark()
        : const SpendWiseColors.light();
  }

  @override
  SpendWiseColors copyWith({
    Color? safe,
    Color? warning,
    Color? exceeded,
    Color? cardBorder,
    Color? mutedSurface,
  }) {
    return SpendWiseColors(
      safe: safe ?? this.safe,
      warning: warning ?? this.warning,
      exceeded: exceeded ?? this.exceeded,
      cardBorder: cardBorder ?? this.cardBorder,
      mutedSurface: mutedSurface ?? this.mutedSurface,
    );
  }

  @override
  SpendWiseColors lerp(ThemeExtension<SpendWiseColors>? other, double t) {
    if (other is! SpendWiseColors) return this;
    return SpendWiseColors(
      safe: Color.lerp(safe, other.safe, t) ?? safe,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      exceeded: Color.lerp(exceeded, other.exceeded, t) ?? exceeded,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t) ?? cardBorder,
      mutedSurface:
          Color.lerp(mutedSurface, other.mutedSurface, t) ?? mutedSurface,
    );
  }
}

/// Material Design 3 light and dark themes for SpendWise.
abstract final class AppTheme {
  static const Color _darkBackground = Color(0xFF0B1120);
  static const Color _darkSurface = Color(0xFF111827);
  static const Color _darkCard = Color(0xFF1E293B);
  static const Color _darkSeed = Color(0xFF6366F1);

  static const Color _lightBackground = Color(0xFFF8FAFC);
  static const Color _lightSeed = Color(0xFF4F46E5);

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _darkSeed,
      brightness: Brightness.dark,
      surface: _darkSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _darkBackground,
      extensions: const [SpendWiseColors.dark()],
      appBarTheme: AppBarTheme(
        backgroundColor: _darkBackground,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: _darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14.0,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _darkSurface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _lightSeed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _lightBackground,
      extensions: const [SpendWiseColors.light()],
      appBarTheme: AppBarTheme(
        backgroundColor: _lightBackground,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14.0,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.14),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
    );
  }
}
