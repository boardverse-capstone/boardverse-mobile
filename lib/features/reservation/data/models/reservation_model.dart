import '../../domain/entities/entities.dart';

/// Data model cho Reservation API response
class ReservationModel extends ReservationEntity {
  const ReservationModel({
    required super.id,
    required super.hostId,
    super.hostDisplayName,
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
    required super.status,
    required super.currentPlayers,
    super.lobbyId,
    super.lobbyShareCode,
    super.lobbyStatus,
    super.isPrivate,
    required super.requiresCafeApproval,
    super.cafeApprovalDeadline,
    super.cafeRejectionReason,
    super.refundPolicyApplied,
    required super.createdAt,
    super.updatedAt,
    super.isHost,
    super.remainingApprovalHours,
    super.remainingApprovalMinutes,
    super.isCafeApproved,
    super.approvedAt,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] as String? ?? '',
      hostId: json['hostId'] as String? ?? '',
      hostDisplayName: json['hostDisplayName'] as String?,
      cafeId: json['cafeId'] as String? ?? '',
      cafeName: json['cafeName'] as String? ?? '',
      gameId: json['gameId'] as String? ?? '',
      gameName: json['gameName'] as String? ?? '',
      playDate: DateTime.tryParse(json['playDate'] as String? ?? '') ?? DateTime.now(),
      timeSlot: TimeSlot.fromString(json['timeSlot'] as String? ?? 'morning'),
      preferredStartTime: json['preferredStartTime'] as String?,
      scheduledTime: DateTime.tryParse(json['scheduledTime'] as String? ?? '') ?? DateTime.now(),
      recruitmentDeadline:
          DateTime.tryParse(json['recruitmentDeadline'] as String? ?? '') ?? DateTime.now(),
      minPlayers: json['minPlayers'] as int? ?? 2,
      maxPlayers: json['maxPlayers'] as int? ?? 4,
      depositRatePerPerson: json['depositRatePerPerson'] as int? ?? 0,
      baseDeposit: json['baseDeposit'] as int? ?? 0,
      riskMultiplier: (json['riskMultiplier'] as num?)?.toDouble() ?? 1.0,
      minDepositApplied: json['minDepositApplied'] as int? ?? 0,
      finalDeposit: json['finalDeposit'] as int? ?? 0,
      status: ReservationStatus.fromString(json['status'] as String? ?? 'draft'),
      currentPlayers: json['currentPlayers'] as int? ?? 1,
      lobbyId: json['lobbyId'] as String?,
      lobbyShareCode: (json['lobbyShareCode'] ?? json['reservationCode']) as String?,
      lobbyStatus: json['lobbyStatus'] != null
          ? LobbyStatus.fromString(json['lobbyStatus'] as String)
          : null,
      isPrivate: json['isPrivate'] as bool? ?? false,
      requiresCafeApproval: json['requiresCafeApproval'] as bool? ?? false,
      cafeApprovalDeadline: json['cafeApprovalDeadline'] != null
          ? DateTime.tryParse(json['cafeApprovalDeadline'] as String)
          : null,
      cafeRejectionReason: json['cafeRejectionReason'] as String?,
      refundPolicyApplied: json['refundPolicyApplied'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      isHost: json['isHost'] as bool?,
      remainingApprovalHours: (json['remainingApprovalHours'] as num?)?.toInt(),
      remainingApprovalMinutes: (json['remainingApprovalMinutes'] as num?)?.toInt(),
      isCafeApproved: json['isCafeApproved'] as bool?,
      approvedAt: json['approvedAt'] != null
          ? DateTime.tryParse(json['approvedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hostId': hostId,
      'hostDisplayName': hostDisplayName,
      'cafeId': cafeId,
      'cafeName': cafeName,
      'gameId': gameId,
      'gameName': gameName,
      'playDate': playDate.toIso8601String(),
      'timeSlot': timeSlot.name,
      'preferredStartTime': preferredStartTime,
      'scheduledTime': scheduledTime.toIso8601String(),
      'recruitmentDeadline': recruitmentDeadline.toIso8601String(),
      'minPlayers': minPlayers,
      'maxPlayers': maxPlayers,
      'depositRatePerPerson': depositRatePerPerson,
      'baseDeposit': baseDeposit,
      'riskMultiplier': riskMultiplier,
      'minDepositApplied': minDepositApplied,
      'finalDeposit': finalDeposit,
      'status': status.name,
      'currentPlayers': currentPlayers,
      'lobbyId': lobbyId,
      'lobbyShareCode': lobbyShareCode,
      'lobbyStatus': lobbyStatus?.name,
      'requiresCafeApproval': requiresCafeApproval,
      'cafeApprovalDeadline': cafeApprovalDeadline?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isHost': isHost,
      'remainingApprovalHours': remainingApprovalHours,
      'remainingApprovalMinutes': remainingApprovalMinutes,
      'isCafeApproved': isCafeApproved,
      'approvedAt': approvedAt?.toIso8601String(),
    };
  }
}
