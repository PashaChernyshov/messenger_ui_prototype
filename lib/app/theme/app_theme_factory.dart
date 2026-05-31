import 'package:flutter/material.dart';

class AppThemeFactory {
  const AppThemeFactory();

  ThemeData build(double fontSize) {
    const accent = Color(0xFF3B82F6);
    const bg = Color(0xFF0B1120);
    const surface = Color(0xFF111827);
    const surface2 = Color(0xFF172033);
    const surface3 = Color(0xFF1A2538);
    const outline = Color(0x001A2332);

    final cs = const ColorScheme.dark().copyWith(
      primary: accent,
      secondary: accent,
      background: bg,
      surface: surface,
      error: const Color(0xFFFF5C7A),
    );

    final baseTextTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
    ).textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(
        thickness: 1,
        space: 1,
        color: outline,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: _scaleTextTheme(baseTextTheme, fontSize),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide.none,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          side: BorderSide.none,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        iconColor: Colors.white70,
        textColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: bg,
        selectedIconTheme: IconThemeData(color: accent),
        unselectedIconTheme: IconThemeData(color: Colors.white54),
        selectedLabelTextStyle:
            TextStyle(color: accent, fontWeight: FontWeight.w700),
        unselectedLabelTextStyle: TextStyle(color: Colors.white54),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        hintStyle: const TextStyle(color: Colors.white38),
        labelStyle: const TextStyle(color: Colors.white70),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accent.withOpacity(0.38)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: surface3,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  TextTheme _scaleTextTheme(TextTheme theme, double fontSize) {
    final factor = (fontSize / 14).clamp(0.85, 1.25);
    return theme.copyWith(
      displayLarge: _scaleTextStyle(theme.displayLarge, factor),
      displayMedium: _scaleTextStyle(theme.displayMedium, factor),
      displaySmall: _scaleTextStyle(theme.displaySmall, factor),
      headlineLarge: _scaleTextStyle(theme.headlineLarge, factor),
      headlineMedium: _scaleTextStyle(theme.headlineMedium, factor),
      headlineSmall: _scaleTextStyle(theme.headlineSmall, factor),
      titleLarge: _scaleTextStyle(theme.titleLarge, factor),
      titleMedium: _scaleTextStyle(theme.titleMedium, factor),
      titleSmall: _scaleTextStyle(theme.titleSmall, factor),
      bodyLarge: _scaleTextStyle(theme.bodyLarge, factor),
      bodyMedium: _scaleTextStyle(theme.bodyMedium, factor),
      bodySmall: _scaleTextStyle(theme.bodySmall, factor),
      labelLarge: _scaleTextStyle(theme.labelLarge, factor),
      labelMedium: _scaleTextStyle(theme.labelMedium, factor),
      labelSmall: _scaleTextStyle(theme.labelSmall, factor),
    );
  }

  TextStyle? _scaleTextStyle(TextStyle? style, double factor) {
    final fontSize = style?.fontSize;
    if (style == null || fontSize == null) return style;
    return style.copyWith(fontSize: fontSize * factor);
  }
}
