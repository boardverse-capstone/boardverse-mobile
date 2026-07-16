import 'package:equatable/equatable.dart';

import 'game_play_configuration_entity.dart';

/// Mục tiêu điều hướng từ backend `play-navigation` response.
enum NavigationTarget {
  /// Tạo phòng chờ nhóm — chuyển sang `LobbyConfigPage`.
  lobbyCreation,

  /// Đặt bàn trực tiếp 1 người — chuyển sang `BookingSummaryPage`
  /// (SoloBooking flow).
  soloBooking,
}

extension NavigationTargetX on NavigationTarget {
  static NavigationTarget? tryFromApi(String? value) {
    switch (value) {
      case 'LobbyCreation':
        return NavigationTarget.lobbyCreation;
      case 'SoloBooking':
        return NavigationTarget.soloBooking;
      default:
        return null;
    }
  }
}

/// Kết quả `POST /api/v1/board-games/{id}/play-navigation` — dùng để
/// quyết định mở màn Lobby hay Solo Booking dựa trên `navigationTarget`.
class GamePlayNavigationEntity extends Equatable {
  final String gameTemplateId;
  final String? gameName;
  final PlayMode playMode;
  final bool supportsSoloPlay;
  final NavigationTarget navigationTarget;
  final RoomConfigurationEntity roomConfiguration;

  const GamePlayNavigationEntity({
    required this.gameTemplateId,
    this.gameName,
    required this.playMode,
    required this.supportsSoloPlay,
    required this.navigationTarget,
    required this.roomConfiguration,
  });

  /// Helper: có phải luồng solo booking hay không.
  bool get isSoloBooking =>
      navigationTarget == NavigationTarget.soloBooking;

  /// Helper: có phải luồng lobby creation hay không.
  bool get isLobbyCreation =>
      navigationTarget == NavigationTarget.lobbyCreation;

  @override
  List<Object?> get props => [
        gameTemplateId,
        gameName,
        playMode,
        supportsSoloPlay,
        navigationTarget,
        roomConfiguration,
      ];
}
