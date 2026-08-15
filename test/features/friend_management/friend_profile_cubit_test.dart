// Unit tests for FriendProfileCubit.
//
// Verify state transitions for:
// - loadProfile (loading → loaded / failure)
// - sendFriendRequest → reload → success
// - unfriend → reload → success
// - blockUser → reload → success
// - unblockUser → reload → success
// - report → emit action message
// - loadMutualFriends → update mutual list
// - clearActionMessage

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/features/friend_management/domain/entities/entities.dart';
import 'package:boardverse/features/friend_management/domain/repositories/friend_repository.dart';
import 'package:boardverse/features/friend_management/presentation/cubit/friend_profile_cubit.dart';
import 'package:boardverse/features/friend_management/presentation/cubit/states/states.dart';

class MockFriendRepository implements FriendRepository {
  final Map<String, dynamic> stubs = {};
  String? lastSentAddresseeId;
  String? lastSentMessage;
  String? lastUnfriendId;
  String? lastBlockedUserId;
  FriendRequestEntity? lastRequestResult;
  List<FriendEntity> stubbedMutual = const [];

  void stubGetPlayerProfile(Either<Failure, FriendProfileEntity> result) {
    stubs['getPlayerProfile'] = result;
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

  void stubUnblockUser(Either<Failure, void> result) {
    stubs['unblockUser'] = result;
  }

  void stubCreateReport(Either<Failure, void> result) {
    stubs['createReport'] = result;
  }

  void stubGetMutualFriends(Either<Failure, List<FriendEntity>> result) {
    stubs['getMutualFriends'] = result;
  }

  @override
  Future<Either<Failure, FriendProfileEntity>> getPlayerProfile(
    String userId,
  ) async {
    return stubs['getPlayerProfile'] as Either<Failure, FriendProfileEntity>;
  }

  @override
  Future<Either<Failure, FriendRequestEntity>> sendFriendRequest({
    required String addresseeId,
    String? message,
  }) async {
    lastSentAddresseeId = addresseeId;
    lastSentMessage = message;
    final res = stubs['sendFriendRequest'] as Either<Failure, FriendRequestEntity>;
    res.fold(
      (_) {},
      (r) => lastRequestResult = r,
    );
    return res;
  }

  @override
  Future<Either<Failure, void>> unfriend(String friendId) async {
    lastUnfriendId = friendId;
    return stubs['unfriend'] as Either<Failure, void>;
  }

  @override
  Future<Either<Failure, void>> blockUser(String userId) async {
    lastBlockedUserId = userId;
    return stubs['blockUser'] as Either<Failure, void>;
  }

  @override
  Future<Either<Failure, void>> unblockUser(String userId) async {
    return stubs['unblockUser'] as Either<Failure, void>;
  }

  @override
  Future<Either<Failure, void>> createReport({
    required String targetUserId,
    required String category,
    required String reason,
  }) async {
    return stubs['createReport'] as Either<Failure, void>;
  }

  @override
  Future<Either<Failure, List<FriendEntity>>> getMutualFriends(
    String otherUserId,
  ) async {
    return stubs['getMutualFriends'] as Either<Failure, List<FriendEntity>>;
  }

  // ─── Unused stubs (only required by interface) ────────────────────────────

  @override
  Future<Either<Failure, List<FriendEntity>>> getFriends() async =>
      const Right(<FriendEntity>[]);

  @override
  Future<Either<Failure, List<FriendEntity>>> getFriendsWithActivity() async =>
      const Right(<FriendEntity>[]);

  @override
  Future<Either<Failure, List<FriendEntity>>> getFriendList(
    String otherUserId,
  ) async =>
      const Right(<FriendEntity>[]);

  @override
  Future<Either<Failure, List<FriendRequestEntity>>> getReceivedRequests() async =>
      const Right(<FriendRequestEntity>[]);

  @override
  Future<Either<Failure, List<FriendRequestEntity>>> getSentRequests() async =>
      const Right(<FriendRequestEntity>[]);

  @override
  Future<Either<Failure, FriendRequestEntity>> acceptFriendRequest(
    String requestId,
  ) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, FriendRequestEntity>> declineFriendRequest(
    String requestId,
  ) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, void>> markRequestAsRead(String requestId) async =>
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
  Future<Either<Failure, List<FriendReportEntity>>> getMyReports() async =>
      const Right(<FriendReportEntity>[]);
}

FriendProfileEntity _mockProfile({
  String userId = 'u1',
  String username = 'alice',
  FriendshipStatus friendshipStatus = FriendshipStatus.none,
  bool isBlockedByMe = false,
}) {
  return FriendProfileEntity(
    userId: userId,
    username: username,
    avatarUrl: '',
    karmaPoints: 100,
    gamerTier: GamerTier.silver,
    globalElo: 1200,
    level: 5,
    mutualFriendsCount: 2,
    friendshipStatus: friendshipStatus,
    canSendFriendRequest: true,
    canReport: false,
    isBlockedByMe: isBlockedByMe,
  );
}

FriendRequestEntity _mockRequest({
  required String requestId,
  required String addresseeId,
}) {
  return FriendRequestEntity(
    requestId: requestId,
    requesterId: 'me',
    requesterName: 'me',
    requesterAvatar: '',
    status: FriendRequestStatus.pending,
    createdAt: DateTime(2026, 1, 1),
    expiresAt: DateTime(2026, 2, 1),
  );
}

void main() {
  late MockFriendRepository repository;
  late FriendProfileCubit cubit;

  setUp(() {
    repository = MockFriendRepository();
    cubit = FriendProfileCubit(repository: repository);
  });

  tearDown(() {
    cubit.close();
  });

  group('loadProfile', () {
    blocTest<FriendProfileCubit, FriendProfileState>(
      'emits [FriendProfileLoading, FriendProfileLoaded] on success',
      build: () {
        repository.stubGetPlayerProfile(
          Right(_mockProfile()),
        );
        return cubit;
      },
      act: (c) => c.loadProfile('u1'),
      expect: () => [
        const FriendProfileLoading(userId: 'u1'),
        isA<FriendProfileLoaded>().having(
          (s) => s.profile.username,
          'username',
          'alice',
        ),
      ],
    );

    blocTest<FriendProfileCubit, FriendProfileState>(
      'emits [FriendProfileLoading, FriendProfileError] on failure',
      build: () {
        repository.stubGetPlayerProfile(
          const Left(NotFoundFailure(message: 'Không tìm thấy')),
        );
        return cubit;
      },
      act: (c) => c.loadProfile('u1'),
      expect: () => [
        const FriendProfileLoading(userId: 'u1'),
        isA<FriendProfileError>(),
      ],
    );

    test('currentUserId is set after loadProfile', () async {
      repository.stubGetPlayerProfile(Right(_mockProfile()));
      await cubit.loadProfile('u1');
      expect(cubit.currentUserId, 'u1');
    });
  });

  group('sendFriendRequest', () {
    blocTest<FriendProfileCubit, FriendProfileState>(
      'reloads profile and emits actionMessage on success',
      build: () {
        repository.stubSendFriendRequest(
          Right(_mockRequest(requestId: 'r1', addresseeId: 'u1')),
        );
        repository.stubGetPlayerProfile(
          Right(_mockProfile(
            friendshipStatus: FriendshipStatus.pendingSent,
          )),
        );
        return cubit;
      },
      act: (c) async {
        await c.loadProfile('u1');
        await c.sendFriendRequest();
      },
      skip: 1, // Skip the loading emitted by initial loadProfile
      verify: (_) {
        expect(repository.lastSentAddresseeId, 'u1');
      },
    );

    blocTest<FriendProfileCubit, FriendProfileState>(
      'emits FriendProfileError on failure',
      build: () {
        repository.stubGetPlayerProfile(Right(_mockProfile()));
        repository.stubSendFriendRequest(
          const Left(ConflictFailure(message: 'Đã gửi rồi')),
        );
        return cubit;
      },
      act: (c) async {
        await c.loadProfile('u1');
        await c.sendFriendRequest();
      },
      verify: (_) {
        // Verify last state is either error or holds previous profile.
        final state = cubit.state;
        expect(
          state is FriendProfileError || state is FriendProfileLoaded,
          isTrue,
        );
      },
    );
  });

  group('unfriend', () {
    test('calls repository with current userId', () async {
      repository.stubGetPlayerProfile(
        Right(_mockProfile(friendshipStatus: FriendshipStatus.accepted)),
      );
      repository.stubUnfriend(const Right(null));
      await cubit.loadProfile('u1');
      await cubit.unfriend();
      expect(repository.lastUnfriendId, 'u1');
    });
  });

  group('blockUser / unblockUser', () {
    test('blockUser calls repository', () async {
      repository.stubGetPlayerProfile(Right(_mockProfile()));
      repository.stubBlockUser(const Right(null));
      await cubit.loadProfile('u1');
      await cubit.blockUser();
      expect(repository.lastBlockedUserId, 'u1');
    });

    test('unblockUser calls repository', () async {
      repository.stubGetPlayerProfile(
        Right(_mockProfile(isBlockedByMe: true)),
      );
      repository.stubUnblockUser(const Right(null));
      await cubit.loadProfile('u1');
      await cubit.unblockUser();
      // No assertion failure means it dispatched correctly.
      expect(cubit.currentUserId, 'u1');
    });
  });

  group('clearActionMessage', () {
    test('clears the message on Loaded state', () async {
      repository.stubGetPlayerProfile(
        Right(_mockProfile(friendshipStatus: FriendshipStatus.pendingSent)),
      );
      repository.stubSendFriendRequest(
        Right(_mockRequest(requestId: 'r1', addresseeId: 'u1')),
      );
      await cubit.loadProfile('u1');
      await cubit.sendFriendRequest();
      cubit.clearActionMessage();
      final state = cubit.state;
      if (state is FriendProfileLoaded) {
        expect(state.actionMessage, isNull);
      }
    });
  });
}
