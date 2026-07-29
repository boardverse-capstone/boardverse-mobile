import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_radius.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';

/// Single entry in the [QuickActionsCard] grid.
class QuickActionItem {
  const QuickActionItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.tint,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  /// Optional tint color for the icon. Nếu không truyền sẽ dùng `primary`.
  final Color? tint;
}

/// Grid 2x2 hiển thị các thao tác nhanh (bạn bè, xếp hạng, lịch sử, cài đặt).
///
/// Mỗi item là 1 ô vuông bo tròn, icon trên + label dưới — phong cách minimal.
/// Toàn bộ grid được bọc trong 1 surface bo góc với border + shadow nhẹ.
class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key, required this.actions});

  final List<QuickActionItem> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.radiusLgAll,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.6,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        children: [
          for (final item in actions) _ActionTile(item: item),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.item});

  final QuickActionItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = item.tint ?? theme.colorScheme.primary;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: AppRadius.radiusMdAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: AppRadius.radiusMdAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: AppRadius.radiusSmAll,
                ),
                child: Icon(item.icon, color: tint, size: AppIcons.md),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                AppIcons.forward,
                size: AppIcons.sm,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
