import 'package:flutter/material.dart';

/// Dark Theme Colors - Neo-Brutalism Design System
/// 
/// Philosophy:
/// - Keep brand colors vibrant (primary, secondary, accent stay similar)
/// - Dark surfaces with depth (not pure black)
/// - Clear text hierarchy
class AppColorsDark {
  AppColorsDark._();

  // ========================
  // DARK THEME - NEUTRALS
  // ========================

  /// Background - Not pure black, has depth
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFF2C2C2C);
  
  /// Elevated surfaces (cards, dialogs)
  static const Color surfaceElevated = Color(0xFF2D2D2D);
  static const Color surfaceElevatedHigh = Color(0xFF383838);

  /// Text colors (Dark mode)
  static const Color textPrimary = Color(0xFFE6E1E5);
  static const Color textSecondary = Color(0xFFCAC4D0);
  static const Color textTertiary = Color(0xFF938F99);
  static const Color textDisabled = Color(0xFF595959);

  /// Border & Divider (Dark)
  static const Color border = Color(0xFF49454F);
  static const Color borderLight = Color(0xFF2E2E2E);
  static const Color divider = Color(0xFF383838);

  /// Overlay (Dark)
  static const Color overlay = Color(0xB3000000);
  static const Color scrim = Color(0x80000000);

  // ========================
  // BRAND COLORS (Same as light for recognition)
  // ========================

  /// Primary - Vibrant Orange (same as light for brand recognition)
  static const Color primary = Color(0xFFFF5722);
  static const Color primaryLight = Color(0xFFFF8A50);
  static const Color primaryDark = Color(0xFFE64A19);

  /// Secondary - Cyan (same as light)
  static const Color secondary = Color(0xFF00BCD4);
  static const Color secondaryLight = Color(0xFF4DD0E1);
  static const Color secondaryDark = Color(0xFF0097A7);

  /// Accent - Amber Gold (same as light)
  static const Color accent = Color(0xFFFFC107);
  static const Color accentLight = Color(0xFFFFD54F);
  static const Color accentDark = Color(0xFFFFA000);

  // ========================
  // SEMANTIC COLORS
  // ========================

  /// Success - Xanh lá tươi
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);

  /// Error - Đỏ nổi bật
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFD32F2F);

  /// Warning - Cam vàng
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningDark = Color(0xFFF57C00);

  /// Info - Xanh dương
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoDark = Color(0xFF1976D2);

  // ========================
  // FUNCTIONAL COLORS
  // ========================

  /// Rating/Star colors
  static const Color starFilled = Color(0xFFFFC107);
  static const Color starEmpty = Color(0xFF595959);

  /// Player count badge
  static const Color playersMin = Color(0xFF81C784);
  static const Color playersMax = Color(0xFFFFB74D);

  /// Difficulty
  static const Color difficultyEasy = Color(0xFF81C784);
  static const Color difficultyMedium = Color(0xFFFFB74D);
  static const Color difficultyHard = Color(0xFFFF8A65);
  static const Color difficultyExpert = Color(0xFFEF5350);

  /// Status colors
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF757575);
  static const Color busy = Color(0xFFFFB74D);
  static const Color inGame = Color(0xFF64B5F6);

  /// Card gradients
  static const List<Color> cardGradientOrange = [
    Color(0xFFFF5722),
    Color(0xFFFF8A50),
  ];

  static const List<Color> cardGradientTeal = [
    Color(0xFF00BCD4),
    Color(0xFF4DD0E1),
  ];

  static const List<Color> cardGradientAmber = [
    Color(0xFFFFC107),
    Color(0xFFFFD54F),
  ];

  // ========================
  // BLACK & WHITE
  // ========================
  
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
}
