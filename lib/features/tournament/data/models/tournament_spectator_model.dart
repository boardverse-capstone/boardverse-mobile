import 'package:boardverse/features/tournament/domain/entities/tournament_spectator_entity.dart';

/// Model cho endpoint T-04 Tournament Spectator — danh sách public và
/// entry trả về từ `POST/DELETE /spectators`.
///
/// Tolerant với field alias `tournamentTitle`/`tournamentName`,
/// `userName`/`username` (1 số endpoint Swagger dùng name khác).
class TournamentSpectatorModel {
  final String? id;
  final String tournamentId;
  final String? tournamentTitle;
  final String userId;
  final String? userName;
  final DateTime joinedAt;
  final DateTime? leftAt;

  const TournamentSpectatorModel({
    this.id,
    required this.tournamentId,
    this.tournamentTitle,
    required this.userId,
    this.userName,
    required this.joinedAt,
    this.leftAt,
  });

  factory TournamentSpectatorModel.fromJson(Map<String, dynamic> json) {
    final joinedRaw = json['joinedAt'] as String?;
    final leftRaw = json['leftAt'] as String?;
    return TournamentSpectatorModel(
      id: json['id'] as String?,
      tournamentId: (json['tournamentId'] as String?) ?? '',
      tournamentTitle: (json['tournamentTitle'] ??
              json['tournamentName']) as String?,
      userId: (json['userId'] as String?) ?? '',
      userName: (json['userName'] ?? json['username']) as String?,
      joinedAt: joinedRaw != null
          ? DateTime.tryParse(joinedRaw) ?? DateTime.now()
          : DateTime.now(),
      leftAt: leftRaw != null ? DateTime.tryParse(leftRaw) : null,
    );
  }

  TournamentSpectatorEntry toEntity({
    required String fallbackTournamentTitle,
  }) {
    return TournamentSpectatorEntry(
      id: id,
      tournamentId: tournamentId,
      tournamentTitle: tournamentTitle ?? fallbackTournamentTitle,
      userId: userId,
      userName: userName ?? 'Unknown',
      joinedAt: joinedAt,
      leftAt: leftAt,
    );
  }
}

/// Model cho wrapper `GET /spectators/me` — backend trả `data: null` khi
/// user chưa spectate. `isSpectating=false` + null model đại diện case đó.
class MySpectatorStatusModel {
  final bool isSpectating;

  /// Optional — chỉ có khi [isSpectating] = true.
  final TournamentSpectatorModel? model;

  const MySpectatorStatusModel({
    required this.isSpectating,
    this.model,
  });

  /// Default cho trường hợp user chưa spectate.
  static const MySpectatorStatusModel notSpectating =
      MySpectatorStatusModel(isSpectating: false);

  /// Build từ entry spectate trả về từ `GET /spectators/me`.
  factory MySpectatorStatusModel.fromEntry(
    TournamentSpectatorModel model,
  ) {
    return MySpectatorStatusModel(isSpectating: true, model: model);
  }
}