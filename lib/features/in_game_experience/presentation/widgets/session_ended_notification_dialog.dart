import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_spacing.dart';

/// Dialog notification khi phiên chơi kết thúc — neo-brutalism style.
class SessionEndedNotificationDialog extends StatelessWidget {
  final Duration totalDuration;
  final VoidCallback onRateNow;
  final VoidCallback onVoteNoShow;
  final VoidCallback onLater;

  const SessionEndedNotificationDialog({
    super.key,
    required this.totalDuration,
    required this.onRateNow,
    required this.onVoteNoShow,
    required this.onLater,
  });

  static Future<void> show({
    required BuildContext context,
    required Duration totalDuration,
    required VoidCallback onRateNow,
    required VoidCallback onVoteNoShow,
    required VoidCallback onLater,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SessionEndedNotificationDialog(
        totalDuration: totalDuration,
        onRateNow: onRateNow,
        onVoteNoShow: onVoteNoShow,
        onLater: onLater,
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.border,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.4),
              blurRadius: 0,
              offset: const Offset(6, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon badge
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border,
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.celebration,
                size: 48,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Phiên chơi đã kết thúc!',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: AppColors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Cảm ơn bạn đã tham gia!',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Duration pill
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.border,
                  width: 2,
                ),
              ),
              child: Text(
                'Thời gian: ${_formatDuration(totalDuration)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: AppColors.white,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Hãy đánh giá đồng đội và bình chọn người vắng mặt (no-show) để giúp cộng đồng tốt hơn.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            // Primary action - Đánh giá ngay
            _NeoFullButton(
              label: 'Đánh giá ngay',
              icon: Icons.star_outline,
              color: AppColors.primary,
              onPressed: () {
                Navigator.pop(context);
                onRateNow();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            // Secondary action - Bình chọn no-show
            _NeoOutlineButton(
              label: 'Bình chọn no-show',
              icon: Icons.how_to_vote_outlined,
              color: AppColors.warning,
              onPressed: () {
                Navigator.pop(context);
                onVoteNoShow();
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            // Tertiary - Để sau
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onLater();
              },
              child: const Text(
                'Để sau',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Neo-brutalism filled button used in dialogs.
class _NeoFullButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _NeoFullButton({
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
            border: Border.all(
              color: AppColors.border,
              width: 2.5,
            ),
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
              Icon(icon, color: AppColors.white, size: 18),
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

/// Neo-brutalism outline button used in dialogs.
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
              Icon(icon, color: color, size: 18),
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