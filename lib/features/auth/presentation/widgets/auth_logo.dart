import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Logo widget với bold style.
class AuthLogo extends StatelessWidget {
  const AuthLogo({
    super.key,
    this.size = 100,
    this.showAppName = true,
    this.showTagline = true,
  });

  final double size;
  final bool showAppName;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/logos/logoBG.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.games_outlined,
            size: size * 0.7,
            color: AppColors.white,
          ),
        ),
        if (showAppName) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'BoardVerse',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
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

/// Neo-brutalism Mini logo cho app bar.
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
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.huge),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/logos/logoBG.png',
            width: AppIcons.sm + 4,
            height: AppIcons.sm + 4,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.games_outlined,
              color: AppColors.white,
              size: AppIcons.sm,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'BoardVerse',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
