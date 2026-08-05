import 'dart:async';

import 'package:dartz/dartz.dart';

import 'package:boardverse_mobile/core/cache/cacheable_repository.dart';
import 'package:boardverse_mobile/core/error/failures.dart';
import 'package:boardverse_mobile/features/friend_management/domain/entities/friend_entity.dart';
import '../domain/entities/lobby_entity.dart';
import '../domain/entities/lobby_summary.dart';
import '../domain/entities/lobby_chat_message.dart';
import '../domain/repositories/lobby_repository.dart';
import 'datasources/base/lobby_remote_datasource.dart';
import 'realtime/lobby_realtime_service.dart';

/// Implementation của [LobbyRepository].
///
/// Extends [CacheableRepository] để dedupe `getHostedLobbies` và
/// `getJoinedLobbies` — 2 endpoint này bị gọi từ cả
/// `MyLobbiesCubit.load()` (LobbyHubPage tab "Phòng chờ") lẫn
/// `BookingHistoryCubit.loadAll()` (BookingsPage) trong cùng session.
class LobbyRepositoryImpl extends CacheableRepository implements LobbyRepository {
  LobbyRepositoryImpl({
    required LobbyRemoteDatasource remoteDatasource,
    required LobbyRealtimeService realtimeService,
  })  : _remote = remoteDatasource,
        _realtime = realtimeService,
        super(defaultTtl: const Duration(seconds: 30));

  final LobbyRemoteDatasource _remote;
  final LobbyRealtimeService _realtime;

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
  Future<Either<Failure, void>> dissolveLobby({
    required String lobbyId,
    String? reason,
  }) =>
      _remote.dissolveLobby(lobbyId: lobbyId, reason: reason);

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
    bool excludeSelfOverlapping = true,
  }) =>
      _remote.searchNearbyLobbies(
        latitude: latitude,
        longitude: longitude,
        filter: filter,
        currentUserKarma: currentUserKarma,
        excludeSelfOverlapping: excludeSelfOverlapping,
      );

  @override
  Future<Either<Failure, List<LobbyEntity>>> discoverableLobbies({
    String? gameTemplateId,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int limit = 50,
    bool excludeSelfOverlapping = true,
  }) =>
      _remote.discoverableLobbies(
        gameTemplateId: gameTemplateId,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        limit: limit,
        excludeSelfOverlapping: excludeSelfOverlapping,
      );

  @override
  Future<Either<Failure, LobbyEntity>> updateLobbyStatus(
    String lobbyId,
    LobbyStatus newStatus,
  ) {
    // Real mode: delegate to remote datasource
    return _remote.updateLobbyStatus(lobbyId, newStatus);
  }

  // ─── Host Actions ─────────────────────────────────────────────────

  @override
  Future<Either<Failure, LobbyEntity>> transferHost({
    required String lobbyId,
    required String newHostId,
  }) {
    return _remote.transferHost(lobbyId: lobbyId, newHostId: newHostId);
  }

  @override
  Future<Either<Failure, LobbyEntity>> kickMember({
    required String lobbyId,
    required String targetUserId,
    String? reason,
  }) {
    return _remote.kickMember(
      lobbyId: lobbyId,
      targetUserId: targetUserId,
      reason: reason,
    );
  }

  @override
  Future<Either<Failure, LobbyEntity>> setReady({
    required String lobbyId,
    required bool isReady,
  }) {
    return _remote.setReady(lobbyId: lobbyId, isReady: isReady);
  }

  @override
  Future<Either<Failure, LobbyEntity>> updateLobby({
    required String lobbyId,
    String? description,
    int? maxMembers,
    bool? isPrivate,
    int? minKarmaScore,
  }) {
    return _remote.updateLobby(
      lobbyId: lobbyId,
      description: description,
      maxMembers: maxMembers,
      isPrivate: isPrivate,
      minKarmaScore: minKarmaScore,
    );
  }

  // ─── Lobby Lists ─────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<LobbyEntity>>> getHostedLobbies() {
    // Dedupe: cùng response có thể được dùng bởi MyLobbiesCubit và
    // BookingHistoryCubit trong vòng 30s.
    return cache<Either<Failure, List<LobbyEntity>>>(
      'lobbies-hosted',
      () => _remote.getHostedLobbies(),
    );
  }

  @override
  Future<Either<Failure, List<LobbyEntity>>> getJoinedLobbies() {
    return cache<Either<Failure, List<LobbyEntity>>>(
      'lobbies-joined',
      () => _remote.getJoinedLobbies(),
    );
  }

  // ─── Lobby Social ─────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> reportLobby({
    required String lobbyId,
    required String category,
    required String reason,
  }) {
    return _remote.reportLobby(
      lobbyId: lobbyId,
      category: category,
      reason: reason,
    );
  }

  @override
  @override
  Future<Either<Failure, LobbyChatMessage>> sendChatMessage({
    required String lobbyId,
    required String content,
  }) {
    return _remote.sendChatMessage(lobbyId: lobbyId, content: content);
  }

  @override
  Future<Either<Failure, List<LobbyChatMessage>>> getChatMessages({
    required String lobbyId,
    String? beforeCursor,
    int limit = 50,
  }) {
    return _remote.getChatMessages(
      lobbyId: lobbyId,
      beforeCursor: beforeCursor,
      limit: limit,
    );
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
