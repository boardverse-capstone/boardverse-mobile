import '../../domain/entities/game_play_configuration_entity.dart';

class GamePlayConfigurationModel {
  final String gameTemplateId;
  final String gameName;
  final int minPlayers;
  final int maxPlayers;
  final bool supportsSoloPlay;
  final List<PlayMode> availablePlayModes;

  const GamePlayConfigurationModel({
    required this.gameTemplateId,
    required this.gameName,
    required this.minPlayers,
    required this.maxPlayers,
    required this.supportsSoloPlay,
    required this.availablePlayModes,
  });

  factory GamePlayConfigurationModel.fromJson(Map<String, dynamic> json) {
    final modes = (json['availablePlayModes'] as List?)
            ?.cast<dynamic>()
            .map((e) {
              // Backend trả về list of strings ("Solo", "Group") hoặc
              // list of ints (0, 1) — chấp nhận cả hai.
              if (e is String) return PlayModeX.tryFromApi(e);
              if (e is int) {
                switch (e) {
                  case 0:
                    return PlayMode.solo;
                  case 1:
                    return PlayMode.group;
                }
              }
              return null;
            })
            .whereType<PlayMode>()
            .toList() ??
        const <PlayMode>[];

    return GamePlayConfigurationModel(
      gameTemplateId: (json['gameTemplateId'] as String?) ?? '',
      gameName: (json['gameName'] as String?) ?? '',
      minPlayers: (json['minPlayers'] as num?)?.toInt() ?? 1,
      maxPlayers: (json['maxPlayers'] as num?)?.toInt() ?? 4,
      supportsSoloPlay: (json['supportsSoloPlay'] as bool?) ?? false,
      availablePlayModes: modes,
    );
  }

  Map<String, dynamic> toJson() => {
        'gameTemplateId': gameTemplateId,
        'gameName': gameName,
        'minPlayers': minPlayers,
        'maxPlayers': maxPlayers,
        'supportsSoloPlay': supportsSoloPlay,
        'availablePlayModes':
            availablePlayModes.map((m) => m.apiValue).toList(),
      };

  GamePlayConfigurationEntity toEntity() => GamePlayConfigurationEntity(
        gameTemplateId: gameTemplateId,
        gameName: gameName,
        minPlayers: minPlayers,
        maxPlayers: maxPlayers,
        supportsSoloPlay: supportsSoloPlay,
        availablePlayModes: availablePlayModes,
      );
}
