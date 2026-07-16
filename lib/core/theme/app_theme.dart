import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_colors_dark.dart';
import 'app_icons.dart';
import 'app_radius.dart';
import 'app_typography.dart';

/// Main Theme Configuration
/// Định nghĩa theme cho toàn bộ ứng dụng (Light & Dark mode)
class AppTheme {
  AppTheme._();

  // ========================
  // APP NAME & VERSION
  // ========================

  static const String appName = 'BoardVerse';

  // ========================
  // LIGHT THEME
  // ========================

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        secondaryColor: AppColors.secondary,
        accentColor: AppColors.accent,
        backgroundColor: AppColors.background,
        surfaceColor: AppColors.surface,
        textPrimaryColor: AppColors.textPrimary,
        textSecondaryColor: AppColors.textSecondary,
        borderColor: AppColors.border,
        dividerColor: AppColors.divider,
        errorColor: AppColors.error,
        successColor: AppColors.success,
        warningColor: AppColors.warning,
        infoColor: AppColors.info,
      );

  // ========================
  // DARK THEME
  // ========================

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        primaryColor: AppColorsDark.primary,
        secondaryColor: AppColorsDark.secondary,
        accentColor: AppColorsDark.accent,
        backgroundColor: AppColorsDark.background,
        surfaceColor: AppColorsDark.surface,
        textPrimaryColor: AppColorsDark.textPrimary,
        textSecondaryColor: AppColorsDark.textSecondary,
        borderColor: AppColorsDark.border,
        dividerColor: AppColorsDark.divider,
        errorColor: AppColorsDark.error,
        successColor: AppColorsDark.success,
        warningColor: AppColorsDark.warning,
        infoColor: AppColorsDark.info,
      );

  // ========================
  // THEME BUILDER
  // ========================

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color secondaryColor,
    required Color accentColor,
    required Color backgroundColor,
    required Color surfaceColor,
    required Color textPrimaryColor,
    required Color textSecondaryColor,
    required Color borderColor,
    required Color dividerColor,
    required Color errorColor,
    required Color successColor,
    required Color warningColor,
    required Color infoColor,
  }) {
    final isDark = brightness == Brightness.dark;

    // Get text theme based on brightness
    final textTheme = isDark
        ? AppTypography.textThemeDark
        : AppTypography.textThemeLight;

    // Create color scheme
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: primaryColor.withValues(alpha: 0.1),
      onPrimaryContainer: primaryColor,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: secondaryColor.withValues(alpha: 0.1),
      onSecondaryContainer: secondaryColor,
      tertiary: accentColor,
      onTertiary: Colors.black,
      tertiaryContainer: accentColor.withValues(alpha: 0.1),
      onTertiaryContainer: accentColor,
      error: errorColor,
      onError: Colors.white,
      errorContainer: errorColor.withValues(alpha: 0.1),
      onErrorContainer: errorColor,
      surface: surfaceColor,
      onSurface: textPrimaryColor,
      surfaceContainerHighest:
          isDark ? AppColorsDark.surfaceVariant : AppColors.surfaceVariant,
      onSurfaceVariant: textSecondaryColor,
      outline: borderColor,
      outlineVariant: dividerColor,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? AppColors.textPrimary : AppColorsDark.surface,
      onInverseSurface:
          isDark ? AppColors.textPrimary : AppColorsDark.textPrimary,
      inversePrimary: isDark ? AppColors.primaryDark : AppColorsDark.primary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.beVietnamProTextTheme(textTheme),

      // ========================
      // FONT FAMILY
      // ========================
      fontFamily: 'Be Vietnam Pro',

      // ========================
      // APP BAR THEME
      // ========================
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        backgroundColor: backgroundColor,
        foregroundColor: textPrimaryColor,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: textPrimaryColor,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: textPrimaryColor,
          size: AppIcons.lg,
        ),
      ),

      // ========================
      // BOTTOM NAVIGATION BAR
      // ========================
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelSmall,
        showUnselectedLabels: true,
      ),

      // ========================
      // NAVIGATION BAR (Material 3)
      // ========================
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withValues(alpha: 0.15),
        elevation: 0,
        height: 80,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(
              color: primaryColor,
              fontWeight: FontWeight.w600,
            );
          }
          return textTheme.labelSmall?.copyWith(
            color: textSecondaryColor,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryColor, size: AppIcons.md);
          }
          return IconThemeData(color: textSecondaryColor, size: AppIcons.md);
        }),
      ),

      // ========================
      // CARD THEME
      // ========================
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        ),
        margin: EdgeInsets.zero,
      ),

      // ========================
      // ELEVATED BUTTON
      // ========================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusXs),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ========================
      // FILLED BUTTON
      // ========================
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusXs),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ========================
      // OUTLINED BUTTON
      // ========================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusXs),
          ),
          side: BorderSide(color: borderColor),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ========================
      // TEXT BUTTON
      // ========================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusXs),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ========================
      // ICON BUTTON
      // ========================
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusXs),
          ),
        ),
      ),

      // ========================
      // FLOATING ACTION BUTTON
      // ========================
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        highlightElevation: 8,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        ),
      ),

      // ========================
      // INPUT DECORATION
      // ========================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? AppColorsDark.surfaceVariant : AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusXs),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusXs),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusXs),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusXs),
          borderSide: BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusXs),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: textSecondaryColor,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: textSecondaryColor,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: errorColor,
        ),
      ),

      // ========================
      // CHIP THEME
      // ========================
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: primaryColor.withValues(alpha: 0.15),
        disabledColor: surfaceColor.withValues(alpha: 0.5),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: primaryColor,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          side: BorderSide(color: borderColor),
        ),
      ),

      // ========================
      // DIALOG THEME
      // ========================
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: textPrimaryColor,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: textSecondaryColor,
        ),
      ),

      // ========================
      // BOTTOM SHEET THEME
      // ========================
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        dragHandleColor: textSecondaryColor.withValues(alpha: 0.4),
        dragHandleSize: const Size(40, 4),
        showDragHandle: true,
      ),

      // ========================
      // SNACK BAR THEME
      // ========================
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDark ? AppColorsDark.surfaceElevated : AppColors.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColorsDark.textPrimary : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusSm),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ========================
      // DIVIDER THEME
      // ========================
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // ========================
      // LIST TILE THEME
      // ========================
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusXs),
        ),
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          color: textPrimaryColor,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: textSecondaryColor,
        ),
      ),

      // ========================
      // TAB BAR THEME
      // ========================
      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondaryColor,
        indicatorColor: primaryColor,
        labelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelLarge,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
      ),

      // ========================
      // PROGRESS INDICATOR THEME
      // ========================
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: primaryColor.withValues(alpha: 0.15),
        circularTrackColor: primaryColor.withValues(alpha: 0.15),
      ),

      // ========================
      // SWITCH THEME
      // ========================
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return textSecondaryColor;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: 0.5);
          }
          return textSecondaryColor.withValues(alpha: 0.3);
        }),
      ),

      // ========================
      // CHECKBOX THEME
      // ========================
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: BorderSide(color: borderColor, width: 2),
      ),

      // ========================
      // RADIO THEME
      // ========================
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return textSecondaryColor;
        }),
      ),

      // ========================
      // TOOLTIP THEME
      // ========================
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark
              ? AppColorsDark.surfaceElevated
              : AppColors.textPrimary,
          borderRadius: BorderRadius.circular(AppRadius.radiusXs),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: isDark ? AppColorsDark.textPrimary : Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // ========================
      // SCAFFOLD
      // ========================
      scaffoldBackgroundColor: backgroundColor,
    );
  }
}
