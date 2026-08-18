import '../../domain/entities/default_time_slot_entity.dart';

/// Data model cho `DefaultTimeSlotDto` từ
/// `GET /api/v1/manager/time-slots/defaults`.
///
/// Parser được viết tay (không dùng json_serializable) vì map này có vài
/// trường nullable (displayName, description) và thứ tự key ổn định nên
/// không cần code generation overhead.
class DefaultTimeSlotModel extends DefaultTimeSlotEntity {
  const DefaultTimeSlotModel({
    required super.slot,
    required super.displayName,
    required super.defaultStartTime,
    required super.defaultEndTime,
    required super.durationMinutes,
    required super.description,
  });

  factory DefaultTimeSlotModel.fromJson(Map<String, dynamic> json) {
    final slot = TimeSlotKey.fromApiName(json['slot'] as String?) ??
        TimeSlotKey.morning;

    return DefaultTimeSlotModel(
      slot: slot,
      displayName: (json['displayName'] as String?) ?? slot.displayLabel,
      defaultStartTime: (json['defaultStartTime'] as String?) ?? '00:00:00',
      defaultEndTime: (json['defaultEndTime'] as String?) ?? '00:00:00',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      description: (json['description'] as String?) ?? '',
    );
  }
}
