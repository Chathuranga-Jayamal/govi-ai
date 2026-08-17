import 'package:flutter/material.dart';

/// Seed palette approved in the Phase D design system review.
/// Named for their source in Sri Lankan smallholder agriculture rather than
/// generic Material roles, so the mapping to [AppTheme] stays legible.
class AppColors {
  AppColors._();

  // Seed colors — feed ColorScheme.fromSeed in app_theme.dart
  static const Color paddyGreen = Color(0xFF2F6B3F);
  static const Color turmericGold = Color(0xFFD99A2B);
  static const Color monsoonTeal = Color(0xFF2D7D82);
  static const Color riceHusk = Color(0xFFFAF7F0);
  static const Color soilInk = Color(0xFF2A2521);
  static const Color alertRed = Color(0xFFBA1A1A);

  // Hand-picked container/on-container tones from the approved design
  // system, applied via ColorScheme.copyWith so they match exactly rather
  // than relying solely on M3's algorithmically-derived tonal palette.
  static const Color paddyGreenContainer = Color(0xFFE3F1E5);
  static const Color paddyGreenOnContainer = Color(0xFF12401F);

  static const Color turmericGoldContainer = Color(0xFFFBEBCB);
  static const Color turmericGoldOnContainer = Color(0xFF503C05);

  static const Color monsoonTealContainer = Color(0xFFDCEEF0);
  static const Color monsoonTealOnContainer = Color(0xFF0B3A3D);

  static const Color alertRedContainer = Color(0xFFFDDEDC);
  static const Color alertRedOnContainer = Color(0xFF650A0A);

  static const Color soilInkSoft = Color(0xFF6B6259);
  static const Color hairline = Color(0xFFE4DDD0);
  static const Color surfaceRaised = Color(0xFFFFFFFF);
}
