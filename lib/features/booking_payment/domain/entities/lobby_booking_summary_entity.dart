import 'package:equatable/equatable.dart';

/// Tóm tắt lobby + booking (nếu có) cho player.
///
/// Khi `bookingId != null` nghĩa là lobby đã có booking kèm theo
/// (luồng A — backend auto-create). Khi đó flow tiếp theo của mobile
/// là gọi `POST /api/payments/booking-deposit` thay vì tạo booking mới.
class LobbyBookingSummaryEntity extends Equatable {
  final String lobbyId;
  final String? bookingId;
  final bool walkInAvailable;

  const LobbyBookingSummaryEntity({
    required this.lobbyId,
    this.bookingId,
    this.walkInAvailable = false,
  });

  bool get hasBooking => bookingId != null && bookingId!.isNotEmpty;

  @override
  List<Object?> get props => [lobbyId, bookingId, walkInAvailable];
}
