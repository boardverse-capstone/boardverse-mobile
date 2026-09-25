import 'package:equatable/equatable.dart';

/// Lobby đang mở cho game được gợi ý (chỉ cho top-1 game).
class OpenLobbySummaryEntity extends Equatable {
  final String lobbyId;
  final String lobbyName;

  /// Số người hiện tại / tối đa.
  final int currentMembers;
  final int maxMembers;

  /// Thời gian bắt đầu dự kiến.
  final DateTime? scheduledStartTime;

  const OpenLobbySummaryEntity({
    required this.lobbyId,
    required this.lobbyName,
    required this.currentMembers,
    required this.maxMembers,
    this.scheduledStartTime,
  });

  @override
  List<Object?> get props => [
        lobbyId, lobbyName, currentMembers, maxMembers, scheduledStartTime,
      ];
}
