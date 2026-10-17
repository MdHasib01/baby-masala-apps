import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Text style in the app font. The app uses the device's system font, like
/// the Facebook app: Roboto for Latin and Android's built-in Noto Sans Bengali
/// for Bengali (picked automatically as fallback). No bundled font.
TextStyle _font({double? fontSize, FontWeight? fontWeight, Color? color}) =>
    TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color);

/// Light-only theme (the web app has no dark mode). Font: system (Facebook-style).
///
/// Modern mobile look: light app bars with maroon titles, filled rounded
/// inputs, 14–20 px radii, Material 3 bottom navigation with a sand pill.
/// Avoid blurred BoxShadows (see MOBILE_SYNC.md — Impeller emulator bug);
/// depth comes from borders and tonal fills instead.
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

  final text = base.textTheme.apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
  );

  final radius = BorderRadius.circular(14);
  const hind = _font;
  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.maroon,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      titleTextStyle: hind(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.maroon),
      iconTheme: const IconThemeData(color: AppColors.maroon, size: 22),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: hind(fontSize: 13, color: AppColors.grey400),
      prefixIconColor: AppColors.grey500,
      border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: AppColors.sandA(0.7))),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: AppColors.sandA(0.7))),
      focusedBorder:
          OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.maroon, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.red600)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.maroon,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.grey200,
        elevation: 0,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: hind(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.maroon,
        side: const BorderSide(color: AppColors.sand),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: hind(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.maroon,
        textStyle: hind(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: AppColors.sandA(0.55),
      indicatorShape: const StadiumBorder(),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          size: 22,
          color: s.contains(WidgetState.selected) ? AppColors.maroon : AppColors.ink.withValues(alpha: 0.55),
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => hind(
          fontSize: 11.5,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? AppColors.maroon : AppColors.ink.withValues(alpha: 0.6),
        ),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.maroon,
      unselectedLabelColor: AppColors.grey500,
      indicatorColor: AppColors.maroon,
      dividerColor: AppColors.sandA(0.6),
      labelStyle: hind(fontSize: 12.5, fontWeight: FontWeight.w700),
      unselectedLabelStyle: hind(fontSize: 12.5, fontWeight: FontWeight.w600),
    ),
    dividerTheme: DividerThemeData(color: AppColors.sandA(0.7), thickness: 1, space: 1),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.cream,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      showDragHandle: true,
      dragHandleColor: AppColors.sand,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.sandA(0.6))),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentTextStyle: hind(color: Colors.white, fontSize: 13),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: BorderSide(color: AppColors.sandA(0.8)),
      shape: const StadiumBorder(),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.maroon,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}
