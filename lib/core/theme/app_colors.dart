import 'package:flutter/material.dart';

/// Brand Colors - Sử dụng cho logo, primary buttons, headers
/// Mô tả design system: https://github.com/orgs/boardverse/repo/design_system.md
class AppColors {
  AppColors._();

  // ========================
  // BRAND COLORS
  // ========================

  /// Primary - Deep Orange (Game energy)
  static const Color primary = Color(0xFFE65100);
  static const Color primaryLight = Color(0xFFFF9E40);
  static const Color primaryDark = Color(0xFFAC1900);

  /// Secondary - Teal (Cafe warmth, trust)
  static const Color secondary = Color(0xFF00897B);
  static const Color secondaryLight = Color(0xFF4EBAAA);
  static const Color secondaryDark = Color(0xFF005B4F);

  /// Accent - Amber (Highlights, rewards, points)
  static const Color accent = Color(0xFFFFD600);
  static const Color accentLight = Color(0xFFFFFF52);
  static const Color accentDark = Color(0xFFC7A500);

  /// Neutral - Black & White
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // ========================
  // SEMANTIC COLORS
  // ========================

  /// Success - Thành công, xác nhận
  static const Color success = Color(0xFF00C853);
  static const Color successLight = Color(0xFF5EFF82);
  static const Color successDark = Color(0xFF009C32);

  /// Error - Lỗi, hủy, cảnh báo nghiêm trọng
  static const Color error = Color(0xFFFF1744);
  static const Color errorLight = Color(0xFFFF616F);
  static const Color errorDark = Color(0xFFC50E29);

  /// Warning - Cảnh báo, chờ xử lý
  static const Color warning = Color(0xFFFFAB00);
  static const Color warningLight = Color(0xFFFFDD4B);
  static const Color warningDark = Color(0xFFC67C00);

  /// Info - Thông tin, tips
  static const Color info = Color(0xFF2979FF);
  static const Color infoLight = Color(0xFF75A7FF);
  static const Color infoDark = Color(0xFF005ECB);

  // ========================
  // LIGHT THEME - NEUTRALS
  // ========================

  /// Background colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color surfaceVariant = Color(0xFFEEEEEE);

  /// Dark mode surfaces (for navigation bar)
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceElevatedDark = Color(0xFF2D2D2D);
  static const Color textSecondaryDark = Color(0xFFB3B3B3);

  /// Text colors (Light mode)
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textDisabled = Color(0xFFBDBDBD);

  /// Border & Divider
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);
  static const Color divider = Color(0xFFEEEEEE);

  /// Overlay
  static const Color overlay = Color(0x80000000);
  static const Color scrim = Color(0x52000000);

  // ========================
  // FUNCTIONAL COLORS
  // ========================

  /// Rating/Star colors
  static const Color starFilled = Color(0xFFFFD600);
  static const Color starEmpty = Color(0xFFE0E0E0);

  /// Player count badge
  static const Color playersMin = Color(0xFF4CAF50);
  static const Color playersMax = Color(0xFFFF9800);

  /// Rating difficulty
  static const Color difficultyEasy = Color(0xFF4CAF50);
  static const Color difficultyMedium = Color(0xFFFF9800);
  static const Color difficultyHard = Color(0xFFFF5722);
  static const Color difficultyExpert = Color(0xFFF44336);

  /// Status colors
  static const Color online = Color(0xFF00C853);
  static const Color offline = Color(0xFF9E9E9E);
  static const Color busy = Color(0xFFFF9800);
  static const Color inGame = Color(0xFF2196F3);

  /// Card gradients
  static const List<Color> cardGradientOrange = [
    Color(0xFFE65100),
    Color(0xFFFF9E40),
  ];

  static const List<Color> cardGradientTeal = [
    Color(0xFF00897B),
    Color(0xFF4EBAAA),
  ];

  static const List<Color> cardGradientAmber = [
    Color(0xFFFFD600),
    Color(0xFFFFAB00),
  ];
}
