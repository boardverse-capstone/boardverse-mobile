import 'package:equatable/equatable.dart';

import 'lobby_entity.dart';

/// Dạng rút gọn của [LobbyEntity] dùng cho danh sách tìm phòng.
/// (chỉ các field cần hiển thị trên NearbyLobbiesPage / Search Result)
class LobbySummary extends Equatable {
  final String id;
  final String gameId;
  final String gameName;
  final String gameImageUrl;
  final String cafeId;
  final String cafeName;
  final String hostName;
  final double distanceKm;
  final int currentPlayers;
  final int maxPlayers;
  final int minPlayers;
  final double minimumKarma;
  final DateTime scheduledTime;
  final DateTime timeoutAt;
  final LobbyStatus status;
  final bool isPublic;

  const LobbySummary({
    required this.id,
    required this.gameId,
    required this.gameName,
    required this.gameImageUrl,
    required this.cafeId,
    required this.cafeName,
    required this.hostName,
    required this.distanceKm,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.minPlayers,
    required this.minimumKarma,
    required this.scheduledTime,
    required this.timeoutAt,
    required this.status,
    required this.isPublic,
  });

  int get slotsRemaining => maxPlayers - currentPlayers;
  bool get canJoin =>
      status == LobbyStatus.open && currentPlayers < maxPlayers;

  @override
  List<Object?> get props => [
        id,
        gameId,
        gameName,
        gameImageUrl,
        cafeId,
        cafeName,
        hostName,
        distanceKm,
        currentPlayers,
        maxPlayers,
        minPlayers,
        minimumKarma,
        scheduledTime,
        timeoutAt,
        status,
        isPublic,
      ];
}

/// Bộ lọc cho việc tìm lobby khả dụng.
class LobbySearchFilter extends Equatable {
  /// Bán kính tìm kiếm (km). `null` = không giới hạn.
  final double? radiusKm;

  /// Ngưỡng Karma mà lobby yêu cầu. Lobby có `minimumKarma` > currentUserKarma
  /// bị filter bỏ (BR-10).
  final double? minKarma;

  /// gameId cụ thể — `null` = bất kỳ game.
  final String? gameId;

  /// Bỏ qua lobby do chính user tạo (mặc định: có).
  final bool excludeOwnLobbies;

  const LobbySearchFilter({
    this.radiusKm,
    this.minKarma,
    this.gameId,
    this.excludeOwnLobbies = true,
  });

  @override
  List<Object?> get props => [radiusKm, minKarma, gameId, excludeOwnLobbies];
}
