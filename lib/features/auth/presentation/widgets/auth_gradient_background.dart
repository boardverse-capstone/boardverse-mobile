import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_colors_dark.dart';

/// Gradient background dùng chung cho các auth pages.
///
/// Hỗ trợ light/dark mode tự động.
class AuthGradientBackground extends StatelessWidget {
  const AuthGradientBackground({
    super.key,
    required this.colors,
    this.stops,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    required this.child,
  });

  final List<Color> colors;
  final List<double>? stops;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors,
          stops: stops,
        ),
      ),
      child: child,
    );
  }

  /// Login page gradient — Deep Orange → đen.
  static List<Color> loginGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const [
        AppColorsDark.primary,
        AppColorsDark.primaryDark,
        AppColorsDark.background,
      ];
    }
    return const [
      AppColors.primary,
      AppColors.primaryDark,
      AppColors.background,
    ];
  }

  /// Register page gradient — Teal → đen.
  static List<Color> registerGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const [
        AppColorsDark.secondary,
        AppColorsDark.secondaryDark,
        AppColorsDark.background,
      ];
    }
    return const [
      AppColors.secondary,
      AppColors.secondaryDark,
      AppColors.background,
    ];
  }

  /// Verify email gradient — Amber/Orange.
  static List<Color> verifyGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const [
        AppColorsDark.accent,
        AppColorsDark.accentDark,
        AppColorsDark.primaryDark,
      ];
    }
    return const [
      AppColors.accent,
      AppColors.primary,
      AppColors.primaryDark,
    ];
  }

  /// Stops cho login/register.
  static List<double>? get standardStops => const [0.0, 0.4, 1.0];
}
