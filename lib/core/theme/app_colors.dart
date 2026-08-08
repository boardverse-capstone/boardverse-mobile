import 'package:flutter/material.dart';

/// Brand Colors - Vibrant cho cả Light & Dark Mode
/// 
/// Design System:
/// - LIGHT MODE: Sáng rực, contrast cao
/// - DARK MODE: Đậm đà, không bị chói
class AppColors {
  AppColors._();

  // ========================
  // PRIMARY - CAM (Game Energy)
  // ========================
  
  /// Primary - Vibrant Orange (LIGHT: sáng, DARK: đậm vừa)
  static const Color primary = Color(0xFFFF5722);      // Deep Orange sống động
  static const Color primaryLight = Color(0xFFFF8A50);  // Cam nhạt
  static const Color primaryDark = Color(0xFFE64A19);   // Cam đậm

  // ========================
  // SECONDARY - XANH DƯƠNG (Trust & Cafe)
  // ========================
  
  /// Secondary - Deep Cyan (LIGHT: sáng, DARK: teal đậm)
  static const Color secondary = Color(0xFF00BCD4);   // Cyan sống động
  static const Color secondaryLight = Color(0xFF4DD0E1);
  static const Color secondaryDark = Color(0xFF0097A7);

  // ========================
  // ACCENT - VÀNG (Highlights)
  // ========================
  
  /// Accent - Amber Gold (LIGHT: rực, DARK: vàng đậm)
  static const Color accent = Color(0xFFFFC107);        // Amber rực
  static const Color accentLight = Color(0xFFFFD54F);
  static const Color accentDark = Color(0xFFFFA000);

  // ========================
  // BLACK & WHITE
  // ========================
  
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // ========================
  // GRADIENTS
  // ========================

  /// Gradient Primary - Cam
  static const List<Color> cardGradientOrange = [
    Color(0xFFFF5722),
    Color(0xFFFF8A50),
  ];

  /// Gradient Secondary - Teal
  static const List<Color> cardGradientTeal = [
    Color(0xFF00BCD4),
    Color(0xFF4DD0E1),
  ];

  /// Gradient Accent - Vàng
  static const List<Color> cardGradientAmber = [
    Color(0xFFFFC107),
    Color(0xFFFFD54F),
  ];

  // ========================
  // SEMANTIC - SỐNG ĐỘNG
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
  // LIGHT THEME - SÁNG VÀ TƯƠI
  // ========================

  /// Background - Trắng ấm
  static const Color background = Color(0xFFFFFBFE);    // Material 3 white
  static const Color surface = Color(0xFFFFFFFF);       // Trắng tinh
  static const Color surfaceVariant = Color(0xFFF5F5F5); // Grey nhẹ

  /// Text (Light mode)
  static const Color textPrimary = Color(0xFF1C1B1F);
  static const Color textSecondary = Color(0xFF49454F);
  static const Color textTertiary = Color(0xFF79747E);
  static const Color textDisabled = Color(0xFFCAC4D0);

  // ========================
  // DARK THEME - ĐẬM VÀ HÀI HÒA
  // ========================

  /// Dark surfaces - Không quá đen, có depth
  static const Color surfaceDark = Color(0xFF1E1E1E);      // Dark grey
  static const Color surfaceElevatedDark = Color(0xFF2D2D2D);
  static const Color surfaceContainerDark = Color(0xFF252525);
  static const Color backgroundDark = Color(0xFF121212);   // Nền đen mềm

  /// Text (Dark mode)
  static const Color textPrimaryDark = Color(0xFFE6E1E5);
  static const Color textSecondaryDark = Color(0xFFCAC4D0);
  static const Color textTertiaryDark = Color(0xFF938F99);

  // ========================
  // BORDERS & DIVIDERS
  // ========================
  
  /// Light borders
  static const Color border = Color(0xFFCAC4D0);
  static const Color borderLight = Color(0xFFE0E0E0);
  
  /// Dark borders
  static const Color borderDark = Color(0xFF49454F);
  static const Color borderDarkAccent = Color(0xFF625B71);
  
  /// Divider
  static const Color divider = Color(0xFFE7E0EC);

  // ========================
  // FUNCTIONAL COLORS
  // ========================

  /// Star rating
  static const Color starFilled = Color(0xFFFFC107);
  static const Color starEmpty = Color(0xFFE0E0E0);

  /// Player count
  static const Color playersMin = Color(0xFF4CAF50);
  static const Color playersMax = Color(0xFFFF9800);

  /// Difficulty levels
  static const Color difficultyEasy = Color(0xFF4CAF50);
  static const Color difficultyMedium = Color(0xFFFF9800);
  static const Color difficultyHard = Color(0xFFFF5722);
  static const Color difficultyExpert = Color(0xFFF44336);

  /// Status indicators
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF9E9E9E);
  static const Color busy = Color(0xFFFF9800);
  static const Color inGame = Color(0xFF2196F3);

  // ========================
  // GRADIENTS
  // ========================

  static const List<Color> gradientPrimary = [
    Color(0xFFFF5722),
    Color(0xFFFF8A50),
  ];

  static const List<Color> gradientSecondary = [
    Color(0xFF00BCD4),
    Color(0xFF4DD0E1),
  ];

  static const List<Color> gradientAccent = [
    Color(0xFFFFC107),
    Color(0xFFFFD54F),
  ];

  // ========================
  // ELO/RANK COLORS
  // ========================

  static const Color eloBronze = Color(0xFFCD7F32);
  static const Color eloSilver = Color(0xFFC0C0C0);
  static const Color eloGold = Color(0xFFFFD700);
  static const Color eloPlatinum = Color(0xFFE5E4E2);
  static const Color eloDiamond = Color(0xFFB9F2FF);

  static Color getMedalColor(int rank) {
    return switch (rank) {
      1 => eloGold,
      2 => eloSilver,
      3 => eloBronze,
      _ => textSecondary,
    };
  }
}
