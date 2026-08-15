import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Form Card Container
class AuthFormCard extends StatelessWidget {
  const AuthFormCard({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: NeoBrutalismTheme.borderWidth,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: child,
    );
  }
}

/// Email info badge cho verify page - Neo style.
class EmailInfoBadge extends StatelessWidget {
  const EmailInfoBadge({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.email_outlined,
            color: AppColors.primary,
            size: AppIcons.md,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Password strength indicator - Neo style.
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    final (strengthColor, strengthText) = switch (strength) {
      0 || 1 => (AppColors.error, 'Yếu'),
      2 => (AppColors.warning, 'Trung bình'),
      3 => (AppColors.success, 'Khá'),
      4 || 5 => (AppColors.primary, 'Mạnh'),
      _ => (AppColors.error, 'Yếu'),
    };

    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength / 5,
              backgroundColor: theme.colorScheme.outlineVariant,
              valueColor: AlwaysStoppedAnimation(strengthColor),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: strengthColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: strengthColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Text(
            strengthText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: strengthColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// Terms checkbox - Neo style.
class TermsCheckbox extends StatelessWidget {
  const TermsCheckbox({
    super.key,
    this.value = false,
    this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onChanged?.call(!value),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: value ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.border),
                width: 2,
              ),
              boxShadow: value
                  ? NeoBrutalismTheme.lightShadow(
                      shadowColor: AppColors.primary.withValues(alpha: 0.3),
                    )
                  : null,
            ),
            child: value
                ? const Icon(Icons.check, size: 16, color: AppColors.white)
                : null,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'Tôi đồng ý với '),
                TextSpan(
                  text: 'Điều khoản sử dụng',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(text: ' và '),
                TextSpan(
                  text: 'Chính sách bảo mật',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(text: ' của BoardVerse'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
