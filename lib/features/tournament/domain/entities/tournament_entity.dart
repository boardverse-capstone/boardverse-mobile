import 'tournament_status.dart';

/// Tournament entity for Player mobile app.
///
/// Maps to backend TournamentResponseDto.
class TournamentEntity {
  final String id;
  final String title;
  final String cafeName;
  final String gameTemplateName;
  final DateTime startTime;
  final DateTime registrationDeadline;
  final TournamentStatus status;
  final int currentParticipants;
  final int maxParticipants;
  final int minKarmaRequirement;
  final int? registrationFee;
  final int prizePool;
  final String description;
  final String? organizerName;
  final int roundDurationMinutes;
  final int preliminaryRounds;
  final int? currentRound;
  final bool isUserRegistered;
  final bool isUserCheckedIn;
  final int? userCurrentRank;

  const TournamentEntity({
    required this.id,
    required this.title,
    required this.cafeName,
    required this.gameTemplateName,
    required this.startTime,
    required this.registrationDeadline,
    required this.status,
    required this.currentParticipants,
    required this.maxParticipants,
    required this.minKarmaRequirement,
    this.registrationFee,
    required this.prizePool,
    required this.description,
    this.organizerName,
    required this.roundDurationMinutes,
    required this.preliminaryRounds,
    this.currentRound,
    required this.isUserRegistered,
    required this.isUserCheckedIn,
    this.userCurrentRank,
  });

  /// Slots remaining for registration.
  int get slotsRemaining => maxParticipants - currentParticipants;

  /// Fill ratio for progress bar.
  double get fillRatio =>
      maxParticipants == 0 ? 0 : currentParticipants / maxParticipants;

  /// Whether this tournament requires minimum karma to register.
  bool get requiresKarma => minKarmaRequirement > 0;

  /// Whether registration is still open and user can register.
  bool get canRegister =>
      status.canRegister && !isUserRegistered && slotsRemaining > 0;

  /// Whether registration is open and user is registered but can withdraw.
  bool get canWithdraw => status.canWithdraw && isUserRegistered;

  /// Whether tournament is free to enter.
  bool get isFree => registrationFee == null || registrationFee == 0;

  /// Whether tournament has prize pool.
  bool get hasPrizePool => prizePool > 0;

  /// User can view bracket when tournament is ongoing or completed.
  bool get canViewBracket =>
      status == TournamentStatus.ongoing ||
      status == TournamentStatus.completed;

  /// Whether the registration deadline has passed.
  bool get isRegistrationDeadlinePassed =>
      DateTime.now().isAfter(registrationDeadline);

  /// Time remaining until registration deadline.
  Duration? get registrationTimeRemaining {
    if (isRegistrationDeadlinePassed) return null;
    return registrationDeadline.difference(DateTime.now());
  }

  /// Whether the tournament has started.
  bool get hasStarted => DateTime.now().isAfter(startTime);

  /// Time remaining until tournament starts.
  Duration? get timeUntilStart {
    if (hasStarted) return null;
    return startTime.difference(DateTime.now());
  }
}
