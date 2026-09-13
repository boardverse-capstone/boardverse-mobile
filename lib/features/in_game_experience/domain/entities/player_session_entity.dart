import '../../data/models/player_session_model.dart';
import 'cost_estimate_entity.dart';
import 'extension_request_entity.dart';

export '../../data/models/player_session_model.dart';
export 'cost_estimate_entity.dart';
export 'extension_request_entity.dart';
export 'member_payment_info.dart';

/// Player session entity - represents the current session from API
class PlayerSessionEntity {
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
  final CostEstimateEntity costEstimate;
  final String gameName;
  final int totalGroupMembers;
  final bool canExtend;
  final bool canPay;
  final bool isPaid;
  final LastExtensionRequestEntity? lastExtensionRequest;

  const PlayerSessionEntity({
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

  /// Check if session is active (player is still playing)
  bool get isActive => memberStatus == MemberStatus.playing;

  /// Check if session can be extended
  bool get canBeExtended =>
      canExtend && memberStatus == MemberStatus.playing;

  /// Check if session can be paid
  bool get canBePaid => canPay && sessionStatus == SessionStatus.unpaid && !isPaid;

  /// Check if extension request is pending
  bool get hasPendingExtensionRequest =>
      lastExtensionRequest?.status == ExtensionStatus.pending;

  /// Get formatted elapsed time
  String get formattedElapsedTime {
    final hours = elapsedMinutes ~/ 60;
    final minutes = elapsedMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}p';
    }
    return '${minutes}p';
  }

  /// Get formatted total due — số BVC tối thiểu cần có.
  String get formattedTotalDue {
    final bvc = (costEstimate.totalDue / 1000).ceil();
    return '$bvc BVC';
  }

  PlayerSessionEntity copyWith({
    String? sessionId,
    String? cafeName,
    String? cafeId,
    String? lobbyId,
    MemberStatus? memberStatus,
    SessionStatus? sessionStatus,
    DateTime? joinedAt,
    DateTime? joinedAtOffset,
    int? elapsedMinutes,
    int? totalMinutesPlayed,
    CostEstimateEntity? costEstimate,
    String? gameName,
    int? totalGroupMembers,
    bool? canExtend,
    bool? canPay,
    bool? isPaid,
    LastExtensionRequestEntity? lastExtensionRequest,
  }) {
    return PlayerSessionEntity(
      sessionId: sessionId ?? this.sessionId,
      cafeName: cafeName ?? this.cafeName,
      cafeId: cafeId ?? this.cafeId,
      lobbyId: lobbyId ?? this.lobbyId,
      memberStatus: memberStatus ?? this.memberStatus,
      sessionStatus: sessionStatus ?? this.sessionStatus,
      joinedAt: joinedAt ?? this.joinedAt,
      joinedAtOffset: joinedAtOffset ?? this.joinedAtOffset,
      elapsedMinutes: elapsedMinutes ?? this.elapsedMinutes,
      totalMinutesPlayed: totalMinutesPlayed ?? this.totalMinutesPlayed,
      costEstimate: costEstimate ?? this.costEstimate,
      gameName: gameName ?? this.gameName,
      totalGroupMembers: totalGroupMembers ?? this.totalGroupMembers,
      canExtend: canExtend ?? this.canExtend,
      canPay: canPay ?? this.canPay,
      isPaid: isPaid ?? this.isPaid,
      lastExtensionRequest: lastExtensionRequest ?? this.lastExtensionRequest,
    );
  }
}
