import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';

/// Tab bar widget dùng trong LobbyConfigPage (4 tabs).
class LobbyConfigTabBar extends StatelessWidget {
  final TabController controller;

  const LobbyConfigTabBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const tabs = ['Quán & Game', 'Thời gian', 'Cấu hình', 'Đặt cọc'];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicatorColor: theme.colorScheme.primary,
        indicatorWeight: 3,
        tabs: tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }
}