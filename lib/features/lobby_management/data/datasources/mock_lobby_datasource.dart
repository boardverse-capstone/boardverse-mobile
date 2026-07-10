import 'dart:async';
import 'dart:math';

import '../models/friend_model.dart';
import '../models/lobby_model.dart';

/// Mock data source for lobby management feature.
///
/// Phase 2 (Task 3) thay đổi lớn:
/// - Hỗ trợ nhiều lobby cùng tồn tại (multi-lobby store).
/// - Có filter Karma (BR-10) + bán kính (BR-08) cho searchNearbyLobbies.
/// - Realtime stream mô phỏng join liên tục (Stream.periodic 5s).
/// - Hỗ trợ auto-create booking khi lobby đầy (Luồng A).
/// - BR-07: validate maxSlots không vượt booking.seatCount.
class MockLobbyDatasource {
  // ─── Seed Data Defaults ─────────────────────────────────────────────

  /// Cấu hình giới hạn slider dựa theo thuộc tính số lượng người của game
  static LobbyConfigLimits get mockLobbyConfigLimit => const LobbyConfigLimits(
        minSlots: 4,
        maxSlots: 10,
        suggestedMinSlots: 5,
        suggestedMaxSlots: 10,
        gameName: 'Avalon',
        playerRangeDescription: '5-10 người',
      );

  /// Trạng thái realtime seed cho UI phát triển. Single-instance cố định.
  static LobbyModel get mockLobbyRealtimeUsers {
    final now = DateTime.now();
    return _lobbiesById['lobby_001'] ?? LobbyModel(
      id: 'lobby_001',
      gameId: 'bg_001',
      gameName: 'Avalon: The Resistance Game',
      gameImageUrl: 'https://picsum.photos/seed/avalon/200',
      cafeId: 'cafe_001',
      cafeName: 'Board Game Hub District 1',
      hostId: 'user_001',
      hostName: 'Minh Player',
      scheduledTime: now.add(const Duration(minutes: 30)),
      currentPlayers: 5,
      maxPlayers: 7,
      minPlayers: 5,
      isPublic: true,
      inviteCode: 'AVL2024',
      status: LobbyStatusModel.open,
      players: const [
        LobbyPlayerModel(
          id: 'user_001',
          name: 'Minh Player',
          avatarUrl: 'https://picsum.photos/seed/minh/150',
          isHost: true,
          isReady: true,
          joinedAt: '2024-01-15T10:00:00Z',
          karma: 92,
        ),
        LobbyPlayerModel(
          id: 'user_002',
          name: 'Thu Hà',
          avatarUrl: 'https://picsum.photos/seed/thuha/150',
          isHost: false,
          isReady: true,
          joinedAt: '2024-01-15T10:05:00Z',
          karma: 78,
        ),
        LobbyPlayerModel(
          id: 'user_003',
          name: 'Anh Khoa',
          avatarUrl: 'https://picsum.photos/seed/anhkhoa/150',
          isHost: false,
          isReady: false,
          joinedAt: '2024-01-15T10:08:00Z',
          karma: 65,
        ),
        LobbyPlayerModel(
          id: 'user_004',
          name: 'Lan Chi',
          avatarUrl: 'https://picsum.photos/seed/lanchi/150',
          isHost: false,
          isReady: true,
          joinedAt: '2024-01-15T10:10:00Z',
          karma: 88,
        ),
        LobbyPlayerModel(
          id: 'user_005',
          name: 'Hoàng Nam',
          avatarUrl: 'https://picsum.photos/seed/hoangnam/150',
          isHost: false,
          isReady: false,
          joinedAt: '2024-01-15T10:12:00Z',
          karma: 55,
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      timeoutAt: now.add(const Duration(minutes: 20)),
      minimumKarma: 50,
      searchRadiusKm: 10,
      distanceKm: 2.5,
      cafeLat: 10.7769,
      cafeLng: 106.7009,
    );
  }

  // ─── Multi-Lobby Store (in-memory) ─────────────────────────────────

  /// Map id → LobbyModel. Public để repository impl truy cập trực tiếp.
  static final Map<String, LobbyModel> _lobbiesById = {};

  /// Counter sinh id cho lobby mới.
  static int _idCounter = 100;

  static Timer? _realtimeTicker;
  static final _rng = Random();

  /// Khởi tạo seed data lần đầu.
  static void ensureSeeded() {
    if (_lobbiesById.isNotEmpty) return;
    _lobbiesById['lobby_001'] = mockLobbyRealtimeUsers;
    _seedNearbyLobbies();
  }

  /// Sinh ~8 lobby "khả dụng" quanh TP.HCM phục vụ search.
  static void _seedNearbyLobbies() {
    final seedData = <Map<String, dynamic>>[
      {
        'gameName': 'Catan',
        'gameImageUrl': 'https://picsum.photos/seed/catan/200',
        'cafeName': 'Meeple Station Q1',
        'hostName': 'Trần Văn A',
        'minPlayers': 3,
        'maxPlayers': 4,
        'current': 2,
        'minKarma': 40,
        'radius': 8,
        'dist': 1.2,
        'lat': 10.7769,
        'lng': 106.7009,
      },
      {
        'gameName': 'Wingspan',
        'gameImageUrl': 'https://picsum.photos/seed/wingspan/200',
        'cafeName': 'Dice & Slice Q3',
        'hostName': 'Lê Thị B',
        'minPlayers': 2,
        'maxPlayers': 5,
        'current': 3,
        'minKarma': 60,
        'radius': 12,
        'dist': 2.8,
        'lat': 10.7820,
        'lng': 106.6950,
      },
      {
        'gameName': 'Splendor',
        'gameImageUrl': 'https://picsum.photos/seed/splendor/200',
        'cafeName': 'Board & Brew Bình Thạnh',
        'hostName': 'Phạm Văn C',
        'minPlayers': 2,
        'maxPlayers': 4,
        'current': 1,
        'minKarma': 30,
        'radius': 15,
        'dist': 4.5,
        'lat': 10.8010,
        'lng': 106.7100,
      },
      {
        'gameName': 'Gloomhaven',
        'gameImageUrl': 'https://picsum.photos/seed/gloomhaven/200',
        'cafeName': 'Quest Board Game',
        'hostName': 'Hoàng Thị D',
        'minPlayers': 2,
        'maxPlayers': 4,
        'current': 2,
        'minKarma': 70,
        'radius': 20,
        'dist': 6.1,
        'lat': 10.8100,
        'lng': 106.7200,
      },
      {
        'gameName': 'Azul',
        'gameImageUrl': 'https://picsum.photos/seed/azul/200',
        'cafeName': 'Tabletop Thủ Đức',
        'hostName': 'Đỗ Văn E',
        'minPlayers': 2,
        'maxPlayers': 4,
        'current': 3,
        'minKarma': 50,
        'radius': 10,
        'dist': 3.7,
        'lat': 10.8500,
        'lng': 106.7700,
      },
      {
        'gameName': 'Codenames',
        'gameImageUrl': 'https://picsum.photos/seed/codenames/200',
        'cafeName': 'Meeple Station Q2',
        'hostName': 'Nguyễn Thị F',
        'minPlayers': 4,
        'maxPlayers': 8,
        'current': 6,
        'minKarma': 50,
        'radius': 8,
        'dist': 1.9,
        'lat': 10.7780,
        'lng': 106.7050,
      },
      {
        'gameName': 'Dixit',
        'gameImageUrl': 'https://picsum.photos/seed/dixit/200',
        'cafeName': 'The Cardboard Café',
        'hostName': 'Võ Văn G',
        'minPlayers': 3,
        'maxPlayers': 6,
        'current': 2,
        'minKarma': 35,
        'radius': 10,
        'dist': 5.5,
        'lat': 10.7600,
        'lng': 106.6900,
      },
      {
        'gameName': 'Terraforming Mars',
        'gameImageUrl': 'https://picsum.photos/seed/terraforming/200',
        'cafeName': 'Strategy Lounge',
        'hostName': 'Bùi Thị H',
        'minPlayers': 2,
        'maxPlayers': 5,
        'current': 4,
        'minKarma': 75,
        'radius': 20,
        'dist': 8.3,
        'lat': 10.8200,
        'lng': 106.7300,
      },
    ];

    final now = DateTime.now();
    for (var i = 0; i < seedData.length; i++) {
      final s = seedData[i];
      final id = 'lobby_seed_${i + 1}';
      final max = s['maxPlayers'] as int;
      final cur = s['current'] as int;
      _lobbiesById[id] = LobbyModel(
        id: id,
        gameId: 'bg_seed_${i + 1}',
        gameName: s['gameName'] as String,
        gameImageUrl: s['gameImageUrl'] as String,
        cafeId: 'cafe_seed_${i + 1}',
        cafeName: s['cafeName'] as String,
        hostId: 'user_seed_${i + 1}',
        hostName: s['hostName'] as String,
        scheduledTime: now.add(Duration(hours: 1 + i)),
        currentPlayers: cur,
        maxPlayers: max,
        minPlayers: s['minPlayers'] as int,
        isPublic: true,
        inviteCode: 'SEED${i + 1}${_rng.nextInt(999)}',
        status: LobbyStatusModel.open,
        players: _buildSeedPlayers(cur, s['hostName'] as String),
        createdAt: now.subtract(Duration(minutes: 5 + i)),
        timeoutAt: now.add(Duration(minutes: 45 - i)),
        minimumKarma: (s['minKarma'] as int).toDouble(),
        searchRadiusKm: (s['radius'] as int).toDouble(),
        distanceKm: (s['dist'] as num).toDouble(),
        cafeLat: (s['lat'] as num).toDouble(),
        cafeLng: (s['lng'] as num).toDouble(),
      );
    }
  }

  static List<LobbyPlayerModel> _buildSeedPlayers(int current, String hostName) {
    final names = [
      'Quốc Bảo', 'Mai Linh', 'Thanh Tùng', 'Kim Anh', 'Hải Đăng',
      'Phương Thảo', 'Minh Khôi', 'Gia Hân',
    ];
    final list = <LobbyPlayerModel>[
      LobbyPlayerModel(
        id: 'user_seed_host_${current}_$_idCounter',
        name: hostName,
        avatarUrl: 'https://picsum.photos/seed/${hostName.hashCode}/150',
        isHost: true,
        isReady: true,
        joinedAt: DateTime.now()
            .subtract(const Duration(minutes: 15))
            .toIso8601String(),
        karma: 85 + _rng.nextInt(15).toDouble(),
      ),
    ];
    for (var i = 1; i < current; i++) {
      list.add(LobbyPlayerModel(
        id: 'user_seed_member_${i}_$_idCounter',
        name: names[i % names.length],
        avatarUrl: 'https://picsum.photos/seed/seed${names[i % names.length].hashCode}/150',
        isHost: false,
        isReady: _rng.nextBool(),
        joinedAt: DateTime.now()
            .subtract(Duration(minutes: 14 - i))
            .toIso8601String(),
        karma: (40 + _rng.nextInt(50)).toDouble(),
      ));
    }
    return list;
  }

  // ─── Lobby CRUD ────────────────────────────────────────────────────

  static LobbyModel createLobby({
    required String gameId,
    required String gameName,
    required String? gameImageUrl,
    required String cafeId,
    required String cafeName,
    required String hostId,
    required String hostName,
    required DateTime scheduledTime,
    required int maxPlayers,
    required int minPlayers,
    required bool isPublic,
    double minimumKarma = 0,
    double searchRadiusKm = 5,
    Duration leadTime = const Duration(minutes: 20),
    String? bookingId,
  }) {
    ensureSeeded();
    final id = _idCounter++;
    final now = DateTime.now();
    final lobby = LobbyModel(
      id: 'lobby_$id',
      gameId: gameId,
      gameName: gameName,
      gameImageUrl: gameImageUrl,
      cafeId: cafeId,
      cafeName: cafeName,
      hostId: hostId,
      hostName: hostName,
      scheduledTime: scheduledTime,
      currentPlayers: 1,
      maxPlayers: maxPlayers,
      minPlayers: minPlayers,
      isPublic: isPublic,
      inviteCode: id.toRadixString(36).toUpperCase().padLeft(4, 'X'),
      status: LobbyStatusModel.open,
      players: [
        LobbyPlayerModel(
          id: hostId,
          name: hostName,
          avatarUrl: 'https://picsum.photos/seed/$hostId/150',
          isHost: true,
          isReady: true,
          joinedAt: now.toIso8601String(),
          karma: 90,
        ),
      ],
      createdAt: now,
      timeoutAt: scheduledTime.subtract(leadTime),
      bookingId: bookingId,
      minimumKarma: minimumKarma,
      searchRadiusKm: searchRadiusKm,
    );
    _lobbiesById[lobby.id] = lobby;
    return lobby;
  }

  static LobbyModel? getLobbyById(String id) => _lobbiesById[id];

  static List<LobbyModel> getAll() =>
      List<LobbyModel>.unmodifiable(_lobbiesById.values);

  /// Ghi đè lobby trong store (dùng khi cancel/update status).
  static void setLobby(String id, LobbyModel updated) {
    if (_lobbiesById.containsKey(id)) {
      _lobbiesById[id] = updated;
    }
  }

  // ─── Realtime Stream Simulation ────────────────────────────────────

  /// Stream realtime cho 1 lobby. Phát initial state ngay + cập nhật định kỳ.
  static Stream<LobbyModel> watchLobby(String lobbyId) {
    ensureSeeded();
    final initial = _lobbiesById[lobbyId];
    if (initial == null) {
      return Stream<LobbyModel>.empty();
    }
    return Stream<LobbyModel>.multi((controller) {
      // Phát state hiện tại ngay.
      controller.add(_lobbiesById[lobbyId] ?? initial);
      // Tick 5s: mô phỏng join tự động (chỉ khi còn slot).
      final timer = Timer.periodic(const Duration(seconds: 5), (_) {
        final lobby = _lobbiesById[lobbyId];
        if (lobby == null) {
          controller.close();
          return;
        }
        if (lobby.status != LobbyStatusModel.open) return;
        if (lobby.isFull) return;
        // Tăng currentPlayers & nếu đạt max thì chuyển status → full.
        final shouldJoin = _rng.nextDouble() < 0.55;
        if (!shouldJoin) return;
        final newPlayer = LobbyPlayerModel(
          id: 'user_auto_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Người chơi mới',
          avatarUrl:
              'https://picsum.photos/seed/auto${_rng.nextInt(999)}/150',
          isHost: false,
          isReady: false,
          joinedAt: DateTime.now().toIso8601String(),
          karma: (45 + _rng.nextInt(50)).toDouble(),
        );
        final updated = lobby.copyWith(
          currentPlayers: lobby.currentPlayers + 1,
          players: [...lobby.players, newPlayer],
          status: (lobby.currentPlayers + 1 >= lobby.maxPlayers)
              ? LobbyStatusModel.full
              : lobby.status,
        );
        _lobbiesById[lobbyId] = updated;
        controller.add(updated);
      });
      controller.onCancel = () {
        timer.cancel();
      };
    });
  }

  static void stopAllTimers() {
    _realtimeTicker?.cancel();
    _realtimeTicker = null;
  }

  // ─── Online Friends List ──────────────────────────────────────────────

  static List<FriendModel> get mockOnlineFriendsList => const [
        FriendModel(
          id: 'friend_001',
          name: 'Minh Anh',
          avatarUrl: 'https://picsum.photos/seed/minhanh/150',
          isOnline: true,
          isInLobby: false,
        ),
        FriendModel(
          id: 'friend_002',
          name: 'Thanh Sơn',
          avatarUrl: 'https://picsum.photos/seed/thanhson/150',
          isOnline: true,
          isInLobby: true,
        ),
        FriendModel(
          id: 'friend_003',
          name: 'Phương Linh',
          avatarUrl: 'https://picsum.photos/seed/phuonglinh/150',
          isOnline: true,
          isInLobby: false,
        ),
        FriendModel(
          id: 'friend_004',
          name: 'Đức Minh',
          avatarUrl: 'https://picsum.photos/seed/ducminh/150',
          isOnline: false,
          isInLobby: false,
        ),
        FriendModel(
          id: 'friend_005',
          name: 'Hải Yến',
          avatarUrl: 'https://picsum.photos/seed/haiyen/150',
          isOnline: true,
          isInLobby: false,
        ),
      ];

  static FriendModel? getFriendById(String id) {
    return mockOnlineFriendsList.cast<FriendModel?>().firstWhere(
          (f) => f?.id == id,
          orElse: () => null,
        );
  }

  // ─── Lobby Dismiss Reasons ────────────────────────────────────────────

  static List<LobbyDismissReasonModel> get mockLobbyDismissReasons => const [
        LobbyDismissReasonModel(
          code: 'TIMEOUT_FAILED',
          title: 'Hết hạn tuyển người (BR-08)',
          message:
              'Đến giờ hẹn chơi trừ đi lead-time mà phòng vẫn chưa đủ số người tối thiểu. Hệ thống đã tự động giải tán để giải phóng ghế.',
        ),
        LobbyDismissReasonModel(
          code: 'HOST_CANCELLED',
          title: 'Chủ phòng đã hủy',
          message: 'Trưởng phòng chờ đã chủ động giải tán phòng.',
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
          code: 'SYSTEM_ERROR',
          title: 'Lỗi hệ thống',
          message: 'Phòng đã bị hủy do lỗi kỹ thuật từ hệ thống.',
        ),
      ];

  // ─── Helpers ────────────────────────────────────────────────────────

  /// Mô phỏng thêm người mới vào phòng (giữ để tương thích nội bộ / test).
  static LobbyModel simulateNewPlayerJoined(LobbyModel lobby) {
    final newPlayer = LobbyPlayerModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Người chơi mới',
      avatarUrl: 'https://picsum.photos/seed/newplayer/150',
      isHost: false,
      isReady: false,
      joinedAt: DateTime.now().toIso8601String(),
    );

    return lobby.copyWith(
      currentPlayers: lobby.currentPlayers + 1,
      players: [...lobby.players, newPlayer],
      status: (lobby.currentPlayers + 1 >= lobby.maxPlayers)
          ? LobbyStatusModel.full
          : lobby.status,
    );
  }

  /// Mô phỏng thêm friend vào lobby — dùng cho dev simulate.
  /// Trả về lobby đã cập nhật; null nếu lobby không tồn tại hoặc đã đầy.
  static LobbyModel? simulateJoinPlayerById(String lobbyId, LobbyPlayerModel player) {
    final lobby = _lobbiesById[lobbyId];
    if (lobby == null) return null;
    if (lobby.isFull) return null;
    final updated = lobby.copyWith(
      currentPlayers: lobby.currentPlayers + 1,
      players: [...lobby.players, player],
      status: (lobby.currentPlayers + 1 >= lobby.maxPlayers)
          ? LobbyStatusModel.full
          : lobby.status,
    );
    _lobbiesById[lobbyId] = updated;
    return updated;
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
