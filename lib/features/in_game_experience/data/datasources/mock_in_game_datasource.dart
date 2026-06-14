import '../models/in_game_session_model.dart';

/// Mock data source for in-game experience feature.
/// Provides realistic sample data for UI development and testing.
class MockInGameDatasource {
  // ─── Active Session Details ────────────────────────────────────────────

  /// Thông tin phiên chơi hiện tại
  static InGameSessionModel get mockActiveSessionDetails => InGameSessionModel(
        sessionId: 'session_001',
        bookingId: 'BOOK2024_001',
        cafeId: 'cafe_001',
        cafeName: 'Board Game Hub District 1',
        gameId: 'bg_001',
        gameName: 'Avalon: The Resistance Game',
        tableNumber: 5,
        players: const [
          InGamePlayerModel(
            id: 'user_001',
            name: 'Minh Player',
            avatarUrl: 'https://i.pravatar.cc/150?u=minh',
            isPresent: true,
          ),
          InGamePlayerModel(
            id: 'user_002',
            name: 'Thu Hà',
            avatarUrl: 'https://i.pravatar.cc/150?u=thuha',
            isPresent: true,
          ),
          InGamePlayerModel(
            id: 'user_003',
            name: 'Anh Khoa',
            avatarUrl: 'https://i.pravatar.cc/150?u=anhkhoa',
            isPresent: true,
          ),
          InGamePlayerModel(
            id: 'user_004',
            name: 'Lan Chi',
            avatarUrl: 'https://i.pravatar.cc/150?u=lanchi',
            isPresent: true,
          ),
          InGamePlayerModel(
            id: 'user_005',
            name: 'Hoàng Nam',
            avatarUrl: 'https://i.pravatar.cc/150?u=hoangnam',
            isPresent: true,
          ),
        ],
        startTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 23)),
        status: InGameSessionStatusModel.active,
        playDuration: const Duration(hours: 1, minutes: 23),
        isCheckingInventory: false,
      );

  // ─── Inventory Checking Status ────────────────────────────────────────

  /// Trạng thái chờ kiểm kho
  static InGameSessionModel get mockInventoryCheckingStatus => InGameSessionModel(
        sessionId: 'session_001',
        bookingId: 'BOOK2024_001',
        cafeId: 'cafe_001',
        cafeName: 'Board Game Hub District 1',
        gameId: 'bg_001',
        gameName: 'Avalon: The Resistance Game',
        tableNumber: 5,
        players: const [
          InGamePlayerModel(
            id: 'user_001',
            name: 'Minh Player',
            avatarUrl: 'https://i.pravatar.cc/150?u=minh',
            isPresent: true,
          ),
          InGamePlayerModel(
            id: 'user_002',
            name: 'Thu Hà',
            avatarUrl: 'https://i.pravatar.cc/150?u=thuha',
            isPresent: true,
          ),
          InGamePlayerModel(
            id: 'user_003',
            name: 'Anh Khoa',
            avatarUrl: 'https://i.pravatar.cc/150?u=anhkhoa',
            isPresent: true,
          ),
          InGamePlayerModel(
            id: 'user_004',
            name: 'Lan Chi',
            avatarUrl: 'https://i.pravatar.cc/150?u=lanchi',
            isPresent: true,
          ),
          InGamePlayerModel(
            id: 'user_005',
            name: 'Hoàng Nam',
            avatarUrl: 'https://i.pravatar.cc/150?u=hoangnam',
            isPresent: true,
          ),
        ],
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        status: InGameSessionStatusModel.checkingOut,
        playDuration: const Duration(hours: 2),
        isCheckingInventory: true,
      );
}
