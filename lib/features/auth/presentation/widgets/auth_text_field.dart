import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';

/// Neo-brutalism Styled text field cho auth forms.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.textInputAction,
    this.keyboardType,
    this.onFieldSubmitted,
    this.validator,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final void Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(
          prefixIcon,
          size: AppIcons.md,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        floatingLabelStyle: theme.textTheme.labelMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        errorStyle: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.error,
        ),
      ),
    );
  }
}

/// Password field với toggle visibility - Neo style.
class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.textInputAction,
    this.onFieldSubmitted,
    this.validator,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      validator: widget.validator,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: Icon(
          Icons.lock_outline,
          size: AppIcons.md,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: AppIcons.sm,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
          onPressed: () => setState(() => _obscureText = !_obscureText),
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        floatingLabelStyle: theme.textTheme.labelMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// OTP input field - Neo style.
class OtpInputField extends StatelessWidget {
  const OtpInputField({
    super.key,
    required this.controller,
    this.length = 6,
    this.onChanged,
  });

  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return SizedBox(
      height: 60,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: length,
        style: theme.textTheme.headlineMedium?.copyWith(
          letterSpacing: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
        decoration: InputDecoration(
          hintText: List.filled(length, '•').join(' '),
          counterText: '',
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(length),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
