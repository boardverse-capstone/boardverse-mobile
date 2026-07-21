import 'package:equatable/equatable.dart';

import 'package:boardverse_mobile/features/tournament/domain/entities/leaderboard_entity.dart';

sealed class LeaderboardState extends Equatable {
  const LeaderboardState();

  @override
  List<Object?> get props => [];
}

class LeaderboardInitial extends LeaderboardState {
  const LeaderboardInitial();
}

class LeaderboardLoading extends LeaderboardState {
  const LeaderboardLoading();
}

class LeaderboardLoaded extends LeaderboardState {
  final List<LeaderboardEntryEntity> entries;
  final int totalPlayers;

  const LeaderboardLoaded({
    required this.entries,
    required this.totalPlayers,
  });

  @override
  List<Object?> get props => [entries, totalPlayers];
}

class LeaderboardError extends LeaderboardState {
  final String message;
  const LeaderboardError({required this.message});

  @override
  List<Object?> get props => [message];
}