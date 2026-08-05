import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/entities.dart';

/// Helper widget `extension` cho [ActivityStatus] — chuyển enum sang màu và
/// label tiếng Việt dùng hiển thị badge online/offline.
///
/// Đặt trong `widgets/shared/` vì đây là UI presentation helper, không phải
/// business logic. Nếu sau này cần reuse cho lobby (online players), chỉ cần
/// move vào `core/`.
extension FriendStatusPresentation on ActivityStatus {
  Color get color {
    switch (this) {
      case ActivityStatus.online:
        return AppColors.success;
      case ActivityStatus.recentlyActive:
        return AppColors.successLight;
      case ActivityStatus.away:
        return AppColors.warning;
      case ActivityStatus.offline:
        return AppColors.textSecondary;
    }
  }

  String get label {
    switch (this) {
      case ActivityStatus.online:
        return 'Đang online';
      case ActivityStatus.recentlyActive:
        return 'Vừa hoạt động';
      case ActivityStatus.away:
        return 'Tạm nghỉ';
      case ActivityStatus.offline:
        return 'Ngoại tuyến';
    }
  }
}

extension GamerTierPresentation on GamerTier {
  Color get color {
    switch (this) {
      case GamerTier.bronze:
        return AppColors.eloBronze;
      case GamerTier.silver:
        return AppColors.eloSilver;
      case GamerTier.gold:
        return AppColors.eloGold;
      case GamerTier.platinum:
        return AppColors.eloPlatinum;
      case GamerTier.diamond:
        return AppColors.eloDiamond;
    }
  }
}

/// Wrapper xử lý null-safe cho [ActivityStatus] — trả fallback label/color khi
/// friend chưa có presence info.
class ActivityStatusBadge {
  const ActivityStatusBadge._(this.label, this.color);

  factory ActivityStatusBadge.of(ActivityStatus? status) {
    if (status == null) {
      return const ActivityStatusBadge._('Ngoại tuyến', null);
    }
    return ActivityStatusBadge._(status.label, status.color);
  }

  final String label;
  final Color? color;
}
