// Unit tests cho LobbyInviteCubit.acceptInvite state transitions.
//
// Bug background: trước đây khi accept invite thành công, cubit chỉ emit
// `LobbyInviteAccepted` rồi dừng — UI danh sách "kẹt" ở state này cho tới
// khi user reload page. Fix: emit tiếp `LobbyInviteLoaded` (hoặc
// `LobbyInviteEmpty` nếu list rỗng) sau khi emit `LobbyInviteAccepted`.

import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/features/friend_management/domain/entities/friend_entity.dart';
import 'package:boardverse/features/lobby_management/data/datasources/base/lobby_remote_datasource.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_entity.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_invitable_friend.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_invite_entity.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_share_info.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_summary.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_chat_message.dart';
import 'package:boardverse/features/lobby_management/domain/entities/match_result_entity.dart';
import 'package:boardverse/features/lobby_management/data/models/elo_update_model.dart';
import 'package:boardverse/features/lobby_management/presentation/cubit/lobby_invite_cubit.dart';
import 'package:boardverse/features/lobby_management/presentation/cubit/lobby_invite_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

/// Type alias để tránh Dart parser nhầm `List<X>>` thành bit-shift.
typedef Lst<T> = List<T>;

/// Helper để tạo `Right(List&lt;X&gt;)` không bị parser nhầm `>>`.
Either<L, T> rightOf<L, T>(T value) => Right<L, T>(value);

/// Fake datasource cho phép test kiểm soát response của acceptInvite.
class _FakeLobbyRemoteDatasource implements LobbyRemoteDatasource {
  _FakeLobbyRemoteDatasource({
    required this.acceptResult,
    this.pendingInvites = const [],
  });

  Either<Failure, LobbyEntity> acceptResult;

  /// Danh sách invite mà fake trả về cho `getPendingInvites()` — test
  /// dùng để seed state cho cubit qua `loadPendingInvites()`.
  List<LobbyInviteEntity> pendingInvites;

  int acceptCallCount = 0;
  String? lastAcceptedInviteId;

  @override
  Future<Either<Failure, LobbyEntity>> acceptInvite(String inviteId) async {
    acceptCallCount++;
    lastAcceptedInviteId = inviteId;
    return acceptResult;
  }

  // ─── Stub các methods khác (không dùng trong test) ─────────────────

  @override
  Future<Either<Failure, void>> cancelInvite(String inviteId) async =>
      Right<Failure, void>(null);

  @override
  Future<Either<Failure, void>> declineInvite(String inviteId) async =>
      Right<Failure, void>(null);

  @override
  Future<Either<Failure, List<LobbyInviteEntity>>> getAllInvites(
    LobbyInviteStatus? status,
  ) async =>
      rightOf<Failure, Lst<LobbyInviteEntity>>(_emptyInvites);

  @override
  Future<Either<Failure, List<LobbyInviteEntity>>> getLobbyInvites({
    required String lobbyId,
    LobbyInviteStatus? status,
    int limit = 100,
  }) async =>
      rightOf<Failure, Lst<LobbyInviteEntity>>(_emptyInvites);

  @override
  Future<Either<Failure, List<LobbyInviteEntity>>> getPendingInvites() async =>
      rightOf<Failure, Lst<LobbyInviteEntity>>(pendingInvites);

  @override
  Future<Either<Failure, LobbyInviteEntity>> resendInvite(
          String inviteId) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> sendLobbyInvite(
    String lobbyId,
    String inviteeId,
    String? message,
  ) async =>
      Right<Failure, void>(null);

  @override
  Future<Either<Failure, void>> inviteFriend(
    String lobbyId,
    String friendId,
  ) async =>
      Right<Failure, void>(null);

  @override
  Future<Either<Failure, void>> leaveLobby(String lobbyId) async =>
      Right<Failure, void>(null);

  @override
  Future<Either<Failure, void>> reportLobby({
    required String lobbyId,
    required String category,
    required String reason,
  }) async =>
      Right<Failure, void>(null);

  @override
  Future<Either<Failure, bool>> joinLobby(
    String lobbyId,
    String? inviteCode,
  ) async =>
      Right<Failure, bool>(true);

  @override
  Future<Either<Failure, LobbyEntity>> joinLobbyByCode(String shareCode) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, LobbyEntity>> closeLobby(String lobbyId) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> dissolveLobby({
    required String lobbyId,
    String? reason,
  }) async =>
      Right<Failure, void>(null);

  @override
  Future<Either<Failure, LobbyEntity>> lockLobby(String lobbyId) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, LobbyEntity>> openKarmaWindow(String lobbyId) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, LobbyEntity?>> getLobbyById(String lobbyId) async =>
      Right<Failure, LobbyEntity?>(null);

  @override
  Future<Either<Failure, List<LobbyEntity>>> getHostedLobbies() async =>
      rightOf<Failure, Lst<LobbyEntity>>(const []);

  @override
  Future<Either<Failure, List<LobbyEntity>>> getJoinedLobbies() async =>
      rightOf<Failure, Lst<LobbyEntity>>(const []);

  @override
  Future<Either<Failure, List<LobbyEntity>>> getMyLobbies() async =>
      rightOf<Failure, Lst<LobbyEntity>>(const []);

  @override
  Future<Either<Failure, List<LobbyEntity>>> discoverableLobbies({
    String? gameTemplateId,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int limit = 50,
    bool excludeSelfOverlapping = true,
  }) async =>
      rightOf<Failure, Lst<LobbyEntity>>(const []);

  @override
  Future<Either<Failure, List<LobbySummary>>> searchNearbyLobbies({
    required double latitude,
    required double longitude,
    required LobbySearchFilter filter,
    required double currentUserKarma,
    bool excludeSelfOverlapping = true,
  }) async =>
      rightOf<Failure, Lst<LobbySummary>>(const []);

  @override
  Future<Either<Failure, List<LobbyInvitableFriend>>> getInvitableFriends({
    required String lobbyId,
    String? search,
    bool onlineOnly = false,
    int? minKarma,
    List<LobbyInviteFriendStatus> statusFilter = const [],
    int limit = 100,
  }) async =>
      rightOf<Failure, Lst<LobbyInvitableFriend>>(const []);

  @override
  Future<Either<Failure, List<FriendEntity>>> getOnlineFriends() async =>
      rightOf<Failure, Lst<FriendEntity>>(const []);

  @override
  Future<Either<Failure, LobbyShareInfo>> getShareInfo(String lobbyId) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, LobbyChatMessage>> sendChatMessage({
    required String lobbyId,
    required String content,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<LobbyChatMessage>>> getChatMessages({
    required String lobbyId,
    String? beforeCursor,
    int limit = 50,
  }) async =>
      rightOf<Failure, Lst<LobbyChatMessage>>(const []);

  @override
  Future<Either<Failure, LobbyEntity>> transferHost({
    required String lobbyId,
    required String newHostId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, LobbyEntity>> kickMember({
    required String lobbyId,
    required String targetUserId,
    String? reason,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, LobbyEntity>> setReady({
    required String lobbyId,
    required bool isReady,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, LobbyEntity>> updateLobby({
    required String lobbyId,
    String? description,
    int? maxMembers,
    bool? isPrivate,
    int? minKarmaScore,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, MatchResultSubmitResponseModel>> submitMatchResult({
    required String lobbyId,
    required MatchOutcome outcome,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, LobbyEntity>> updateLobbyStatus(
    String lobbyId,
    LobbyStatus newStatus,
  ) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, MatchResultEntity>> getMatchResultStatus(
          String lobbyId) async =>
      throw UnimplementedError();
}

const List<LobbyInviteEntity> _emptyInvites = [];

LobbyEntity _buildLobby(String id) => LobbyEntity(
      id: id,
      gameId: 'game-1',
      gameName: 'Catan',
      cafeId: 'cafe-1',
      cafeName: 'Cafe',
      hostId: 'host-1',
      hostName: 'Host',
      scheduledTime: DateTime.utc(2026, 8, 10, 19),
      currentPlayers: 3,
      maxPlayers: 4,
      minPlayers: 2,
      isPublic: true,
      inviteCode: 'CODE1',
      status: LobbyStatus.open,
      players: const [],
      createdAt: DateTime.utc(2026, 8, 8),
      timeoutAt: DateTime.utc(2026, 8, 10, 18),
    );

LobbyInviteEntity _buildInvite(String inviteId, String lobbyId) =>
    LobbyInviteEntity(
      inviteId: inviteId,
      lobbyId: lobbyId,
      inviterId: 'host-1',
      inviterName: 'Host',
      inviterAvatar: '',
      inviteeId: 'user-1',
      status: LobbyInviteStatus.pending,
      createdAt: DateTime.utc(2026, 8, 8),
      expiresAt: DateTime.utc(2026, 8, 9),
      gameName: 'Catan',
      cafeName: 'Cafe',
      currentMembers: 3,
      maxMembers: 4,
    );

void main() {
  group('LobbyInviteCubit.acceptInvite state transitions', () {
    /// Helper: seed state bằng `loadPendingInvites()` (cập nhật cả
    /// `_pendingInvites` internal lẫn emitted state) → subscribe → thực
    /// hiện action → capture tất cả states emit ra.
    Future<List<LobbyInviteState>> seedAndCapture(
      LobbyInviteCubit cubit,
      List<LobbyInviteEntity> seedInvites,
      Future<void> Function() action,
    ) async {
      // Replace pendingInvites ở fake datasource rồi gọi loadPendingInvites
      // — đảm bảo cubit cập nhật đầy đủ internal state.
      // (Thực tế `fakeDs.pendingInvites` đã được set qua constructor.)
      await cubit.loadPendingInvites();

      final states = <LobbyInviteState>[];
      final sub = cubit.stream.listen(states.add);

      await action();

      // Pump thêm để các pending emissions flush qua stream subscription.
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      return states;
    }

    test(
        'accept success khi còn 1 invite khác → emit Loaded (không kẹt ở Accepted)',
        () async {
      final seedInvites = [
        _buildInvite('inv-1', 'lob-1'),
        _buildInvite('inv-2', 'lob-2'),
      ];
      final fakeDs = _FakeLobbyRemoteDatasource(
        acceptResult: Right<Failure, LobbyEntity>(_buildLobby('lob-1')),
        pendingInvites: seedInvites,
      );
      final cubit = LobbyInviteCubit(remoteDatasource: fakeDs);

      final states = await seedAndCapture(
        cubit,
        seedInvites,
        () => cubit.acceptInvite('inv-1'),
      );

      // Verify emit sequence: ActionLoading → Accepted → Loaded
      expect(states.length, 3,
          reason:
              'Expected 3 states: ActionLoading → Accepted → Loaded. Got: $states');
      expect(states[0], isA<LobbyInviteActionLoading>());
      expect(states[1], isA<LobbyInviteAccepted>());
      expect(
        states[1],
        isA<LobbyInviteAccepted>().having((s) => s.lobbyId, 'lobbyId', 'lob-1'),
      );
      // Sau cùng phải là LobbyInviteLoaded (KHÔNG phải LobbyInviteAccepted).
      expect(states.last, isA<LobbyInviteLoaded>(),
          reason:
              'Phải emit Loaded để UI không kẹt ở Accepted. Got: ${states.last}');

      // Verify danh sách đã remove invite vừa accept.
      final loadedState = states.last as LobbyInviteLoaded;
      expect(loadedState.pendingInvites.length, 1);
      expect(loadedState.pendingInvites.first.inviteId, 'inv-2');

      await cubit.close();
    });

    test('accept success khi list rỗng → emit Empty (không kẹt ở Accepted)',
        () async {
      final seedInvites = [_buildInvite('inv-1', 'lob-1')];
      final fakeDs = _FakeLobbyRemoteDatasource(
        acceptResult: Right<Failure, LobbyEntity>(_buildLobby('lob-1')),
        pendingInvites: seedInvites,
      );
      final cubit = LobbyInviteCubit(remoteDatasource: fakeDs);

      final states = await seedAndCapture(
        cubit,
        seedInvites,
        () => cubit.acceptInvite('inv-1'),
      );

      expect(states.length, 3);
      expect(states.last, isA<LobbyInviteEmpty>(),
          reason: 'Sau khi accept invite cuối cùng, phải emit Empty');

      await cubit.close();
    });

    test('accept failure → emit Error + giữ danh sách cũ', () async {
      final seedInvites = [
        _buildInvite('inv-1', 'lob-1'),
        _buildInvite('inv-2', 'lob-2'),
      ];
      final fakeDs = _FakeLobbyRemoteDatasource(
        acceptResult: const Left<Failure, LobbyEntity>(
          ServerFailure(message: 'Network error'),
        ),
        pendingInvites: seedInvites,
      );
      final cubit = LobbyInviteCubit(remoteDatasource: fakeDs);

      final states = await seedAndCapture(
        cubit,
        seedInvites,
        () => cubit.acceptInvite('inv-1'),
      );

      expect(states.last, isA<LobbyInviteError>());
      final errorState = states.last as LobbyInviteError;
      expect(errorState.message, contains('Network error'));
      // Verify danh sách KHÔNG bị remove khi accept fail.
      expect(errorState.pendingInvites.length, 2);

      await cubit.close();
    });
  });
}