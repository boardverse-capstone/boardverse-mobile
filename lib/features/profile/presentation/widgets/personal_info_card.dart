import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import 'package:boardverse_mobile/features/profile/domain/entities/profile_entity.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/detail_row.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/section_card.dart';

/// Thẻ "Thông tin tài khoản":
/// - Hiển thị bio (nếu có) + các [DetailRow] (Karma, Họ tên, Ngày sinh, SĐT).
/// - Header có nút edit mở bottom sheet.
///
/// Dùng [InfoEntry] pattern để DRY: duyệt qua 1 list entries, filter entries
/// có value hợp lệ, render [DetailRow]. Tránh lặp `if (x != null) Padding(...)`.
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
    final entries = _buildEntries(profile);

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
            color: theme.colorScheme.outlineVariant,
          ),
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
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

  /// Trả về list entries đã được filter — entry nào thiếu value sẽ bị bỏ.
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
