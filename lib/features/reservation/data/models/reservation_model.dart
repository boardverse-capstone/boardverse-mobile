import '../../domain/entities/entities.dart';

/// Data model cho Reservation API response
class ReservationModel extends ReservationEntity {
  const ReservationModel({
    required super.id,
    required super.hostId,
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
    super.lobbyStatus,
    required super.requiresCafeApproval,
    super.cafeApprovalDeadline,
    required super.createdAt,
    super.updatedAt,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] as String,
      hostId: json['hostId'] as String,
      cafeId: json['cafeId'] as String,
      cafeName: json['cafeName'] as String? ?? '',
      gameId: json['gameId'] as String,
      gameName: json['gameName'] as String? ?? '',
      playDate: DateTime.parse(json['playDate'] as String),
      timeSlot: TimeSlot.fromString(json['timeSlot'] as String),
      preferredStartTime: json['preferredStartTime'] as String?,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      recruitmentDeadline:
          DateTime.parse(json['recruitmentDeadline'] as String),
      minPlayers: json['minPlayers'] as int,
      maxPlayers: json['maxPlayers'] as int,
      depositRatePerPerson: json['depositRatePerPerson'] as int? ?? 0,
      baseDeposit: json['baseDeposit'] as int? ?? 0,
      riskMultiplier: (json['riskMultiplier'] as num?)?.toDouble() ?? 1.0,
      minDepositApplied: json['minDepositApplied'] as int? ?? 0,
      finalDeposit: json['finalDeposit'] as int? ?? 0,
      status: ReservationStatus.fromString(json['status'] as String? ?? 'draft'),
      currentPlayers: json['currentPlayers'] as int? ?? 1,
      lobbyId: json['lobbyId'] as String?,
      lobbyStatus: json['lobbyStatus'] != null
          ? LobbyStatus.fromString(json['lobbyStatus'] as String)
          : null,
      requiresCafeApproval: json['requiresCafeApproval'] as bool? ?? false,
      cafeApprovalDeadline: json['cafeApprovalDeadline'] != null
          ? DateTime.parse(json['cafeApprovalDeadline'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hostId': hostId,
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
      'lobbyStatus': lobbyStatus?.name,
      'requiresCafeApproval': requiresCafeApproval,
      'cafeApprovalDeadline': cafeApprovalDeadline?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
