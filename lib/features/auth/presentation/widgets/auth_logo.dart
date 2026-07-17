import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';

/// Logo widget với glow effect cho auth pages
class AuthLogo extends StatelessWidget {
  final double size;
  final bool showAppName;
  final bool showTagline;

  const AuthLogo({
    super.key,
    this.size = 100,
    this.showAppName = true,
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo Icon with glow effect
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.cardGradientOrange,
            ),
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            Icons.games_outlined,
            size: size * 0.48,
            color: AppColors.white,
          ),
        ),

        if (showAppName) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'BoardVerse',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],

        if (showTagline) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Kết nối yêu board game',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.white.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

/// Mini logo cho app bar
class AuthLogoMini extends StatelessWidget {
  const AuthLogoMini({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.huge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.games_outlined,
            color: AppColors.white,
            size: AppIcons.sm,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'BoardVerse',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
