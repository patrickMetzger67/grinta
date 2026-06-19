import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color success;
  final Color warning;
  final Color danger;

  const AppColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.success,
    required this.warning,
    required this.danger,
  });

  static const AppColors light = AppColors(
    primary: Color(0xFFF95C1B),
    secondary: Color(0xFFFF8A5B),
    background: Color(0xFFF7F7F8),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1C1C1E),
    textSecondary: Color(0xFF6E6E73),
    border: Color(0xFFE5E5EA),
    success: Color(0xFF1FA971),
    warning: Color(0xFFF5A524),
    danger: Color(0xFFE53935),
  );

  static const AppColors dark = AppColors(
    primary: Color(0xFFF95C1B),
    secondary: Color(0xFFFF8A5B),
    background: Color(0xFF111214),
    surface: Color(0xFF1A1B1E),
    card: Color(0xFF202126),
    textPrimary: Color(0xFFF5F5F7),
    textSecondary: Color(0xFFAEAEB2),
    border: Color(0xFF34363C),
    success: Color(0xFF35C78A),
    warning: Color(0xFFF5B74A),
    danger: Color(0xFFFF6B6B),
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? secondary,
    Color? background,
    Color? surface,
    Color? card,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? success,
    Color? warning,
    Color? danger,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;

    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

class AppTheme {
  static const String fontFamily = 'SFPro';
  static const Color primaryColor = Color(0xFFE76637);

  static ThemeData get lightTheme => _buildTheme(
    brightness: Brightness.light,
    colors: AppColors.light,
  );

  static ThemeData get darkTheme => _buildTheme(
    brightness: Brightness.dark,
    colors: AppColors.dark,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppColors colors,
  }) {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primary,
        onPrimary: Colors.white,
        secondary: colors.secondary,
        onSecondary: Colors.white,
        error: colors.danger,
        onError: Colors.white,
        surface: colors.surface,
        onSurface: colors.textPrimary,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: colors.background,
      primaryColor: colors.primary,
      extensions: <ThemeExtension<dynamic>>[colors],

      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),

      textTheme: base.textTheme.apply(
        fontFamily: fontFamily,
        bodyColor: colors.textPrimary,
        displayColor: colors.textPrimary,
      ),

      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.border),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(
          color: colors.textSecondary,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: colors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        border: _inputBorder(colors.border),
        enabledBorder: _inputBorder(colors.border),
        focusedBorder: _inputBorder(colors.primary, width: 1.5),
        errorBorder: _inputBorder(colors.danger),
        focusedErrorBorder: _inputBorder(colors.danger, width: 1.5),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colors.surface,
        selectedColor: colors.primary.withValues(alpha: 0.15),
        secondarySelectedColor: colors.primary.withValues(alpha: 0.15),
        side: BorderSide(color: colors.border),
        labelStyle: TextStyle(
          color: colors.textPrimary,
          fontFamily: fontFamily,
          fontWeight: FontWeight.w500,
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 10,
        backgroundColor: colors.primary,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
    );
  }
}

extension BuildContextThemeX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}