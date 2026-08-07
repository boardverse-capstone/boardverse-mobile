import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/cafe_entity.dart';
import 'cafe_chip.dart';

/// Card hiển thị cafe có thể chọn — icon + name + address + chips + chevron.
class SelectableCafeCard extends StatelessWidget {
  final CafeEntity cafe;
  final VoidCallback onTap;

  const SelectableCafeCard({
    super.key,
    required this.cafe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distanceLabel = cafe.distanceMeters < 1000
        ? '${cafe.distanceMeters.toStringAsFixed(0)} m'
        : '${(cafe.distanceMeters / 1000).toStringAsFixed(1)} km';

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSmAll),
      child: InkWell(
        borderRadius: AppRadius.radiusSmAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.local_cafe,
                color: theme.colorScheme.primary,
                size: AppSpacing.xl + AppSpacing.xs,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cafe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (cafe.address.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        cafe.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        CafeChip(
                          icon: Icons.location_on,
                          label: distanceLabel,
                        ),
                        if (cafe.isWaitingForGame &&
                            cafe.estimatedWaitMinutes != null)
                          CafeChip(
                            icon: Icons.hourglass_bottom,
                            label:
                                'Chờ game ~${cafe.estimatedWaitMinutes} phút',
                            color: AppColors.warning.withValues(alpha: 0.12),
                            textColor: AppColors.warningDark,
                          ),
                        if (cafe.totalTableCount > 0)
                          CafeChip(
                            icon: Icons.table_restaurant,
                            label:
                                '${cafe.availableTableCount}/${cafe.totalTableCount} bàn',
                          ),
                        if (cafe.rating > 0)
                          CafeChip(
                            icon: Icons.star,
                            label: cafe.rating.toStringAsFixed(1),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}