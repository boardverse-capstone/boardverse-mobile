import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../domain/entities/lobby_entity.dart';
import '../domain/entities/lobby_summary.dart';
import '../domain/entities/friend_entity.dart';
import '../domain/repositories/lobby_repository.dart';
import 'datasources/base/lobby_remote_datasource.dart';
import 'datasources/mock/mock_lobby_remote_datasource.dart';
import 'models/lobby_model.dart';
import 'realtime/lobby_realtime_service.dart';

/// Triển khai [LobbyRepository] dùng chung cho cả 2 mode (mock / remote).
///
/// Mode được quyết định bởi DI (xem `lib/core/di/injection.dart`):
/// - `AppConfig.useMockLobbyData = true`  → MockLobbyRemoteDatasource
/// - `AppConfig.useMockLobbyData = false` → RealLobbyRemoteDatasource
///
/// Repository không tự switch — chỉ delegate xuống datasource + realtime
/// service đã inject. Behavior BR-07/BR-08 được đảm bảo bởi backend
/// (hoặc mock tương đương).
class LobbyRepositoryImpl implements LobbyRepository {
  LobbyRepositoryImpl({
    required LobbyRemoteDatasource remoteDatasource,
    required LobbyRealtimeService realtimeService,
  })  : _remote = remoteDatasource,
        _realtime = realtimeService;

  final LobbyRemoteDatasource _remote;
  final LobbyRealtimeService _realtime;

  // ─── Create Lobby ────────────────────────────────────────────────────

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
  }) {
    return _remote.createLobby(
      gameId: gameId,
      cafeId: cafeId,
      scheduledTime: scheduledTime,
      additionalSlots: additionalSlots,
      isPublic: isPublic,
      searchRadiusKm: searchRadiusKm,
      minimumKarma: minimumKarma,
      leadTime: leadTime,
    );
  }

  // ─── Create Lobby for existing booking (Luồng B / BR-07) ─────────────

  @override
  Future<Either<Failure, LobbyEntity>> createLobbyForExistingBooking({
    required String bookingId,
    required int bookingSeatCount,
    required String gameId,
    required String cafeId,
    required DateTime scheduledTime,
    required int additionalSlots,
    required bool isPublic,
    double? searchRadiusKm,
    double? minimumKarma,
    Duration? leadTime,
  }) async {
    // BR-07: validate maxMembers ≤ bookingSeatCount ngay tại client —
    // backend cũng validate nhưng kiểm sớm ở client để UX mượt hơn.
    if (additionalSlots + 1 > bookingSeatCount) {
      return Left(
        ServerFailure(
          message:
              'Số người trong phòng chờ (${additionalSlots + 1}) vượt quá số ghế còn lại của đơn đặt chỗ ($bookingSeatCount). Vui lòng chọn số slot nhỏ hơn.',
        ),
      );
    }
    // BR-07 OK — tạo lobby với bookingId đính kèm.
    final result = await _remote.createLobby(
      gameId: gameId,
      cafeId: cafeId,
      scheduledTime: scheduledTime,
      additionalSlots: additionalSlots,
      isPublic: isPublic,
      searchRadiusKm: searchRadiusKm,
      minimumKarma: minimumKarma,
      leadTime: leadTime,
    );
    return result.fold(
      (failure) => Left<Failure, LobbyEntity>(failure),
      (lobby) => Right<Failure, LobbyEntity>(lobby.copyWith(bookingId: bookingId)),
    );
  }

  // ─── Read ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, LobbyEntity?>> getLobbyById(String lobbyId) =>
      _remote.getLobbyById(lobbyId);

  @override
  Future<Either<Failure, bool>> joinLobby(
    String lobbyId,
    String? inviteCode,
  ) =>
      _remote.joinLobby(lobbyId, inviteCode);

  @override
  Future<Either<Failure, void>> leaveLobby(String lobbyId) =>
      _remote.leaveLobby(lobbyId);

  @override
  Future<Either<Failure, void>> inviteFriend(
    String lobbyId,
    String friendId,
  ) =>
      _remote.inviteFriend(lobbyId, friendId);

  @override
  Future<Either<Failure, List<FriendEntity>>> getOnlineFriends() =>
      _remote.getOnlineFriends();

  // ─── Host-only actions (Phase 4 — wired to backend /mock store) ────

  @override
  Future<Either<Failure, LobbyEntity>> closeLobby(String lobbyId) =>
      _remote.closeLobby(lobbyId);

  @override
  Future<Either<Failure, LobbyEntity>> lockLobby(String lobbyId) =>
      _remote.lockLobby(lobbyId);

  @override
  Future<Either<Failure, LobbyEntity>> openKarmaWindow(String lobbyId) =>
      _remote.openKarmaWindow(lobbyId);

  // ─── Realtime ────────────────────────────────────────────────────────

  @override
  Stream<LobbyEntity> watchLobbyRealtime(String lobbyId) {
    // 1. Đảm bảo hub đã connect (idempotent ở cả 2 impl).
    unawaited(_realtime.connect());

    // 2. Subscribe group của lobby (no-op nếu mock).
    unawaited(_realtime.joinLobby(lobbyId));

    // 3. Forward event đã lọc `lobbyId` ra Stream<LobbyEntity>.
    //    - `MemberJoined` / `MemberLeft` / `LobbyFull` / `LobbyCancelled` /
    //      `LobbyTimeout` → trigger `getLobbyById` để lấy state mới nhất.
    //    - `BookingConfirmed` → set bookingId qua state mới.
    //
    // Vì `LobbyEntity` không thay đổi theo từng event riêng, ta ghép
    // chúng bằng cách fetch lại lobby và emit state mới. Đây là cách
    // đơn giản nhất — UI luôn thấy state đầy đủ nhất.
    return _realtime.events
        .where((event) => _eventMatchesLobby(event, lobbyId))
        .asyncMap((_) async {
      final res = await _remote.getLobbyById(lobbyId);
      return res.fold(
        (_) => null,
        (lobby) => lobby,
      );
    })
        .where((lobby) => lobby != null)
        .cast<LobbyEntity>();
  }

  /// Subscribe trực tiếp tới raw event — Cubit dùng để dispatch đặc biệt
  /// (timeout, host cancelled, booking confirmed).
  @override
  Stream<LobbyRealtimeEvent> watchLobbyEvents(String lobbyId) {
    unawaited(_realtime.connect());
    unawaited(_realtime.joinLobby(lobbyId));
    return _realtime.events
        .where((event) => _eventMatchesLobby(event, lobbyId));
  }

  bool _eventMatchesLobby(LobbyRealtimeEvent event, String lobbyId) {
    return switch (event) {
      MemberJoinedEvent e => e.lobbyId == lobbyId,
      MemberLeftEvent e => e.lobbyId == lobbyId,
      LobbyFullEvent e => e.lobbyId == lobbyId,
      LobbyCancelledEvent e => e.lobbyId == lobbyId,
      LobbyTimeoutEvent e => e.lobbyId == lobbyId,
      BookingConfirmedEvent e => e.lobbyId == lobbyId,
    };
  }

  // ─── Cancel ──────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> cancelLobby(
    String lobbyId,
    String reasonCode,
  ) async {
    // reasonCode mapping theo backend spec `lobby.md:215-226`:
    // - 'HOST_CANCELLED' → closeLobby
    // - 'TIMEOUT_FAILED'  → setTimeout (sẽ tự broadcast `LobbyTimeout`)
    // - các reason khác    → fallback to `closeLobby`
    if (reasonCode == 'TIMEOUT_FAILED') {
      // Backend tự động check BR-08 và broadcast LobbyTimeout — client
      // không gọi API riêng. Giữ no-op.
      await _realtime.leaveLobby(lobbyId);
      return const Right(null);
    }
    final res = await _remote.closeLobby(lobbyId);
    await _realtime.leaveLobby(lobbyId);
    return res.fold(
      (failure) => Left<Failure, void>(failure),
      (_) => const Right<Failure, void>(null),
    );
  }

  // ─── Search + Auto-booking ────────────────────────────────────────────

  @override
  Future<Either<Failure, List<LobbySummary>>> searchNearbyLobbies({
    required double latitude,
    required double longitude,
    required LobbySearchFilter filter,
    required double currentUserKarma,
  }) =>
      _remote.searchNearbyLobbies(
        latitude: latitude,
        longitude: longitude,
        filter: filter,
        currentUserKarma: currentUserKarma,
      );

  /// Luồng A: khi lobby đầy → tự động tạo booking.
  /// Ở real backend: server tự trigger sau `LobbyFull` event — endpoint
  /// này chỉ dùng cho mock mode khi client muốn chủ động tạo booking
  /// trước khi nhận event `BookingConfirmed`.
  @override
  Future<Either<Failure, String>> autoCreateBookingWhenFull(String lobbyId) async {
    // BR-07 guard: chỉ tạo booking khi lobby đã đầy.
    if (_remote is MockLobbyRemoteDatasource) {
      final lobby =
          MockLobbyRemoteDatasource.getLobbyByIdStatic(lobbyId);
      if (lobby == null) {
        return const Left<Failure, String>(
          ServerFailure(message: 'Không tìm thấy phòng'),
        );
      }
      // BR-07 guard: lobby đầy = `currentPlayers >= maxPlayers` HOẶC
      // status đã được flip sang `full` (do mock test force).
      final isFull = lobby.isFull || lobby.status == LobbyStatusModel.full;
      if (!isFull) {
        return const Left<Failure, String>(
          ServerFailure(message: 'Lobby chưa đầy — không thể tạo booking'),
        );
      }
    }
    return _remote.autoCreateBooking(lobbyId);
  }

  /// Update status (timeoutFailed / hostCancelled / ...).
  /// Ở real backend: status tự động chuyển do server. Endpoint này chỉ
  /// dùng cho mock. Phase sau sẽ bỏ hẳn nếu backend không cần.
  @override
  Future<Either<Failure, LobbyEntity>> updateLobbyStatus(
    String lobbyId,
    LobbyStatus newStatus,
  ) async {
    // Mock-only path: route qua MockLobbyRemoteDatasource static store.
    if (_remote is MockLobbyRemoteDatasource) {
      final lobby =
          MockLobbyRemoteDatasource.getLobbyByIdStatic(lobbyId)?.toEntity();
      if (lobby == null) {
        return const Left(ServerFailure(message: 'Không tìm thấy phòng'));
      }
      // Ghi trực tiếp vào store.
      final modelStatus = LobbyStatusModel.values.firstWhere(
        (s) => s.name == newStatus.name,
        orElse: () => LobbyStatusModel.open,
      );
      final existing =
          MockLobbyRemoteDatasource.getLobbyByIdStatic(lobbyId);
      if (existing != null) {
        MockLobbyRemoteDatasource.setLobby(
          lobbyId,
          existing.copyWith(status: modelStatus),
        );
      }
      return Right(lobby.copyWith(status: newStatus));
    }
    // Real mode: backend không expose endpoint này — coi như noop.
    // Cubit nên dựa vào SignalR event thay vì gọi thủ công.
    return Left(
      ServerFailure(
        message:
            'updateLobbyStatus không khả dụng ở real mode — server tự trigger thông qua SignalR.',
      ),
    );
  }

  // ─── Dev simulation ──────────────────────────────────────────────────

  @override
  Future<Either<Failure, LobbyEntity>> simulateAddFriend({
    required String lobbyId,
    required String friendId,
  }) async {
    // Chỉ mock mode mới hỗ trợ.
    if (_remote is MockLobbyRemoteDatasource) {
      try {
        final friendModel =
            MockLobbyRemoteDatasource.mockOnlineFriendsList.cast<dynamic>().firstWhere(
                  (f) => (f as dynamic).id == friendId,
                  orElse: () => null,
                );
        if (friendModel == null) {
          return const Left(ServerFailure(message: 'Không tìm thấy bạn bè'));
        }
        final player = LobbyPlayerModel(
          id: friendModel.id as String,
          name: friendModel.name as String,
          avatarUrl: friendModel.avatarUrl as String,
          isHost: false,
          isReady: false,
          joinedAt: DateTime.now().toIso8601String(),
          karma: 70,
        );
        final existing = MockLobbyRemoteDatasource.getLobbyByIdStatic(lobbyId);
        if (existing == null) {
          return const Left(ServerFailure(message: 'Không tìm thấy phòng'));
        }
        final updated = existing.copyWith(
          currentPlayers: existing.currentPlayers + 1,
          players: [...existing.players, player],
          status: (existing.currentPlayers + 1 >= existing.maxPlayers)
              ? LobbyStatusModel.full
              : existing.status,
        );
        MockLobbyRemoteDatasource.setLobby(lobbyId, updated);
        return Right(updated.toEntity());
      } catch (e) {
        return Left(ServerFailure(message: 'Lỗi thêm bạn: $e'));
      }
    }
    return const Left<Failure, LobbyEntity>(
      ServerFailure(message: 'simulateAddFriend chỉ khả dụng ở mock mode.'),
    );
  }
}
