import 'dart:async';
import 'dart:math';

import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../domain/entities/friend_entity.dart';
import '../../../domain/entities/lobby_entity.dart';
import '../../../domain/entities/lobby_summary.dart';
import '../../models/friend_model.dart';
import '../../models/lobby_model.dart';
import '../base/lobby_remote_datasource.dart';

/// Mock implementation của [LobbyRemoteDatasource].
/// Toàn bộ state lưu trong memory; không yêu cầu backend.
///
/// Realtime được giả lập ở `MockLobbyRealtimeService` (Phase 2) — file
/// này chỉ cung cấp các REST-shaped methods.
class MockLobbyRemoteDatasource implements LobbyRemoteDatasource {
  MockLobbyRemoteDatasource();

  // ════════════════════════════════════════════════════════════════════
  // In-memory store (lifted nguyên xi từ MockLobbyDatasource cũ để giữ
  // tương thích với data seed dùng bởi các phần khác của app).
  // ════════════════════════════════════════════════════════════════════

  static final Map<String, LobbyModel> _lobbiesById = {};
  static int _idCounter = 100;
  static final _rng = Random();

  static void ensureSeeded() {
    if (_lobbiesById.isNotEmpty) return;
    _lobbiesById['lobby_001'] = _mockLobbyRealtimeUsers;
    _seedNearbyLobbies();
  }

  static LobbyModel get _mockLobbyRealtimeUsers {
    final now = DateTime.now();
    return LobbyModel(
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

  static void _seedNearbyLobbies() {
    final seedData = <Map<String, dynamic>>[
      _seed('Catan', 'Meeple Station Q1', 'Trần Văn A', 3, 4, 2, 40, 8, 1.2, 10.7769, 106.7009),
      _seed('Wingspan', 'Dice & Slice Q3', 'Lê Thị B', 2, 5, 3, 60, 12, 2.8, 10.7820, 106.6950),
      _seed('Splendor', 'Board & Brew Bình Thạnh', 'Phạm Văn C', 2, 4, 1, 30, 15, 4.5, 10.8010, 106.7100),
      _seed('Gloomhaven', 'Quest Board Game', 'Hoàng Thị D', 2, 4, 2, 70, 20, 6.1, 10.8100, 106.7200),
      _seed('Azul', 'Tabletop Thủ Đức', 'Đỗ Văn E', 2, 4, 3, 50, 10, 3.7, 10.8500, 106.7700),
      _seed('Codenames', 'Meeple Station Q2', 'Nguyễn Thị F', 4, 8, 6, 50, 8, 1.9, 10.7780, 106.7050),
      _seed('Dixit', 'The Cardboard Café', 'Võ Văn G', 3, 6, 2, 35, 10, 5.5, 10.7600, 106.6900),
      _seed('Terraforming Mars', 'Strategy Lounge', 'Bùi Thị H', 2, 5, 4, 75, 20, 8.3, 10.8200, 106.7300),
    ];

    final now = DateTime.now();
    for (var i = 0; i < seedData.length; i++) {
      final s = seedData[i];
      final id = 'lobby_seed_${i + 1}';
      _lobbiesById[id] = LobbyModel(
        id: id,
        gameId: 'bg_seed_${i + 1}',
        gameName: s['gameName'] as String,
        gameImageUrl: 'https://picsum.photos/seed/$id/200',
        cafeId: 'cafe_seed_${i + 1}',
        cafeName: s['cafeName'] as String,
        hostId: 'user_seed_${i + 1}',
        hostName: s['hostName'] as String,
        scheduledTime: now.add(Duration(hours: 1 + i)),
        currentPlayers: s['current'] as int,
        maxPlayers: s['maxPlayers'] as int,
        minPlayers: s['minPlayers'] as int,
        isPublic: true,
        inviteCode: 'SEED${i + 1}${_rng.nextInt(999)}',
        status: LobbyStatusModel.open,
        players: _buildSeedPlayers(s['current'] as int, s['hostName'] as String),
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

  static Map<String, dynamic> _seed(
    String gameName,
    String cafeName,
    String hostName,
    int minPlayers,
    int maxPlayers,
    int current,
    int minKarma,
    int radius,
    double dist,
    double lat,
    double lng,
  ) =>
      {
        'gameName': gameName,
        'cafeName': cafeName,
        'hostName': hostName,
        'minPlayers': minPlayers,
        'maxPlayers': maxPlayers,
        'current': current,
        'minKarma': minKarma,
        'radius': radius,
        'dist': dist,
        'lat': lat,
        'lng': lng,
      };

  static List<LobbyPlayerModel> _buildSeedPlayers(int current, String hostName) {
    final names = [
      'Quốc Bảo', 'Mai Linh', 'Thanh Tùng', 'Kim Anh',
      'Hải Đăng', 'Phương Thảo', 'Minh Khôi', 'Gia Hân',
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
      list.add(
        LobbyPlayerModel(
          id: 'user_seed_member_${i}_$_idCounter',
          name: names[i % names.length],
          avatarUrl:
              'https://picsum.photos/seed/seed${names[i % names.length].hashCode}/150',
          isHost: false,
          isReady: _rng.nextBool(),
          joinedAt: DateTime.now()
              .subtract(Duration(minutes: 14 - i))
              .toIso8601String(),
          karma: (40 + _rng.nextInt(50)).toDouble(),
        ),
      );
    }
    return list;
  }

  static LobbyModel createLobbyInternal({
    required String gameId,
    required String gameName,
    String? gameImageUrl,
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

  static LobbyModel? getLobbyByIdStatic(String id) => _lobbiesById[id];

  static List<LobbyModel> getAll() =>
      List<LobbyModel>.unmodifiable(_lobbiesById.values);

  static void setLobby(String id, LobbyModel updated) {
    if (_lobbiesById.containsKey(id)) {
      _lobbiesById[id] = updated;
    }
  }

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

  static FriendModel? getFriendByIdStatic(String id) {
    return mockOnlineFriendsList.cast<FriendModel?>().firstWhere(
          (f) => f?.id == id,
          orElse: () => null,
        );
  }

  // ════════════════════════════════════════════════════════════════════
  // LobbyRemoteDatasource implementation (in-memory REST-shaped).
  // ════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, LobbyEntity>> createLobby({
    required String gameId,
    required String cafeId,
    required DateTime scheduledTime,
    required int additionalSlots,
    required bool isPublic,
    double? searchRadiusKm,
    double? minimumKarma,
    Duration? leadTime,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    ensureSeeded();
    final model = createLobbyInternal(
      gameId: gameId,
      gameName: gameId,
      gameImageUrl: null,
      cafeId: cafeId,
      cafeName: cafeId,
      hostId: 'user_001',
      hostName: 'Bạn',
      scheduledTime: scheduledTime,
      maxPlayers: additionalSlots + 1,
      minPlayers: 2,
      isPublic: isPublic,
      minimumKarma: minimumKarma ?? 0,
      searchRadiusKm: searchRadiusKm ?? 5,
      leadTime: leadTime ?? const Duration(minutes: 20),
    );
    return Right(model.toEntity());
  }

  @override
  Future<Either<Failure, LobbyEntity>> closeLobby(String lobbyId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final lobby = _lobbiesById[lobbyId];
    if (lobby == null) {
      return const Left(ServerFailure(message: 'Không tìm thấy phòng'));
    }
    final updated = lobby.copyWith(status: LobbyStatusModel.closed);
    _lobbiesById[lobbyId] = updated;
    return Right(updated.toEntity());
  }

  @override
  Future<Either<Failure, LobbyEntity>> lockLobby(String lobbyId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final lobby = _lobbiesById[lobbyId];
    if (lobby == null) {
      return const Left(ServerFailure(message: 'Không tìm thấy phòng'));
    }
    if (lobby.status != LobbyStatusModel.open) {
      return const Left(ServerFailure(message: 'Phòng không ở trạng thái Open'));
    }
    final updated = lobby.copyWith(
      status: LobbyStatusModel.full,
      currentPlayers: lobby.maxPlayers,
    );
    _lobbiesById[lobbyId] = updated;
    return Right(updated.toEntity());
  }

  @override
  Future<Either<Failure, LobbyEntity>> openKarmaWindow(String lobbyId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final lobby = _lobbiesById[lobbyId];
    if (lobby == null) {
      return const Left(ServerFailure(message: 'Không tìm thấy phòng'));
    }
    // Mock: chỉ trả về lobby hiện tại. Phase sau sẽ thêm field ratingOpenedAt.
    return Right(lobby.toEntity());
  }

  @override
  Future<Either<Failure, bool>> joinLobby(
    String lobbyId,
    String? inviteCode,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    ensureSeeded();
    final lobby = _lobbiesById[lobbyId];
    if (lobby == null) {
      return const Left(ServerFailure(message: 'Phòng không tồn tại'));
    }
    if (lobby.status != LobbyStatusModel.open) {
      return const Left(
        ServerFailure(message: 'Phòng không còn nhận thành viên'),
      );
    }
    if (lobby.currentPlayers >= lobby.maxPlayers) {
      return const Left(ServerFailure(message: 'Phòng đã đủ người'));
    }
    return const Right(true);
  }

  @override
  Future<Either<Failure, void>> leaveLobby(String lobbyId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const Right(null);
  }

  @override
  Future<Either<Failure, LobbyEntity?>> getLobbyById(String lobbyId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    ensureSeeded();
    final model = _lobbiesById[lobbyId];
    if (model == null) return const Right(null);
    return Right(model.toEntity());
  }

  @override
  Future<Either<Failure, List<LobbySummary>>> searchNearbyLobbies({
    required double latitude,
    required double longitude,
    required LobbySearchFilter filter,
    required double currentUserKarma,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    ensureSeeded();

    final filtered = _lobbiesById.values.where((lobby) {
      if (currentUserKarma < lobby.minimumKarma) return false;
      if (lobby.status != LobbyStatusModel.open) return false;
      if (lobby.isFull) return false;
      if (filter.gameId != null && lobby.gameId != filter.gameId) {
        return false;
      }
      if (filter.excludeOwnLobbies && lobby.hostId == 'user_001') return false;
      if (filter.radiusKm != null &&
          lobby.distanceKm != null &&
          lobby.distanceKm! > filter.radiusKm!) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      final da = a.distanceKm ?? double.infinity;
      final db = b.distanceKm ?? double.infinity;
      return da.compareTo(db);
    });

    return Right(filtered.map(_toSummary).toList());
  }

  @override
  Future<Either<Failure, String>> autoCreateBooking(String lobbyId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final lobby = _lobbiesById[lobbyId];
    if (lobby == null) {
      return const Left(ServerFailure(message: 'Không tìm thấy phòng'));
    }
    final newBookingId =
        'AUTO_BOOK_${DateTime.now().year}_${_idCounter.toString().padLeft(3, '0')}';
    final updated = lobby.copyWith(bookingId: newBookingId);
    _lobbiesById[lobbyId] = updated;
    return Right(newBookingId);
  }

  @override
  Future<Either<Failure, void>> inviteFriend(
    String lobbyId,
    String friendId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<FriendEntity>>> getOnlineFriends() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return Right(mockOnlineFriendsList.map((f) => f.toEntity()).toList());
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  LobbySummary _toSummary(LobbyModel m) => LobbySummary(
        id: m.id,
        gameId: m.gameId,
        gameName: m.gameName,
        gameImageUrl: m.gameImageUrl ?? '',
        cafeId: m.cafeId,
        cafeName: m.cafeName,
        hostName: m.hostName,
        distanceKm: m.distanceKm ?? 0,
        currentPlayers: m.currentPlayers,
        maxPlayers: m.maxPlayers,
        minPlayers: m.minPlayers,
        minimumKarma: m.minimumKarma,
        scheduledTime: m.scheduledTime,
        timeoutAt: m.timeoutAt,
        status: LobbyStatusModelX.toEntity(m.status),
        isPublic: m.isPublic,
      );
}

/// Mapping helper cho status — extract từ MockLobbyDatasource cũ để không
/// buộc Repository phải import trực tiếp implementation này.
extension LobbyStatusModelX on LobbyStatusModel {
  static LobbyStatus toEntity(LobbyStatusModel m) {
    switch (m) {
      case LobbyStatusModel.open:
        return LobbyStatus.open;
      case LobbyStatusModel.full:
        return LobbyStatus.full;
      case LobbyStatusModel.inProgress:
        return LobbyStatus.inProgress;
      case LobbyStatusModel.closed:
        return LobbyStatus.closed;
      case LobbyStatusModel.timeoutFailed:
        return LobbyStatus.timeoutFailed;
      case LobbyStatusModel.hostCancelled:
        return LobbyStatus.hostCancelled;
    }
  }
}
