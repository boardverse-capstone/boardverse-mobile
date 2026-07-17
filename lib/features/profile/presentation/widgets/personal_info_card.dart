import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import 'package:boardverse_mobile/features/profile/domain/entities/profile_entity.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/detail_row.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/section_card.dart';

/// Thẻ "Thông tin tài khoản": hiển thị bio, karma, họ tên, ngày sinh, SĐT,
/// có nút edit mở bottom sheet.
class PersonalInfoCard extends StatelessWidget {
  const PersonalInfoCard({
    super.key,
    required this.profile,
    required this.onEditPressed,
  });

  final ProfileEntity profile;
  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: AppIcons.user,
            title: 'Thông tin tài khoản',
            trailing: IconButton(
              icon: const Icon(AppIcons.edit),
              tooltip: 'Chỉnh sửa hồ sơ',
              color: theme.colorScheme.primary,
              onPressed: onEditPressed,
            ),
          ),
          Divider(
            height: AppSpacing.lg,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
          DetailRow(
            icon: AppIcons.karma,
            iconColor: AppColors.warning,
            label: 'Karma / Điểm uy tín',
            value: profile.karmaPoints != null
                ? '${profile.karmaPoints} PTS'
                : 'Chưa có',
          ),
          if (profile.firstName != null || profile.lastName != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: DetailRow(
                icon: AppIcons.profile,
                label: 'Họ tên',
                value:
                    '${profile.firstName ?? ''} ${profile.lastName ?? ''}'
                        .trim(),
              ),
            ),
          if (profile.dateOfBirth != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: DetailRow(
                icon: AppIcons.schedule,
                label: 'Ngày sinh',
                value: profile.dateOfBirth!,
              ),
            ),
          if (profile.phoneNumber != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: DetailRow(
                icon: AppIcons.phone,
                label: 'Số điện thoại',
                value: profile.phoneNumber!,
              ),
            ),
        ],
      ),
    );
  }
}
