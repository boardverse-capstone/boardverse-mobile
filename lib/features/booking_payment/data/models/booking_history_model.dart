import '../../domain/entities/booking_history_entity.dart';
import '../../domain/enums/booking_status.dart';

/// JSON ↔ Entity cho `BookingHistoryEntity`.
///
/// Backend mới không còn `GET /api/bookings/history` — ta build thủ công
/// từ `BookingEntity` ở tầng repository. Model này giữ để tương thích
/// nếu backend mở lại endpoint và cần parse trực tiếp.
class BookingHistoryModel {
  final String id;
  final String? lobbyId;
  final String cafeId;
  final String cafeName;
  final String gameName;
  final DateTime scheduledTime;
  final DateTime scheduleEndTime;
  final String status;
  final double depositAmount;
  final String? verificationQrCode;

  const BookingHistoryModel({
    required this.id,
    this.lobbyId,
    required this.cafeId,
    required this.cafeName,
    required this.gameName,
    required this.scheduledTime,
    required this.scheduleEndTime,
    required this.status,
    required this.depositAmount,
    this.verificationQrCode,
  });

  factory BookingHistoryModel.fromJson(Map<String, dynamic> json) {
    return BookingHistoryModel(
      id: json['id'] as String,
      lobbyId: json['lobbyId'] as String?,
      cafeId: json['cafeId'] as String,
      cafeName: json['cafeName'] as String? ?? '',
      gameName: json['gameName'] as String? ?? '',
      scheduledTime: DateTime.parse(json['scheduledStartTime'] as String? ??
              json['scheduledTime'] as String)
          .toLocal(),
      scheduleEndTime: DateTime.parse(
        json['scheduleEndTime'] as String? ?? json['scheduledTime'] as String,
      ).toLocal(),
      status: json['status'] as String? ?? 'PendingDeposit',
      depositAmount: (json['depositAmount'] as num).toDouble(),
      verificationQrCode: json['verificationQRCode'] as String?,
    );
  }

  BookingHistoryEntity toEntity() => BookingHistoryEntity(
        id: id,
        lobbyId: lobbyId,
        cafeId: cafeId,
        cafeName: cafeName,
        gameName: gameName,
        scheduledTime: scheduledTime,
        scheduleEndTime: scheduleEndTime,
        status: _statusFromString(status),
        depositAmount: depositAmount,
        verificationQrCode: verificationQrCode,
      );

  static BookingStatus _statusFromString(String s) {
    switch (s) {
      case 'Confirmed':
      case 'CheckedIn':
        return BookingStatus.checkedIn;
      case 'Cancelled':
        return BookingStatus.cancelled;
      case 'NoShow':
        return BookingStatus.noShow;
      default:
        return BookingStatus.pendingDeposit;
    }
  }
}
