import 'package:equatable/equatable.dart';

import 'package:boardverse_mobile/features/tournament/domain/entities/elo_history_entity.dart';

/// States for EloHistoryCubit.
sealed class EloHistoryState extends Equatable {
  const EloHistoryState();

  @override
  List<Object?> get props => [];
}

class EloHistoryInitial extends EloHistoryState {
  const EloHistoryInitial();
}

class EloHistoryLoading extends EloHistoryState {
  const EloHistoryLoading();
}

class EloHistoryLoaded extends EloHistoryState {
  final List<EloHistoryEntity> history;
  final int initialElo;
  final int currentElo;
  final int totalDelta;
  final int tournamentsPlayed;

  const EloHistoryLoaded({
    required this.history,
    required this.initialElo,
    required this.currentElo,
    required this.totalDelta,
    required this.tournamentsPlayed,
  });

  @override
  List<Object?> get props => [
        history,
        initialElo,
        currentElo,
        totalDelta,
        tournamentsPlayed,
      ];
}

class EloHistoryError extends EloHistoryState {
  final String message;
  const EloHistoryError({required this.message});

  @override
  List<Object?> get props => [message];
}