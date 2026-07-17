import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// Card container cho auth forms
class AuthFormCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const AuthFormCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.radiusLgAll,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Email info badge cho verify page
class EmailInfoBadge extends StatelessWidget {
  final String email;

  const EmailInfoBadge({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.15),
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.email_outlined,
            color: AppColors.white,
            size: AppIcons.md,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Password strength indicator
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    int strength = 0;
    Color strengthColor = AppColors.error;
    String strengthText = 'Yếu';

    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    switch (strength) {
      case 0:
      case 1:
        strengthColor = AppColors.error;
        strengthText = 'Yếu';
        break;
      case 2:
        strengthColor = AppColors.warning;
        strengthText = 'Trung bình';
        break;
      case 3:
        strengthColor = AppColors.success;
        strengthText = 'Khá';
        break;
      case 4:
      case 5:
        strengthColor = AppColors.primary;
        strengthText = 'Mạnh';
        break;
    }

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: AppRadius.radiusFullAll,
            child: LinearProgressIndicator(
              value: strength / 5,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          strengthText,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: strengthColor,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

/// Terms checkbox
class TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const TermsCheckbox({
    super.key,
    this.value = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: AppRadius.radiusXxsAll,
          ),
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.secondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: const BorderSide(color: AppColors.border, width: 1.5),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              children: const [
                TextSpan(text: 'Tôi đồng ý với '),
                TextSpan(
                  text: 'Điều khoản sử dụng',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: ' và '),
                TextSpan(
                  text: 'Chính sách bảo mật',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: ' của BoardVerse'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
