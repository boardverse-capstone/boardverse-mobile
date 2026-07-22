import 'package:flutter/foundation.dart';
import '../../features/matchmaking_discovery/domain/entities/board_game_entity.dart';

/// Broadcast signal dùng để đề xuất "chuyển sang screen Lobby cho game X".
///
/// Flow nghiệp vụ (theo yêu cầu của người dùng):
/// - Discovery chỉ tập trung tìm boardgame + quán cafe gần.
/// - Tất cả nghiệp vụ liên quan đến lobby (xem phòng, search phòng, join,
///   create) phải nằm trong screen lobby (`NearbyLobbiesPage`).
/// - Khi user bấm "Chơi cùng nhóm" trong `BoardGameDetailPage`, ta phát
///   signal này với `game` đã chọn → MainScaffold chuyển sang tab Discovery
///   → DiscoveryTab nhảy vào sub-tab "Phòng chờ" → NearbyLobbiesPage bật
///   advanced filter + preselect game → user có thể chọn "Tìm phòng" hoặc
///   "Tạo phòng" trong cùng một màn hình lobby.
///
/// Pattern tương tự `DiscoveryResetSignal` / `BookingRefreshSignal` đã có.
class LobbySuggestionSignal extends ChangeNotifier {
  LobbySuggestionSignal._();
  static final LobbySuggestionSignal instance = LobbySuggestionSignal._();

  BoardGameEntity? _pendingGame;

  /// Game đang chờ được xử lý bởi `NearbyLobbiesPage`. `null` = không có
  /// yêu cầu pending.
  BoardGameEntity? get pendingGame => _pendingGame;

  /// Phát yêu cầu: MainScaffold sẽ chuyển sang tab Discovery + DiscoveryTab
  /// sẽ nhảy vào "Phòng chờ" + NearbyLobbiesPage sẽ preselect [game].
  void request(BoardGameEntity game) {
    _pendingGame = game;
    if (hasListeners) notifyListeners();
  }

  /// Đánh dấu yêu cầu đã được xử lý — gọi sau khi NearbyLobbiesPage đã
  /// consume [pendingGame] để tránh apply lại khi user switch tab.
  void consume() {
    if (_pendingGame == null) return;
    _pendingGame = null;
  }
}
