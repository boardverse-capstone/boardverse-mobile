import 'package:equatable/equatable.dart';

import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_entity.dart';

/// States for TournamentListCubit.
sealed class TournamentListState extends Equatable {
  const TournamentListState();

  @override
  List<Object?> get props => [];
}

/// Initial state.
class TournamentListInitial extends TournamentListState {
  const TournamentListInitial();
}

/// Loading state.
class TournamentListLoading extends TournamentListState {
  const TournamentListLoading();
}

/// Loaded state with tournament lists.
class TournamentListLoaded extends TournamentListState {
  final List<TournamentEntity> openTournaments;
  final List<TournamentEntity> upcomingTournaments;
  final List<TournamentEntity> ongoingTournaments;
  final List<TournamentEntity> completedTournaments;
  final int totalOpenCount;

  const TournamentListLoaded({
    required this.openTournaments,
    required this.upcomingTournaments,
    this.ongoingTournaments = const [],
    this.completedTournaments = const [],
    required this.totalOpenCount,
  });

  @override
  List<Object?> get props => [
        openTournaments,
        upcomingTournaments,
        ongoingTournaments,
        completedTournaments,
        totalOpenCount,
      ];
}

/// Error state.
class TournamentListError extends TournamentListState {
  final String message;

  const TournamentListError({required this.message});

  @override
  List<Object?> get props => [message];
}
