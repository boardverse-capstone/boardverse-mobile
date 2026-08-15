import 'package:equatable/equatable.dart';

import '../../domain/entities/leaderboard_kind.dart';
import '../../domain/entities/leaderboard_result_entity.dart';

sealed class LeaderboardState extends Equatable {
  const LeaderboardState();

  @override
  List<Object?> get props => [];
}

class LeaderboardInitial extends LeaderboardState {
  const LeaderboardInitial();
}

class LeaderboardLoading extends LeaderboardState {
  final LeaderboardKind kind;
  const LeaderboardLoading(this.kind);

  @override
  List<Object?> get props => [kind];
}

class LeaderboardLoaded extends LeaderboardState {
  final LeaderboardResultEntity result;
  final LeaderboardKind kind;
  final bool isRefresh;

  const LeaderboardLoaded({
    required this.result,
    required this.kind,
    this.isRefresh = false,
  });

  @override
  List<Object?> get props => [result, kind, isRefresh];
}

class LeaderboardError extends LeaderboardState {
  final String message;
  final LeaderboardKind? kind;

  const LeaderboardError({required this.message, this.kind});

  @override
  List<Object?> get props => [message, kind];
}
