import 'package:flutter/foundation.dart';

/// Signal phát khi user rời khỏi lobby (bấm "Rời phòng" trên LobbyPage).
///
/// Flow:
/// 1. User ở LobbyPage → bấm "Rời phòng" → xác nhận trong dialog
/// 2. LobbyPage gọi `LobbyLeftSignal.instance.request()`
/// 3. `LobbiesPage` nhận signal → switch sang tab "Của tôi" (index 1)
/// 4. `MainScaffold` nhận signal → pop về root (LobbyPage pop) + switch tab Lobbies
///
/// Pattern tương tự `LobbyJoinSignal`.
class LobbyLeftSignal extends ChangeNotifier {
  LobbyLeftSignal._();
  static final LobbyLeftSignal instance = LobbyLeftSignal._();

  /// Phát yêu cầu chuyển về tab Lobbies sau khi rời lobby.
  void request() {
    if (hasListeners) notifyListeners();
  }
}
