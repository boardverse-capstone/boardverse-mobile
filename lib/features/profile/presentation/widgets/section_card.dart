import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_radius.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';

/// Bọc ngoài thống nhất cho mọi "card" trong profile:
/// border 1px outlineVariant + radius [AppRadius.radiusMd], shadow mềm.
///
/// Dùng [Material] thay vì [Container] để ListTile bên trong có thể vẽ
/// ink splashes trên surface của card.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.paddingAllMd,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.6);

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Tiêu đề section: icon + text, thường nằm trên đầu [SectionCard].
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: AppIcons.md),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
