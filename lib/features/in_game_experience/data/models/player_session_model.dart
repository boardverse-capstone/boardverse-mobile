import '../../domain/entities/player_session_entity.dart';

/// Model for GET /api/v1/sessions/me/current response
/// Maps API response to PlayerSessionModel
class PlayerSessionModel {
  final String sessionId;
  final String cafeName;
  final String cafeId;
  final String? lobbyId;
  final MemberStatus memberStatus;
  final SessionStatus sessionStatus;
  final DateTime joinedAt;
  final DateTime joinedAtOffset;
  final int elapsedMinutes;
  final int totalMinutesPlayed;
  final CostEstimateModel costEstimate;
  final String gameName;
  final int totalGroupMembers;
  final bool canExtend;
  final bool canPay;
  final bool isPaid;
  final LastExtensionRequestModel? lastExtensionRequest;

  const PlayerSessionModel({
    required this.sessionId,
    required this.cafeName,
    required this.cafeId,
    this.lobbyId,
    required this.memberStatus,
    required this.sessionStatus,
    required this.joinedAt,
    required this.joinedAtOffset,
    required this.elapsedMinutes,
    required this.totalMinutesPlayed,
    required this.costEstimate,
    required this.gameName,
    required this.totalGroupMembers,
    required this.canExtend,
    required this.canPay,
    required this.isPaid,
    this.lastExtensionRequest,
  });

  factory PlayerSessionModel.fromJson(Map<String, dynamic> json) {
    return PlayerSessionModel(
      sessionId: json['sessionId'] as String,
      cafeName: json['cafeName'] as String,
      cafeId: json['cafeId'] as String,
      lobbyId: json['lobbyId'] as String?,
      memberStatus: MemberStatus.values.firstWhere(
        (e) => e.name == json['memberStatus'],
        orElse: () => MemberStatus.playing,
      ),
      sessionStatus: SessionStatus.values.firstWhere(
        (e) => e.name == json['sessionStatus'],
        orElse: () => SessionStatus.active,
      ),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      joinedAtOffset: DateTime.parse(json['joinedAtOffset'] as String),
      elapsedMinutes: (json['elapsedMinutes'] as num?)?.toInt() ?? 0,
      totalMinutesPlayed: (json['totalMinutesPlayed'] as num?)?.toInt() ?? 0,
      costEstimate: CostEstimateModel.fromJson(
          json['costEstimate'] as Map<String, dynamic>),
      gameName: json['gameName'] as String,
      totalGroupMembers: (json['totalGroupMembers'] as num?)?.toInt() ?? 0,
      canExtend: json['canExtend'] as bool? ?? false,
      canPay: json['canPay'] as bool? ?? false,
      isPaid: json['isPaid'] as bool? ?? false,
      lastExtensionRequest: json['lastExtensionRequest'] != null
          ? LastExtensionRequestModel.fromJson(
              json['lastExtensionRequest'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'cafeName': cafeName,
      'cafeId': cafeId,
      'lobbyId': lobbyId,
      'memberStatus': memberStatus.name,
      'sessionStatus': sessionStatus.name,
      'joinedAt': joinedAt.toIso8601String(),
      'joinedAtOffset': joinedAtOffset.toIso8601String(),
      'elapsedMinutes': elapsedMinutes,
      'totalMinutesPlayed': totalMinutesPlayed,
      'costEstimate': costEstimate.toJson(),
      'gameName': gameName,
      'totalGroupMembers': totalGroupMembers,
      'canExtend': canExtend,
      'canPay': canPay,
      'isPaid': isPaid,
      'lastExtensionRequest': lastExtensionRequest?.toJson(),
    };
  }

  PlayerSessionEntity toEntity() => PlayerSessionEntity(
        sessionId: sessionId,
        cafeName: cafeName,
        cafeId: cafeId,
        lobbyId: lobbyId,
        memberStatus: memberStatus,
        sessionStatus: sessionStatus,
        joinedAt: joinedAt,
        joinedAtOffset: joinedAtOffset,
        elapsedMinutes: elapsedMinutes,
        totalMinutesPlayed: totalMinutesPlayed,
        costEstimate: costEstimate.toEntity(),
        gameName: gameName,
        totalGroupMembers: totalGroupMembers,
        canExtend: canExtend,
        canPay: canPay,
        isPaid: isPaid,
        lastExtensionRequest: lastExtensionRequest?.toEntity(),
      );
}

/// Cost estimate from API
class CostEstimateModel {
  final int baseMinutes;
  final int subtotal;
  final int penaltyAmount;
  final int depositApplied;
  final int totalDue;
  final String currency;

  const CostEstimateModel({
    required this.baseMinutes,
    required this.subtotal,
    required this.penaltyAmount,
    required this.depositApplied,
    required this.totalDue,
    required this.currency,
  });

  factory CostEstimateModel.fromJson(Map<String, dynamic> json) {
    return CostEstimateModel(
      baseMinutes: (json['baseMinutes'] as num?)?.toInt() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      penaltyAmount: (json['penaltyAmount'] as num?)?.toInt() ?? 0,
      depositApplied: (json['depositApplied'] as num?)?.toInt() ?? 0,
      totalDue: (json['totalDue'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'VND',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseMinutes': baseMinutes,
      'subtotal': subtotal,
      'penaltyAmount': penaltyAmount,
      'depositApplied': depositApplied,
      'totalDue': totalDue,
      'currency': currency,
    };
  }

  CostEstimateEntity toEntity() => CostEstimateEntity(
        baseMinutes: baseMinutes,
        subtotal: subtotal,
        penaltyAmount: penaltyAmount,
        depositApplied: depositApplied,
        totalDue: totalDue,
        currency: currency,
      );
}

/// Last extension request model
class LastExtensionRequestModel {
  final String requestId;
  final int requestedMinutes;
  final int? approvedMinutes;
  final int estimatedAdditionalCostVnd;
  final ExtensionStatus status;
  final String? rejectionReason;
  final DateTime requestedAt;
  final DateTime? requestedAtUtc;
  final DateTime? processedAt;
  final DateTime? processedAtOffset;

  const LastExtensionRequestModel({
    required this.requestId,
    required this.requestedMinutes,
    this.approvedMinutes,
    required this.estimatedAdditionalCostVnd,
    required this.status,
    this.rejectionReason,
    required this.requestedAt,
    this.requestedAtUtc,
    this.processedAt,
    this.processedAtOffset,
  });

  factory LastExtensionRequestModel.fromJson(Map<String, dynamic> json) {
    return LastExtensionRequestModel(
      requestId: json['requestId'] as String,
      requestedMinutes: (json['requestedMinutes'] as num?)?.toInt() ?? 0,
      approvedMinutes: (json['approvedMinutes'] as num?)?.toInt(),
      estimatedAdditionalCostVnd: (json['estimatedAdditionalCostVnd'] as num?)?.toInt() ?? 0,
      status: ExtensionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ExtensionStatus.pending,
      ),
      rejectionReason: json['rejectionReason'] as String?,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      requestedAtUtc: json['requestedAtUtc'] != null
          ? DateTime.parse(json['requestedAtUtc'] as String)
          : null,
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String)
          : null,
      processedAtOffset: json['processedAtOffset'] != null
          ? DateTime.parse(json['processedAtOffset'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'requestedMinutes': requestedMinutes,
      'approvedMinutes': approvedMinutes,
      'estimatedAdditionalCostVnd': estimatedAdditionalCostVnd,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'requestedAt': requestedAt.toIso8601String(),
      'requestedAtUtc': requestedAtUtc?.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'processedAtOffset': processedAtOffset?.toIso8601String(),
    };
  }

  LastExtensionRequestEntity toEntity() => LastExtensionRequestEntity(
        requestId: requestId,
        requestedMinutes: requestedMinutes,
        approvedMinutes: approvedMinutes,
        estimatedAdditionalCostVnd: estimatedAdditionalCostVnd,
        status: status,
        rejectionReason: rejectionReason,
        requestedAt: requestedAt,
        requestedAtUtc: requestedAtUtc,
        processedAt: processedAt,
        processedAtOffset: processedAtOffset,
      );
}

/// Member status enum
enum MemberStatus { playing, suspendedMutation, finished }

/// Session status enum
enum SessionStatus { active, checking, unpaid, paid }
