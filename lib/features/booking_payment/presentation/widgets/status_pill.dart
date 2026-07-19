import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Status variants for [StatusPill] — kept simple, semantic và dễ dùng.
enum StatusPillVariant {
  confirmed,
  checkedIn,
  pendingDeposit,
  cancelledByPlayer,
  cancelledByCafe,
  expired,
  upcoming,
  completed,
  cancelled,
  noShow,
  success,
  warning,
  info,
  neutral,
}

/// Pill nhãn trạng thái dùng chung cho các card danh sách & detail.
///
/// Áp dụng design tokens: dùng [AppColors], [AppRadius], [AppSpacing],
/// [AppTypography] — không hard-code bất kỳ giá trị nào.
class StatusPill extends StatelessWidget {
  final String label;
  final StatusPillVariant variant;
  final IconData? icon;
  final bool dense;

  const StatusPill({
    super.key,
    required this.label,
    required this.variant,
    this.icon,
    this.dense = false,
  });

  Color _resolveForeground(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final c = _resolveBaseColor();
    // For darker backgrounds in light mode, darken color further.
    if (isDark) return c;
    return HSLColor.fromColor(c)
        .withLightness((HSLColor.fromColor(c).lightness - 0.05).clamp(0.0, 1.0))
        .toColor();
  }

  Color _resolveBaseColor() {
    switch (variant) {
      case StatusPillVariant.confirmed:
      case StatusPillVariant.upcoming:
      case StatusPillVariant.info:
        return AppColors.info;
      case StatusPillVariant.checkedIn:
      case StatusPillVariant.completed:
      case StatusPillVariant.success:
        return AppColors.success;
      case StatusPillVariant.pendingDeposit:
      case StatusPillVariant.warning:
        return AppColors.warning;
      case StatusPillVariant.cancelledByPlayer:
      case StatusPillVariant.cancelledByCafe:
      case StatusPillVariant.cancelled:
      case StatusPillVariant.neutral:
        return AppColors.textSecondary;
      case StatusPillVariant.expired:
      case StatusPillVariant.noShow:
        return AppColors.error;
    }
  }

  IconData _resolveDefaultIcon() {
    switch (variant) {
      case StatusPillVariant.confirmed:
      case StatusPillVariant.upcoming:
        return Icons.check_circle_rounded;
      case StatusPillVariant.checkedIn:
        return Icons.sports_esports_rounded;
      case StatusPillVariant.completed:
        return Icons.task_alt_rounded;
      case StatusPillVariant.pendingDeposit:
        return Icons.hourglass_top_rounded;
      case StatusPillVariant.warning:
        return Icons.warning_amber_rounded;
      case StatusPillVariant.cancelledByPlayer:
      case StatusPillVariant.cancelledByCafe:
      case StatusPillVariant.cancelled:
        return Icons.cancel_rounded;
      case StatusPillVariant.expired:
        return Icons.timer_off_rounded;
      case StatusPillVariant.noShow:
        return Icons.person_off_rounded;
      case StatusPillVariant.success:
        return Icons.check_circle_rounded;
      case StatusPillVariant.info:
        return Icons.info_rounded;
      case StatusPillVariant.neutral:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = _resolveBaseColor();
    final foreground = _resolveForeground(theme.brightness);
    final iconData = icon ?? _resolveDefaultIcon();

    final hPad = dense ? AppSpacing.xs : AppSpacing.sm;
    final vPad = dense ? (AppSpacing.xxs / 2) : AppSpacing.xxs;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.12),
        borderRadius: AppRadius.tagRadius,
        border: Border.all(color: base.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: dense ? AppIcons.xs : AppIcons.sm, color: foreground),
          SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: (dense
                    ? theme.textTheme.labelSmall
                    : theme.textTheme.labelMedium)
                ?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
