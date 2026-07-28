import 'package:flutter/material.dart';

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
        return Colors.green;
      case ActivityStatus.recentlyActive:
        return Colors.lightGreen;
      case ActivityStatus.away:
        return Colors.orange;
      case ActivityStatus.offline:
        return Colors.grey;
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
        return const Color(0xFFCD7F32);
      case GamerTier.silver:
        return const Color(0xFFC0C0C0);
      case GamerTier.gold:
        return const Color(0xFFFFD700);
      case GamerTier.platinum:
        return const Color(0xFFB0E0E6);
      case GamerTier.diamond:
        return const Color(0xFFB9F2FF);
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
