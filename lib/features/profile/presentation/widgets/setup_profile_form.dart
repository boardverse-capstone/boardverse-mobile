import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_radius.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';

/// Form nhập hồ sơ lần đầu khi [ProfileEntity.hasProfile] = false.
///
/// Đã được pre-fill từ trước ở [HomePage] nên widget này chỉ thuần UI.
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
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IntroBanner(),
            const SizedBox(height: AppSpacing.xl),

            // Bio
            TextFormField(
              controller: bioController,
              maxLines: 3,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Mô tả cá nhân (Bio)',
                prefixIcon: Icon(Icons.description_outlined),
                helperText: 'Giới thiệu về bản thân bạn',
                helperMaxLines: 2,
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

            // Tên + Họ (2 columns)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        return 'Vui lòng nhập tên';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: lastNameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Họ',
                      prefixIcon: Icon(AppIcons.user),
                    ),
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
            TextFormField(
              controller: dobController,
              readOnly: true,
              onTap: onPickDate,
              decoration: const InputDecoration(
                labelText: 'Ngày sinh',
                prefixIcon: Icon(AppIcons.schedule),
                suffixIcon: Icon(AppIcons.booking),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng chọn ngày sinh';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // SĐT
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                prefixIcon: Icon(AppIcons.phone),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSubmit,
                icon: const Icon(AppIcons.confirmBooking),
                label: Text(
                  'Tạo hồ sơ cá nhân',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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

class _IntroBanner extends StatelessWidget {
  const _IntroBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            AppIcons.user,
            color: theme.colorScheme.primary,
            size: AppIcons.xxl,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoàn tất hồ sơ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Để tiếp tục trải nghiệm hệ thống, vui lòng điền thông tin cá nhân của bạn.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
