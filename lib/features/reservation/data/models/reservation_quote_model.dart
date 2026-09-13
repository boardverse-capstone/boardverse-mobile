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

    // Helper: cast sang String, fallback về null. Handle int → String.
    String? strOpt(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      return value.toString();
    }

    // Helper: cast sang String, fallback về empty string.
    String str(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    return ReservationQuoteModel(
      reservationId: strOpt(data['reservationId']),
      cafeId: str(data['cafeId']),
      cafeName: str(data['cafeName']),
      gameId: str(data['gameId']),
      gameName: str(data['gameName']),
      playDate: DateTime.tryParse(strOpt(data['playDate']) ?? '') ?? DateTime.now(),
      timeSlot: TimeSlot.fromString(strOpt(data['timeSlot']) ?? 'morning'),
      preferredStartTime: strOpt(data['preferredStartTime']),
      preferredEndTime: strOpt(data['preferredEndTime']),
      scheduledStartTime: DateTime.tryParse(
              strOpt(data['scheduledStartTime']) ?? '') ??
          DateTime.now(),
      scheduledEndTime: DateTime.tryParse(
              strOpt(data['scheduledEndTime']) ?? '') ??
          DateTime.now().add(const Duration(hours: 4)),
      recruitmentDeadline:
          DateTime.tryParse(strOpt(data['recruitmentDeadline']) ?? '') ?? DateTime.now(),
      minPlayers: (data['minPlayers'] as num?)?.toInt() ?? 2,
      maxPlayers: (data['maxPlayers'] as num?)?.toInt() ?? 4,
      depositRatePerPerson: (data['depositRatePerPerson'] as num?)?.toInt() ?? 0,
      baseDeposit: (data['baseDeposit'] as num?)?.toInt() ?? 0,
      riskMultiplier:
          (data['riskMultiplier'] as num?)?.toDouble() ?? 1.0,
      minDepositApplied: (data['minDepositApplied'] as num?)?.toInt() ?? 0,
      finalDeposit: (data['finalDeposit'] as num?)?.toInt() ?? 0,
      currentBalance: (data['currentBalance'] as num?)?.toInt() ?? 0,
      missingAmount: (data['missingAmount'] as num?)?.toInt() ?? 0,
      bufferMinutes: (data['bufferMinutes'] as num?)?.toInt() ?? 0,
      bufferWarning: data['bufferWarning'] as bool? ?? false,
      isPrivate: data['isPrivate'] as bool? ?? false,
      requiresCafeApproval: data['requiresCafeApproval'] as bool? ?? false,
      expiresAt: DateTime.tryParse(strOpt(data['expiresAt']) ?? '') ??
          DateTime.now().add(const Duration(minutes: 5)),
      warnings: (data['warnings'] as List<dynamic>?)
              ?.map((e) => e is String ? e : e.toString())
              .toList() ??
          [],
      riskLevel: strOpt(data['riskLevel']) != null
          ? RiskLevel.fromString(strOpt(data['riskLevel'])!)
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

    // Helper: cast sang String, fallback về null. Handle int → String.
    String? strOpt(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      return value.toString();
    }

    return ReservationConfirmResultModel(
      reservationId: strOpt(data['reservationId']) ?? '',
      lobbyId: strOpt(data['lobbyId']) ?? '',
      lobbyShareCode:
          strOpt(data['lobbyShareCode']) ?? strOpt(data['shareCode']),
      recruitmentDeadline:
          DateTime.tryParse(strOpt(data['recruitmentDeadline']) ?? '') ?? DateTime.now(),
      requiresCafeApproval: data['requiresCafeApproval'] as bool? ?? false,
      cafeApprovalDeadline: data['cafeApprovalDeadline'] != null
          ? DateTime.tryParse(strOpt(data['cafeApprovalDeadline'])!)
          : null,
      heldBvc: (data['heldBvc'] as num?)?.toInt() ?? 0,
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

    // Helper: cast sang String, fallback về null.
    String? strOpt(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      return value.toString();
    }

    return ReservationCancelResultModel(
      reservationId: strOpt(data['reservationId']) ?? '',
      lobbyId: strOpt(data['lobbyId']) ?? '',
      refundBvc: (data['refundBvc'] as num?)?.toInt() ?? 0,
      forfeitBvc: (data['forfeitBvc'] as num?)?.toInt() ?? 0,
      refundPolicyApplied: strOpt(data['refundPolicyApplied']) ?? '',
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

    // Helper: cast sang String, fallback về null.
    String? strOpt(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      return value.toString();
    }

    return ReservationCancelAfterCheckinResultModel(
      reservationId: strOpt(data['reservationId']) ?? '',
      previousStatus: strOpt(data['previousStatus']) ?? '',
      newStatus: strOpt(data['newStatus']) ?? '',
      playDurationMinutes: (data['playDurationMinutes'] as num?)?.toInt() ?? 0,
      playedRatio: (data['playedRatio'] as num?)?.toDouble() ?? 0.0,
      refundBvc: (data['refundBvc'] as num?)?.toInt() ?? 0,
      forfeitBvc: (data['forfeitBvc'] as num?)?.toInt() ?? 0,
      refundReason: strOpt(data['refundReason']) ?? '',
      cancellationType: strOpt(data['cancellationType']) ?? '',
      cancelledAt: DateTime.tryParse(strOpt(data['cancelledAt']) ?? '') ??
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

    // Helper: cast sang String, fallback về null.
    String? strOpt(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      return value.toString();
    }

    return ExtendAvailabilityResultModel(
      reservationId: strOpt(data['reservationId']) ?? '',
      currentScheduledEndTime: DateTime.tryParse(
        strOpt(data['currentScheduledEndTime']) ?? '',
      ) ?? DateTime.now(),
      requestedExtensionMinutes:
          (data['requestedExtensionMinutes'] as num?)?.toInt() ?? 0,
      newScheduledEndTime: DateTime.tryParse(
        strOpt(data['newScheduledEndTime']) ?? '',
      ) ?? DateTime.now(),
      isAvailable: data['isAvailable'] as bool? ?? false,
      remainingExtensionMinutes:
          (data['remainingExtensionMinutes'] as num?)?.toInt() ?? 0,
      extensionCount: (data['extensionCount'] as num?)?.toInt() ?? 0,
      maxExtensionMinutes: (data['maxExtensionMinutes'] as num?)?.toInt() ?? 120,
      reason: strOpt(data['reason']),
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

    // Helper: cast sang String, fallback về null.
    String? strOpt(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      return value.toString();
    }

    return CheckInByCodeResultModel(
      reservationId: strOpt(data['reservationId']) ?? '',
      lobbyId: strOpt(data['lobbyId']) ?? '',
      activeSessionId: strOpt(data['activeSessionId']) ?? '',
      reservationStatus: strOpt(data['reservationStatus']) ?? '',
      lobbyStatus: strOpt(data['lobbyStatus']) ?? '',
      checkedInAt: DateTime.tryParse(
        strOpt(data['checkedInAt']) ?? '',
      ) ?? DateTime.now(),
      heldBvc: (data['heldBvc'] as num?)?.toInt() ?? 0,
    );
  }
}
