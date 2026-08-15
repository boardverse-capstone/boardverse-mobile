// Unit tests for FriendListCubit — focus on per-section data preservation.
//
// Verify state transitions for:
// - loadFriends (loading → loaded / section error)
// - loadReceivedRequests (loading → loaded / section error)
// - Bug fix: data preservation khi 1 section fail (user chuyển tab qua lại
//   không bị mất dữ liệu của section khác).
// - Retry mechanism cho từng section.

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/features/friend_management/domain/entities/entities.dart';
import 'package:boardverse/features/friend_management/domain/repositories/friend_repository.dart';
import 'package:boardverse/features/friend_management/presentation/cubit/friend_list_cubit.dart';
import 'package:boardverse/features/friend_management/presentation/cubit/states/states.dart';

class MockFriendListRepository implements FriendRepository {
  final Map<String, dynamic> stubs = {};

  // Track call order để test retry.
  final List<String> callOrder = [];

  void stubGetFriendsWithActivity(Either<Failure, List<FriendEntity>> result) {
    stubs['getFriendsWithActivity'] = result;
  }

  void stubGetReceivedRequests(
      Either<Failure, List<FriendRequestEntity>> result) {
    stubs['getReceivedRequests'] = result;
  }

  void stubAcceptFriendRequest(Either<Failure, FriendRequestEntity> result) {
    stubs['acceptFriendRequest'] = result;
  }

  void stubDeclineFriendRequest(Either<Failure, FriendRequestEntity> result) {
    stubs['declineFriendRequest'] = result;
  }

  void stubSendFriendRequest(Either<Failure, FriendRequestEntity> result) {
    stubs['sendFriendRequest'] = result;
  }

  void stubUnfriend(Either<Failure, void> result) {
    stubs['unfriend'] = result;
  }

  void stubBlockUser(Either<Failure, void> result) {
    stubs['blockUser'] = result;
  }

  // ─── Required by interface ──────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<FriendEntity>>> getFriendsWithActivity() async {
    callOrder.add('getFriendsWithActivity');
    return stubs['getFriendsWithActivity']
        as Either<Failure, List<FriendEntity>>;
  }

  @override
  Future<Either<Failure, List<FriendRequestEntity>>> getReceivedRequests() async {
    callOrder.add('getReceivedRequests');
    return stubs['getReceivedRequests']
        as Either<Failure, List<FriendRequestEntity>>;
  }

  @override
  Future<Either<Failure, FriendRequestEntity>> acceptFriendRequest(
      String requestId) async {
    return stubs['acceptFriendRequest']
        as Either<Failure, FriendRequestEntity>;
  }

  @override
  Future<Either<Failure, FriendRequestEntity>> declineFriendRequest(
      String requestId) async {
    return stubs['declineFriendRequest']
        as Either<Failure, FriendRequestEntity>;
  }

  @override
  Future<Either<Failure, FriendRequestEntity>> sendFriendRequest({
    required String addresseeId,
    String? message,
  }) async {
    return stubs['sendFriendRequest']
        as Either<Failure, FriendRequestEntity>;
  }

  @override
  Future<Either<Failure, void>> unfriend(String friendId) async {
    return stubs['unfriend'] as Either<Failure, void>;
  }

  @override
  Future<Either<Failure, void>> blockUser(String userId) async {
    return stubs['blockUser'] as Either<Failure, void>;
  }

  // Unused stubs.
  @override
  Future<Either<Failure, List<FriendEntity>>> getFriends() async =>
      const Right(<FriendEntity>[]);

  @override
  Future<Either<Failure, List<FriendEntity>>> getFriendList(
          String otherUserId) async =>
      const Right(<FriendEntity>[]);

  @override
  Future<Either<Failure, FriendProfileEntity>> getPlayerProfile(
          String userId) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, List<FriendRequestEntity>>> getSentRequests() async =>
      const Right(<FriendRequestEntity>[]);

  @override
  Future<Either<Failure, void>> markRequestAsRead(String requestId) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> unblockUser(String userId) async =>
      const Right(null);

  @override
  Future<Either<Failure, List<UserSearchEntity>>> searchUsers({
    required String query,
    int limit = 20,
  }) async =>
      const Right(<UserSearchEntity>[]);

  @override
  Future<Either<Failure, List<FriendSuggestionEntity>>> getSuggestions({
    int limit = 20,
  }) async =>
      const Right(<FriendSuggestionEntity>[]);

  @override
  Future<Either<Failure, List<FriendEntity>>> getMutualFriends(
          String otherUserId) async =>
      const Right(<FriendEntity>[]);

  @override
  Future<Either<Failure, List<FriendNoteEntity>>> getAllNotes() async =>
      const Right(<FriendNoteEntity>[]);

  @override
  Future<Either<Failure, FriendNoteEntity>> upsertNote({
    required String friendUserId,
    required String alias,
    String? note,
    List<String>? tags,
  }) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, void>> deleteNote(String noteId) async =>
      const Right(null);

  @override
  Future<Either<Failure, FriendPrivacyEntity>> getPrivacySettings() async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, FriendPrivacyEntity>> updatePrivacySettings({
    bool? isFriendListPublic,
    String? acceptFriendRequestsFrom,
    int? friendLimit,
  }) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, void>> createReport({
    required String targetUserId,
    required String category,
    required String reason,
  }) async =>
      const Right(null);

  @override
  Future<Either<Failure, List<FriendReportEntity>>> getMyReports() async =>
      const Right(<FriendReportEntity>[]);
}

FriendEntity _friend({
  required String id,
  required String username,
}) {
  return FriendEntity(
    odId: id,
    username: username,
    avatarUrl: '',
    karmaPoints: 100,
  );
}

FriendRequestEntity _request({required String requestId}) {
  return FriendRequestEntity(
    requestId: requestId,
    requesterId: 'requester-$requestId',
    requesterName: 'Requester $requestId',
    requesterAvatar: '',
    status: FriendRequestStatus.pending,
    createdAt: DateTime(2026, 1, 1),
    expiresAt: DateTime(2026, 2, 1),
  );
}

void main() {
  late MockFriendListRepository repository;
  late FriendListCubit cubit;

  setUp(() {
    repository = MockFriendListRepository();
    cubit = FriendListCubit(repository: repository);
  });

  tearDown(() {
    cubit.close();
  });

  // Helper: cast an opaque FriendListData state to FriendListLoaded.
  FriendListLoaded asLoaded(FriendListData state) {
    expect(state, isA<FriendListLoaded>(),
        reason: 'State phải là FriendListLoaded, nhưng là ${state.runtimeType}');
    return state as FriendListLoaded;
  }

  group('loadFriends', () {
    blocTest<FriendListCubit, FriendListData>(
      'emits FriendListLoaded (loading → loaded) trên success',
      build: () {
        repository.stubGetFriendsWithActivity(
          Right([_friend(id: 'f1', username: 'alice')]),
        );
        return cubit;
      },
      act: (c) => c.loadFriends(),
      expect: () => [
        // Loading state (set bởi _setSectionLoading).
        isA<FriendListLoaded>().having((s) => s.friendsLoading, 'friendsLoading', true),
        // Loaded state với data.
        isA<FriendListLoaded>()
            .having((s) => s.friends.length, 'friends count', 1)
            .having((s) => s.friendsEverLoaded, 'friendsEverLoaded', true)
            .having((s) => s.friendsError, 'friendsError', isNull)
            .having((s) => s.friendsLoading, 'friendsLoading', false),
      ],
    );

    blocTest<FriendListCubit, FriendListData>(
      'emits FriendListLoaded với friendsError khi load fail',
      build: () {
        repository.stubGetFriendsWithActivity(
          const Left(ServerFailure(message: 'Lỗi mạng')),
        );
        return cubit;
      },
      act: (c) => c.loadFriends(),
      expect: () => [
        isA<FriendListLoaded>().having((s) => s.friendsLoading, 'friendsLoading', true),
        isA<FriendListLoaded>().having((s) => s.friendsLoading, 'friendsLoading', false),
        isA<FriendListLoaded>()
            .having((s) => s.friendsError, 'friendsError', 'Lỗi mạng')
            .having((s) => s.friends, 'friends', isEmpty),
      ],
    );
  });

  group('loadReceivedRequests', () {
    test('giữ friends data khi load received fail', () async {
      repository.stubGetFriendsWithActivity(
        Right([_friend(id: 'f1', username: 'alice')]),
      );
      repository.stubGetReceivedRequests(
        const Left(ServerFailure(message: 'Lỗi mạng')),
      );

      await cubit.loadFriends();
      await cubit.loadReceivedRequests();

      final state = asLoaded(cubit.state);
      expect(state.friends.length, 1,
          reason: 'BUG FIX: Friends data KHÔNG được mất khi received fail');
      expect(state.friends.first.username, 'alice');
      expect(state.receivedRequestsError, 'Lỗi mạng',
          reason: 'receivedRequestsError phải set');
      expect(state.receivedRequestsLoading, false);
    });
  });

  group('bug fix: chuyển tab giữ data', () {
    test('friends data được giữ khi received requests fail', () async {
      // Arrange.
      repository.stubGetFriendsWithActivity(
        Right([_friend(id: 'f1', username: 'alice')]),
      );
      repository.stubGetReceivedRequests(
        const Left(ServerFailure(message: 'Lỗi mạng')),
      );

      // Act.
      await cubit.loadFriends();
      await cubit.loadReceivedRequests();

      // Assert.
      final state = asLoaded(cubit.state);
      expect(state.friends, isNotEmpty);
      expect(state.friends.first.username, 'alice');
      expect(state.receivedRequestsError, 'Lỗi mạng');
      expect(state.receivedRequests, isEmpty);
    });

    test('received data được giữ khi friends fail', () async {
      // Arrange.
      repository.stubGetFriendsWithActivity(
        const Left(ServerFailure(message: 'Lỗi mạng')),
      );
      repository.stubGetReceivedRequests(
        Right([_request(requestId: 'r1')]),
      );

      // Act.
      await cubit.loadFriends();
      await cubit.loadReceivedRequests();

      // Assert.
      final state = asLoaded(cubit.state);
      expect(state.receivedRequests, isNotEmpty,
          reason: 'BUG FIX: Received data KHÔNG được mất khi friends fail');
      expect(state.receivedRequests.first.requestId, 'r1');
      expect(state.friendsError, 'Lỗi mạng');
      expect(state.friends, isEmpty);
    });

    test('cả 2 section fail → cả 2 đều có error riêng, state là Loaded',
        () async {
      // Arrange.
      repository.stubGetFriendsWithActivity(
        const Left(ServerFailure(message: 'Lỗi friends')),
      );
      repository.stubGetReceivedRequests(
        const Left(ServerFailure(message: 'Lỗi requests')),
      );

      // Act.
      await cubit.loadFriends();
      await cubit.loadReceivedRequests();

      // Assert.
      final state = asLoaded(cubit.state);
      expect(state.friendsError, 'Lỗi friends');
      expect(state.receivedRequestsError, 'Lỗi requests');
      expect(state.friends, isEmpty);
      expect(state.receivedRequests, isEmpty);
    });

    test('cả 2 section OK → cả 2 đều có data', () async {
      // Arrange.
      repository.stubGetFriendsWithActivity(
        Right([_friend(id: 'f1', username: 'alice')]),
      );
      repository.stubGetReceivedRequests(
        Right([_request(requestId: 'r1')]),
      );

      // Act.
      await cubit.loadFriends();
      await cubit.loadReceivedRequests();

      // Assert.
      final loaded = asLoaded(cubit.state);
      expect(loaded.friends.length, 1);
      expect(loaded.receivedRequests.length, 1);
      expect(loaded.friendsEverLoaded, true);
      expect(loaded.receivedRequestsEverLoaded, true);
    });
  });

  group('retry per section', () {
    test('retry loadFriends → clear friendsError', () async {
      // First call fails.
      repository.stubGetFriendsWithActivity(
        const Left(ServerFailure(message: 'Lỗi')),
      );
      await cubit.loadFriends();
      expect(asLoaded(cubit.state).friendsError, 'Lỗi');

      // Second call (retry) succeeds.
      repository.stubGetFriendsWithActivity(
        Right([_friend(id: 'f1', username: 'alice')]),
      );
      await cubit.refreshFriends();

      final loaded = asLoaded(cubit.state);
      expect(loaded.friendsError, isNull,
          reason: 'Retry thành công → friendsError được clear');
      expect(loaded.friends.length, 1);
    });

    test('retry loadReceivedRequests → clear receivedRequestsError',
        () async {
      // First call for received fails.
      repository.stubGetReceivedRequests(
        const Left(ServerFailure(message: 'Lỗi')),
      );
      await cubit.loadReceivedRequests();
      expect(asLoaded(cubit.state).receivedRequestsError, 'Lỗi');

      // Second call (retry) succeeds.
      repository.stubGetReceivedRequests(
        Right([_request(requestId: 'r1')]),
      );
      await cubit.refreshReceivedRequests();

      final loaded = asLoaded(cubit.state);
      expect(loaded.receivedRequestsError, isNull,
          reason: 'Retry thành công → receivedRequestsError được clear');
      expect(loaded.receivedRequests.length, 1);
    });
  });

  group('copyWith với sentinel cho error fields', () {
    test('copyWith không truyền error → giữ nguyên error cũ', () {
      const original = FriendListLoaded(
        friendsError: 'Lỗi A',
        receivedRequestsError: 'Lỗi B',
      );

      final updated = original.copyWith(
          friends: [_friend(id: 'f1', username: 'a')]);

      expect(updated.friendsError, 'Lỗi A',
          reason: 'Sentinel giúp giữ nguyên error khi không truyền');
      expect(updated.receivedRequestsError, 'Lỗi B');
      expect(updated.friends.length, 1);
    });

    test('copyWith truyền null → xóa error', () {
      const original = FriendListLoaded(
        friendsError: 'Lỗi A',
      );

      final updated = original.copyWith(friendsError: null);

      expect(updated.friendsError, isNull,
          reason: 'Truyền null phải xóa error (clear)');
    });

    test('copyWith truyền error mới → thay thế error cũ', () {
      const original = FriendListLoaded(
        friendsError: 'Lỗi A',
      );

      final updated = original.copyWith(friendsError: 'Lỗi B');

      expect(updated.friendsError, 'Lỗi B');
    });
  });

  group('mutation fail không phá hủy FriendListLoaded', () {
    test('sendFriendRequest fail → giữ nguyên state', () async {
      // Setup initial state.
      repository.stubGetFriendsWithActivity(
        Right([_friend(id: 'f1', username: 'alice')]),
      );
      await cubit.loadFriends();
      final beforeState = cubit.state;

      // Send request fails.
      repository.stubSendFriendRequest(
        const Left(ServerFailure(message: 'Lỗi gửi')),
      );
      await cubit.sendFriendRequest(addresseeId: 'u2');

      expect(cubit.state, equals(beforeState),
          reason: 'State phải giữ nguyên khi mutation fail');
    });

    test('acceptFriendRequest fail → giữ nguyên state', () async {
      repository.stubGetFriendsWithActivity(
        Right([_friend(id: 'f1', username: 'alice')]),
      );
      repository.stubGetReceivedRequests(
        Right([_request(requestId: 'r1')]),
      );
      await cubit.loadFriends();
      await cubit.loadReceivedRequests();
      final beforeState = cubit.state;

      repository.stubAcceptFriendRequest(
        const Left(ServerFailure(message: 'Lỗi accept')),
      );
      await cubit.acceptFriendRequest('r1');

      expect(cubit.state, equals(beforeState),
          reason: 'Accept fail phải giữ nguyên FriendListLoaded');
    });

    test('declineFriendRequest fail → giữ nguyên state', () async {
      repository.stubGetFriendsWithActivity(
        Right([_friend(id: 'f1', username: 'alice')]),
      );
      repository.stubGetReceivedRequests(
        Right([_request(requestId: 'r1')]),
      );
      await cubit.loadFriends();
      await cubit.loadReceivedRequests();
      final beforeState = cubit.state;

      repository.stubDeclineFriendRequest(
        const Left(ServerFailure(message: 'Lỗi decline')),
      );
      await cubit.declineFriendRequest('r1');

      expect(cubit.state, equals(beforeState));
    });

    test('unfriend fail → giữ nguyên state', () async {
      repository.stubGetFriendsWithActivity(
        Right([_friend(id: 'f1', username: 'alice')]),
      );
      await cubit.loadFriends();
      final beforeState = cubit.state;

      repository.stubUnfriend(
        const Left(ServerFailure(message: 'Lỗi unfriend')),
      );
      await cubit.unfriend('f1');

      expect(cubit.state, equals(beforeState));
    });

    test('blockUser fail → giữ nguyên state, không reload', () async {
      repository.stubGetFriendsWithActivity(
        Right([_friend(id: 'f1', username: 'alice')]),
      );
      await cubit.loadFriends();
      final beforeState = cubit.state;
      repository.callOrder.clear();

      repository.stubBlockUser(
        const Left(ServerFailure(message: 'Lỗi block')),
      );
      await cubit.blockUser('u2');

      // State giữ nguyên.
      expect(cubit.state, equals(beforeState));
      // Quan trọng: blockUser fail không được trigger loadFriends/loadReceivedRequests.
      expect(repository.callOrder, isEmpty,
          reason: 'Block fail không nên reload (tránh side-effect không mong muốn)');
    });
  });
}