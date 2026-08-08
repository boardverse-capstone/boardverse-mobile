import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import 'package:boardverse_mobile/core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism TournamentFilterSection — Filter chips for tournament list.
class TournamentFilterSection extends StatelessWidget {
  final int selectedFilter;
  final ValueChanged<int> onFilterChanged;

  const TournamentFilterSection({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  static const _filterLabels = <String>[
    'Tất cả',
    'Đang mở',
    'Đang diễn ra',
    'Đã kết thúc',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      color: isDark ? AppColors.backgroundDark : AppColors.background,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KHÁM PHÁ GIẢI ĐẤU',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_filterLabels.length, (index) {
                final isSelected = selectedFilter == index;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => onFilterChanged(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs + 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.surfaceDark : AppColors.surface),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : borderColor,
                            width: isSelected
                                ? NeoBrutalismTheme.borderWidthBold
                                : NeoBrutalismTheme.borderWidth,
                          ),
                          boxShadow: isSelected
                              ? NeoBrutalismTheme.lightShadow(
                                  shadowColor:
                                      AppColors.primary.withValues(alpha: 0.4),
                                )
                              : NeoBrutalismTheme.lightShadow(
                                  shadowColor:
                                      AppColors.black.withValues(alpha: 0.04),
                                ),
                        ),
                        child: Text(
                          _filterLabels[index].toUpperCase(),
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.white
                                : (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}