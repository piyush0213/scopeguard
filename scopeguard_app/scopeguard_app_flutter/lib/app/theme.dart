import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Same palette as the ScopeGuard website: obsidian canvas, vermilion flame, mint "proof" green, cyan.
const canvas = Color(0xFF08090D);
const surface = Color(0xFF10121A);
const raised = Color(0xFF1B1E2A);
const line = Color(0x14FFFFFF);
const ink = Color(0xFFF8F9FB);
const muted = Color(0xFF939CB5);
const faint = Color(0xFF69718C);
const brand = Color(0xFFFF5733);
const leaf = Color(0xFF34D399);
const cyan = Color(0xFF38BDF8);
const amber = Color(0xFFFBBF24);

/// One colour per seat in a Scope Room; the lock wave lights each phone in its own colour.
const seatColors = <Color>[brand, leaf, cyan, amber, Color(0xFFA78BFA), Color(0xFFF472B6), Color(0xFF2DD4BF), Color(0xFFFB923C)];
Color seatColor(int i) => seatColors[i % seatColors.length];

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: canvas,
    colorScheme: ColorScheme.fromSeed(seedColor: brand, brightness: Brightness.dark, surface: surface, primary: brand),
  );
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: ink, displayColor: ink),
    appBarTheme: const AppBarTheme(backgroundColor: canvas, surfaceTintColor: Colors.transparent, elevation: 0),
    dividerColor: line,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.03),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x1AFFFFFF))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: brand)),
      hintStyle: const TextStyle(color: faint),
      labelStyle: const TextStyle(color: muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: brand,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size(64, 52),
        side: const BorderSide(color: Color(0x26FFFFFF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: raised, contentTextStyle: TextStyle(color: ink)),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: brand.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, color: muted)),
    ),
  );
}

TextStyle display(double size, {Color color = ink, FontStyle? style}) =>
    GoogleFonts.instrumentSerif(fontSize: size, color: color, height: 1.0, fontStyle: style, letterSpacing: -0.5);

TextStyle mono(double size, {Color color = muted, FontWeight? weight, double spacing = 1.2}) =>
    GoogleFonts.jetBrainsMono(fontSize: size, color: color, fontWeight: weight, letterSpacing: spacing);

String money(num cents) {
  final d = cents / 100;
  final whole = d.truncate();
  final s = whole.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  final frac = (cents % 100).toInt();
  return frac == 0 ? '\$$s' : '\$$s.${frac.toString().padLeft(2, '0')}';
}
