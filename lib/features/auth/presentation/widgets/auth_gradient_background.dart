import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Gradient background widget dùng chung cho các auth pages
class AuthGradientBackground extends StatelessWidget {
  final List<Color> colors;
  final List<double>? stops;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final Widget child;

  const AuthGradientBackground({
    super.key,
    required this.colors,
    this.stops,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
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

  /// Login page gradient - Deep Orange
  static List<Color> get loginGradient => const [
        AppColors.primary,
        AppColors.primaryDark,
        Color(0xFF1A1A1A),
      ];

  /// Register page gradient - Teal
  static List<Color> get registerGradient => const [
        AppColors.secondary,
        AppColors.secondaryDark,
        Color(0xFF1A1A1A),
      ];

  /// Verify email gradient - Amber/Orange
  static List<Color> get verifyGradient => const [
        AppColors.accent,
        AppColors.primary,
        AppColors.primaryDark,
      ];

  /// Stops cho login/register
  static List<double>? get standardStops => const [0.0, 0.4, 1.0];
}
