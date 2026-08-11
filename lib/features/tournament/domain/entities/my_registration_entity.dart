/// `GET /tournaments/my-registrations` returns a *flat* shape that mixes
/// tournament info with the current user's participant info — it does NOT
/// match the full `TournamentResponseDto` used by `/open` and `/{id}`
/// (many fields like `registrationDeadline`, `maxParticipants`,
/// `gameName`, … are missing).
///
/// This entity mirrors the actual response shape so we don't need to
/// fall back to defaults when fetching "My Registrations".
class MyRegistrationEntry {
  final String tournamentId;
  final String title;
  final String cafeId;
  final String cafeName;
  final DateTime startTime;

  /// Backend field is `tournamentStatus` (not `status`).
  final String tournamentStatus;

  final String participantId;
  final String participantStatus;
  final bool isWalkIn;
  final String? walkInDisplayName;
  final DateTime registeredAt;
  final DateTime? checkedInAt;
  final double swissScore;
  final int swissWins;
  final int swissDraws;
  final int swissLosses;
  final int? finalRank;
  final int initialElo;
  final int finalElo;
  final int eloDelta;

  const MyRegistrationEntry({
    required this.tournamentId,
    required this.title,
    required this.cafeId,
    required this.cafeName,
    required this.startTime,
    required this.tournamentStatus,
    required this.participantId,
    required this.participantStatus,
    required this.isWalkIn,
    this.walkInDisplayName,
    required this.registeredAt,
    this.checkedInAt,
    required this.swissScore,
    required this.swissWins,
    required this.swissDraws,
    required this.swissLosses,
    this.finalRank,
    required this.initialElo,
    required this.finalElo,
    required this.eloDelta,
  });
}
