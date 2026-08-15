import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';
import 'package:boardverse/core/widgets/app_toast_card.dart';

/// Toast helper cho auth pages - Neo style.
class AuthToast {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    DelightToastBar(
      autoDismiss: true,
      snackbarDuration: const Duration(seconds: 3),
      position: DelightSnackbarPosition.top,
      builder: (ctx) => AppToastCard(
        leading: Icon(
          isError ? Icons.error_outline : Icons.check_circle_outlined,
          color: isError ? AppColors.error : AppColors.success,
          size: 28,
        ),
        title: Text(
          message,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    ).show(context);
  }
}

/// Back button cho auth app bar - Neo style.
class AuthBackButton extends StatefulWidget {
  const AuthBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<AuthBackButton> createState() => _AuthBackButtonState();
}

class _AuthBackButtonState extends State<AuthBackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: NeoBrutalismTheme.borderWidth,
            ),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: AppColors.primary.withValues(alpha: 0.4),
            ),
          ),
          child: const Icon(
            Icons.arrow_back,
            color: AppColors.white,
            size: AppIcons.md,
          ),
        ),
      ),
    );
  }
}

/// Title + subtitle cho auth pages - Neo style.
class AuthTitle extends StatelessWidget {
  const AuthTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.color = AppColors.white,
  });

  final String title;
  final String? subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleColor = color == AppColors.white
        ? color.withValues(alpha: 0.8)
        : (theme.brightness == Brightness.dark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondary);

    return Column(
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: subtitleColor,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Link text button cho auth pages - Neo style.
class AuthLinkText extends StatelessWidget {
  const AuthLinkText({
    super.key,
    required this.text,
    required this.linkText,
    required this.onTap,
  });

  final String text;
  final String linkText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Align(
      alignment: Alignment.center,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: text,
              style: TextStyle(color: textColor),
            ),
            TextSpan(
              text: linkText,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()..onTap = onTap,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

