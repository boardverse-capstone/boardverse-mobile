import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';
import '../../../domain/entities/cafe_detail_entity.dart';

/// Card hiển thị trạng thái hoạt động của quán — Active/Inactive/Suspended
/// + badge "Đang mở cửa / Đóng cửa" dựa trên `isCurrentlyOpen`.
class OperationalStatusCard extends StatelessWidget {
  final CafeDetailEntity cafe;

  const OperationalStatusCard({super.key, required this.cafe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusCfg = _statusConfig(cafe.operationalStatus);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: statusCfg.bg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusCfg.bg,
          width: NeoBrutalismTheme.borderWidthBold,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusCfg.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  statusCfg.icon,
                  size: 22,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRẠNG THÁI',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusCfg.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: statusCfg.bg,
                      ),
                    ),
                  ],
                ),
              ),
              _OpenBadge(isOpen: cafe.isCurrentlyOpen),
            ],
          ),
          if (cafe.operationalStatusReason != null &&
              cafe.operationalStatusReason!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Lý do: ${cafe.operationalStatusReason}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  _StatusConfig _statusConfig(CafeOperationalStatus status) {
    switch (status) {
      case CafeOperationalStatus.active:
        return const _StatusConfig(
          bg: AppColors.success,
          icon: Icons.check_circle_rounded,
          label: 'Hoạt động',
        );
      case CafeOperationalStatus.inactive:
        return const _StatusConfig(
          bg: AppColors.textSecondary,
          icon: Icons.do_not_disturb_on_rounded,
          label: 'Ngưng hoạt động',
        );
      case CafeOperationalStatus.suspended:
        return const _StatusConfig(
          bg: AppColors.error,
          icon: Icons.block_rounded,
          label: 'Tạm đình chỉ',
        );
    }
  }
}

class _StatusConfig {
  final Color bg;
  final IconData icon;
  final String label;

  const _StatusConfig({required this.bg, required this.icon, required this.label});
}

class _OpenBadge extends StatelessWidget {
  final bool isOpen;

  const _OpenBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? AppColors.success : AppColors.error;
    final icon =
        isOpen ? Icons.toggle_on_rounded : Icons.toggle_off_rounded;
    final label = isOpen ? 'ĐANG MỞ' : 'ĐÃ ĐÓNG';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}