import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CashuranceTheme {
  // ── Winter Chill Palette ─────────────────────────────────────────────────
  static const deep      = Color(0xFF0B2E33);   // darkest teal
  static const teal      = Color(0xFF4F7C82);   // primary accent
  static const sage      = Color(0xFF93B1B5);   // muted / secondary
  static const ice       = Color(0xFFB8E3E9);   // light highlight

  // Derived surface tones
  static const primary            = teal;
  static const primaryContainer   = Color(0xFF3D6A70);   // slightly darker teal for emphasis
  static const primaryFixed       = ice;
  static const onPrimary          = Color(0xFFFFFFFF);
  static const onPrimaryFixed     = deep;
  static const secondary          = sage;
  static const secondaryFixed     = Color(0xFFD9EEF1);   // very light ice
  static const surface            = Color(0xFFF4FAFB);   // ice-tinted white
  static const surfaceContainerLowest  = Color(0xFFFFFFFF);
  static const surfaceContainerLow     = Color(0xFFEDF6F7);
  static const surfaceContainerHigh    = Color(0xFFDCEDEF);
  static const surfaceContainerHighest = Color(0xFFCDE3E6);
  static const onSurface          = deep;
  static const onSurfaceVariant   = Color(0xFF3E5C60);
  static const outline            = sage;
  static const outlineVariant     = Color(0xFFCADEE1);

  static const error              = Color(0xFFBA1A1A);
  static const errorContainer     = Color(0xFFFFDAD6);

  // Semantic Colors (harmonised with teal palette)
  static const successGreen  = Color(0xFF137B3A);
  static const successBg     = Color(0xFFE2F5EA);
  static const warningOrange = Color(0xFF9C6704);
  static const warningBg     = Color(0xFFFFF5E5);
  static const rejectRed     = Color(0xFFAD1E1E);
  static const rejectBg      = Color(0xFFFFECEC);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: teal,
          brightness: Brightness.light,
        ).copyWith(
          primary: teal,
          primaryContainer: primaryContainer,
          surface: surface,
          onSurface: onSurface,
          outline: outline,
        ),
        textTheme: GoogleFonts.interTextTheme().copyWith(
          displayLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
          displayMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
          headlineLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
          headlineMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
          headlineSmall: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
          titleLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
          titleMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
          labelSmall: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: surfaceContainerLowest,
          elevation: 0,
          scrolledUnderElevation: 1,
          titleTextStyle: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: deep,
          ),
          iconTheme: const IconThemeData(color: deep),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: deep,
          indicatorColor: teal,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.white);
            }
            return const IconThemeData(color: sage);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isSelected ? Colors.white : sage,
            );
          }),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: outlineVariant, width: 0.8),
          ),
          margin: EdgeInsets.zero,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: teal,
            foregroundColor: onPrimary,
            textStyle: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: teal,
            side: const BorderSide(color: teal),
            textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: teal, width: 2),
          ),
          labelStyle: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: sage,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: ice,
          selectedColor: teal,
          secondarySelectedColor: teal,
          labelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        scaffoldBackgroundColor: surface,
      );
}

class CashuranceCard extends StatelessWidget {
  const CashuranceCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CashuranceTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CashuranceTheme.outlineVariant, width: 0.8),
      ),
      child: child,
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.spaceGrotesk(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: CashuranceTheme.teal,
      ),
    );
  }
}
