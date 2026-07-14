import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF1F211D);
  static const paper = Color(0xFFF4F3EC);
  static const yellow = Color(0xFFFFD84D);
  static const mint = Color(0xFFDFF0E4);
  static const ice = Color(0xFFDDEEF0);
  static const peach = Color(0xFFF3D6C5);
  static const dark = Color(0xFF242621);
  static const purple = Color(0xFF7B61A8);
}

abstract final class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    scaffold: const Color(0xFFAEB4BD),
    surface: AppColors.paper,
    text: AppColors.ink,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    scaffold: const Color(0xFF121310),
    surface: const Color(0xFF1C1E1A),
    text: const Color(0xFFF5F2E8),
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color text,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.yellow,
      brightness: brightness,
      surface: surface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: 'Segoe UI',
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
        bodyColor: text,
        displayColor: text,
        fontFamily: 'Segoe UI',
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: brightness == Brightness.light
                ? Colors.black.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(42, 42)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: brightness == Brightness.light
            ? AppColors.ink
            : AppColors.yellow,
        selectedIconTheme: IconThemeData(
          color: brightness == Brightness.light ? Colors.white : AppColors.ink,
        ),
      ),
    );
  }
}
