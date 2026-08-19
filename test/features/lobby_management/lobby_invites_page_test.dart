// Widget tests cho LobbyInvitesPage — verify bug fix "phải ấn reload mới thấy
// danh sách lời mời lần đầu mở trang".
//
// Bug cũ (2026-08-18): `LobbyInvitesPage` là `StatelessWidget`, không gọi
// `loadPendingInvites()` khi widget mount. State khởi tạo là
// `LobbyInviteInitial` → UI rơi vào `_EmptyState` (vì `_getInvites(Initial)`
// trả về list rỗng). User phải bấm nút Refresh mới thấy danh sách.
//
// Fix: chuyển sang `StatefulWidget`, trong `initState` check state của
// cubit — nếu đang `LobbyInviteInitial` thì trigger `loadPendingInvites()`.

import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/features/friend_management/domain/entities/friend_entity.dart';
import 'package:boardverse/features/lobby_management/data/datasources/base/lobby_remote_datasource.dart';
import 'package:boardverse/features/lobby_management/data/models/elo_update_model.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_entity.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_invite_entity.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_invitable_friend.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_share_info.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_summary.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_chat_message.dart';
import 'package:boardverse/features/lobby_management/domain/entities/match_result_entity.dart';
import 'package:boardverse/features/lobby_management/presentation/cubit/lobby_invite_cubit.dart';
import 'package:boardverse/features/lobby_management/presentation/cubit/lobby_invite_state.dart';
import 'package:boardverse/features/lobby_management/presentation/pages/lobby_invites_page.dart';
import 'package:boardverse/features/lobby_management/presentation/widgets/lobby_invite_card.dart';
import 'package:boardverse/features/lobby_management/presentation/widgets/lobby_list_shimmer.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

typedef Lst<T> = List<T>;

Either<L, T> rightOf<L, T>(T value) => Right<L, T>(value);

LobbyInviteEntity _makeInvite({
  String inviteId = 'inv-1',
  String inviterName = 'jonny',
  String gameName = 'Catan',
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
    gameName: gameName,
    cafeName: 'BoardVerse Cafe',
    currentMembers: 1,
    maxMembers: 4,
  );
}

/// Fake datasource cho widget test — implement TẤT CẢ methods của
/// `LobbyRemoteDatasource` (Dart yêu cầu). Chỉ override `getPendingInvites`
/// thật sự; còn lại stub throw UnimplementedError / return empty.
class _FakeLobbyRemoteDatasource implements LobbyRemoteDatasource {
  _FakeLobbyRemoteDatasource({this.pendingInvites = const []});

  List<LobbyInviteEntity> pendingInvites;
  int getPendingInvitesCallCount = 0;

  @override
  Future<Either<Failure, List<LobbyInviteEntity>>> getPendingInvites() async {
    getPendingInvitesCallCount++;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return Right<Failure, List<LobbyInviteEntity>>(pendingInvites);
  }

  // ─── Stubs (không dùng trong widget test) ───────────────────────────

  @override
  Future<Either<Failure, LobbyEntity>> acceptInvite(String inviteId) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> cancelInvite(String inviteId) async =>
      Right<Failure, void>(null);

  @override
  Future<Either<Failure, void>> declineInvite(String inviteId) async =>
      Right<Failure, void>(null);

  @override
  Future<Either<Failure, List<LobbyInviteEntity>>> getAllInvites(
          LobbyInviteStatus? status) async =>
      rightOf<Failure, Lst<LobbyInviteEntity>>(const []);

  @override
  Future<Either<Failure, List<LobbyInviteEntity>>> getLobbyInvites({
    required String lobbyId,
    LobbyInviteStatus? status,
    int limit = 100,
  }) async =>
      rightOf<Failure, Lst<LobbyInviteEntity>>(const []);

  @override
  Future<Either<Failure, LobbyInviteEntity>> resendInvite(
          String inviteId) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> sendLobbyInvite(
          String lobbyId, String inviteeId, String? message) async =>
      Right<Failure, void>(null);

  @override
  Future<Either<Failure, void>> inviteFriend(
          String lobbyId, String friendId) async =>
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
          String lobbyId, String? inviteCode) async =>
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
          String lobbyId, LobbyStatus newStatus) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, MatchResultEntity>> getMatchResultStatus(
          String lobbyId) async =>
      throw UnimplementedError();
}

void main() {
  Widget wrapPage(LobbyInviteCubit cubit) {
    return MaterialApp(
      home: BlocProvider<LobbyInviteCubit>.value(
        value: cubit,
        child: LobbyInvitesPage(lobbyInviteCubit: cubit),
      ),
    );
  }

  group('LobbyInvitesPage auto-load on first open', () {
    testWidgets(
      'Tự động gọi getPendingInvites khi cubit state là Initial',
      (tester) async {
        final fakeDs = _FakeLobbyRemoteDatasource(
          pendingInvites: [_makeInvite()],
        );
        final cubit = LobbyInviteCubit(remoteDatasource: fakeDs);

        // State ban đầu là LobbyInviteInitial (chưa load).
        expect(cubit.state, isA<LobbyInviteInitial>());

        await tester.pumpWidget(wrapPage(cubit));
        // Pump frame đầu — chạy initState + postFrameCallback.
        await tester.pump();

        // Verify: getPendingInvites đã được gọi ít nhất 1 lần mà user
        // KHÔNG cần bấm nút Refresh.
        expect(fakeDs.getPendingInvitesCallCount, greaterThanOrEqualTo(1));

        // Pump tiếp để state Loading → Loaded render xong.
        await tester.pump(const Duration(milliseconds: 100));

        // Verify: hiển thị LobbyInviteCard (danh sách lời mời) thay vì
        // empty state.
        expect(find.byType(LobbyInviteCard), findsOneWidget);

        await cubit.close();
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'Render shimmer khi đang load thay vì empty state',
      (tester) async {
        final fakeDs = _FakeLobbyRemoteDatasource(
          pendingInvites: [_makeInvite()],
        );
        final cubit = LobbyInviteCubit(remoteDatasource: fakeDs);

        await tester.pumpWidget(wrapPage(cubit));
        // Drain microtasks để postFrameCallback chạy + cubit chuyển sang
        // Loading state trước khi ta kiểm tra shimmer.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 10));

        // Ngay sau khi load trigger, state = Loading → render shimmer
        // (trước fix: render _EmptyState).
        expect(find.byType(LobbyInvitesShimmer), findsOneWidget);

        // Pump xong thì list hiện ra.
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(LobbyInviteCard), findsOneWidget);

        await cubit.close();
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'Hiển thị empty state khi không có lời mời nào',
      (tester) async {
        final fakeDs = _FakeLobbyRemoteDatasource(pendingInvites: const []);
        final cubit = LobbyInviteCubit(remoteDatasource: fakeDs);

        await tester.pumpWidget(wrapPage(cubit));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Không có card nào và cũng không có shimmer.
        expect(find.byType(LobbyInviteCard), findsNothing);
        expect(find.byType(LobbyInvitesShimmer), findsNothing);
        // Có text báo không có lời mời (xem `_EmptyState`).
        expect(find.text('Không có lời mời nào'), findsOneWidget);

        await cubit.close();
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'Mount page lần 2 với cubit đã có data — verify state được giữ nguyên',
      (tester) async {
        // Setup cubit + load xong, rồi mount page vào widget tree.
        final fakeDs = _FakeLobbyRemoteDatasource(
          pendingInvites: [_makeInvite()],
        );
        final cubit = LobbyInviteCubit(remoteDatasource: fakeDs);

        await tester.pumpWidget(wrapPage(cubit));
        // Đợi load hoàn tất → state = Loaded.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        expect(find.byType(LobbyInviteCard), findsOneWidget);
        final callsAfterFirstLoad = fakeDs.getPendingInvitesCallCount;
        expect(callsAfterFirstLoad, greaterThanOrEqualTo(1));

        // Rebuild page (giả lập Flutter re-render khi back nav). Fix KHÔNG
        // được trigger load lại (tránh flash shimmer không cần thiết).
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(
          fakeDs.getPendingInvitesCallCount,
          callsAfterFirstLoad,
          reason: 'Page phải tôn trọng state đã Loaded — không re-fetch.',
        );
        expect(find.byType(LobbyInviteCard), findsOneWidget);

        await cubit.close();
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'Nút Refresh trong app bar trigger loadPendingInvites',
      (tester) async {
        final fakeDs = _FakeLobbyRemoteDatasource(
          pendingInvites: [_makeInvite()],
        );
        final cubit = LobbyInviteCubit(remoteDatasource: fakeDs);

        await tester.pumpWidget(wrapPage(cubit));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final beforeRefreshCalls = fakeDs.getPendingInvitesCallCount;

        // Tap icon Refresh trong AppBar.
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          fakeDs.getPendingInvitesCallCount,
          greaterThan(beforeRefreshCalls),
          reason: 'Refresh button phải trigger 1 lần fetch mới.',
        );

        await cubit.close();
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });
}
