import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Form nhập hồ sơ lần đầu khi [ProfileEntity.hasProfile] = false.
class SetupProfileForm extends StatelessWidget {
  const SetupProfileForm({
    super.key,
    required this.formKey,
    required this.bioController,
    required this.firstNameController,
    required this.lastNameController,
    required this.dobController,
    required this.phoneController,
    required this.onPickDate,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController bioController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController dobController;
  final TextEditingController phoneController;
  final VoidCallback onPickDate;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.border;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _IntroBanner(),
            const SizedBox(height: AppSpacing.xl),

            // Bio
            _NeoTextField(
              controller: bioController,
              label: 'Mô tả cá nhân (Bio)',
              helperText: 'Giới thiệu về bản thân bạn',
              icon: Icons.description_outlined,
              maxLines: 3,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập mô tả cá nhân';
                }
                if (value.length > 1000) {
                  return 'Mô tả không được vượt quá 1000 ký tự';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Tên + Họ (2 columns)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _NeoTextField(
                    controller: firstNameController,
                    label: 'Tên',
                    icon: AppIcons.user,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _NeoTextField(
                    controller: lastNameController,
                    label: 'Họ',
                    icon: AppIcons.user,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập họ';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // DOB
            _NeoTextField(
              controller: dobController,
              label: 'Ngày sinh',
              icon: AppIcons.schedule,
              suffixIcon: AppIcons.booking,
              readOnly: true,
              onTap: onPickDate,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng chọn ngày sinh';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // SĐT
            _NeoTextField(
              controller: phoneController,
              label: 'Số điện thoại',
              icon: AppIcons.phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.xxl),

            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: borderColor,
                    width: NeoBrutalismTheme.borderWidthBold,
                  ),
                  boxShadow: NeoBrutalismTheme.lightShadow(
                    shadowColor: AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onSubmit,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            AppIcons.confirmBooking,
                            color: AppColors.white,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            'TẠO HỒ SƠ CÁ NHÂN',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Neo-brutalism text field với bold border.
class _NeoTextField extends StatelessWidget {
  const _NeoTextField({
    required this.controller,
    required this.label,
    this.helperText,
    this.icon,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? helperText;
  final IconData? icon;
  final IconData? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
        prefixIcon: icon != null ? Icon(icon) : null,
        suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
        helperText: helperText,
        helperMaxLines: 2,
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: borderColor,
            width: NeoBrutalismTheme.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: borderColor,
            width: NeoBrutalismTheme.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: NeoBrutalismTheme.borderWidthBold,
          ),
        ),
      ),
    );
  }
}

class _IntroBanner extends StatelessWidget {
  const _IntroBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary,
          width: NeoBrutalismTheme.borderWidthBold,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              AppIcons.user,
              color: AppColors.white,
              size: AppIcons.xxl,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOÀN TẤT HỒ SƠ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Để tiếp tục trải nghiệm hệ thống, vui lòng điền thông tin cá nhân của bạn.',
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
        ],
      ),
    );
  }
}
