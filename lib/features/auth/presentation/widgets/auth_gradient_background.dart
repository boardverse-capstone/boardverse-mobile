import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';

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
  return Stack(
    fit: StackFit.expand,
    children: [
      // Background gradient that fills the *entire* screen, including
      // any space below the scrollable content (e.g. when the page
      // is shorter than the viewport or the on-screen keyboard is
      // open and reveals the area underneath the scroll view).
      //
      // Without this, the gradient only stretched to the size of the
      // [SingleChildScrollView] child, leaving a white strip at the
      // bottom of the screen on shorter pages.
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: end,
            colors: colors,
            stops: stops,
          ),
        ),
      ),
      child,
    ],
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

  /// Setup-profile gradient — dùng cho màn hình buộc player điền
  /// thông tin cá nhân cơ bản sau khi đăng ký / login. Tone cyan/cool
  /// để phân biệt với login (orange) và register (cyan-đen), tránh
  /// nhầm lẫn với màn hình auth.
  static List<Color> setupGradient(BuildContext context) {
    return const [
      AppColors.primary,
      AppColors.primaryDark,
      AppColors.backgroundDark,
    ];
  }

  /// Stops cho login/register.
  static List<double>? get standardStops => const [0.0, 0.4, 1.0];
}
