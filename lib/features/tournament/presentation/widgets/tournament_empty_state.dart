import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Tournament empty state.
class TournamentEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const TournamentEmptyState({
    super.key,
    this.title = 'Chưa có giải đấu nào',
    this.message = 'Hãy quay lại sau hoặc chọn bộ lọc khác để xem thêm.',
    this.icon = Icons.emoji_events_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: NeoBrutalismTheme.borderWidthBold),
                boxShadow: NeoBrutalismTheme.lightShadow(
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title.toUpperCase(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}