import '../../domain/entities/entities.dart';

/// Data model cho Quote API response
class ReservationQuoteModel extends ReservationQuoteEntity {
  const ReservationQuoteModel({
    super.reservationId,
    required super.cafeId,
    required super.cafeName,
    required super.gameId,
    required super.gameName,
    required super.playDate,
    required super.timeSlot,
    super.preferredStartTime,
    super.preferredEndTime,
    required super.scheduledStartTime,
    required super.scheduledEndTime,
    required super.recruitmentDeadline,
    required super.minPlayers,
    required super.maxPlayers,
    required super.depositRatePerPerson,
    required super.baseDeposit,
    required super.riskMultiplier,
    required super.minDepositApplied,
    required super.finalDeposit,
    required super.currentBalance,
    required super.missingAmount,
    required super.bufferMinutes,
    required super.bufferWarning,
    super.isPrivate,
    required super.requiresCafeApproval,
    required super.expiresAt,
    required super.warnings,
    super.riskLevel,
  });

  factory ReservationQuoteModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return ReservationQuoteModel(
      reservationId: data['reservationId'] as String?,
      cafeId: data['cafeId'] as String? ?? '',
      cafeName: data['cafeName'] as String? ?? '',
      gameId: data['gameId'] as String? ?? '',
      gameName: data['gameName'] as String? ?? '',
      playDate: DateTime.tryParse(data['playDate'] as String? ?? '') ?? DateTime.now(),
      timeSlot: TimeSlot.fromString(data['timeSlot'] as String? ?? 'morning'),
      preferredStartTime: data['preferredStartTime'] as String?,
      preferredEndTime: data['preferredEndTime'] as String?,
      scheduledStartTime: DateTime.tryParse(
              data['scheduledStartTime'] as String? ?? '') ??
          DateTime.now(),
      scheduledEndTime: DateTime.tryParse(
              data['scheduledEndTime'] as String? ?? '') ??
          DateTime.now().add(const Duration(hours: 4)),
      recruitmentDeadline:
          DateTime.tryParse(data['recruitmentDeadline'] as String? ?? '') ?? DateTime.now(),
      minPlayers: data['minPlayers'] as int? ?? 2,
      maxPlayers: data['maxPlayers'] as int? ?? 4,
      depositRatePerPerson: data['depositRatePerPerson'] as int? ?? 0,
      baseDeposit: data['baseDeposit'] as int? ?? 0,
      riskMultiplier:
          (data['riskMultiplier'] as num?)?.toDouble() ?? 1.0,
      minDepositApplied: data['minDepositApplied'] as int? ?? 0,
      finalDeposit: data['finalDeposit'] as int? ?? 0,
      currentBalance: data['currentBalance'] as int? ?? 0,
      missingAmount: data['missingAmount'] as int? ?? 0,
      bufferMinutes: data['bufferMinutes'] as int? ?? 0,
      bufferWarning: data['bufferWarning'] as bool? ?? false,
      isPrivate: data['isPrivate'] as bool? ?? false,
      requiresCafeApproval: data['requiresCafeApproval'] as bool? ?? false,
      expiresAt: DateTime.tryParse(data['expiresAt'] as String? ?? '') ??
          DateTime.now().add(const Duration(minutes: 5)),
      warnings: (data['warnings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      riskLevel: data['riskLevel'] is String
          ? RiskLevel.fromString(data['riskLevel'] as String)
          : RiskLevel.low,
    );
  }
}

/// Request model cho Quote API
///
/// BR-NEW-15 (2026-08-18): Backend đã BỎ `timeSlot` khỏi request body của
/// `POST /api/v1/reservations/quote`. Thay vào đó FE phải gửi
/// `preferredStartTime` + `preferredEndTime` (cả 2 REQUIRED theo
/// `ReservationQuoteRequestDto` trong swagger.json).
///
/// Schema backend (swagger.json `ReservationQuoteRequestDto` line 27806):
/// ```json
/// {
///   "cafeId": "guid",
///   "gameId": "guid",
///   "playDate": "YYYY-MM-DD",
///   "preferredStartTime": "HH:mm:ss",
///   "preferredEndTime": "HH:mm:ss",
///   "minPlayers": 4,
///   "maxPlayers": 6,
///   "isPrivate": false,
///   "idempotencyKey": "..."
/// }
/// ```
class QuoteRequestModel {
  final String cafeId;
  final String gameId;
  final DateTime playDate;

  /// REQUIRED (BR-NEW-15) — giờ bắt đầu dự kiến (HH:mm:ss).
  final String preferredStartTime;

  /// REQUIRED (BR-NEW-15) — giờ kết thúc dự kiến (HH:mm:ss).
  final String preferredEndTime;
  final int minPlayers;
  final int maxPlayers;
  final bool isPrivate;
  final String idempotencyKey;

  const QuoteRequestModel({
    required this.cafeId,
    required this.gameId,
    required this.playDate,
    required this.preferredStartTime,
    required this.preferredEndTime,
    required this.minPlayers,
    required this.maxPlayers,
    this.isPrivate = false,
    required this.idempotencyKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'cafeId': cafeId,
      'gameId': gameId,
      'playDate': playDate.toIso8601String().split('T')[0],
      // BR-NEW-15: backend không còn `timeSlot` trong quote request —
      // dùng `preferredStartTime`/`preferredEndTime` (HH:mm:ss) để xác
      // định giờ chơi cụ thể. Server tự resolve TimeSlot từ cặp giờ này
      // và xác định scheduledStartTime/EndTime cho reservation.
      'preferredStartTime': preferredStartTime,
      'preferredEndTime': preferredEndTime,
      'minPlayers': minPlayers,
      'maxPlayers': maxPlayers,
      'isPrivate': isPrivate,
      'idempotencyKey': idempotencyKey,
    };
  }
}

/// Response model cho Confirm API
class ReservationConfirmResultModel extends ReservationConfirmResult {
  const ReservationConfirmResultModel({
    required super.reservationId,
    required super.lobbyId,
    super.lobbyShareCode,
    required super.recruitmentDeadline,
    required super.requiresCafeApproval,
    super.cafeApprovalDeadline,
    required super.heldBvc,
  });

  factory ReservationConfirmResultModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return ReservationConfirmResultModel(
      reservationId: data['reservationId'] as String? ?? '',
      lobbyId: data['lobbyId'] as String? ?? '',
      lobbyShareCode:
          (data['lobbyShareCode'] ?? data['shareCode']) as String?,
      recruitmentDeadline:
          DateTime.tryParse(data['recruitmentDeadline'] as String? ?? '') ?? DateTime.now(),
      requiresCafeApproval: data['requiresCafeApproval'] as bool? ?? false,
      cafeApprovalDeadline: data['cafeApprovalDeadline'] != null
          ? DateTime.tryParse(data['cafeApprovalDeadline'] as String)
          : null,
      heldBvc: data['heldBvc'] as int? ?? 0,
    );
  }
}

/// Request model cho Confirm API
///
/// BR-NEW-15 (2026-08-18): Backend đã BỎ `timeSlot` khỏi request body.
/// Confirm chỉ cần `cafeId`/`gameId`/`playDate` + `preferredStartTime`/
/// `preferredEndTime`/`maxPlayers`/`minPlayers`/`expectedFinalDeposit`/
/// `idempotencyKey` (xem swagger.json `ReservationConfirmRequestDto`
/// line 27747). Server đã biết TimeSlot từ quote trước đó, confirm chỉ
/// verify params khớp + tạo reservation/lobby.
class ConfirmRequestModel {
  final String cafeId;
  final String gameId;
  final DateTime playDate;

  /// REQUIRED (BR-NEW-15) — phải khớp với `preferredStartTime` từ quote.
  final String preferredStartTime;

  /// REQUIRED (BR-NEW-15) — phải khớp với `preferredEndTime` từ quote.
  final String preferredEndTime;
  final int minPlayers;
  final int maxPlayers;
  final bool isPrivate;
  final int expectedFinalDeposit;
  final String idempotencyKey;

  const ConfirmRequestModel({
    required this.cafeId,
    required this.gameId,
    required this.playDate,
    required this.preferredStartTime,
    required this.preferredEndTime,
    required this.minPlayers,
    required this.maxPlayers,
    this.isPrivate = false,
    required this.expectedFinalDeposit,
    required this.idempotencyKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'cafeId': cafeId,
      'gameId': gameId,
      'playDate': playDate.toIso8601String().split('T')[0],
      // BR-NEW-15: backend không còn `timeSlot` trong confirm request.
      // Server tự suy ra từ quote fingerprint đã cache trong confirm session.
      'preferredStartTime': preferredStartTime,
      'preferredEndTime': preferredEndTime,
      'minPlayers': minPlayers,
      'maxPlayers': maxPlayers,
      'isPrivate': isPrivate,
      'expectedFinalDeposit': expectedFinalDeposit,
      'idempotencyKey': idempotencyKey,
    };
  }
}

/// Response model cho Cancel API
class ReservationCancelResultModel extends ReservationCancelResult {
  const ReservationCancelResultModel({
    required super.reservationId,
    required super.lobbyId,
    required super.refundBvc,
    required super.forfeitBvc,
    required super.refundPolicyApplied,
  });

  factory ReservationCancelResultModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return ReservationCancelResultModel(
      reservationId: data['reservationId'] as String? ?? '',
      lobbyId: data['lobbyId'] as String? ?? '',
      refundBvc: data['refundBvc'] as int? ?? 0,
      forfeitBvc: data['forfeitBvc'] as int? ?? 0,
      refundPolicyApplied: data['refundPolicyApplied'] as String? ?? '',
    );
  }
}

/// Request model cho Cafe Approval API
class CafeApprovalRequestModel {
  final bool approve;
  final String? reason;

  const CafeApprovalRequestModel({
    required this.approve,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'approve': approve,
      'reason': reason,
    };
  }
}

/// Model cho cancel-after-checkin result
class ReservationCancelAfterCheckinResultModel
    extends ReservationCancelAfterCheckinResult {
  const ReservationCancelAfterCheckinResultModel({
    required super.reservationId,
    required super.previousStatus,
    required super.newStatus,
    required super.playDurationMinutes,
    required super.playedRatio,
    required super.refundBvc,
    required super.forfeitBvc,
    required super.refundReason,
    required super.cancellationType,
    required super.cancelledAt,
  });

  factory ReservationCancelAfterCheckinResultModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return ReservationCancelAfterCheckinResultModel(
      reservationId: data['reservationId'] as String? ?? '',
      previousStatus: data['previousStatus'] as String? ?? '',
      newStatus: data['newStatus'] as String? ?? '',
      playDurationMinutes: data['playDurationMinutes'] as int? ?? 0,
      playedRatio: (data['playedRatio'] as num?)?.toDouble() ?? 0.0,
      refundBvc: data['refundBvc'] as int? ?? 0,
      forfeitBvc: data['forfeitBvc'] as int? ?? 0,
      refundReason: data['refundReason'] as String? ?? '',
      cancellationType: data['cancellationType'] as String? ?? '',
      cancelledAt: DateTime.tryParse(data['cancelledAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Model cho extend availability result
class ExtendAvailabilityResultModel extends ExtendAvailabilityResult {
  const ExtendAvailabilityResultModel({
    required super.reservationId,
    required super.currentScheduledEndTime,
    required super.requestedExtensionMinutes,
    required super.newScheduledEndTime,
    required super.isAvailable,
    required super.remainingExtensionMinutes,
    required super.extensionCount,
    required super.maxExtensionMinutes,
    super.reason,
  });

  factory ExtendAvailabilityResultModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return ExtendAvailabilityResultModel(
      reservationId: data['reservationId'] as String? ?? '',
      currentScheduledEndTime: DateTime.tryParse(
        data['currentScheduledEndTime'] as String? ?? '',
      ) ?? DateTime.now(),
      requestedExtensionMinutes:
          data['requestedExtensionMinutes'] as int? ?? 0,
      newScheduledEndTime: DateTime.tryParse(
        data['newScheduledEndTime'] as String? ?? '',
      ) ?? DateTime.now(),
      isAvailable: data['isAvailable'] as bool? ?? false,
      remainingExtensionMinutes:
          data['remainingExtensionMinutes'] as int? ?? 0,
      extensionCount: data['extensionCount'] as int? ?? 0,
      maxExtensionMinutes: data['maxExtensionMinutes'] as int? ?? 120,
      reason: data['reason'] as String?,
    );
  }
}

/// Model cho check-in by code result
class CheckInByCodeResultModel extends CheckInByCodeResult {
  const CheckInByCodeResultModel({
    required super.reservationId,
    required super.lobbyId,
    required super.activeSessionId,
    required super.reservationStatus,
    required super.lobbyStatus,
    required super.checkedInAt,
    required super.heldBvc,
  });

  factory CheckInByCodeResultModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return CheckInByCodeResultModel(
      reservationId: data['reservationId'] as String? ?? '',
      lobbyId: data['lobbyId'] as String? ?? '',
      activeSessionId: data['activeSessionId'] as String? ?? '',
      reservationStatus: data['reservationStatus'] as String? ?? '',
      lobbyStatus: data['lobbyStatus'] as String? ?? '',
      checkedInAt: DateTime.tryParse(
        data['checkedInAt'] as String? ?? '',
      ) ?? DateTime.now(),
      heldBvc: data['heldBvc'] as int? ?? 0,
    );
  }
}
