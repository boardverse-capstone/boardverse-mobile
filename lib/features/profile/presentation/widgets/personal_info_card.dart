import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/features/profile/domain/entities/profile_entity.dart';
import 'package:boardverse/features/profile/presentation/widgets/detail_row.dart';
import 'package:boardverse/features/profile/presentation/widgets/section_card.dart';

/// Neo-brutalism Thẻ "Thông tin tài khoản".
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
    final isDark = theme.brightness == Brightness.dark;
    final entries = _buildEntries(profile);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: AppIcons.user,
            title: 'Thông tin tài khoản',
            trailing: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
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
              child: IconButton(
                icon: const Icon(
                  AppIcons.edit,
                  color: AppColors.white,
                  size: 18,
                ),
                tooltip: 'Chỉnh sửa hồ sơ',
                onPressed: onEditPressed,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            height: 2,
            color: isDark
                ? AppColors.borderDark.withValues(alpha: 0.5)
                : AppColors.border.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            DetailRow(
              icon: entries[i].icon,
              iconColor: entries[i].iconColor,
              label: entries[i].label,
              value: entries[i].value,
            ),
          ],
        ],
      ),
    );
  }

  /// Trả về list entries đã được filter.
  static List<InfoEntry> _buildEntries(ProfileEntity p) {
    final entries = <InfoEntry>[
      InfoEntry(
        icon: AppIcons.karma,
        iconColor: AppColors.warning,
        label: 'Karma / Điểm uy tín',
        value: p.karmaPoints != null ? '${p.karmaPoints} PTS' : 'Chưa có',
      ),
      InfoEntry(
        icon: AppIcons.profile,
        label: 'Họ tên',
        value: '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim(),
      ),
      InfoEntry(
        icon: AppIcons.schedule,
        label: 'Ngày sinh',
        value: p.dateOfBirth ?? '',
      ),
      InfoEntry(
        icon: AppIcons.phone,
        label: 'Số điện thoại',
        value: p.phoneNumber ?? '',
      ),
    ];

    return entries.where((e) => e.value.isNotEmpty).toList();
  }
}

/// Mô tả 1 dòng thông tin trong [PersonalInfoCard].
class InfoEntry {
  const InfoEntry({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
}
