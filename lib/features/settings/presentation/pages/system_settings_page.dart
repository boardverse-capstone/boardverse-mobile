import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../cubit/theme_cubit.dart';

/// Neo-brutalism Trang Cài đặt hệ thống.
class SystemSettingsPage extends StatelessWidget {
  const SystemSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          'CÀI ĐẶT HỆ THỐNG',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          final cubit = context.read<ThemeCubit>();
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            children: [
              const _SectionHeader(
                icon: AppIcons.moon,
                title: 'Giao diện',
                subtitle: 'Chọn chế độ hiển thị cho ứng dụng',
              ),
              const SizedBox(height: AppSpacing.md),
              _SettingsCard(
                children: [
                  _ThemeOptionTile(
                    icon: Icons.brightness_auto_outlined,
                    title: 'Theo hệ thống',
                    subtitle: 'Tự động theo cài đặt thiết bị',
                    value: ThemeMode.system,
                    groupValue: state.mode,
                    onTap: () => cubit.setSystem(),
                  ),
                  _ThemeOptionTile(
                    icon: Icons.light_mode_outlined,
                    title: 'Sáng (Light mode)',
                    subtitle: 'Luôn dùng giao diện sáng',
                    value: ThemeMode.light,
                    groupValue: state.mode,
                    onTap: () => cubit.setLight(),
                  ),
                  _ThemeOptionTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Tối (Dark mode)',
                    subtitle: 'Luôn dùng giao diện tối',
                    value: ThemeMode.dark,
                    groupValue: state.mode,
                    onTap: () => cubit.setDark(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const _InfoNote(),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.black, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.black,
                  blurRadius: 0,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: AppColors.white,
              size: AppIcons.md,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: NeoBrutalismTheme.borderWidth),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.black.withValues(alpha: 0.06),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const _Divider(),
            children[i],
          ],
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
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final ThemeMode value;
  final ThemeMode groupValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selected = value == groupValue;
    final selectedColor = selected ? AppColors.primary : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
                  color: selected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.surfaceVariant
                          : AppColors.surfaceVariant),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: selected ? AppColors.white : selectedColor,
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
                        color: theme.brightness == Brightness.dark
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
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: NeoBrutalismTheme.borderWidthBold),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppColors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Cài đặt sẽ được lưu lại cho những lần mở ứng dụng tiếp theo.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}