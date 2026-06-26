import 'package:flutter/material.dart';

class AppColors {
  // -- Core brand (aligned with primebusiness.network) --
  static const Color primary      = Color(0xFF080D24);  // Website --navy
  static const Color primaryMid   = Color(0xFF0E1535);  // Website --navy-mid
  static const Color primaryLight = Color(0xFF162050);  // Website --navy-light
  static const Color secondary    = Color(0xFFEAEDF5);
  static const Color accent       = Color(0xFFC9A84C);  // Brand gold

  // -- Backgrounds --
  static const Color background     = Color(0xFFFFFFFF);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceAlt     = Color(0xFFEAEDF5);

  // -- Text hierarchy --
  static const Color text           = Color(0xFF080D24);
  static const Color textSecondary  = Color(0xFF4A5580);
  static const Color textMuted      = Color(0xFF7A85B0);

  // -- Semantic --
  static const Color accentBlue  = Color(0xFF4F7CFF);
  static const Color success     = Color(0xFF10B981);
  static const Color warning     = Color(0xFFF59E0B);
  static const Color error       = Color(0xFFEF4444);

  // -- Borders & Shadows --
  static const Color border      = Color(0xFFDDE1F0);
  static const Color borderLight = Color(0xFFEAEDF5);
  static const Color shadowBase  = Color(0xFF080D24);

  // -- Premium gradient helpers (palette-derived, no new colors) --
  /// Polished gold gradient — use for premium buttons, badges, highlights.
  static const List<Color> goldGradient = [
    Color(0xFFE8C97A),
    Color(0xFFC9A84C),
    Color(0xFF8A6A20),
  ];

  /// Soft elevated gold gradient — lighter, used for subtle accents.
  static const List<Color> goldSoftGradient = [
    Color(0xFFF5E7B8),
    Color(0xFFE8C97A),
  ];

  /// Deep navy gradient — premium dark surfaces / hero cards.
  static const List<Color> primaryGradient = [
    Color(0xFF080D24),
    Color(0xFF162050),
  ];

  /// Subtle surface gradient — for premium "off-white" cards.
  static const List<Color> surfaceGradient = [
    Color(0xFFFFFFFF),
    Color(0xFFFAFBFC),
  ];

  // -- Premium shadow presets (two-layer soft shadow) --
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: const Color(0xFF080D24).withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: const Color(0xFF080D24).withValues(alpha: 0.02),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: const Color(0xFF080D24).withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF080D24).withValues(alpha: 0.03),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: const Color(0xFF080D24).withValues(alpha: 0.08),
      blurRadius: 32,
      offset: const Offset(0, 16),
    ),
    BoxShadow(
      color: const Color(0xFF080D24).withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  /// Gold glow — for premium CTAs and highlight cards.
  static List<BoxShadow> goldGlow = [
    BoxShadow(
      color: const Color(0xFFC9A84C).withValues(alpha: 0.25),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: const Color(0xFFC9A84C).withValues(alpha: 0.10),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
}
