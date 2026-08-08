import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';

/// Gradient background dùng chung cho các auth pages.
/// 
/// Neo-brutalism style - vibrant gradients.
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

  /// Login page gradient — Orange → đen.
  static List<Color> loginGradient(BuildContext context) {
    return const [
      AppColors.primary,
      AppColors.primaryDark,
      AppColors.background,
    ];
  }

  /// Register page gradient — Cyan → đen.
  static List<Color> registerGradient(BuildContext context) {
    return const [
      AppColors.secondary,
      AppColors.secondaryDark,
      AppColors.background,
    ];
  }

  /// Verify email gradient — Amber/Orange.
  static List<Color> verifyGradient(BuildContext context) {
    return const [
      AppColors.accent,
      AppColors.primary,
      AppColors.primaryDark,
    ];
  }

  /// Stops cho login/register.
  static List<double>? get standardStops => const [0.0, 0.4, 1.0];
}
