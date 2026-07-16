import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_colors_dark.dart';

/// Typography System - Định nghĩa các kiểu chữ theo Material Design 3
/// Font family: Be Vietnam Pro (tối ưu cho tiếng Việt)
class AppTypography {
  AppTypography._();

  // ========================
  // TEXT THEME - LIGHT
  // ========================

  static TextTheme get textThemeLight => _buildTextTheme(
        textColor: AppColors.textPrimary,
        secondaryColor: AppColors.textSecondary,
      );

  // ========================
  // TEXT THEME - DARK
  // ========================

  static TextTheme get textThemeDark => _buildTextTheme(
        textColor: Colors.white,
        secondaryColor: AppColorsDark.textSecondary,
      );

  static TextTheme _buildTextTheme({
    required Color textColor,
    required Color secondaryColor,
  }) {
    final baseTextTheme = GoogleFonts.beVietnamProTextTheme();

    return baseTextTheme.copyWith(
      // ========================
      // DISPLAY - Dùng cho tiêu đề lớn, hero text
      // ========================
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: textColor,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),

      // ========================
      // HEADLINE - Dùng cho tiêu đề section
      // ========================
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),

      // ========================
      // TITLE - Dùng cho title của cards, list items
      // ========================
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: textColor,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: textColor,
      ),

      // ========================
      // BODY - Dùng cho nội dung chính
      // ========================
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: textColor,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: textColor,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: secondaryColor,
      ),

      // ========================
      // LABEL - Dùng cho buttons, chips, tags
      // ========================
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: textColor,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: textColor,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: secondaryColor,
      ),
    );
  }

  // ========================
  // HELPER METHODS
  // ========================

  /// Lấy style cho price text
  static TextStyle priceStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        );
  }

  /// Lấy style cho badge text
  static TextStyle badgeStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall!.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        );
  }

  /// Lấy style cho caption
  static TextStyle captionStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: AppColors.textSecondary,
        );
  }
}
