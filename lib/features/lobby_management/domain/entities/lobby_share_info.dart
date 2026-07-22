import 'package:equatable/equatable.dart';

/// Thông tin share code của một lobby.
///
/// Backend: GET /api/v1/lobbies/{lobbyId}/share-info
/// Response: { lobbyId, shareCode, isPrivate, lobbyStatus }
class LobbyShareInfo extends Equatable {
  /// ID của lobby.
  final String lobbyId;

  /// Mã share code (8 ký tự alphanumeric, uppercase).
  /// VD: "K7H3NP9X"
  final String shareCode;

  /// Lobby có phải private hay không.
  final bool isPrivate;

  /// Trạng thái hiện tại của lobby.
  final String lobbyStatus;

  const LobbyShareInfo({
    required this.lobbyId,
    required this.shareCode,
    required this.isPrivate,
    required this.lobbyStatus,
  });

  @override
  List<Object?> get props => [lobbyId, shareCode, isPrivate, lobbyStatus];
}
