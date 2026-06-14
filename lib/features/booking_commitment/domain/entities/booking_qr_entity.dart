import 'package:equatable/equatable.dart';

class BookingQrEntity extends Equatable {
  final String bookingId;
  final String cafeName;
  final String gameName;
  final DateTime scheduledTime;
  final int tableNumber;
  final String playerNames;
  final String qrPayload;

  const BookingQrEntity({
    required this.bookingId,
    required this.cafeName,
    required this.gameName,
    required this.scheduledTime,
    required this.tableNumber,
    required this.playerNames,
    required this.qrPayload,
  });

  @override
  List<Object?> get props => [
        bookingId,
        cafeName,
        gameName,
        scheduledTime,
        tableNumber,
        playerNames,
        qrPayload,
      ];
}

class BookingHistoryEntity extends Equatable {
  final String id;
  final String cafeName;
  final String gameName;
  final DateTime scheduledTime;
  final DateTime? actualCheckinTime;
  final BookingHistoryStatus status;
  final bool hasNoShowBadge;

  const BookingHistoryEntity({
    required this.id,
    required this.cafeName,
    required this.gameName,
    required this.scheduledTime,
    this.actualCheckinTime,
    required this.status,
    required this.hasNoShowBadge,
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
      ];
}

enum BookingHistoryStatus {
  completed,
  cancelled,
  noShow,
  pending,
}
