import 'package:flutter/material.dart';

/// Color Hunt palette: https://colorhunt.co/palette/4e56c09b5de0d78feefdcffa
class AppColors {
  AppColors._();

  // Palette
  static const Color indigo = Color(0xFF4E56C0);
  static const Color violet = Color(0xFF9B5DE0);
  static const Color orchid = Color(0xFFD78FEE);
  static const Color blush = Color(0xFFFDCFFA);

  // Semantic aliases
  static const Color primary = indigo;
  static const Color primaryDark = Color(0xFF3A4199);
  static const Color primaryLight = Color(0xFF6B72D0);
  static const Color secondary = violet;
  static const Color accent = orchid;
  static const Color accentLight = blush;
  static const Color purple = violet;
  static const Color purpleLight = orchid;
  static const Color purpleSurface = Color(0xFFF9F0FE);

  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFAF8FD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color darkGray = Color(0xFF2D2A3E);
  static const Color mediumGray = Color(0xFF6B6578);
  static const Color lightGray = Color(0xFFB8B0C4);
  static const Color border = Color(0xFFE8E0F0);

  static const Color success = Color(0xFF4CAF7D);
  static const Color successLight = Color(0xFFE8F8F0);
  static const Color error = Color(0xFFE05A6E);
  static const Color errorLight = Color(0xFFFDEDF0);
  static const Color warning = Color(0xFFE8A838);
  static const Color info = Color(0xFF4E56C0);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [indigo, primaryDark],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [indigo, violet],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, orchid],
  );

  static const LinearGradient richGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [indigo, violet, orchid],
  );

  /// Soft, near-white wash with a hint of purple — used behind dark-on-light
  /// brand marks (e.g. splash screen) so the logo pops without a heavy block
  /// of color.
  static const LinearGradient lightSurfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [white, purpleSurface],
  );

  /// @deprecated Use [accentGradient] instead.
  static const LinearGradient goldGradient = accentGradient;
}
