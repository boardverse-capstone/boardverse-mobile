import 'package:equatable/equatable.dart';

import '../enums/booking_status.dart';

/// Booking rút gọn cho Player khi gọi `GET /api/bookings/cafe/{cafeId}`
/// (xem `.agents/docs/apis_docs/booking.md` §231-253 — gap #14).
///
/// Player view chỉ trả summary fields, KHÔNG lộ `verificationQRCode`,
/// `paymentRef`, `memberIds` (bảo mật).
class CafeBookingSummaryEntity extends Equatable {
  final String id;
  final DateTime scheduledStartTime;
  final DateTime scheduleEndTime;
  final int playerQuantity;
  final BookingStatus status;

  const CafeBookingSummaryEntity({
    required this.id,
    required this.scheduledStartTime,
    required this.scheduleEndTime,
    required this.playerQuantity,
    required this.status,
  });

  @override
  List<Object?> get props => [
        id,
        scheduledStartTime,
        scheduleEndTime,
        playerQuantity,
        status,
      ];
}
