import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Neo-brutalism Design Tokens
/// 
/// Features:
/// - Bold borders (2-3px)
/// - Hard offset shadows (không blur)
/// - Rounded corners nhẹ
/// - Vibrant brand colors
class NeoBrutalismTheme {
  NeoBrutalismTheme._();

  // ========================
  // TOKENS
  // ========================
  
  static const double borderWidth = 2.0;
  static const double borderWidthBold = 3.0;
  
  static const Offset shadowOffset = Offset(3, 3);
  static const Offset shadowOffsetBold = Offset(5, 5);

  // ========================
  // BRAND COLORS
  // ========================
  
  static Color get primary => AppColors.primary;
  static Color get primaryLight => AppColors.primaryLight;
  static Color get primaryDark => AppColors.primaryDark;
  
  static Color get secondary => AppColors.secondary;
  static Color get secondaryLight => AppColors.secondaryLight;
  
  static Color get accent => AppColors.accent;
  static Color get accentLight => AppColors.accentLight;
  
  static Color get success => AppColors.success;
  static Color get error => AppColors.error;
  static Color get warning => AppColors.warning;
  static Color get info => AppColors.info;
  
  // ========================
  // THEME COLORS
  // ========================
  
  /// Light mode
  static const Color bgLight = AppColors.background;
  static const Color surfaceLight = AppColors.surface;
  static const Color surfaceWarm = Color(0xFFFFFBF7);
  static const Color borderLight = AppColors.border;
  
  /// Dark mode
  static const Color bgDark = AppColors.backgroundDark;
  static const Color surfaceDark = AppColors.surfaceDark;
  static const Color surfaceElevatedDark = AppColors.surfaceElevatedDark;
  static const Color borderDark = AppColors.borderDark;
  
  // ========================
  // SHADOWS
  // ========================
  
  /// Light mode - Black shadow với opacity vừa phải
  static List<BoxShadow> lightShadow({bool bold = false, Color? shadowColor}) => [
    BoxShadow(
      color: shadowColor ?? Colors.black.withValues(alpha: 0.5),
      offset: bold ? shadowOffsetBold : shadowOffset,
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];
  
  /// Dark mode - Subtle dark shadow
  static List<BoxShadow> darkShadow({bool bold = false, Color? shadowColor}) => [
    BoxShadow(
      color: shadowColor ?? Colors.black.withValues(alpha: 0.4),
      offset: bold ? const Offset(3, 3) : const Offset(2, 2),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  // ========================
  // DECORATIONS
  // ========================
  
  /// Light mode decoration
  static BoxDecoration brutalBox({
    Color? backgroundColor,
    Color borderColor = AppColors.border,
    bool bold = false,
    double borderRadius = 16,
    Color? shadowColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? AppColors.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor,
        width: bold ? borderWidthBold : borderWidth,
      ),
      boxShadow: lightShadow(bold: bold, shadowColor: shadowColor),
    );
  }
  
  /// Dark mode decoration
  static BoxDecoration brutalBoxDark({
    Color? backgroundColor,
    Color borderColor = borderDark,
    bool bold = false,
    double borderRadius = 16,
    Color? shadowColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? surfaceDark,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor,
        width: bold ? borderWidthBold : borderWidth,
      ),
      boxShadow: darkShadow(bold: bold, shadowColor: shadowColor),
    );
  }

  // ========================
  // CONTEXT HELPERS
  // ========================
  
  static Color surfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? surfaceDark 
        : surfaceLight;
  }
  
  static Color backgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? bgDark 
        : bgLight;
  }
  
  static Color textColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? AppColors.textPrimaryDark 
        : AppColors.textPrimary;
  }
  
  static Color textSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? AppColors.textSecondaryDark 
        : AppColors.textSecondary;
  }
  
  /// Main auto decoration - tự chọn light/dark theo context
  static BoxDecoration autoBox(
    BuildContext context, {
    Color? backgroundColor,
    Color? borderColor,
    bool bold = false,
    double borderRadius = 16,
    Color? shadowColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return isDark
        ? brutalBoxDark(
            backgroundColor: backgroundColor,
            borderColor: borderColor ?? borderDark,
            bold: bold,
            borderRadius: borderRadius,
            shadowColor: shadowColor,
          )
        : brutalBox(
            backgroundColor: backgroundColor ?? AppColors.surface,
            borderColor: borderColor ?? AppColors.border,
            bold: bold,
            borderRadius: borderRadius,
            shadowColor: shadowColor,
          );
  }
}
