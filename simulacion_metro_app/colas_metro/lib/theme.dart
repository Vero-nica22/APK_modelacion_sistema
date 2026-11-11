import 'package:flutter/material.dart';

/// Paleta: morado (base), rosado (acción) y amarillo (acento), en contraste.
class AppColors {
  static const deepPurple = Color(0xFF2E1065);
  static const purple = Color(0xFF5B21B6);
  static const pink = Color(0xFFEC4899);
  static const yellow = Color(0xFFFACC15);
  static const lilac = Color(0xFFDDD6FE);
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = dark
      ? const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFFD0BCFF),
          onPrimary: Color(0xFF381E72),
          primaryContainer: Color(0xFF4A2C8F),
          onPrimaryContainer: Color(0xFFEADDFF),
          secondary: Color(0xFFFF8CC1),
          onSecondary: Color(0xFF560A31),
          secondaryContainer: Color(0xFF7A1F4C),
          onSecondaryContainer: Color(0xFFFFD9EA),
          tertiary: Color(0xFFFFD84D),
          onTertiary: Color(0xFF2E2400),
          tertiaryContainer: Color(0xFF574500),
          onTertiaryContainer: Color(0xFFFFF1A8),
          error: Color(0xFFFFB4AB),
          onError: Color(0xFF690005),
          errorContainer: Color(0xFF93000A),
          onErrorContainer: Color(0xFFFFDAD6),
          surface: Color(0xFF1B1530),
          onSurface: Color(0xFFEDE7F8),
          surfaceContainerHighest: Color(0xFF2A2240),
          onSurfaceVariant: Color(0xFFCBC0DE),
          outline: Color(0xFF968BAA),
          outlineVariant: Color(0xFF443A5C),
        )
      : const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF5B21B6),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFEDE4FF),
          onPrimaryContainer: Color(0xFF2E1065),
          secondary: Color(0xFFDB2777),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFFFD9EA),
          onSecondaryContainer: Color(0xFF500724),
          tertiary: Color(0xFFFACC15),
          onTertiary: Color(0xFF2E1065),
          tertiaryContainer: Color(0xFFFFF1A8),
          onTertiaryContainer: Color(0xFF3B2F00),
          error: Color(0xFFBA1A1A),
          onError: Colors.white,
          errorContainer: Color(0xFFFFDAD6),
          onErrorContainer: Color(0xFF410002),
          surface: Colors.white,
          onSurface: Color(0xFF1D1530),
          surfaceContainerHighest: Color(0xFFEEE8F8),
          onSurfaceVariant: Color(0xFF5B5070),
          outline: Color(0xFF8B7FA3),
          outlineVariant: Color(0xFFD9D0EA),
        );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? const Color(0xFF110C1E) : const Color(0xFFF5F0FF),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? scheme.tertiary : scheme.surface),
        foregroundColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? scheme.onTertiary : scheme.onSurface),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outlineVariant)),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.secondary,
      inactiveTrackColor: scheme.outlineVariant,
      thumbColor: scheme.tertiary,
      overlayColor: scheme.secondary.withAlpha(40),
      valueIndicatorColor: scheme.primary,
      trackHeight: 6,
    ),
  );
}
