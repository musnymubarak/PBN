import 'package:flutter/material.dart';

class AppColors {
  // -- Core brand --
  static const Color primary    = Color(0xFF0F172A);
  static const Color secondary  = Color(0xFFF1F5F9);
  static const Color accent     = Color(0xFFD4A64F);  // Premium gold

  // -- Backgrounds --
  static const Color background     = Color(0xFFF8FAFC);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceAlt     = Color(0xFFF1F5F9);

  // -- Text hierarchy --
  static const Color text           = Color(0xFF0F172A);
  static const Color textSecondary  = Color(0xFF64748B);
  static const Color textMuted      = Color(0xFF94A3B8);

  // -- Semantic --
  static const Color accentBlue  = Color(0xFF4F7CFF);
  static const Color success     = Color(0xFF10B981);
  static const Color warning     = Color(0xFFF59E0B);
  static const Color error       = Color(0xFFEF4444);

  // -- Borders & Shadows --
  static const Color border      = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color shadowBase  = Color(0xFF0F172A);

  // -- Premium gradient helpers (palette-derived, no new colors) --
  /// Polished gold gradient — use for premium buttons, badges, highlights.
  static const List<Color> goldGradient = [
    Color(0xFFE8C268),
    Color(0xFFD4A64F),
    Color(0xFFB78936),
  ];

  /// Soft elevated gold gradient — lighter, used for subtle accents.
  static const List<Color> goldSoftGradient = [
    Color(0xFFF5E2B0),
    Color(0xFFE8C268),
  ];

  /// Deep navy gradient — premium dark surfaces / hero cards.
  static const List<Color> primaryGradient = [
    Color(0xFF0B0F1F),
    Color(0xFF162033),
  ];

  /// Subtle surface gradient — for premium "off-white" cards.
  static const List<Color> surfaceGradient = [
    Color(0xFFFFFFFF),
    Color(0xFFFAFBFC),
  ];

  // -- Premium shadow presets (two-layer soft shadow) --
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.02),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
      blurRadius: 32,
      offset: const Offset(0, 16),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  /// Gold glow — for premium CTAs and highlight cards.
  static List<BoxShadow> goldGlow = [
    BoxShadow(
      color: const Color(0xFFD4A64F).withValues(alpha: 0.25),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: const Color(0xFFD4A64F).withValues(alpha: 0.10),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
}
