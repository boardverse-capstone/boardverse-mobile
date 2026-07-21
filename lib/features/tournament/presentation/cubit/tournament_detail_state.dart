import 'package:equatable/equatable.dart';

import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_participant_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_match_entity.dart';

/// States for TournamentDetailCubit.
sealed class TournamentDetailState extends Equatable {
  const TournamentDetailState();

  @override
  List<Object?> get props => [];
}

/// Initial state.
class TournamentDetailInitial extends TournamentDetailState {
  const TournamentDetailInitial();
}

/// Loading state.
class TournamentDetailLoading extends TournamentDetailState {
  const TournamentDetailLoading();
}

/// Loaded state with all tournament data.
class TournamentDetailLoaded extends TournamentDetailState {
  final TournamentEntity tournament;
  final List<TournamentParticipantEntity> participants;
  final List<TournamentMatchEntity> matches;
  final int selectedRound; // 0 = all rounds

  const TournamentDetailLoaded({
    required this.tournament,
    required this.participants,
    required this.matches,
    this.selectedRound = 0,
  });

  @override
  List<Object?> get props => [tournament, participants, matches, selectedRound];

  /// Gets matches filtered by selected round.
  List<TournamentMatchEntity> get filteredMatches {
    if (selectedRound == 0) return matches;
    return matches.where((m) => m.roundNumber == selectedRound).toList();
  }

  /// Gets unique round numbers from matches.
  List<int> get roundNumbers {
    final rounds = matches.map((m) => m.roundNumber).toSet().toList();
    rounds.sort();
    return rounds;
  }

  TournamentDetailLoaded copyWith({
    TournamentEntity? tournament,
    List<TournamentParticipantEntity>? participants,
    List<TournamentMatchEntity>? matches,
    int? selectedRound,
  }) {
    return TournamentDetailLoaded(
      tournament: tournament ?? this.tournament,
      participants: participants ?? this.participants,
      matches: matches ?? this.matches,
      selectedRound: selectedRound ?? this.selectedRound,
    );
  }
}

/// Registering/Unregistering state.
class TournamentDetailRegistering extends TournamentDetailState {
  final TournamentEntity tournament;
  final List<TournamentParticipantEntity> participants;
  final List<TournamentMatchEntity> matches;
  final bool isRegistering; // true = register, false = unregister

  const TournamentDetailRegistering({
    required this.tournament,
    required this.participants,
    required this.matches,
    required this.isRegistering,
  });

  @override
  List<Object?> get props => [tournament, participants, matches, isRegistering];
}

/// Success state after register/unregister.
class TournamentDetailActionSuccess extends TournamentDetailState {
  final String message;
  final bool wasRegistered;

  const TournamentDetailActionSuccess({
    required this.message,
    required this.wasRegistered,
  });

  @override
  List<Object?> get props => [message, wasRegistered];
}

/// Error state.
class TournamentDetailError extends TournamentDetailState {
  final String message;
  final TournamentEntity? tournament;
  final List<TournamentParticipantEntity>? participants;
  final List<TournamentMatchEntity>? matches;

  const TournamentDetailError({
    required this.message,
    this.tournament,
    this.participants,
    this.matches,
  });

  @override
  List<Object?> get props => [message, tournament, participants, matches];
}
