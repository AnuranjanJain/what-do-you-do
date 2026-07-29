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
    final dark = brightness == Brightness.dark;
    final baseScheme = ColorScheme.fromSeed(
      seedColor: AppColors.yellow,
      brightness: brightness,
      surface: surface,
    );
    final scheme = baseScheme.copyWith(
      primary: dark ? AppColors.yellow : AppColors.ink,
      onPrimary: dark ? AppColors.ink : Colors.white,
      secondary: dark ? AppColors.mint : AppColors.purple,
      onSecondary: dark ? AppColors.ink : Colors.white,
      surface: surface,
      onSurface: text,
      surfaceContainerLowest: dark
          ? const Color(0xFF171915)
          : const Color(0xFFF9F8F2),
      surfaceContainerLow: dark
          ? const Color(0xFF20221E)
          : const Color(0xFFF0EFE8),
      surfaceContainer: dark
          ? const Color(0xFF252722)
          : const Color(0xFFEAE9E1),
      surfaceContainerHigh: dark
          ? const Color(0xFF2A2C27)
          : const Color(0xFFE4E3DB),
      surfaceContainerHighest: dark
          ? const Color(0xFF30322C)
          : const Color(0xFFDCDBD3),
      outline: dark ? const Color(0xFF8D9186) : const Color(0xFF73776F),
      outlineVariant: dark ? const Color(0xFF44473F) : const Color(0xFFC7C7BD),
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
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.72),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: AppColors.yellow.withValues(alpha: 0.4),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? (dark ? AppColors.ink : Colors.white)
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
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
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: dark ? AppColors.yellow : AppColors.ink,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? (dark ? AppColors.ink : Colors.white)
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
