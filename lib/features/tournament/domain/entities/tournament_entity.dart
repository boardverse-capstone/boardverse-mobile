import 'tournament_status.dart';

class TournamentEntity {
  final String id;
  final String name;
  final String gameName;
  final String cafeName;
  final String organizer;
  final DateTime startDate;
  final DateTime registrationDeadline;
  final int currentParticipants;
  final int maxParticipants;
  final int? minEloRequired;
  final int? entryFee;
  final int prizePool;
  final TournamentStatus status;
  final String description;

  const TournamentEntity({
    required this.id,
    required this.name,
    required this.gameName,
    required this.cafeName,
    required this.organizer,
    required this.startDate,
    required this.registrationDeadline,
    required this.currentParticipants,
    required this.maxParticipants,
    required this.minEloRequired,
    required this.entryFee,
    required this.prizePool,
    required this.status,
    required this.description,
  });

  int get slotsRemaining => maxParticipants - currentParticipants;

  double get fillRatio =>
      maxParticipants == 0 ? 0 : currentParticipants / maxParticipants;

  bool get requiresElo => minEloRequired != null && minEloRequired! > 0;
}
