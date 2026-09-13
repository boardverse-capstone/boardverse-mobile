import 'package:flutter/material.dart';

import '../../../domain/entities/default_time_slot_entity.dart';

/// Map `TimeSlotKey` (server-facing enum) → icon Material phù hợp cho UI.
///
/// BR-NEW-15 (2026-08-18): cafe response giờ là `Map<String, int>` raw — UI
/// dùng `TimeSlotKey.fromApiName(apiKey)` để lookup icon/label chuẩn.
extension TimeSlotIconX on TimeSlotKey {
  IconData get icon {
    switch (this) {
      case TimeSlotKey.morning:
        return Icons.wb_sunny_outlined;
      case TimeSlotKey.afternoon:
        return Icons.wb_cloudy_outlined;
      case TimeSlotKey.evening:
        return Icons.nights_stay_outlined;
      case TimeSlotKey.lateNight:
        return Icons.bedtime_outlined;
    }
  }
}
