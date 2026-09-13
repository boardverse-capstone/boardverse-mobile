/// Session history entity for past sessions
class SessionHistoryEntity {
  final String sessionId;
  final String cafeName;
  final String cafeId;
  final String? lobbyId;
  final String gameName;
  final String sessionStatus;
  final DateTime joinedAt;
  final DateTime joinedAtOffset;
  final DateTime? paidAt;
  final DateTime? paidAtOffset;
  final int totalMinutesPlayed;
  final int totalAmountDue;
  final String memberStatus;
  final String currency;

  const SessionHistoryEntity({
    required this.sessionId,
    required this.cafeName,
    required this.cafeId,
    this.lobbyId,
    required this.gameName,
    required this.sessionStatus,
    required this.joinedAt,
    required this.joinedAtOffset,
    this.paidAt,
    this.paidAtOffset,
    required this.totalMinutesPlayed,
    required this.totalAmountDue,
    required this.memberStatus,
    required this.currency,
  });

  /// Format total amount as display string
  String get formattedTotalAmount {
    return '${(totalAmountDue / 1000).toStringAsFixed(0)} BVC';
  }

  /// Format duration
  String get formattedDuration {
    final hours = totalMinutesPlayed ~/ 60;
    final minutes = totalMinutesPlayed % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}p';
    }
    return '${minutes}p';
  }

  /// Check if payment was completed
  bool get isPaid => sessionStatus == 'Paid';

  /// Get formatted play date
  String get formattedPlayDate {
    return '${joinedAtOffset.day}/${joinedAtOffset.month}/${joinedAtOffset.year}';
  }

  /// Get formatted play time
  String get formattedPlayTime {
    final hour = joinedAtOffset.hour.toString().padLeft(2, '0');
    final minute = joinedAtOffset.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  SessionHistoryEntity copyWith({
    String? sessionId,
    String? cafeName,
    String? cafeId,
    String? lobbyId,
    String? gameName,
    String? sessionStatus,
    DateTime? joinedAt,
    DateTime? joinedAtOffset,
    DateTime? paidAt,
    DateTime? paidAtOffset,
    int? totalMinutesPlayed,
    int? totalAmountDue,
    String? memberStatus,
    String? currency,
  }) {
    return SessionHistoryEntity(
      sessionId: sessionId ?? this.sessionId,
      cafeName: cafeName ?? this.cafeName,
      cafeId: cafeId ?? this.cafeId,
      lobbyId: lobbyId ?? this.lobbyId,
      gameName: gameName ?? this.gameName,
      sessionStatus: sessionStatus ?? this.sessionStatus,
      joinedAt: joinedAt ?? this.joinedAt,
      joinedAtOffset: joinedAtOffset ?? this.joinedAtOffset,
      paidAt: paidAt ?? this.paidAt,
      paidAtOffset: paidAtOffset ?? this.paidAtOffset,
      totalMinutesPlayed: totalMinutesPlayed ?? this.totalMinutesPlayed,
      totalAmountDue: totalAmountDue ?? this.totalAmountDue,
      memberStatus: memberStatus ?? this.memberStatus,
      currency: currency ?? this.currency,
    );
  }
}
