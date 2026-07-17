import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_radius.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';

/// Bottom sheet để chỉnh sửa bio, họ tên và ngày sinh.
///
/// Form state đến từ bên ngoài (controllers trong [HomePage]) nên widget
/// chỉ thuần UI. Submit chỉ trigger [onSubmit] rồi cubit xử lý.
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

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: ShapeDecoration(
          color: theme.colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.radiusXl),
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

                  // Bio
                  TextFormField(
                    controller: bioController,
                    maxLines: 3,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả cá nhân',
                      prefixIcon: Icon(Icons.description_outlined),
                      helperText: 'Tối đa 1000 ký tự',
                    ),
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

                  // First + Last name (2 columns)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: firstNameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Tên',
                            prefixIcon: Icon(AppIcons.user),
                          ),
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
                        child: TextFormField(
                          controller: lastNameController,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Họ',
                            prefixIcon: Icon(AppIcons.user),
                          ),
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

                  // Date of Birth
                  TextFormField(
                    controller: dobController,
                    readOnly: true,
                    onTap: onPickDate,
                    decoration: const InputDecoration(
                      labelText: 'Ngày sinh',
                      prefixIcon: Icon(AppIcons.schedule),
                      suffixIcon: Icon(AppIcons.booking),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onSubmit,
                      icon: const Icon(AppIcons.confirmBooking),
                      label: const Text('Lưu thay đổi'),
                    ),
                  ),
                ],
              ),
            ),
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
    return Row(
      children: [
        Icon(
          AppIcons.edit,
          size: AppIcons.md,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            'Chỉnh sửa hồ sơ',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(AppIcons.close),
          tooltip: 'Đóng',
        ),
      ],
    );
  }
}
