import 'package:flutter/material.dart';

/// Brand palette — copied from the hex values used across the web app's
/// Tailwind classes (frontend/src). Keep in sync with MOBILE_SYNC.md.
class AppColors {
  const AppColors._();

  static const maroon = Color(0xFF56020A); // primary
  static const olive = Color(0xFF375013); // secondary
  static const gold = Color(0xFFD6AA4F); // accent
  static const sand = Color(0xFFEDD6A9); // borders / chips
  static const cream = Color(0xFFFAF6F0); // background
  static const ink = Color(0xFF2D2327); // body text
  static const white = Colors.white;

  static const grey50 = Color(0xFFF9FAFB);
  static const grey100 = Color(0xFFF3F4F6);
  static const grey200 = Color(0xFFE5E7EB);
  static const grey400 = Color(0xFF9CA3AF);
  static const grey500 = Color(0xFF6B7280);
  static const grey600 = Color(0xFF4B5563);
  static const grey900 = Color(0xFF111827);

  static const red50 = Color(0xFFFEF2F2);
  static const red600 = Color(0xFFDC2626);
  static const green50 = Color(0xFFF0FDF4);
  static const green700 = Color(0xFF15803D);
  static const amber50 = Color(0xFFFFFBEB);
  static const amber800 = Color(0xFF92400E);
  static const blue50 = Color(0xFFEFF6FF);
  static const blue600 = Color(0xFF2563EB);

  static Color sandA(double opacity) => sand.withValues(alpha: opacity);

  /// Signature gradient (maroon → olive).
  static const brandGradient = LinearGradient(
    colors: [maroon, olive],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const brandGradientReverse = LinearGradient(
    colors: [olive, maroon],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
