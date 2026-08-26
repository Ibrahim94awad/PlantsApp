import 'package:flutter/material.dart';

// Botanical Inventory design tokens (from Stitch DESIGN.md).
const Color kPrimary = Color(0xFF2D5A27);
const Color kPrimaryDark = Color(0xFF154212);
const Color kSurface = Color(0xFFFFF8F5);
const Color kCardBorder = Color(0xFFE7E5E4);
const Color kPanelTint = Color(0xFFF7EFEB);
const Color kOnSurface = Color(0xFF1E1B19);
const Color kOnSurfaceVariant = Color(0xFF42493E);
const Color kStatusBg = Color(0xFFDCEFD6);
const Color kStatusGreen = Color(0xFF22A146);
const Color kDanger = Color(0xFFBA1A1A);
const Color kBgGradientTop = Color(0xFFEAF3E6);
const Color kBgGradientBottom = Color(0xFFD3E7CB);

// Tokens promoted from previously inline color literals.
const Color kNavBackground = Color(0xE6FFFFFF);
const Color kChipNeutralBg = Color(0xFFF4ECE8);
const Color kSurfaceContainerHighest = Color(0xFFE9E1DD);
const Color kOutlineVariant = Color(0xFFDDD8D3);
const Color kSecondary = Color(0xFF5E5E5E);
const Color kFilterSelectedBg = Color(0xFFDCFCE7);
const Color kFilterNeutralBg = Color(0xFFE5E7EB);
const Color kErrorContainer = Color(0xFFFFDAD6);
const Color kOnErrorContainer = Color(0xFF93000A);

ThemeData buildAppTheme() {
  final colorScheme = const ColorScheme.light().copyWith(
    primary: kPrimary,
    onPrimary: Colors.white,
    primaryContainer: kStatusBg,
    onPrimaryContainer: kPrimaryDark,
    secondary: kSecondary,
    onSecondary: Colors.white,
    surface: kSurface,
    onSurface: kOnSurface,
    onSurfaceVariant: kOnSurfaceVariant,
    surfaceContainerHighest: kSurfaceContainerHighest,
    outlineVariant: kOutlineVariant,
    error: kDanger,
    onError: Colors.white,
  );
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: kPrimary,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        color: kPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.01,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kCardBorder),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kCardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kCardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kPrimary, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kOnSurface,
        side: const BorderSide(color: kCardBorder),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kNavBackground,
      indicatorColor: kStatusBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? kPrimary
              : kOnSurfaceVariant,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? kPrimary
              : kOnSurfaceVariant,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: kChipNeutralBg,
      selectedColor: kPrimary,
      labelStyle: const TextStyle(
          color: kOnSurfaceVariant, fontWeight: FontWeight.w600),
      secondaryLabelStyle:
          const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      side: const BorderSide(color: kCardBorder),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

/// Wraps the app in the standard botanical gradient background.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kBgGradientTop, kBgGradientBottom],
          ),
        ),
        child: child,
      );
}
