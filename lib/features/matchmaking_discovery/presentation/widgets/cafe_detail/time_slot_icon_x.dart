import 'package:flutter/material.dart';

import '../../../domain/entities/cafe_detail_entity.dart';

/// Map [TimeSlot] → icon Material phù hợp cho UI.
extension TimeSlotIconX on TimeSlot {
  IconData get icon {
    switch (this) {
      case TimeSlot.morning:
        return Icons.wb_sunny_outlined;
      case TimeSlot.afternoon:
        return Icons.wb_cloudy_outlined;
      case TimeSlot.evening:
        return Icons.nights_stay_outlined;
      case TimeSlot.lateNight:
        return Icons.bedtime_outlined;
    }
  }
}