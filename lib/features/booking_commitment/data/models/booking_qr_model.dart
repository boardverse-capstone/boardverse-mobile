import '../../domain/entities/booking_qr_entity.dart';

enum BookingHistoryStatusModel {
  completed,
  cancelled,
  noShow,
  pending,
}

class BookingQrModel {
  final String bookingId;
  final String cafeName;
  final String gameName;
  final DateTime scheduledTime;
  final int tableNumber;
  final String playerNames;
  final String qrPayload;

  const BookingQrModel({
    required this.bookingId,
    required this.cafeName,
    required this.gameName,
    required this.scheduledTime,
    required this.tableNumber,
    required this.playerNames,
    required this.qrPayload,
  });

  factory BookingQrModel.fromJson(Map<String, dynamic> json) {
    return BookingQrModel(
      bookingId: json['bookingId'] as String,
      cafeName: json['cafeName'] as String,
      gameName: json['gameName'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      tableNumber: json['tableNumber'] as int,
      playerNames: json['playerNames'] as String,
      qrPayload: json['qrPayload'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'cafeName': cafeName,
      'gameName': gameName,
      'scheduledTime': scheduledTime.toIso8601String(),
      'tableNumber': tableNumber,
      'playerNames': playerNames,
      'qrPayload': qrPayload,
    };
  }

  BookingQrEntity toEntity() => BookingQrEntity(
        bookingId: bookingId,
        cafeName: cafeName,
        gameName: gameName,
        scheduledTime: scheduledTime,
        tableNumber: tableNumber,
        playerNames: playerNames,
        qrPayload: qrPayload,
      );
}

class BookingHistoryModel {
  final String id;
  final String cafeName;
  final String gameName;
  final DateTime scheduledTime;
  final DateTime? actualCheckinTime;
  final BookingHistoryStatusModel status;
  final bool hasNoShowBadge;

  const BookingHistoryModel({
    required this.id,
    required this.cafeName,
    required this.gameName,
    required this.scheduledTime,
    this.actualCheckinTime,
    required this.status,
    this.hasNoShowBadge = false,
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
      status: BookingHistoryStatusModel.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingHistoryStatusModel.pending,
      ),
      hasNoShowBadge: json['hasNoShowBadge'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cafeName': cafeName,
      'gameName': gameName,
      'scheduledTime': scheduledTime.toIso8601String(),
      'actualCheckinTime': actualCheckinTime?.toIso8601String(),
      'status': status.name,
      'hasNoShowBadge': hasNoShowBadge,
    };
  }

  BookingHistoryEntity toEntity() => BookingHistoryEntity(
        id: id,
        cafeName: cafeName,
        gameName: gameName,
        scheduledTime: scheduledTime,
        actualCheckinTime: actualCheckinTime,
        status: _statusToEntity(status),
        hasNoShowBadge: hasNoShowBadge,
      );

  static BookingHistoryStatus _statusToEntity(BookingHistoryStatusModel status) {
    switch (status) {
      case BookingHistoryStatusModel.completed:
        return BookingHistoryStatus.completed;
      case BookingHistoryStatusModel.cancelled:
        return BookingHistoryStatus.cancelled;
      case BookingHistoryStatusModel.noShow:
        return BookingHistoryStatus.noShow;
      case BookingHistoryStatusModel.pending:
        return BookingHistoryStatus.pending;
    }
  }
}
