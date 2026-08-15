import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';

/// Card hiển thị các tiện ích của quán:
/// - Số bàn (numberOfTables)
/// - Số phòng riêng (numberOfPrivateRooms)
/// - Số game owned (numberOfGamesOwned)
/// - Có game master (hasGameMaster)
///
/// Chỉ render nếu có ít nhất 1 thông tin đáng hiển thị.
class AmenitiesCard extends StatelessWidget {
  final int numberOfTables;
  final int numberOfPrivateRooms;
  final int numberOfGamesOwned;
  final bool hasGameMaster;

  const AmenitiesCard({
    super.key,
    required this.numberOfTables,
    required this.numberOfPrivateRooms,
    required this.numberOfGamesOwned,
    required this.hasGameMaster,
  });

  /// True nếu có ít nhất một tiện ích được expose (>0 / true).
  bool get hasAny =>
      numberOfTables > 0 ||
      numberOfPrivateRooms > 0 ||
      numberOfGamesOwned > 0 ||
      hasGameMaster;

  @override
  Widget build(BuildContext context) {
    if (!hasAny) return const SizedBox.shrink();

    final tiles = <_AmenityTile>[
      if (numberOfTables > 0)
        _AmenityTile(
          icon: Icons.table_restaurant_rounded,
          label: 'Bàn',
          value: '$numberOfTables',
          color: AppColors.primary,
        ),
      if (numberOfPrivateRooms > 0)
        _AmenityTile(
          icon: Icons.meeting_room_rounded,
          label: 'Phòng riêng',
          value: '$numberOfPrivateRooms',
          color: AppColors.secondary,
        ),
      if (numberOfGamesOwned > 0)
        _AmenityTile(
          icon: Icons.casino_rounded,
          label: 'Tựa game',
          value: '$numberOfGamesOwned',
          color: AppColors.accent,
        ),
      if (hasGameMaster)
        const _AmenityTile(
          icon: Icons.support_agent_rounded,
          label: 'Game Master',
          value: 'Có',
          color: AppColors.info,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: NeoBrutalismTheme.borderWidth,
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
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  size: 22,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'TIỆN ÍCH',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.xs,
            mainAxisSpacing: AppSpacing.xs,
            childAspectRatio: 2.6,
            children: tiles,
          ),
        ],
      ),
    );
  }
}

class _AmenityTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _AmenityTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}