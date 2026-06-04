import 'package:flutter/material.dart';

class AppThemeFactory {
  const AppThemeFactory();

  ThemeData build(double fontSize) {
    const accent = Color(0xFFE6E2DA);
    const accentMuted = Color(0xFFB8B2A8);
    const bg = Color(0xFF050505);
    const surface = Color(0xFF0D0D0D);
    const surface2 = Color(0xFF151515);
    const surface3 = Color(0xFF1F1F1F);
    const surface4 = Color(0xFF292929);
    const outline = Color(0xFF2B2B2B);

    final cs = const ColorScheme.dark().copyWith(
      primary: accent,
      onPrimary: const Color(0xFF101010),
      secondary: accentMuted,
      onSecondary: const Color(0xFF101010),
      tertiary: const Color(0xFF8E887E),
      background: bg,
      onBackground: const Color(0xFFEDEBE7),
      surface: surface,
      onSurface: const Color(0xFFEDEBE7),
      surfaceContainerHighest: surface4,
      outline: outline,
      error: const Color(0xFFE06C6C),
      onError: const Color(0xFF120707),
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
        backgroundColor: surface3,
        contentTextStyle: TextStyle(color: Color(0xFFEDEBE7)),
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
        iconColor: Color(0xFFC9C5BD),
        textColor: Color(0xFFEDEBE7),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: Color(0xFF8A8A8A),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: accent.withOpacity(0.12),
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? accent : const Color(0xFF8A8A8A),
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? accent : const Color(0xFF8A8A8A),
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            fontSize: 12,
          );
        }),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: bg,
        selectedIconTheme: IconThemeData(color: accent),
        unselectedIconTheme: IconThemeData(color: Color(0xFF8A8A8A)),
        selectedLabelTextStyle:
            TextStyle(color: accent, fontWeight: FontWeight.w700),
        unselectedLabelTextStyle: TextStyle(color: Color(0xFF8A8A8A)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Color(0xFF101010),
        elevation: 0,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: const Color(0xFFEDEBE7),
          backgroundColor: surface2,
          disabledForegroundColor: const Color(0xFF666666),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: surface2,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: TextStyle(
          color: Color(0xFFEDEBE7),
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        hintStyle: const TextStyle(color: Color(0xFF777777)),
        labelStyle: const TextStyle(color: Color(0xFFC9C5BD)),
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
          borderSide: BorderSide(color: accent.withOpacity(0.34)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: const Color(0xFF101010),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFEDEBE7),
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
