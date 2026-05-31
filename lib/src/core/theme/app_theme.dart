import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData build({required double fontSize}) {
    // Палитра: темно, “мужская” чистота, фиолетовый акцент
    const accent = Color(0xFF8B5CF6);
    const bg = Color(0xFF0B0F17);
    const surface = Color(0xFF111827);
    const surface2 = Color(0xFF0F1A2B);
    const outline = Color(0x1AFFFFFF);

    final cs = const ColorScheme.dark().copyWith(
      primary: accent,
      secondary: accent,
      background: bg,
      surface: surface,
      error: const Color(0xFFFF5C7A),
    );

    // ✅ Масштаб типографики без TextTheme.apply()
    final factor = (fontSize / 14).clamp(0.85, 1.25);

    TextStyle? _scaleStyle(TextStyle? s) {
      if (s == null) return null;
      final fs = s.fontSize;
      if (fs == null) return s;
      return s.copyWith(fontSize: fs * factor);
    }

    TextTheme _scaleTheme(TextTheme t) {
      return t.copyWith(
        displayLarge: _scaleStyle(t.displayLarge),
        displayMedium: _scaleStyle(t.displayMedium),
        displaySmall: _scaleStyle(t.displaySmall),
        headlineLarge: _scaleStyle(t.headlineLarge),
        headlineMedium: _scaleStyle(t.headlineMedium),
        headlineSmall: _scaleStyle(t.headlineSmall),
        titleLarge: _scaleStyle(t.titleLarge),
        titleMedium: _scaleStyle(t.titleMedium),
        titleSmall: _scaleStyle(t.titleSmall),
        bodyLarge: _scaleStyle(t.bodyLarge),
        bodyMedium: _scaleStyle(t.bodyMedium),
        bodySmall: _scaleStyle(t.bodySmall),
        labelLarge: _scaleStyle(t.labelLarge),
        labelMedium: _scaleStyle(t.labelMedium),
        labelSmall: _scaleStyle(t.labelSmall),
      );
    }

    final baseTextTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
    ).textTheme;

    final scaledTextTheme = _scaleTheme(baseTextTheme);

    final base = ThemeData(
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
      textTheme: scaledTextTheme,
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: outline),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(22)),
          side: BorderSide(color: outline),
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
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: accent.withOpacity(0.55)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: outline),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );

    return base;
  }
}
