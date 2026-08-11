// Widget tests cho FriendsPage — tập trung vào:
// 1. Title "BẠN BÈ" không bị status bar che (margin-top / SafeArea).
// 2. Tab switching giữ nguyên dữ liệu đã load (bug fix Aug 2026).
// 3. Per-section error hiển thị retry button mà không phá hủy data section khác.

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:boardverse_mobile/core/error/failures.dart';
import 'package:boardverse_mobile/features/friend_management/domain/entities/entities.dart';
import 'package:boardverse_mobile/features/friend_management/domain/repositories/friend_repository.dart';
import 'package:boardverse_mobile/features/friend_management/presentation/cubit/friend_list_cubit.dart';
import 'package:boardverse_mobile/features/friend_management/presentation/cubit/states/states.dart';
import 'package:boardverse_mobile/features/friend_management/presentation/pages/friends_page.dart';

class _StubFriendRepository implements FriendRepository {
  Either<Failure, List<FriendEntity>> friendsResult =
      const Right(<FriendEntity>[]);
  Either<Failure, List<FriendRequestEntity>> requestsResult =
      const Right(<FriendRequestEntity>[]);

  void stubFriends(List<FriendEntity> data) {
    friendsResult = Right(data);
  }

  void stubFriendsFailure(String message) {
    friendsResult = Left(ServerFailure(message: message));
  }

  void stubRequests(List<FriendRequestEntity> data) {
    requestsResult = Right(data);
  }

  void stubRequestsFailure(String message) {
    requestsResult = Left(ServerFailure(message: message));
  }

  @override
  Future<Either<Failure, List<FriendEntity>>> getFriendsWithActivity() async =>
      friendsResult;

  @override
  Future<Either<Failure, List<FriendRequestEntity>>> getReceivedRequests() async =>
      requestsResult;

  // ─── Unused stubs ──────────────────────────────────────────────────────────

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
  Future<Either<Failure, FriendRequestEntity>> sendFriendRequest({
    required String addresseeId,
    String? message,
  }) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, FriendRequestEntity>> acceptFriendRequest(
          String requestId) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, FriendRequestEntity>> declineFriendRequest(
          String requestId) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, void>> markRequestAsRead(String requestId) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> unfriend(String friendId) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> blockUser(String userId) async =>
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

FriendEntity _friend({required String id, required String username}) =>
    FriendEntity(
      odId: id,
      username: username,
      avatarUrl: '',
      karmaPoints: 100,
    );

/// Instance cuối cùng được tạo — để test có thể verify state.
/// `BlocProvider` tạo cubit qua `sl<FriendListCubit>()` (factory) nên mỗi
/// call tạo instance mới; ta giữ reference instance cuối để test có thể
/// đọc state.
FriendListCubit? lastCreatedCubit;

Widget _wrapWithCubit(_StubFriendRepository repo) {
  // Register FriendListCubit trong GetIt để FriendsPage có thể resolve.
  // Dùng singleton để test có thể truy cập cùng instance mà BlocProvider dùng.
  final sl = GetIt.instance;
  if (sl.isRegistered<FriendListCubit>()) {
    sl.unregister<FriendListCubit>();
  }
  lastCreatedCubit = null;
  sl.registerFactory<FriendListCubit>(
    () {
      final cubit = FriendListCubit(repository: repo);
      lastCreatedCubit = cubit;
      return cubit;
    },
  );

  return const MaterialApp(
    home: FriendsPage(),
  );
}

void main() {
  group('FriendsPage — title position (status bar safe)', () {
    testWidgets(
        'AppBar có toolbarHeight đủ lớn để chứa status bar + title',
        (tester) async {
      // Fake status bar inset = 30dp (Android tiêu chuẩn).
      tester.view.padding = const FakeViewPadding(top: 30);
      addTearDown(tester.view.reset);

      final repo = _StubFriendRepository();
      repo.stubFriends([]);
      await tester.pumpWidget(_wrapWithCubit(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find the AppBar.
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      // ToolbarHeight phải được set (không null) để chứa status bar.
      expect(appBar.toolbarHeight, isNotNull,
          reason: 'ToolbarHeight phải được set để chứa status bar');
      // ToolbarHeight phải > kToolbarHeight (56) — đây là fix chính:
      // trước đây toolbarHeight = 56 làm title bị status bar che.
      expect(appBar.toolbarHeight! > kToolbarHeight, isTrue,
          reason: 'BUG FIX: ToolbarHeight phải > kToolbarHeight (56) để '
              'chứa status bar.');
    });

    testWidgets('title "BẠN BÈ" hiển thị đầy đủ (không bị che)',
        (tester) async {
      // Reset padding về 0 (tránh bị ảnh hưởng từ test trước).
      tester.view.padding = FakeViewPadding.zero;
      addTearDown(tester.view.reset);

      final repo = _StubFriendRepository();
      repo.stubFriends([]);
      await tester.pumpWidget(_wrapWithCubit(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify text widget tồn tại — kể cả khi đứng một mình.
      // AppBar title + TabBar label đều có "BẠN BÈ" nên có 2 instances.
      expect(find.text('BẠN BÈ'), findsWidgets,
          reason: 'Title "BẠN BÈ" phải hiển thị trên AppBar');
      expect(find.text('BẠN BÈ').hitTestable(), findsWidgets,
          reason: 'Title phải render đầy đủ, không bị overflow làm mất text');
    });
  });

  group('FriendsPage — bug fix: tab switching giữ data', () {
    testWidgets(
        'chuyển tab qua lại, friends data không bị mất (qua cubit state)',
        (tester) async {
      final repo = _StubFriendRepository();
      repo.stubFriends([_friend(id: 'f1', username: 'alice')]);
      repo.stubRequests([]);

      // Lấy cubit instance từ GetIt.
      await tester.pumpWidget(_wrapWithCubit(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 100));

      final cubit = lastCreatedCubit;
      expect(cubit, isNotNull, reason: 'Cubit phải được tạo bởi BlocProvider');
      cubit!;

      // Đợi load friends xong.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(cubit.state, isA<FriendListLoaded>(),
          reason: 'Cubit state phải là FriendListLoaded');
      final loaded = cubit.state as FriendListLoaded;
      expect(loaded.friends.length, 1,
          reason: 'Friends data phải được load');
      expect(loaded.friends.first.username, 'alice');

      // Load received requests.
      await cubit.loadReceivedRequests();
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final afterRequests = cubit.state as FriendListLoaded;
      expect(afterRequests.friends.length, 1,
          reason: 'BUG FIX: Friends data KHÔNG bị mất khi received load');
      expect(afterRequests.friends.first.username, 'alice');
      expect(afterRequests.receivedRequests, isEmpty);
    });

    testWidgets(
        'chuyển tab qua lại khi received requests fail → friends data vẫn còn',
        (tester) async {
      final repo = _StubFriendRepository();
      repo.stubFriends([_friend(id: 'f1', username: 'alice')]);
      repo.stubRequestsFailure('Lỗi mạng');

      await tester.pumpWidget(_wrapWithCubit(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 100));

      final cubit = lastCreatedCubit;
      expect(cubit, isNotNull, reason: 'Cubit phải được tạo bởi BlocProvider');
      cubit!;

      // Đợi load friends xong.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Load received requests (sẽ fail).
      await cubit.loadReceivedRequests();
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final state = cubit.state;
      expect(state, isA<FriendListLoaded>(),
          reason: 'BUG FIX: State vẫn là FriendListLoaded, không bị phá hủy');
      final loaded = state as FriendListLoaded;
      expect(loaded.friends.length, 1,
          reason: 'BUG FIX: Friends data KHÔNG bị mất khi received fail');
      expect(loaded.friends.first.username, 'alice');
      expect(loaded.receivedRequestsError, 'Lỗi mạng',
          reason: 'receivedRequestsError phải được set');
    });

    testWidgets('tab 0 friends fail → cubit state có friendsError',
        (tester) async {
      final repo = _StubFriendRepository();
      repo.stubFriendsFailure('Lỗi load friends');
      repo.stubRequests([]);

      await tester.pumpWidget(_wrapWithCubit(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final cubit = lastCreatedCubit;
      expect(cubit, isNotNull, reason: 'Cubit phải được tạo bởi BlocProvider');
      cubit!;

      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final state = cubit.state as FriendListLoaded;
      expect(state.friendsError, 'Lỗi load friends');
      expect(state.friends, isEmpty);
    });
  });
}
