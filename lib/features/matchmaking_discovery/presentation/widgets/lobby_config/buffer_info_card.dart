import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Buffer info card.
///
/// Hiển thị "thời gian tuyển người" (= `scheduledStartTime - now`):
/// - `bufferMinutes < 0` (quá giờ): error — UI hiển thị "Ngày đã qua".
/// - `0 ≤ bufferMinutes < 30` (quá sát giờ để đặt lobby, BR §XXI-B.6):
///   error đỏ — nút "Tiếp tục" sẽ bị disable ở page cha vì không đủ
///   thời gian chuẩn bị (group bạn invite + di chuyển).
/// - `30 ≤ bufferMinutes < 60` (insufficient): warning cam đậm — group
///   bạn đi chung vẫn đặt được nhưng nên chọn slot xa hơn nếu muốn
///   tuyển thêm thành viên ngoài group.
/// - `60 ≤ bufferMinutes < 120`: warning yellow (default).
/// - `bufferMinutes >= 120`: success green.
class LobbyConfigBufferInfoCard extends StatelessWidget {
  final int bufferMinutes;
  final bool hasBufferWarning;

  /// `true` khi buffer nằm trong vùng insufficient (30–60 phút). UI
  /// dùng warning cam đậm để phân biệt với warning thường (≥ 60p).
  final bool isInsufficient;
  final String Function(int) formatBuffer;

  const LobbyConfigBufferInfoCard({
    super.key,
    required this.bufferMinutes,
    required this.hasBufferWarning,
    required this.isInsufficient,
    required this.formatBuffer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (bufferMinutes < 0) {
      return Container(
        padding: AppSpacing.paddingAllMd,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.error,
            width: NeoBrutalismTheme.borderWidthBold,
          ),
          boxShadow: NeoBrutalismTheme.lightShadow(
            shadowColor: AppColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.event_busy,
                color: AppColors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THỜI GIAN TUYỂN NGƯỜI',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.errorDark,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ngày bạn chọn đã qua. Vui lòng chọn ngày khác.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Color logic theo buffer zone (BR §XXI-B.6):
// - `bufferMinutes < 30` (too short, page cha disable nút) → error đỏ.
// - `isInsufficient` (30 ≤ buffer < 60) → warning cam đậm.
// - `hasBufferWarning` (60 ≤ buffer < 120) → warning thường.
// - `bufferMinutes >= 120` → success.
final Color color;
final Color titleColor;
final IconData icon;
if (bufferMinutes < 30) {
  color = AppColors.error;
  titleColor = AppColors.errorDark;
  icon = Icons.error;
} else if (isInsufficient) {
  color = AppColors.warning;
  titleColor = AppColors.warningDark;
  icon = Icons.warning;
} else if (hasBufferWarning) {
  color = AppColors.warning;
  titleColor = AppColors.warningDark;
  icon = Icons.warning;
} else if (bufferMinutes >= 120) {
  color = AppColors.success;
  titleColor = AppColors.successDark;
  icon = Icons.check_circle;
} else {
  color = AppColors.warning;
  titleColor = AppColors.warningDark;
  icon = Icons.warning;
}

    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color,
          width: NeoBrutalismTheme.borderWidthBold,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THỜI GIAN TUYỂN NGƯỜI',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  formatBuffer(bufferMinutes),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
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
