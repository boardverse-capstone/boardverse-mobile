import '../../domain/entities/booking_history_entity.dart';

class BookingHistoryModel {
  final String id;
  final String cafeName;
  final String gameName;
  final DateTime scheduledTime;
  final DateTime? actualCheckinTime;
  final String status;
  final bool hasNoShowBadge;
  final double depositAmount;

  const BookingHistoryModel({
    required this.id,
    required this.cafeName,
    required this.gameName,
    required this.scheduledTime,
    this.actualCheckinTime,
    required this.status,
    this.hasNoShowBadge = false,
    required this.depositAmount,
  });

  factory BookingHistoryModel.fromJson(Map<String, dynamic> json) {
    return BookingHistoryModel(
      id: json['id'] as String,
      cafeName: json['cafeName'] as String,
      gameName: json['gameName'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      actualCheckinTime: json['actualCheckinTime'] != null
          ? DateTime.parse(json['actualCheckinTime'] as String)
          : null,
      status: json['status'] as String,
      hasNoShowBadge: (json['hasNoShowBadge'] as bool?) ?? false,
      depositAmount: (json['depositAmount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cafeName': cafeName,
        'gameName': gameName,
        'scheduledTime': scheduledTime.toIso8601String(),
        'actualCheckinTime': actualCheckinTime?.toIso8601String(),
        'status': status,
        'hasNoShowBadge': hasNoShowBadge,
        'depositAmount': depositAmount,
      };

  BookingHistoryEntity toEntity() => BookingHistoryEntity(
        id: id,
        cafeName: cafeName,
        gameName: gameName,
        scheduledTime: scheduledTime,
        actualCheckinTime: actualCheckinTime,
        status: _statusFromString(status),
        hasNoShowBadge: hasNoShowBadge,
        depositAmount: depositAmount,
      );

  static BookingHistoryStatus _statusFromString(String s) =>
      BookingHistoryStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => BookingHistoryStatus.upcoming,
      );
}