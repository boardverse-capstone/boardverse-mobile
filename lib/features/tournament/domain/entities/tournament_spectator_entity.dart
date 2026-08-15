import 'package:equatable/equatable.dart';

/// 1 entry spectate — user đang theo dõi tournament.
///
/// Backend `GET /tournaments/{id}/spectators` trả về list các entry này
/// (public — không cần auth). Khi user bắt đầu spectate sẽ nhận entry
/// riêng từ `POST /spectators`.
class TournamentSpectatorEntry extends Equatable {
  final String? id;

  final String tournamentId;
  final String tournamentTitle;

  final String userId;
  final String userName;

  final DateTime joinedAt;

  /// `null` khi user đang spectate; có khi user đã rời.
  final DateTime? leftAt;

  const TournamentSpectatorEntry({
    this.id,
    required this.tournamentId,
    required this.tournamentTitle,
    required this.userId,
    required this.userName,
    required this.joinedAt,
    this.leftAt,
  });

  /// User hiện đang còn theo dõi hay đã rời.
  bool get isActive => leftAt == null;

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        tournamentTitle,
        userId,
        userName,
        joinedAt,
        leftAt,
      ];
}

/// Trạng thái spectate của user hiện tại (cho `/spectators/me` endpoint).
///
/// Backend trả `data: null` khi chưa spectate — UI xử lý như
/// [isSpectating] = false.
class MySpectatorStatus extends Equatable {
  final bool isSpectating;
  final TournamentSpectatorEntry? entry;

  const MySpectatorStatus({
    required this.isSpectating,
    this.entry,
  });

  @override
  List<Object?> get props => [isSpectating, entry];
}