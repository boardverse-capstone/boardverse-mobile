import 'package:flutter/material.dart';

/// Dark Theme Colors - Màu sắc cho chế độ Dark Mode
/// Dựa trên design system: https://github.com/orgs/boardverse/repo/design_system.md
class AppColorsDark {
  AppColorsDark._();

  // ========================
  // DARK THEME - NEUTRALS
  // ========================

  /// Background colors (Dark)
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFF2C2C2C);

  /// Elevated surfaces (cards, dialogs)
  static const Color surfaceElevated = Color(0xFF2D2D2D);
  static const Color surfaceElevatedHigh = Color(0xFF383838);

  /// Text colors (Dark mode)
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textTertiary = Color(0xFF808080);
  static const Color textDisabled = Color(0xFF595959);

  /// Border & Divider (Dark)
  static const Color border = Color(0xFF404040);
  static const Color borderLight = Color(0xFF2E2E2E);
  static const Color divider = Color(0xFF383838);

  /// Overlay (Dark)
  static const Color overlay = Color(0xB3000000);
  static const Color scrim = Color(0x80000000);

  // ========================
  // DARK THEME - BRAND COLORS (adjusted for dark)
  // ========================

  /// Primary - Sáng hơn một chút so với light mode
  static const Color primary = Color(0xFFFF9E40);
  static const Color primaryLight = Color(0xFFFFBB66);
  static const Color primaryDark = Color(0xFFE65100);

  /// Secondary
  static const Color secondary = Color(0xFF4EBAAA);
  static const Color secondaryLight = Color(0xFF80CDBB);
  static const Color secondaryDark = Color(0xFF00897B);

  /// Accent
  static const Color accent = Color(0xFFFFD600);
  static const Color accentLight = Color(0xFFFFFF52);
  static const Color accentDark = Color(0xFFC7A500);

  // ========================
  // DARK THEME - SEMANTIC COLORS (adjusted for dark)
  // ========================

  /// Success - Thành công
  static const Color success = Color(0xFF69F0AE);
  static const Color successLight = Color(0xFFA7FFEB);
  static const Color successDark = Color(0xFF00C853);

  /// Error - Lỗi
  static const Color error = Color(0xFFFF8A80);
  static const Color errorLight = Color(0xFFFFB4AB);
  static const Color errorDark = Color(0xFFFF5252);

  /// Warning - Cảnh báo
  static const Color warning = Color(0xFFFFD740);
  static const Color warningLight = Color(0xFFFFE57F);
  static const Color warningDark = Color(0xFFFFAB40);

  /// Info - Thông tin
  static const Color info = Color(0xFF82B1FF);
  static const Color infoLight = Color(0xFFB6E3FF);
  static const Color infoDark = Color(0xFF448AFF);

  // ========================
  // DARK THEME - FUNCTIONAL COLORS
  // ========================

  /// Rating/Star colors (Dark)
  static const Color starFilled = Color(0xFFFFD600);
  static const Color starEmpty = Color(0xFF595959);

  /// Player count badge
  static const Color playersMin = Color(0xFF81C784);
  static const Color playersMax = Color(0xFFFFB74D);

  /// Rating difficulty
  static const Color difficultyEasy = Color(0xFF81C784);
  static const Color difficultyMedium = Color(0xFFFFB74D);
  static const Color difficultyHard = Color(0xFFFF8A65);
  static const Color difficultyExpert = Color(0xFFEF5350);

  /// Status colors (Dark)
  static const Color online = Color(0xFF69F0AE);
  static const Color offline = Color(0xFF757575);
  static const Color busy = Color(0xFFFFB74D);
  static const Color inGame = Color(0xFF64B5F6);

  /// Card gradients (Dark)
  static const List<Color> cardGradientOrange = [
    Color(0xFFFF9E40),
    Color(0xFFFFBB66),
  ];

  static const List<Color> cardGradientTeal = [
    Color(0xFF4EBAAA),
    Color(0xFF80CDBB),
  ];

  static const List<Color> cardGradientAmber = [
    Color(0xFFFFD600),
    Color(0xFFFFE57F),
  ];
}
