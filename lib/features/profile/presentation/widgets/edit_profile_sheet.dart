import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_radius.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Bottom sheet chỉnh sửa bio, họ tên và ngày sinh.
class EditProfileSheet extends StatelessWidget {
  const EditProfileSheet({
    super.key,
    required this.formKey,
    required this.bioController,
    required this.firstNameController,
    required this.lastNameController,
    required this.dobController,
    required this.onPickDate,
    required this.onSubmit,
    required this.onClose,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController bioController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController dobController;
  final VoidCallback onPickDate;
  final VoidCallback onSubmit;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.border;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Stack(
        children: [
          // Hard shadow offset
          Positioned(
            left: 3,
            right: 3,
            top: 3,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.radiusXl),
                ),
              ),
            ),
          ),
          // Main sheet
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.radiusXl),
              ),
              border: Border(
                top: BorderSide(
                  color: borderColor,
                  width: NeoBrutalismTheme.borderWidthBold,
                ),
                left: BorderSide(
                  color: borderColor,
                  width: NeoBrutalismTheme.borderWidthBold,
                ),
                right: BorderSide(
                  color: borderColor,
                  width: NeoBrutalismTheme.borderWidthBold,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(onClose: onClose),
                      const SizedBox(height: AppSpacing.md),

                      _NeoTextField(
                        controller: bioController,
                        label: 'Mô tả cá nhân',
                        helperText: 'Tối đa 1000 ký tự',
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

                      Row(
                        children: [
                          Expanded(
                            child: _NeoTextField(
                              controller: firstNameController,
                              label: 'Tên',
                              icon: AppIcons.user,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nhập tên';
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
                              textInputAction: TextInputAction.done,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nhập họ';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      _NeoTextField(
                        controller: dobController,
                        label: 'Ngày sinh',
                        icon: AppIcons.schedule,
                        suffixIcon: AppIcons.booking,
                        readOnly: true,
                        onTap: onPickDate,
                      ),

                      const SizedBox(height: AppSpacing.lg),
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
                              shadowColor:
                                  AppColors.primary.withValues(alpha: 0.5),
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
                                      'LƯU THAY ĐỔI',
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
              ),
            ),
          ),
        ],
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
      textInputAction: textInputAction,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
        prefixIcon: icon != null ? Icon(icon) : null,
        suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
        helperText: helperText,
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

class _Header extends StatelessWidget {
  const _Header({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.black,
                blurRadius: 0,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: const Icon(
            AppIcons.edit,
            color: AppColors.white,
            size: AppIcons.md,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'CHỈNH SỬA HỒ SƠ',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.black,
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.black,
                blurRadius: 0,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onClose,
            icon: const Icon(
              AppIcons.close,
              color: AppColors.black,
              size: 16,
            ),
            tooltip: 'Đóng',
          ),
        ),
      ],
    );
  }
}
