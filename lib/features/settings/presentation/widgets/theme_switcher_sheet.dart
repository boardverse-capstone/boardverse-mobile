import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/theme_cubit.dart';

/// Bottom sheet cho phép người dùng chuyển đổi giữa Light / Dark / System theme.
///
/// Mở bằng cách gọi [showThemeSwitcher].
class ThemeSwitcherSheet extends StatelessWidget {
  const ThemeSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ThemeCubit>(),
        child: const ThemeSwitcherSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Giao diện',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Chọn chế độ hiển thị cho ứng dụng',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, state) {
                final cubit = context.read<ThemeCubit>();
                return Column(
                  children: [
                    _ThemeOptionTile(
                      icon: Icons.brightness_auto_outlined,
                      title: 'Theo hệ thống',
                      subtitle: 'Tự động theo cài đặt thiết bị',
                      value: ThemeMode.system,
                      groupValue: state.mode,
                      onChanged: (_) => cubit.setSystem(),
                    ),
                    const Divider(height: 1),
                    _ThemeOptionTile(
                      icon: Icons.light_mode_outlined,
                      title: 'Sáng',
                      subtitle: 'Luôn dùng giao diện sáng',
                      value: ThemeMode.light,
                      groupValue: state.mode,
                      onChanged: (_) => cubit.setLight(),
                    ),
                    const Divider(height: 1),
                    _ThemeOptionTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Tối',
                      subtitle: 'Luôn dùng giao diện tối',
                      value: ThemeMode.dark,
                      groupValue: state.mode,
                      onChanged: (_) => cubit.setDark(),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final ThemeMode value;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = value == groupValue;

    return ListTile(
      onTap: () => onChanged(value),
      tileColor: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      leading: Icon(
        icon,
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: selected
          ? Icon(AppIcons.check, color: theme.colorScheme.primary)
          : null,
    );
  }
}