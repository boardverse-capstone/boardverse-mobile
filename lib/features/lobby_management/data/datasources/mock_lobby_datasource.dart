import '../models/lobby_model.dart';
import '../models/friend_model.dart';

/// Mock data source for lobby management feature.
/// Provides realistic sample data for UI development and testing.
class MockLobbyDatasource {
  // ─── Lobby Config Limits ─────────────────────────────────────────────

  /// Cấu hình giới hạn slider dựa theo thuộc tính số lượng người của game
  static LobbyConfigLimits get mockLobbyConfigLimit => const LobbyConfigLimits(
        minSlots: 4,
        maxSlots: 10,
        suggestedMinSlots: 5,
        suggestedMaxSlots: 10,
        gameName: 'Avalon',
        playerRangeDescription: '5-10 người',
      );

  // ─── Lobby Realtime Users ──────────────────────────────────────────────

  /// Trạng thái danh sách avatar thành viên thay đổi real-time
  static LobbyModel get mockLobbyRealtimeUsers => LobbyModel(
        id: 'lobby_001',
        gameId: 'bg_001',
        gameName: 'Avalon: The Resistance Game',
        cafeId: 'cafe_001',
        cafeName: 'Board Game Hub District 1',
        hostId: 'user_001',
        hostName: 'Minh Player',
        scheduledTime: DateTime.now().add(const Duration(minutes: 30)),
        currentPlayers: 5,
        maxPlayers: 7,
        minPlayers: 5,
        isPublic: true,
        inviteCode: 'AVL2024',
        status: LobbyStatusModel.waiting,
        players: const [
          LobbyPlayerModel(
            id: 'user_001',
            name: 'Minh Player',
            avatarUrl: 'https://i.pravatar.cc/150?u=minh',
            isHost: true,
            isReady: true,
            joinedAt: '2024-01-15T10:00:00Z',
          ),
          LobbyPlayerModel(
            id: 'user_002',
            name: 'Thu Hà',
            avatarUrl: 'https://i.pravatar.cc/150?u=thuha',
            isHost: false,
            isReady: true,
            joinedAt: '2024-01-15T10:05:00Z',
          ),
          LobbyPlayerModel(
            id: 'user_003',
            name: 'Anh Khoa',
            avatarUrl: 'https://i.pravatar.cc/150?u=anhkhoa',
            isHost: false,
            isReady: false,
            joinedAt: '2024-01-15T10:08:00Z',
          ),
          LobbyPlayerModel(
            id: 'user_004',
            name: 'Lan Chi',
            avatarUrl: 'https://i.pravatar.cc/150?u=lanchi',
            isHost: false,
            isReady: true,
            joinedAt: '2024-01-15T10:10:00Z',
          ),
          LobbyPlayerModel(
            id: 'user_005',
            name: 'Hoàng Nam',
            avatarUrl: 'https://i.pravatar.cc/150?u=hoangnam',
            isHost: false,
            isReady: false,
            joinedAt: '2024-01-15T10:12:00Z',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        expiresAt: DateTime.now().add(const Duration(minutes: 20)),
      );

  // ─── Online Friends List ──────────────────────────────────────────────

  /// Danh sách bạn bè đang trực tuyến kèm nút trạng thái
  static List<FriendModel> get mockOnlineFriendsList => const [
        FriendModel(
          id: 'friend_001',
          name: 'Minh Anh',
          avatarUrl: 'https://i.pravatar.cc/150?u=minhanh',
          isOnline: true,
          isInLobby: false,
        ),
        FriendModel(
          id: 'friend_002',
          name: 'Thanh Sơn',
          avatarUrl: 'https://i.pravatar.cc/150?u=thanhson',
          isOnline: true,
          isInLobby: true,
        ),
        FriendModel(
          id: 'friend_003',
          name: 'Phương Linh',
          avatarUrl: 'https://i.pravatar.cc/150?u=phuonglinh',
          isOnline: true,
          isInLobby: false,
        ),
        FriendModel(
          id: 'friend_004',
          name: 'Đức Minh',
          avatarUrl: 'https://i.pravatar.cc/150?u=ducminh',
          isOnline: false,
          isInLobby: false,
        ),
        FriendModel(
          id: 'friend_005',
          name: 'Hải Yến',
          avatarUrl: 'https://i.pravatar.cc/150?u=haiyen',
          isOnline: true,
          isInLobby: false,
        ),
      ];

  // ─── Lobby Dismiss Reasons ────────────────────────────────────────────

  /// Danh mục các thông báo lỗi giải tán phòng
  static List<LobbyDismissReasonModel> get mockLobbyDismissReasons => const [
        LobbyDismissReasonModel(
          code: 'TIMEOUT',
          title: 'Hết giờ chờ',
          message:
              'Phòng đã bị giải tán do không đủ người trong thời gian quy định 20 phút.',
        ),
        LobbyDismissReasonModel(
          code: 'TABLE_CONFLICT',
          title: 'Trùng bàn vật lý',
          message:
              'Phòng đã bị hủy do xung đột đặt bàn với khách hàng khác tại quán.',
        ),
        LobbyDismissReasonModel(
          code: 'HOST_LEFT',
          title: 'Chủ phòng rời đi',
          message: 'Phòng đã bị hủy do chủ phòng đã rời khỏi phòng.',
        ),
        LobbyDismissReasonModel(
          code: 'HOST_CANCELLED',
          title: 'Chủ phòng hủy phòng',
          message: 'Chủ phòng đã chủ động hủy phòng chơi.',
        ),
        LobbyDismissReasonModel(
          code: 'SYSTEM_ERROR',
          title: 'Lỗi hệ thống',
          message: 'Phòng đã bị hủy do lỗi kỹ thuật từ hệ thống.',
        ),
      ];

  // ─── Simulate Realtime Updates ─────────────────────────────────────────

  /// Mô phỏng thêm người mới vào phòng
  static LobbyModel simulateNewPlayerJoined(LobbyModel lobby) {
    final newPlayer = LobbyPlayerModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Người chơi mới',
      avatarUrl: 'https://i.pravatar.cc/150?u=newplayer',
      isHost: false,
      isReady: false,
      joinedAt: DateTime.now().toIso8601String(),
    );

    return LobbyModel(
      id: lobby.id,
      gameId: lobby.gameId,
      gameName: lobby.gameName,
      cafeId: lobby.cafeId,
      cafeName: lobby.cafeName,
      hostId: lobby.hostId,
      hostName: lobby.hostName,
      scheduledTime: lobby.scheduledTime,
      currentPlayers: lobby.currentPlayers + 1,
      maxPlayers: lobby.maxPlayers,
      minPlayers: lobby.minPlayers,
      isPublic: lobby.isPublic,
      inviteCode: lobby.inviteCode,
      status: lobby.status,
      players: [...lobby.players, newPlayer],
      createdAt: lobby.createdAt,
      expiresAt: lobby.expiresAt,
    );
  }
}

// ─── Helper Classes ────────────────────────────────────────────────────────────

class LobbyConfigLimits {
  final int minSlots;
  final int maxSlots;
  final int suggestedMinSlots;
  final int suggestedMaxSlots;
  final String gameName;
  final String playerRangeDescription;

  const LobbyConfigLimits({
    required this.minSlots,
    required this.maxSlots,
    required this.suggestedMinSlots,
    required this.suggestedMaxSlots,
    required this.gameName,
    required this.playerRangeDescription,
  });
}

class LobbyDismissReasonModel {
  final String code;
  final String title;
  final String message;

  const LobbyDismissReasonModel({
    required this.code,
    required this.title,
    required this.message,
  });
}
