import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import 'package:boardverse_mobile/features/profile/domain/entities/player_location_entity.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/detail_row.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/section_card.dart';

/// Thẻ "Vị trí đã lưu":
/// - Nếu [location.hasLocation] = true: hiển thị toạ độ + nguồn + nút "Xoá".
/// - Nếu false: hiển thị empty state với nút "Bật GPS".
///
/// Các callback là bắt buộc để widget giữ thuần UI, mọi side-effect
/// được xử lý ở [HomePage].
class LocationCard extends StatelessWidget {
  const LocationCard({
    super.key,
    required this.location,
    required this.onUpdateGpsPressed,
    required this.onDeletePressed,
  });

  final PlayerLocationEntity? location;
  final VoidCallback onUpdateGpsPressed;
  final VoidCallback onDeletePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLocation =
        location != null && location!.hasLocation && location!.latitude != null;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            icon: AppIcons.location,
            title: 'Vị trí đã lưu',
          ),
          Divider(
            height: AppSpacing.lg,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
          if (hasLocation) ...[
            DetailRow(
              icon: AppIcons.directions,
              label: 'Toạ độ',
              value:
                  '${location!.latitude!.toStringAsFixed(4)}, ${location!.longitude!.toStringAsFixed(4)}',
            ),
            const SizedBox(height: AppSpacing.sm),
            DetailRow(
              icon: AppIcons.globe,
              label: 'Nguồn',
              value: location!.source == LocationSource.gps
                  ? 'GPS thiết bị'
                  : 'Chọn trên bản đồ',
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDeletePressed,
                    icon: const Icon(AppIcons.delete, size: AppIcons.sm),
                    label: const Text('Xóa vị trí'),
                  ),
                ),
              ],
            ),
          ] else ...[
            _EmptyLocation(onUpdatePressed: onUpdateGpsPressed),
          ],
        ],
      ),
    );
  }
}

class _EmptyLocation extends StatelessWidget {
  const _EmptyLocation({required this.onUpdatePressed});
  final VoidCallback onUpdatePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_off_outlined,
              size: AppIcons.lg,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Chưa có vị trí nào được lưu',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onUpdatePressed,
            icon: const Icon(AppIcons.directions, size: AppIcons.sm),
            label: const Text('Bật GPS'),
          ),
        ),
      ],
    );
  }
}