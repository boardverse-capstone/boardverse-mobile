import 'package:equatable/equatable.dart';

/// Khung giờ cố định trong ngày của hệ thống (BR-NEW-15 §7.1).
///
/// Có 4 giá trị duy nhất — backend không cho phép thêm slot mới.
/// Mapping string (API contract):
///   - `Morning`   : Sáng
///   - `Afternoon` : Chiều
///   - `Evening`   : Tối
///   - `LateNight` : Khuya (qua đêm — `endTime` thuộc ngày hôm sau)
enum TimeSlotKey {
  morning,
  afternoon,
  evening,
  lateNight;

  /// Tên chuẩn backend dùng trong JSON (`/api/v1/manager/time-slots/defaults`
  /// + quote confirm body). Case-sensitive.
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
}

/// Entity cho `DefaultTimeSlotDto` từ
/// `GET /api/v1/manager/time-slots/defaults`.
///
/// Endpoint trả về 4 slot cố định (morning/afternoon/evening/lateNight)
/// cùng `startTime`, `endTime` mặc định, `durationMinutes` và `description`
/// ngắn cho UI manager. Player mobile dùng lại metadata này để hiển thị
/// khung giờ khi tạo lobby ở `LobbyConfigPage` — tránh phải hardcode
/// `morning=9h, evening=18h` ở client (dễ lệch với backend sau khi
/// manager override schedule).
class DefaultTimeSlotEntity extends Equatable {
  final TimeSlotKey slot;

  /// Tên tiếng Việt do backend trả về (VD: "Sáng", "Chiều", "Tối", "Khuya").
  final String displayName;

  /// Giờ bắt đầu mặc định, format `HH:mm:ss`. Có thể > 23 (LateNight không
  /// có ý nghĩa này — LateNight start = 23:00, end = 06:00 ngày sau).
  final String defaultStartTime;

  final String defaultEndTime;
  final int durationMinutes;
  final String description;

  const DefaultTimeSlotEntity({
    required this.slot,
    required this.displayName,
    required this.defaultStartTime,
    required this.defaultEndTime,
    required this.durationMinutes,
    required this.description,
  });

  @override
  List<Object?> get props => [
        slot,
        displayName,
        defaultStartTime,
        defaultEndTime,
        durationMinutes,
        description,
      ];
}
