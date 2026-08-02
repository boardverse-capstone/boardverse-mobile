import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/deposit_status_entity.dart';
import '../../domain/entities/lobby_summary_entity.dart';
import '../../domain/enums/booking_status.dart';

/// JSON ↔ Entity cho `BookingEntity` theo `BookingResponseDto`.
///
/// Backend bọc data trong envelope `ApiResponse<T>`:
/// ```json
/// {
///   "statusCode": 201,
///   "message": "Booking created",
///   "data": {
///     "id": "BV-0001",
///     "lobbyId": "L-1",
///     "cafeId": "C-1",
///     ...
///   }
/// }
/// ```
///
/// `BookingModel` luôn parse từ `data` (vì datasrc đã unwrap envelope
/// qua `ApiResponse.fromJson`).
class BookingModel {
  final String id;
  final String? lobbyId;
  final String cafeId;
  final String cafeName;
  final String cafeTableId;
  final String? cafeTableName;
  final String gameId;
  final String gameName;
  final DateTime scheduledTime;
  final DateTime scheduleEndTime;
  final int seatCount;
  final int playerQuantity;
  final List<String> memberIds;
  final String hostId;
  final int statusInt;
  final String? statusText;
  final double depositAmount;
  final DateTime depositDeadline;
  final String? paymentRef;
  final String verificationQrCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Fields mới (booking.md §179, gap #10)
  final DateTime? checkedInAt;
  final String? checkedInByUserId;
  final LobbySummaryEntity? lobbySummary;

  // Fields refund (gap #11)
  final DepositStatus? depositRefundStatus;
  final double? depositRefundAmount;

  // Fields walk-in (gap #3)
  final bool isWalkIn;
  final String? bookingGroupCode;

  const BookingModel({
    required this.id,
    this.lobbyId,
    required this.cafeId,
    required this.cafeName,
    required this.cafeTableId,
    this.cafeTableName,
    required this.gameId,
    required this.gameName,
    required this.scheduledTime,
    required this.scheduleEndTime,
    required this.seatCount,
    required this.playerQuantity,
    required this.memberIds,
    required this.hostId,
    required this.statusInt,
    this.statusText,
    required this.depositAmount,
    required this.depositDeadline,
    this.paymentRef,
    required this.verificationQrCode,
    required this.createdAt,
    required this.updatedAt,
    this.checkedInAt,
    this.checkedInByUserId,
    this.lobbySummary,
    this.depositRefundStatus,
    this.depositRefundAmount,
    this.isWalkIn = false,
    this.bookingGroupCode,
  });

  /// Parse từ `data` của `ApiResponse.data` (object thuần).
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      lobbyId: json['lobbyId'] as String?,
      cafeId: json['cafeId'] as String,
      cafeName: json['cafeName'] as String? ?? '',
      cafeTableId: json['cafeTableId'] as String? ?? '',
      cafeTableName: json['cafeTableName'] as String?,
      gameId: json['gameId'] as String? ?? '',
      gameName: json['gameName'] as String? ?? '',
      scheduledTime: _parseDate(json['scheduledStartTime']) ??
          _parseDate(json['scheduledTime'])!,
      scheduleEndTime: _parseDate(json['scheduleEndTime'])!,
      seatCount: (json['seatCount'] as num).toInt(),
      playerQuantity: (json['playerQuantity'] as num?)?.toInt() ??
          (json['seatCount'] as num).toInt(),
      memberIds: (json['memberIds'] as List?)?.cast<String>() ?? const [],
      hostId: json['hostId'] as String? ?? '',
      statusInt: (json['status'] as num).toInt(),
      statusText: json['statusText'] as String?,
      depositAmount: (json['depositAmount'] as num).toDouble(),
      depositDeadline: _parseDate(json['depositDeadline'])!,
      paymentRef: json['paymentRef'] as String?,
      verificationQrCode: json['verificationQRCode'] as String? ??
          json['verificationQrCode'] as String? ??
          '',
      createdAt: _parseDate(json['createdAt'])!,
      updatedAt: _parseDate(json['updatedAt'])!,
      checkedInAt: _parseDate(json['checkedInAt']),
      checkedInByUserId: json['checkedInByUserId'] as String?,
      lobbySummary: _parseLobbySummary(json['lobbySummary']),
      depositRefundStatus: _parseDepositStatus(json['depositRefundStatus']),
      depositRefundAmount: (json['depositRefundAmount'] as num?)?.toDouble(),
      isWalkIn: json['isWalkIn'] as bool? ?? false,
      bookingGroupCode: json['bookingGroupCode'] as String?,
    );
  }

  static LobbySummaryEntity? _parseLobbySummary(dynamic raw) {
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();
    return LobbySummaryEntity(
      id: map['id'] as String?,
      hostId: map['hostId'] as String? ?? '',
      gameId: map['gameId'] as String? ?? '',
      gameName: map['gameName'] as String? ?? '',
      currentMembers: (map['currentMembers'] as num?)?.toInt() ?? 0,
      maxMembers: (map['maxMembers'] as num?)?.toInt() ?? 0,
      memberIds: (map['memberIds'] as List?)?.cast<String>() ?? const [],
    );
  }

  static DepositStatus? _parseDepositStatus(dynamic raw) {
    if (raw is String) {
      switch (raw) {
        case 'Pending':
          return DepositStatus.pending;
        case 'Paid':
          return DepositStatus.paid;
        case 'Refunded':
          return DepositStatus.refunded;
        case 'Forfeited':
          return DepositStatus.forfeited;
        case 'Expired':
          return DepositStatus.expired;
      }
    } else if (raw is num) {
      switch (raw.toInt()) {
        case 0:
          return DepositStatus.pending;
        case 1:
          return DepositStatus.paid;
        case 2:
          return DepositStatus.refunded;
        case 3:
          return DepositStatus.forfeited;
        case 4:
          return DepositStatus.expired;
      }
    }
    return null;
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toLocal();
    if (raw is String) return DateTime.parse(raw).toLocal();
    return null;
  }

  /// Map sang `BookingStatus` — ưu tiên `statusText`, fallback `statusInt`.
  BookingStatus get status {
    final fromText = BookingStatusX.fromStatusText(statusText);
    if (fromText != null) return fromText;
    final fromInt = BookingStatusX.fromInt(statusInt);
    if (fromInt != null) return fromInt;
    return BookingStatus.pendingDeposit;
  }

  BookingEntity toEntity() => BookingEntity(
        id: id,
        lobbyId: lobbyId,
        cafeId: cafeId,
        cafeName: cafeName,
        cafeTableId: cafeTableId,
        cafeTableName: cafeTableName,
        gameId: gameId,
        gameName: gameName,
        scheduledTime: scheduledTime,
        scheduleEndTime: scheduleEndTime,
        seatCount: seatCount,
        playerQuantity: playerQuantity,
        memberIds: memberIds,
        hostId: hostId,
        status: status,
        depositAmount: depositAmount,
        depositDeadline: depositDeadline,
        paymentRef: paymentRef,
        verificationQrCode: verificationQrCode,
        createdAt: createdAt,
        updatedAt: updatedAt,
        checkedInAt: checkedInAt,
        checkedInByUserId: checkedInByUserId,
        lobbySummary: lobbySummary,
        depositRefundStatus: depositRefundStatus,
        depositRefundAmount: depositRefundAmount,
        isWalkIn: isWalkIn,
        bookingGroupCode: bookingGroupCode,
      );
}
