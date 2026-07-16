import 'package:equatable/equatable.dart';

/// Chế độ chơi — map từ `playMode` (0/1) và `availablePlayModes[]`
/// trong response backend.
enum PlayMode {
  /// `0` — chỉ hợp lệ khi `minPlayers == 1`.
  solo,

  /// `1` — chơi nhóm, mặc định cho mọi tựa game.
  group,
}

extension PlayModeX on PlayMode {
  int get apiValue {
    switch (this) {
      case PlayMode.solo:
        return 0;
      case PlayMode.group:
        return 1;
    }
  }

  String get apiName {
    switch (this) {
      case PlayMode.solo:
        return 'Solo';
      case PlayMode.group:
        return 'Group';
    }
  }

  static PlayMode? tryFromApi(String? value) {
    switch (value) {
      case 'Solo':
        return PlayMode.solo;
      case 'Group':
        return PlayMode.group;
      default:
        return null;
    }
  }
}

/// Cấu hình phòng trả về từ `play-navigation` — dùng để giới hạn
/// slider/input số người khi tạo lobby.
class RoomConfigurationEntity extends Equatable {
  final int minPlayers;
  final int maxPlayers;
  final int defaultPlayerCount;

  const RoomConfigurationEntity({
    required this.minPlayers,
    required this.maxPlayers,
    required this.defaultPlayerCount,
  });

  @override
  List<Object?> get props => [minPlayers, maxPlayers, defaultPlayerCount];
}

/// Cấu hình chơi của tựa game — response `GET /api/v1/board-games/{id}/play-configuration`.
/// Dùng để quyết định UI có hiển thị nút "Chơi một mình" hay không.
class GamePlayConfigurationEntity extends Equatable {
  final String gameTemplateId;
  final String gameName;
  final int minPlayers;
  final int maxPlayers;
  final bool supportsSoloPlay;
  final List<PlayMode> availablePlayModes;

  const GamePlayConfigurationEntity({
    required this.gameTemplateId,
    required this.gameName,
    required this.minPlayers,
    required this.maxPlayers,
    required this.supportsSoloPlay,
    required this.availablePlayModes,
  });

  /// Helper: có hỗ trợ chơi solo hay không.
  bool get canPlaySolo =>
      supportsSoloPlay && availablePlayModes.contains(PlayMode.solo);

  /// Helper: có hỗ trợ chơi nhóm hay không.
  bool get canPlayGroup => availablePlayModes.contains(PlayMode.group);

  @override
  List<Object?> get props => [
        gameTemplateId,
        gameName,
        minPlayers,
        maxPlayers,
        supportsSoloPlay,
        availablePlayModes,
      ];
}
