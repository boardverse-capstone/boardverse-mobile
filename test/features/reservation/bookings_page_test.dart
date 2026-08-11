// Widget tests cho `BookingsPage` sau khi redesign (Aug 2026).
//
// Mục tiêu:
//   - Tab "Phòng chờ" (default) hiển thị lobby list qua MyLobbiesCubit.
//   - Tab "Lịch đặt" hiển thị reservation list qua ReservationListPage.
//   - Tap reservation card → navigate tới ReservationDetailPage.
//   - Tap lobby card → navigate tới LobbyPage.
//
// Vì `BookingsPage` cần `MyLobbiesCubit` từ context (do MainScaffold cung
// cấp) và `ReservationRepository` từ GetIt, ta wrap test trong
// `BlocProvider<MyLobbiesCubit>` và stub cả 2 nguồn.

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:boardverse_mobile/core/error/failures.dart';
import 'package:boardverse_mobile/core/network/paginated_response.dart';
import 'package:boardverse_mobile/features/friend_management/domain/entities/friend_entity.dart';
import 'package:boardverse_mobile/features/lobby_management/data/realtime/lobby_realtime_service.dart';
import 'package:boardverse_mobile/features/lobby_management/domain/entities/lobby_chat_message.dart';
import 'package:boardverse_mobile/features/lobby_management/domain/entities/lobby_entity.dart'
    show LobbyEntity, LobbyStatus;
import 'package:boardverse_mobile/features/lobby_management/domain/entities/lobby_invitable_friend.dart';
import 'package:boardverse_mobile/features/lobby_management/domain/entities/lobby_invite_entity.dart';
import 'package:boardverse_mobile/features/lobby_management/domain/entities/lobby_share_info.dart';
import 'package:boardverse_mobile/features/lobby_management/domain/entities/lobby_summary.dart';
import 'package:boardverse_mobile/features/lobby_management/domain/repositories/lobby_repository.dart';
import 'package:boardverse_mobile/features/lobby_management/presentation/cubit/my_lobbies_cubit.dart';
// Chỉ import ReservationEntity (không qua `entities.dart` để tránh pull
// theo LobbyStatus trùng tên với lobby_management).
import 'package:boardverse_mobile/features/reservation/domain/entities/reservation_entity.dart'
    hide LobbyStatus;
import 'package:boardverse_mobile/features/reservation/domain/entities/reservation_quote_entity.dart';
import 'package:boardverse_mobile/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:boardverse_mobile/core/navigation/pages/bookings_page.dart';

class _StubLobbyRepository implements LobbyRepository {
  Either<Failure, List<LobbyEntity>> hostedResult =
      const Right(<LobbyEntity>[]);
  Either<Failure, List<LobbyEntity>> joinedResult =
      const Right(<LobbyEntity>[]);

  void stubHosted(List<LobbyEntity> data) {
    hostedResult = Right(data);
  }

  void stubJoined(List<LobbyEntity> data) {
    joinedResult = Right(data);
  }

  void stubFailure(String message) {
    hostedResult = Left(ServerFailure(message: message));
    joinedResult = Left(ServerFailure(message: message));
  }

  /// Throw exception khi load — dùng để test trạng thái error
  /// (MyLobbiesFailure). Fail trả về Left chỉ làm empty list, không
  /// phải error.
  void stubThrows() {
    hostedResult = const Right(<LobbyEntity>[]);
    joinedResult = const Right(<LobbyEntity>[]);
    throwOnLoad = true;
  }

  bool throwOnLoad = false;

  @override
  Future<Either<Failure, List<LobbyEntity>>> getHostedLobbies() async {
    if (throwOnLoad) {
      throw Exception('Lỗi mạng');
    }
    return hostedResult;
  }

  @override
  Future<Either<Failure, List<LobbyEntity>>> getJoinedLobbies() async {
    if (throwOnLoad) {
      throw Exception('Lỗi mạng');
    }
    return joinedResult;
  }

  // Unused stubs - throw NotFoundFailure để các test khác fail ngay nếu
  // vô tình gọi tới.
  @override
  Future<Either<Failure, LobbyEntity?>> getLobbyById(String lobbyId) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, bool>> joinLobby(String lobbyId, String? inviteCode) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, void>> leaveLobby(String lobbyId) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, void>> inviteFriend(String lobbyId, String friendId) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, void>> sendLobbyInvite({
    required String lobbyId,
    required String inviteeId,
    String? message,
  }) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, List<LobbyInviteEntity>>> getLobbyInvites({
    required String lobbyId,
    LobbyInviteStatus? status,
    int limit = 100,
  }) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, LobbyInviteEntity>> resendInvite(String inviteId) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, List<LobbyInvitableFriend>>> getInvitableFriends({
    required String lobbyId,
    String? search,
    bool onlineOnly = false,
    int? minKarma,
    List<LobbyInviteFriendStatus> statusFilter = const [],
    int limit = 100,
  }) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, List<LobbyInviteEntity>>> getPendingLobbyInvites() async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, List<LobbyInviteEntity>>> getAllLobbyInvites({
    LobbyInviteStatus? status,
  }) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, LobbyEntity>> acceptLobbyInvite(String inviteId) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, void>> declineLobbyInvite(String inviteId) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, void>> cancelLobbyInvite(String inviteId) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, LobbyShareInfo>> getLobbyShareInfo(String lobbyId) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, LobbyEntity>> joinLobbyByCode(String shareCode) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, List<FriendEntity>>> getOnlineFriends() async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, void>> cancelLobby(String lobbyId, String reasonCode) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, LobbyEntity>> closeLobby(String lobbyId) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, void>> dissolveLobby({
    required String lobbyId,
    String? reason,
  }) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, LobbyEntity>> lockLobby(String lobbyId) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, LobbyEntity>> openKarmaWindow(String lobbyId) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, List<LobbySummary>>> searchNearbyLobbies({
    required double latitude,
    required double longitude,
    required LobbySearchFilter filter,
    required double currentUserKarma,
    bool excludeSelfOverlapping = true,
  }) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, List<LobbyEntity>>> discoverableLobbies({
    String? gameTemplateId,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int limit = 50,
    bool excludeSelfOverlapping = true,
  }) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, LobbyEntity>> updateLobbyStatus(
    String lobbyId,
    LobbyStatus newStatus,
  ) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, LobbyEntity>> transferHost({
    required String lobbyId,
    required String newHostId,
  }) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, LobbyEntity>> kickMember({
    required String lobbyId,
    required String targetUserId,
    String? reason,
  }) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, LobbyEntity>> setReady({
    required String lobbyId,
    required bool isReady,
  }) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, LobbyEntity>> updateLobby({
    required String lobbyId,
    String? description,
    int? maxMembers,
    bool? isPrivate,
    int? minKarmaScore,
  }) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, void>> reportLobby({
    required String lobbyId,
    required String category,
    required String reason,
  }) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, LobbyChatMessage>> sendChatMessage({
    required String lobbyId,
    required String content,
  }) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, List<LobbyChatMessage>>> getChatMessages({
    required String lobbyId,
    String? beforeCursor,
    int limit = 50,
  }) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, LobbyEntity>> simulateAddFriend({
    required String lobbyId,
    required String friendId,
  }) async {
    return const Left(NotFoundFailure(message: 'Not implemented'));
  }

  @override
  Stream<LobbyEntity> watchLobbyRealtime(String lobbyId) {
    return const Stream.empty();
  }

  @override
  Stream<LobbyRealtimeEvent> watchLobbyEvents(String lobbyId) {
    return const Stream.empty();
  }
}

class _StubReservationRepository implements ReservationRepository {
  Either<Failure, List<ReservationEntity>> reservationsResult =
      const Right(<ReservationEntity>[]);

  void stubReservations(List<ReservationEntity> data) {
    reservationsResult = Right(data);
  }

  @override
  Future<Either<Failure, PaginatedResponse<ReservationEntity>>>
      getReservations({
    List<String>? statuses,
    DateTime? playDate,
    String? cafeId,
    bool? hostedByMe,
    bool? joinedByMe,
    int page = 1,
    int pageSize = 20,
  }) async {
    return reservationsResult.fold(
      (l) => Left<Failure, PaginatedResponse<ReservationEntity>>(l),
      (r) => Right<Failure, PaginatedResponse<ReservationEntity>>(
        PaginatedResponse<ReservationEntity>(
          items: r,
          page: 1,
          pageSize: r.length,
          totalItems: r.length,
          totalPages: 1,
          hasNextPage: false,
          hasPreviousPage: false,
        ),
      ),
    );
  }

  // Unused stubs.
  @override
  Future<Either<Failure, ReservationQuoteEntity>> createQuote({
    required String cafeId,
    required String gameId,
    required DateTime playDate,
    required TimeSlot timeSlot,
    String? preferredStartTime,
    required int minPlayers,
    required int maxPlayers,
    required bool isPrivate,
    required String idempotencyKey,
  }) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, ReservationConfirmResult>> confirmReservation({
    required String cafeId,
    required String gameId,
    required DateTime playDate,
    required TimeSlot timeSlot,
    String? preferredStartTime,
    required int minPlayers,
    required int maxPlayers,
    required bool isPrivate,
    required int expectedFinalDeposit,
    required String idempotencyKey,
  }) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, ReservationCancelResult>> cancelReservation({
    required String reservationId,
    String? reason,
    required String idempotencyKey,
  }) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, ReservationEntity>> getReservation(
      String reservationId) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, ReservationEntity>> getReservationDetail(
      String reservationId) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, PaginatedResponse<ReservationEntity>>>
      getPendingCafeApprovals({
    String? cafeId,
    DateTime? playDate,
    int page = 1,
    int pageSize = 20,
  }) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, void>> cafeApproval({
    required String reservationId,
    required bool approve,
    String? reason,
  }) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));
}

LobbyEntity _makeLobby({
  String id = 'lobby-1',
  String gameName = 'Catan',
  String cafeName = 'BoardGame Cafe',
  LobbyStatus status = LobbyStatus.open,
  int currentPlayers = 3,
  int maxPlayers = 6,
  bool isPublic = true,
}) {
  final scheduled = DateTime.now().add(const Duration(days: 1));
  return LobbyEntity(
    id: id,
    gameId: 'game-1',
    gameName: gameName,
    cafeId: 'cafe-1',
    cafeName: cafeName,
    hostId: 'host-1',
    hostName: 'Host',
    scheduledTime: scheduled,
    currentPlayers: currentPlayers,
    maxPlayers: maxPlayers,
    minPlayers: 4,
    isPublic: isPublic,
    inviteCode: 'K7H3NP9X',
    status: status,
    players: const [],
    createdAt: DateTime.now(),
    timeoutAt: scheduled.subtract(const Duration(minutes: 30)),
    minimumKarma: 0,
    searchRadiusKm: 5,
  );
}

ReservationEntity _makeReservation({
  String id = 'r1',
  String gameName = 'Catan',
  ReservationStatus status = ReservationStatus.holding,
  // Note: LobbyStatus ở đây là reservation_entity.dart (LobbyStatus duplicate
  // từ lobby_management). 2 enum có cùng members nên code chạy được, nhưng
  // type identity khác nhau → không gán qua nhau được.
  String? lobbyId = 'lobby-1',
}) {
  final time = DateTime.now().add(const Duration(days: 2));
  return ReservationEntity(
    id: id,
    hostId: 'host-1',
    cafeId: 'cafe-1',
    cafeName: 'BoardGame Cafe',
    gameId: 'game-1',
    gameName: gameName,
    playDate: time,
    timeSlot: TimeSlot.evening,
    scheduledTime: time,
    recruitmentDeadline: time.subtract(const Duration(minutes: 20)),
    minPlayers: 4,
    maxPlayers: 6,
    depositRatePerPerson: 5,
    baseDeposit: 30,
    riskMultiplier: 1.0,
    minDepositApplied: 100000,
    finalDeposit: 100000,
    status: status,
    currentPlayers: 3,
    lobbyId: lobbyId,
    lobbyStatus: null,
    requiresCafeApproval: false,
    createdAt: DateTime.now(),
  );
}

void main() {
  late _StubLobbyRepository lobbyRepo;
  late _StubReservationRepository reservationRepo;
  late MyLobbiesCubit cubit;

  setUp(() async {
    lobbyRepo = _StubLobbyRepository();
    reservationRepo = _StubReservationRepository();
    cubit = MyLobbiesCubit(repository: lobbyRepo);

    final sl = GetIt.instance;
    if (sl.isRegistered<ReservationRepository>()) {
      await sl.unregister<ReservationRepository>();
    }
    sl.registerSingleton<ReservationRepository>(reservationRepo);
  });

  tearDown(() async {
    await cubit.close();
    final sl = GetIt.instance;
    if (sl.isRegistered<ReservationRepository>()) {
      await sl.unregister<ReservationRepository>();
    }
  });

  Widget wrap() {
    return BlocProvider<MyLobbiesCubit>.value(
      value: cubit,
      child: const MaterialApp(
        home: BookingsPage(),
      ),
    );
  }

  group('BookingsPage — tabbed layout', () {
    testWidgets('hiển thị page title + 2 tab', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.text('LỊCH ĐẶT'), findsOneWidget,
          reason: 'Page title "LỊCH ĐẶT" phải hiển thị');
      expect(find.text('Phòng chờ'), findsOneWidget);
      expect(find.text('Lịch đặt'), findsOneWidget);
    });

    testWidgets('tab "Lịch đặt" (default) render reservation list',
        (tester) async {
      reservationRepo.stubReservations([
        _makeReservation(gameName: 'Wingspan'),
      ]);

      await tester.pumpWidget(wrap());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Wingspan'), findsOneWidget,
          reason: 'Reservation phải render ở tab Lịch đặt (default)');
    });

    testWidgets('tab "Lịch đặt" hiển thị empty state', (tester) async {
      reservationRepo.stubReservations(const []);

      await tester.pumpWidget(wrap());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.textContaining('Bạn chưa tạo đơn reservation nào'),
        findsOneWidget,
      );
    });

    testWidgets('chuyển sang tab "Phòng chờ" render lobby list', (tester) async {
      lobbyRepo.stubHosted([_makeLobby()]);
      cubit.load(null);

      await tester.pumpWidget(wrap());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tab thứ 2 (index 1) là "Phòng chờ".
      await tester.tap(find.byType(Tab).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Catan'), findsOneWidget,
          reason: 'Lobby phải render trong tab Phòng chờ');
    });

    testWidgets('tab "Phòng chờ" hiển thị empty state khi không có lobby',
        (tester) async {
      lobbyRepo.stubHosted(const []);
      lobbyRepo.stubJoined(const []);

      await tester.pumpWidget(wrap());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(Tab).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.textContaining('Bạn chưa tạo hoặc tham gia phòng chờ nào'),
        findsOneWidget,
      );
    });

    testWidgets('tab "Phòng chờ" render error + retry khi API fail',
        (tester) async {
      lobbyRepo.stubThrows();

      await tester.pumpWidget(wrap());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(Tab).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Cubit bắt exception → emit MyLobbiesFailure với message 'Không tải được phòng chờ: ...'
      expect(find.textContaining('Không tải được phòng chờ'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });
  });
}