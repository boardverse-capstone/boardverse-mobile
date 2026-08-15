import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';
import 'package:boardverse/features/profile/presentation/widgets/section_card.dart';

/// Neo-brutalism Trạng thái lỗi khi GET /userprofile thất bại.
class ProfileErrorState extends StatelessWidget {
  const ProfileErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: SectionCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.error,
                    width: NeoBrutalismTheme.borderWidthBold,
                  ),
                  boxShadow: NeoBrutalismTheme.lightShadow(
                    shadowColor: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  AppIcons.busy,
                  size: AppIcons.xl,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Tải dữ liệu thất bại',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                      width: NeoBrutalismTheme.borderWidthBold,
                    ),
                    boxShadow: NeoBrutalismTheme.lightShadow(
                      shadowColor: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onRetry,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              AppIcons.refresh,
                              color: AppColors.white,
                              size: AppIcons.sm,
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'THỬ LẠI',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
