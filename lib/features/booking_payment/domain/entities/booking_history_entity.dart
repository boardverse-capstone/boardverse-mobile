import 'package:equatable/equatable.dart';

import '../enums/booking_status.dart';

/// Một dòng trong lịch sử đặt chỗ của người chơi.
///
/// Suy ra từ `BookingEntity` ở tầng data bằng cách lọc theo
/// [BookingStatus] thay vì gọi endpoint riêng (backend mới không có
/// `GET /api/bookings/history` cho Player).
class BookingHistoryEntity extends Equatable {
  final String id;

  /// FK → Lobby. Null cho walk-in booking (gap #3).
  final String? lobbyId;
  final String cafeId;
  final String cafeName;
  final String gameName;
  final DateTime scheduledTime;
  final DateTime scheduleEndTime;
  final BookingStatus status;
  final double depositAmount;
  final String? verificationQrCode;

  const BookingHistoryEntity({
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

  @override
  List<Object?> get props => [
        id,
        lobbyId,
        cafeId,
        cafeName,
        gameName,
        scheduledTime,
        scheduleEndTime,
        status,
        depositAmount,
        verificationQrCode,
      ];
}

/// Bucket hiển thị trong UI tổng hợp (LobbyHistoryTab, BookingHistoryPage).
enum BookingHistoryStatus {
  /// Sắp tới / đang chờ thanh toán cọc / đã cọc chờ check-in.
  upcoming,

  /// Đã check-in tại quán, đang chơi hoặc đã chơi xong.
  completed,

  /// Đã hủy (bởi Player hoặc Manager).
  cancelled,

  /// Đã đặt cọc nhưng không đến check-in.
  noShow,
}

/// Helper ánh xạ [BookingStatus] → [BookingHistoryStatus] dùng cho UI.
extension BookingStatusToHistoryX on BookingStatus {
  BookingHistoryStatus get historyBucket {
    switch (this) {
      case BookingStatus.pendingDeposit:
      case BookingStatus.confirmed:
        return BookingHistoryStatus.upcoming;
      case BookingStatus.checkedIn:
        return BookingHistoryStatus.completed;
      case BookingStatus.noShow:
        return BookingHistoryStatus.noShow;
      case BookingStatus.cancelled:
        return BookingHistoryStatus.cancelled;
    }
  }
}
