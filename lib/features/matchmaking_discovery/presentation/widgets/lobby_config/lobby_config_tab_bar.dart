import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Tab bar widget dùng trong LobbyConfigPage.
class LobbyConfigTabBar extends StatelessWidget {
  final TabController controller;

  const LobbyConfigTabBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const tabs = ['Quán & Game', 'Thời gian', 'Cấu hình', 'Đặt cọc'];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: NeoBrutalismTheme.borderWidth,
          ),
        ),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        labelColor: AppColors.primary,
        unselectedLabelColor: theme.colorScheme.outline,
        indicatorColor: AppColors.primary,
        indicatorWeight: 4,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
        tabs: tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }
}
