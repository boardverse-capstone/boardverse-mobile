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
    required super.scheduledTime,
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
  });

  factory ReservationQuoteModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return ReservationQuoteModel(
      reservationId: data['reservationId'] as String?,
      cafeId: data['cafeId'] as String,
      cafeName: data['cafeName'] as String? ?? '',
      gameId: data['gameId'] as String,
      gameName: data['gameName'] as String? ?? '',
      playDate: DateTime.parse(data['playDate'] as String),
      timeSlot: TimeSlot.fromString(data['timeSlot'] as String),
      preferredStartTime: data['preferredStartTime'] as String?,
      scheduledTime: DateTime.parse(data['scheduledTime'] as String),
      recruitmentDeadline:
          DateTime.parse(data['recruitmentDeadline'] as String),
      minPlayers: data['minPlayers'] as int,
      maxPlayers: data['maxPlayers'] as int,
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
      expiresAt: data['expiresAt'] != null
          ? DateTime.parse(data['expiresAt'] as String)
          : DateTime.now().add(const Duration(minutes: 5)),
      warnings: (data['warnings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

/// Request model cho Quote API
class QuoteRequestModel {
  final String cafeId;
  final String gameId;
  final DateTime playDate;
  final String timeSlot;
  final String? preferredStartTime;
  final int minPlayers;
  final int maxPlayers;
  final bool isPrivate;
  final String idempotencyKey;

  const QuoteRequestModel({
    required this.cafeId,
    required this.gameId,
    required this.playDate,
    required this.timeSlot,
    this.preferredStartTime,
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
      // Backend expects PascalCase: "Morning", "Afternoon", "Evening", "Night"
      'timeSlot': timeSlot[0].toUpperCase() + timeSlot.substring(1),
      'preferredStartTime': preferredStartTime,
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
      reservationId: data['reservationId'] as String,
      lobbyId: data['lobbyId'] as String,
      lobbyShareCode:
          (data['lobbyShareCode'] ?? data['shareCode']) as String?,
      recruitmentDeadline:
          DateTime.parse(data['recruitmentDeadline'] as String),
      requiresCafeApproval: data['requiresCafeApproval'] as bool? ?? false,
      cafeApprovalDeadline: data['cafeApprovalDeadline'] != null
          ? DateTime.parse(data['cafeApprovalDeadline'] as String)
          : null,
      heldBvc: data['heldBvc'] as int? ?? 0,
    );
  }
}

/// Request model cho Confirm API
class ConfirmRequestModel {
  final String cafeId;
  final String gameId;
  final DateTime playDate;
  final String timeSlot;
  final String? preferredStartTime;
  final int minPlayers;
  final int maxPlayers;
  final bool isPrivate;
  final int expectedFinalDeposit;
  final String idempotencyKey;

  const ConfirmRequestModel({
    required this.cafeId,
    required this.gameId,
    required this.playDate,
    required this.timeSlot,
    this.preferredStartTime,
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
      // Backend expects PascalCase: "Morning", "Afternoon", "Evening", "Night"
      'timeSlot': timeSlot[0].toUpperCase() + timeSlot.substring(1),
      'preferredStartTime': preferredStartTime,
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
      reservationId: data['reservationId'] as String,
      lobbyId: data['lobbyId'] as String,
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
