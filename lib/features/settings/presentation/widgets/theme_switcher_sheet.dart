import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../cubit/theme_cubit.dart';

/// Neo-brutalism Bottom sheet cho phép người dùng chuyển đổi theme.
class ThemeSwitcherSheet extends StatelessWidget {
  const ThemeSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ThemeCubit>(),
        child: const ThemeSwitcherSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 3,
            right: 3,
            top: 3,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(color: borderColor, width: NeoBrutalismTheme.borderWidthBold),
                left: BorderSide(color: borderColor, width: NeoBrutalismTheme.borderWidthBold),
                right: BorderSide(color: borderColor, width: NeoBrutalismTheme.borderWidthBold),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GIAO DIỆN',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Chọn chế độ hiển thị cho ứng dụng',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    BlocBuilder<ThemeCubit, ThemeState>(
                      builder: (context, state) {
                        final cubit = context.read<ThemeCubit>();
                        return Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceVariant
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: borderColor,
                              width: NeoBrutalismTheme.borderWidth,
                            ),
                            boxShadow: NeoBrutalismTheme.lightShadow(
                              shadowColor:
                                  AppColors.black.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Column(
                            children: [
                              _ThemeOptionTile(
                                icon: Icons.brightness_auto_outlined,
                                title: 'Theo hệ thống',
                                subtitle: 'Tự động theo cài đặt thiết bị',
                                value: ThemeMode.system,
                                groupValue: state.mode,
                                onChanged: (_) => cubit.setSystem(),
                              ),
                              const _Divider(),
                              _ThemeOptionTile(
                                icon: Icons.light_mode_outlined,
                                title: 'Sáng',
                                subtitle: 'Luôn dùng giao diện sáng',
                                value: ThemeMode.light,
                                groupValue: state.mode,
                                onChanged: (_) => cubit.setLight(),
                              ),
                              const _Divider(),
                              _ThemeOptionTile(
                                icon: Icons.dark_mode_outlined,
                                title: 'Tối',
                                subtitle: 'Luôn dùng giao diện tối',
                                value: ThemeMode.dark,
                                groupValue: state.mode,
                                onChanged: (_) => cubit.setDark(),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      color: (isDark ? AppColors.borderDark : AppColors.border)
          .withValues(alpha: 0.6),
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
    final isDark = theme.brightness == Brightness.dark;
    final selected = value == groupValue;

    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: selected ? AppColors.white : AppColors.textPrimary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                        color: selected ? AppColors.primary : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.black, width: 2),
                  ),
                  child: const Icon(
                    AppIcons.check,
                    color: AppColors.white,
                    size: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}