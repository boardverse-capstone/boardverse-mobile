import 'dart:async';

import 'package:dartz/dartz.dart';

import 'package:boardverse_mobile/core/error/failures.dart';
import 'package:boardverse_mobile/features/friend_management/domain/entities/friend_entity.dart';
import '../domain/entities/lobby_entity.dart';
import '../domain/entities/lobby_summary.dart';
import '../domain/repositories/lobby_repository.dart';
import 'datasources/base/lobby_remote_datasource.dart';
import 'realtime/lobby_realtime_service.dart';

/// Implementation của [LobbyRepository].
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

  // ─── Host-only actions ─────────────────────────────────────────────────

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
    // 1. Đảm bảo hub đã connect.
    unawaited(_realtime.connect());

    // 2. Subscribe group của lobby.
    unawaited(_realtime.joinLobby(lobbyId));

    // 3. Forward event đã lọc `lobbyId` ra Stream<LobbyEntity>.
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
      LobbyInviteReceivedEvent e => e.lobbyId == lobbyId,
      InviteAcceptedEvent e => e.lobbyId == lobbyId,
      InviteDeclinedEvent e => e.lobbyId == lobbyId,
      InviteCancelledEvent e => e.lobbyId == lobbyId,
      MatchResultSubmittedEvent e => e.lobbyId == lobbyId,
      EloUpdatedEvent e => e.lobbyId == lobbyId,
      NearbyLobbyCreatedEvent e => e.lobbyId == lobbyId,
      NearbyLobbyRemovedEvent e => e.lobbyId == lobbyId,
      NearbyLobbyUpdatedEvent e => e.lobbyId == lobbyId,
    };
  }

  // ─── Cancel ──────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> cancelLobby(
    String lobbyId,
    String reasonCode,
  ) async {
    // reasonCode mapping:
    // - 'HOST_CANCELLED' → closeLobby
    // - 'TIMEOUT_FAILED'  → backend tự trigger
    if (reasonCode == 'TIMEOUT_FAILED') {
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

  @override
  Future<Either<Failure, List<LobbyEntity>>> discoverableLobbies({
    int limit = 50,
  }) =>
      _remote.discoverableLobbies(limit: limit);

  @override
  Future<Either<Failure, String>> autoCreateBookingWhenFull(String lobbyId) {
    return _remote.autoCreateBooking(lobbyId);
  }

  @override
  Future<Either<Failure, LobbyEntity>> updateLobbyStatus(
    String lobbyId,
    LobbyStatus newStatus,
  ) {
    // Real mode: delegate to remote datasource
    return _remote.updateLobbyStatus(lobbyId, newStatus);
  }

  // ─── Dev simulation ──────────────────────────────────────────────────

  @override
  Future<Either<Failure, LobbyEntity>> simulateAddFriend({
    required String lobbyId,
    required String friendId,
  }) async {
    // Real mode: gọi inviteFriend thay vì simulate
    final inviteResult = await inviteFriend(lobbyId, friendId);
    return inviteResult.fold(
      (failure) => Left(failure),
      (_) => getLobbyById(lobbyId).then((result) => result.fold(
            (failure) => Left(failure),
            (lobby) => lobby == null
                ? const Left(ServerFailure(message: 'Không tìm thấy phòng'))
                : Right(lobby),
          )),
    );
  }
}
