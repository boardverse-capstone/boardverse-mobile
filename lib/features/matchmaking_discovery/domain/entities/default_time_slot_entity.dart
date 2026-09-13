import 'package:flutter/material.dart';

/// Khung giờ cố định trong ngày của hệ thống (BR-NEW-15 §7.1).
///
/// Có 4 giá trị duy nhất — backend không cho phép thêm slot mới.
/// Mapping string (API contract):
///   - `Morning`   : Sáng
///   - `Afternoon` : Chiều
///   - `Evening`   : Tối
///   - `LateNight` : Khuya (qua đêm — `endTime` thuộc ngày hôm sau)
///
/// BR-NEW (2026-08-27): enum này giờ CHỈ dùng để map icon/color cho
/// `availableSeatsByTimeSlot` map trên cafe detail UI. Backend không còn
/// nhận `timeSlot` enum cho reservation/lobby creation (player tự chọn
/// giờ bắt đầu/kết thúc trong ngày).
enum TimeSlotKey {
  morning,
  afternoon,
  evening,
  lateNight;

  /// Tên chuẩn backend dùng trong JSON response (case-sensitive).
  String get apiName {
    switch (this) {
      case TimeSlotKey.morning:
        return 'Morning';
      case TimeSlotKey.afternoon:
        return 'Afternoon';
      case TimeSlotKey.evening:
        return 'Evening';
      case TimeSlotKey.lateNight:
        return 'LateNight';
    }
  }

  static TimeSlotKey? fromApiName(String? raw) {
    switch (raw) {
      case 'Morning':
        return TimeSlotKey.morning;
      case 'Afternoon':
        return TimeSlotKey.afternoon;
      case 'Evening':
        return TimeSlotKey.evening;
      case 'LateNight':
        return TimeSlotKey.lateNight;
      default:
        return null;
    }
  }

  /// Nhãn tiếng Việt ngắn cho UI ("Sáng", "Chiều", "Tối", "Khuya").
  String get displayLabel {
    switch (this) {
      case TimeSlotKey.morning:
        return 'Sáng';
      case TimeSlotKey.afternoon:
        return 'Chiều';
      case TimeSlotKey.evening:
        return 'Tối';
      case TimeSlotKey.lateNight:
        return 'Khuya';
    }
  }

  /// Icon đại diện cho UI. Cố định theo khung giờ — không phụ thuộc theme.
  IconData get icon {
    switch (this) {
      case TimeSlotKey.morning:
        return Icons.wb_sunny;
      case TimeSlotKey.afternoon:
        return Icons.wb_cloudy;
      case TimeSlotKey.evening:
        return Icons.nights_stay;
      case TimeSlotKey.lateNight:
        return Icons.bedtime;
    }
  }

  /// Màu chủ đạo của khung giờ. Cố định để hiển thị ổn định giữa
  /// light/dark mode.
  Color get color {
    switch (this) {
      case TimeSlotKey.morning:
        return Colors.orange;
      case TimeSlotKey.afternoon:
        return Colors.amber;
      case TimeSlotKey.evening:
        return Colors.indigo;
      case TimeSlotKey.lateNight:
        return Colors.deepPurple;
    }
  }
}
