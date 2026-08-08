import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import '../../domain/entities/rating_entity.dart';

/// Neo-brutalism Elo result display.
class EloResultDisplayWidget extends StatelessWidget {
  final EloResult eloResult;
  final VoidCallback? onViewLeaderboard;
  final VoidCallback? onComplete;

  const EloResultDisplayWidget({
    super.key,
    required this.eloResult,
    this.onViewLeaderboard,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = eloResult.eloChange >= 0;
    final changeColor =
        isPositive ? AppColors.success : AppColors.error;

    final resultText = switch (eloResult.result) {
      MatchResult.win => 'Thắng',
      MatchResult.lose => 'Thua',
      MatchResult.draw => 'Hòa',
    };
    final resultIcon = switch (eloResult.result) {
      MatchResult.win => Icons.emoji_events_outlined,
      MatchResult.lose => Icons.sentiment_dissatisfied_outlined,
      MatchResult.draw => Icons.handshake_outlined,
    };
    final resultBg = switch (eloResult.result) {
      MatchResult.win => AppColors.warning,
      MatchResult.lose => AppColors.error,
      MatchResult.draw => AppColors.info,
    };
    final resultFg = AppColors.white;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(5, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Result badge
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: resultBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.4),
                  blurRadius: 0,
                  offset: const Offset(4, 4),
                ),
              ],
            ),
            child: Icon(resultIcon, size: 48, color: resultFg),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            resultText,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 28,
              color: resultBg,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Điểm Elo của bạn biến động như sau:',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Elo change container
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: changeColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.4),
                  blurRadius: 0,
                  offset: const Offset(4, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'ĐIỂM ELO BIẾN ĐỘNG',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.black,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isPositive
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: changeColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${eloResult.eloChange.abs()}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 36,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Before → After row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.black,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${eloResult.currentElo}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(
                        AppIcons.forward,
                        size: 18,
                        color: AppColors.black,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${eloResult.newElo}',
                        style: const TextStyle(
                          color: AppColors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          if (onViewLeaderboard != null) ...[
            _NeoOutlineButton(
              label: 'Xem Bảng xếp hạng',
              icon: AppIcons.rating,
              color: AppColors.warning,
              onPressed: onViewLeaderboard!,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (onComplete != null)
            _NeoFilledButton(
              label: 'Hoàn tất',
              icon: AppIcons.check,
              color: AppColors.primary,
              onPressed: onComplete!,
            ),
        ],
      ),
    );
  }
}

/// Neo-brutalism filled button.
class _NeoFilledButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _NeoFilledButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.white),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Neo-brutalism outline button.
class _NeoOutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _NeoOutlineButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}