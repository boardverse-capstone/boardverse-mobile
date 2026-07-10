import 'package:equatable/equatable.dart';

/// Một dòng trong lịch sử đặt chỗ của người chơi.
///
/// `noShow` cho biết user không đến quán sau khi đã CONFIRMED —
/// dùng để hiển thị badge cảnh báo ở `BookingHistoryPage`.
class BookingHistoryEntity extends Equatable {
  final String id;
  final String cafeName;
  final String gameName;
  final DateTime scheduledTime;
  final DateTime? actualCheckinTime;
  final BookingHistoryStatus status;
  final bool hasNoShowBadge;
  final double depositAmount;

  const BookingHistoryEntity({
    required this.id,
    required this.cafeName,
    required this.gameName,
    required this.scheduledTime,
    this.actualCheckinTime,
    required this.status,
    this.hasNoShowBadge = false,
    required this.depositAmount,
  });

  @override
  List<Object?> get props => [
        id,
        cafeName,
        gameName,
        scheduledTime,
        actualCheckinTime,
        status,
        hasNoShowBadge,
        depositAmount,
      ];
}

enum BookingHistoryStatus {
  /// Sắp tới / đang chờ thanh toán cọc.
  upcoming,

  /// Đã check-in tại quán, đang chơi hoặc đã chơi xong.
  completed,

  /// Đã hủy (bởi Player hoặc Cafe).
  cancelled,

  /// Đã đặt cọc nhưng không đến check-in.
  noShow,
}