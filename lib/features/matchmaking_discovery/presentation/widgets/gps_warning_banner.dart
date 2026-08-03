import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class GpsWarningBanner extends StatelessWidget {
  final VoidCallback? onEnableGps;
  final VoidCallback? onEnterManually;

  const GpsWarningBanner({
    super.key,
    this.onEnableGps,
    this.onEnterManually,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: AppSpacing.paddingAllMd,
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusSmAll,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_off,
                color: AppColors.warningDark,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'GPS đang tắt',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.warningDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Bật GPS để xem các quán cafe gần bạn hoặc nhập vị trí thủ công.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.warningDark,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onEnableGps,
                  icon: const Icon(Icons.gps_fixed, size: AppSpacing.md + 2),
                  label: const Text('Bật GPS'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEnterManually,
                  icon: const Icon(Icons.edit_location_alt,
                      size: AppSpacing.md + 2),
                  label: const Text('Nhập tay'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}