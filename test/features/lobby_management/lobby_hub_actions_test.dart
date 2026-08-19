// Widget tests cho LobbyHubActions — verify badge update sau khi accept/decline.
//
// Bug (2026-08-18): Sau khi accept invite, badge bên LobbyHubActions không
// update vì BlocListener chỉ handle LobbyInviteLoaded/Empty/ActionLoading/Error.
// Không handle LobbyInviteAccepted/Declined → badge vẫn hiện số cũ.
//
// Fix: thêm nhánh xử lý LobbyInviteAccepted và LobbyInviteDeclined trong
// listener → trigger refresh() để badge đồng bộ.

import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/features/lobby_management/data/datasources/base/lobby_remote_datasource.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_entity.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_invite_entity.dart';
import 'package:boardverse/features/lobby_management/presentation/cubit/lobby_invite_cubit.dart';
import 'package:boardverse/features/lobby_management/presentation/widgets/lobby_hub_actions.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardverse/features/friend_management/domain/entities/friend_entity.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_invitable_friend.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_share_info.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_summary.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_chat_message.dart';
import 'package:boardverse/features/lobby_management/domain/entities/match_result_entity.dart';
import 'package:boardverse/features/lobby_management/data/models/elo_update_model.dart';

LobbyInviteEntity _makeInvite({
  String inviteId = 'inv-1',
  String inviterName = 'jonny',
}) {
  final now = DateTime.utc(2026, 8, 18);
  return LobbyInviteEntity(
    inviteId: inviteId,
    lobbyId: 'lob-1',
    inviterId: 'u-inviter',
    inviterName: inviterName,
    inviterAvatar: '',
    inviteeId: 'u-invitee',
    status: LobbyInviteStatus.pending,
    createdAt: now,
    expiresAt: now.add(const Duration(hours: 24)),
    gameName: 'Catan',
    cafeName: 'BoardVerse Cafe',
    currentMembers: 1,
    maxMembers: 4,
  );
}

/// Fake datasource cho badge test.
class _FakeLobbyRemoteDatasource implements LobbyRemoteDatasource {
  _FakeLobbyRemoteDatasource({
    this.pendingInvites = const [],
  });

  List<LobbyInviteEntity> pendingInvites;
  int getPendingInvitesCallCount = 0;

  @override
  Future<Either<Failure, List<LobbyInviteEntity>>> getPendingInvites() async {
    getPendingInvitesCallCount++;
    return Right<Failure, List<LobbyInviteEntity>>(pendingInvites);
  }

  // ─── Stubs (không dùng trong test) ───────────────────────────────

  @override
  Future<Either<Failure, LobbyEntity>> acceptInvite(String inviteId) async =>
      Right<Failure, LobbyEntity>(_buildLobby('lob-1'));

  @override
  Future<Either<Failure, void>> cancelInvite(String inviteId) async =>
      Right<Failure, void>(null);

  @override
  Future<Either<Failure, void>> declineInvite(String inviteId) async =>
      Right<Failure, void>(null);

  @override
  Future<Either<Failure, List<LobbyInviteEntity>>> getAllInvites(
    LobbyInviteStatus? status,
  ) async => Right<Failure, List<LobbyInviteEntity>>(const []);

  @override
  Future<Either<Failure, List<LobbyInviteEntity>>> getLobbyInvites({
    required String lobbyId,
    LobbyInviteStatus? status,
    int limit = 100,
  }) async => Right<Failure, List<LobbyInviteEntity>>(const []);

  @override
  Future<Either<Failure, LobbyInviteEntity>> resendInvite(
    String inviteId,
  ) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> sendLobbyInvite(
    String lobbyId,
    String inviteeId,
    String? message,
  ) async => Right<Failure, void>(null);

  @override
  Future<Either<Failure, void>> inviteFriend(
    String lobbyId,
    String friendId,
  ) async => Right<Failure, void>(null);

  @override
  Future<Either<Failure, void>> leaveLobby(String lobbyId) async =>
      Right<Failure, void>(null);

  @override
  Future<Either<Failure, void>> reportLobby({
    required String lobbyId,
    required String category,
    required String reason,
  }) async => Right<Failure, void>(null);

  @override
  Future<Either<Failure, bool>> joinLobby(
    String lobbyId,
    String? inviteCode,
  ) async => Right<Failure, bool>(true);

  @override
  Future<Either<Failure, LobbyEntity>> joinLobbyByCode(
    String shareCode,
  ) async => throw UnimplementedError();

  @override
  Future<Either<Failure, LobbyEntity>> closeLobby(String lobbyId) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> dissolveLobby({
    required String lobbyId,
    String? reason,
  }) async => Right<Failure, void>(null);

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
      Right<Failure, List<LobbyEntity>>(const []);

  @override
  Future<Either<Failure, List<LobbyEntity>>> getJoinedLobbies() async =>
      Right<Failure, List<LobbyEntity>>(const []);

  @override
  Future<Either<Failure, List<LobbyEntity>>> getMyLobbies() async =>
      Right<Failure, List<LobbyEntity>>(const []);

  @override
  Future<Either<Failure, List<LobbyEntity>>> discoverableLobbies({
    String? gameTemplateId,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int limit = 50,
    bool excludeSelfOverlapping = true,
  }) async => Right<Failure, List<LobbyEntity>>(const []);

  @override
  Future<Either<Failure, List<LobbySummary>>> searchNearbyLobbies({
    required double latitude,
    required double longitude,
    required LobbySearchFilter filter,
    required double currentUserKarma,
    bool excludeSelfOverlapping = true,
  }) async => rightOf<Failure, List<LobbySummary>>(const []);

  @override
  Future<Either<Failure, List<LobbyInvitableFriend>>> getInvitableFriends({
    required String lobbyId,
    String? search,
    bool onlineOnly = false,
    int? minKarma,
    List<LobbyInviteFriendStatus> statusFilter = const [],
    int limit = 100,
  }) async => rightOf<Failure, List<LobbyInvitableFriend>>(const []);

  @override
  Future<Either<Failure, List<FriendEntity>>> getOnlineFriends() async =>
      rightOf<Failure, List<FriendEntity>>(const []);

  @override
  Future<Either<Failure, LobbyShareInfo>> getShareInfo(String lobbyId) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, LobbyChatMessage>> sendChatMessage({
    required String lobbyId,
    required String content,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, List<LobbyChatMessage>>> getChatMessages({
    required String lobbyId,
    String? beforeCursor,
    int limit = 50,
  }) async => rightOf<Failure, List<LobbyChatMessage>>(const []);

  @override
  Future<Either<Failure, LobbyEntity>> transferHost({
    required String lobbyId,
    required String newHostId,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, LobbyEntity>> kickMember({
    required String lobbyId,
    required String targetUserId,
    String? reason,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, LobbyEntity>> setReady({
    required String lobbyId,
    required bool isReady,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, LobbyEntity>> updateLobby({
    required String lobbyId,
    String? description,
    int? maxMembers,
    bool? isPrivate,
    int? minKarmaScore,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, MatchResultSubmitResponseModel>> submitMatchResult({
    required String lobbyId,
    required MatchOutcome outcome,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, LobbyEntity>> updateLobbyStatus(
    String lobbyId,
    LobbyStatus newStatus,
  ) async => throw UnimplementedError();

  @override
  Future<Either<Failure, MatchResultEntity>> getMatchResultStatus(
    String lobbyId,
  ) async => throw UnimplementedError();
}

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

Either<L, T> rightOf<L, T>(T value) => Right<L, T>(value);

void main() {
  Widget wrapHubActions(LobbyInviteCubit cubit) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(actions: [LobbyHubActions(inviteCubit: cubit)]),
      ),
    );
  }

  group('LobbyHubActions badge auto-update', () {
    testWidgets(
      'Badge hiển thị đúng số invite khi mới mount',
      (tester) async {
        final fakeDs = _FakeLobbyRemoteDatasource(
          pendingInvites: [_makeInvite(inviteId: 'inv-1')],
        );
        final cubit = LobbyInviteCubit(remoteDatasource: fakeDs);

        await tester.pumpWidget(wrapHubActions(cubit));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Badge phải hiện số 1.
        expect(find.text('1'), findsOneWidget);

        await cubit.close();
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'Badge refresh khi cubit emit LobbyInviteAccepted',
      (tester) async {
        final fakeDs = _FakeLobbyRemoteDatasource(
          pendingInvites: [_makeInvite()],
        );
        final cubit = LobbyInviteCubit(remoteDatasource: fakeDs);

        await tester.pumpWidget(wrapHubActions(cubit));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('1'), findsOneWidget);
        final callsBeforeAccept = fakeDs.getPendingInvitesCallCount;

        // Accept invite → trigger refresh trong listener.
        await cubit.acceptInvite('inv-1');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        // Badge phải giảm về 0 sau khi refresh hoàn tất.
        expect(
          find.text('1'),
          findsNothing,
          reason: 'Badge phải cập nhật sau accept',
        );
        // getPendingInvites phải được gọi lại do refresh().
        expect(
          fakeDs.getPendingInvitesCallCount,
          greaterThan(callsBeforeAccept),
          reason: 'Listener phải trigger refresh sau accept',
        );

        await cubit.close();
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'Badge refresh khi cubit emit LobbyInviteDeclined',
      (tester) async {
        final fakeDs = _FakeLobbyRemoteDatasource(
          pendingInvites: [_makeInvite(inviteId: 'inv-1')],
        );
        final cubit = LobbyInviteCubit(remoteDatasource: fakeDs);

        await tester.pumpWidget(wrapHubActions(cubit));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('1'), findsOneWidget);
        final callsBeforeDecline = fakeDs.getPendingInvitesCallCount;

        // Decline invite.
        await cubit.declineInvite('inv-1');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        expect(
          find.text('1'),
          findsNothing,
          reason: 'Badge phải cập nhật sau decline',
        );
        expect(
          fakeDs.getPendingInvitesCallCount,
          greaterThan(callsBeforeDecline),
        );

        await cubit.close();
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });
}
