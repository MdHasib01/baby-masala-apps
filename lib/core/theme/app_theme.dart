import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Light-only theme (the web app has no dark mode). Font: Hind Siliguri.
ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.maroon,
      primary: AppColors.maroon,
      secondary: AppColors.olive,
      tertiary: AppColors.gold,
      surface: AppColors.white,
    ),
    scaffoldBackgroundColor: AppColors.cream,
  );

  final text = GoogleFonts.hindSiliguriTextTheme(base.textTheme).apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
  );

  final radius = BorderRadius.circular(12);
  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.maroon,
      foregroundColor: Colors.white,
      elevation: 2,
      titleTextStyle: GoogleFonts.hindSiliguri(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: GoogleFonts.hindSiliguri(fontSize: 13, color: AppColors.grey400),
      border: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.sand)),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.sand)),
      focusedBorder:
          OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.maroon, width: 1.4)),
      errorBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.red600)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.maroon,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.grey200,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: GoogleFonts.hindSiliguri(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.maroon,
        side: const BorderSide(color: AppColors.sand),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: GoogleFonts.hindSiliguri(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.maroon,
        textStyle: GoogleFonts.hindSiliguri(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.sand, thickness: 1, space: 1),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      showDragHandle: true,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: GoogleFonts.hindSiliguri(color: Colors.white, fontSize: 13),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: const BorderSide(color: AppColors.sand),
      shape: const StadiumBorder(),
    ),
  );
}
