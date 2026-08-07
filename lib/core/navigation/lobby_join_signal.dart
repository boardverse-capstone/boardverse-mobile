import 'package:flutter/foundation.dart';

/// Signal phát khi invitee accept lời mời — yêu cầu navigate đến LobbyPage.
///
/// Flow:
/// 1. User ở LobbyInvitesPage → bấm Accept trên invite card
/// 2. `LobbyInviteCubit.acceptInvite()` → backend auto-join
/// 3. Route handler phát `LobbyJoinSignal.instance.request(lobbyId)`
/// 4. `MainScaffold` nhận signal → pop page hiện tại → navigate đến LobbyPage
///
/// Pattern tương tự `LobbySuggestionSignal`.
class LobbyJoinSignal extends ChangeNotifier {
  LobbyJoinSignal._();
  static final LobbyJoinSignal instance = LobbyJoinSignal._();

  String? _pendingLobbyId;

  /// Lobby ID đang chờ navigate. `null` = không có yêu cầu.
  String? get pendingLobbyId => _pendingLobbyId;

  /// Phát yêu cầu navigate đến lobby.
  void request(String lobbyId) {
    _pendingLobbyId = lobbyId;
    if (hasListeners) notifyListeners();
  }

  /// Đánh dấu đã xử lý — gọi sau khi đã navigate thành công.
  void consume() {
    _pendingLobbyId = null;
  }
}
