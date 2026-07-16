import '../../domain/entities/game_play_configuration_entity.dart';
import '../../domain/entities/game_play_navigation_entity.dart';

class RoomConfigurationModel {
  final int minPlayers;
  final int maxPlayers;
  final int defaultPlayerCount;

  const RoomConfigurationModel({
    required this.minPlayers,
    required this.maxPlayers,
    required this.defaultPlayerCount,
  });

  factory RoomConfigurationModel.fromJson(Map<String, dynamic> json) {
    return RoomConfigurationModel(
      minPlayers: (json['minPlayers'] as num?)?.toInt() ?? 1,
      maxPlayers: (json['maxPlayers'] as num?)?.toInt() ?? 4,
      defaultPlayerCount:
          (json['defaultPlayerCount'] as num?)?.toInt() ?? 2,
    );
  }

  Map<String, dynamic> toJson() => {
        'minPlayers': minPlayers,
        'maxPlayers': maxPlayers,
        'defaultPlayerCount': defaultPlayerCount,
      };

  RoomConfigurationEntity toEntity() => RoomConfigurationEntity(
        minPlayers: minPlayers,
        maxPlayers: maxPlayers,
        defaultPlayerCount: defaultPlayerCount,
      );
}

class GamePlayNavigationModel {
  final String gameTemplateId;
  final String? gameName;
  final PlayMode playMode;
  final bool supportsSoloPlay;
  final NavigationTarget navigationTarget;
  final RoomConfigurationModel roomConfiguration;

  const GamePlayNavigationModel({
    required this.gameTemplateId,
    this.gameName,
    required this.playMode,
    required this.supportsSoloPlay,
    required this.navigationTarget,
    required this.roomConfiguration,
  });

  factory GamePlayNavigationModel.fromJson(Map<String, dynamic> json) {
    final playModeStr = json['playMode'] as String?;
    final playMode = playModeStr != null
        ? (PlayModeX.tryFromApi(playModeStr) ?? PlayMode.group)
        : PlayMode.group;

    return GamePlayNavigationModel(
      gameTemplateId: (json['gameTemplateId'] as String?) ?? '',
      gameName: json['gameName'] as String?,
      playMode: playMode,
      supportsSoloPlay: (json['supportsSoloPlay'] as bool?) ?? false,
      navigationTarget: NavigationTargetX.tryFromApi(
              json['navigationTarget'] as String?) ??
          NavigationTarget.lobbyCreation,
      roomConfiguration: RoomConfigurationModel.fromJson(
        (json['roomConfiguration'] as Map<String, dynamic>?) ??
            const <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'gameTemplateId': gameTemplateId,
        'gameName': gameName,
        'playMode': playMode.apiName,
        'supportsSoloPlay': supportsSoloPlay,
        'navigationTarget': navigationTarget.name,
        'roomConfiguration': roomConfiguration.toJson(),
      };

  GamePlayNavigationEntity toEntity() => GamePlayNavigationEntity(
        gameTemplateId: gameTemplateId,
        gameName: gameName,
        playMode: playMode,
        supportsSoloPlay: supportsSoloPlay,
        navigationTarget: navigationTarget,
        roomConfiguration: roomConfiguration.toEntity(),
      );
}
