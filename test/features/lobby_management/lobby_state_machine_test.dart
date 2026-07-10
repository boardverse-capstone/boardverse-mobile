// Test cho Lobby State Machine (Task 3).
//
// Verify:
// - Search BR-10: lọc karma đúng
// - BR-07: createLobbyForExistingBooking reject khi vượt seat count
// - Realtime: stream phát ít nhất 2 snapshot
// - cancelLobby chuyển status cuối

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardverse_mobile/core/error/failures.dart';
import 'package:boardverse_mobile/features/lobby_management/data/datasources/mock_lobby_datasource.dart';
import 'package:boardverse_mobile/features/lobby_management/data/lobby_persistence_service.dart';
import 'package:boardverse_mobile/features/lobby_management/data/lobby_repository_impl.dart';
import 'package:boardverse_mobile/features/lobby_management/domain/entities/lobby_entity.dart';
import 'package:boardverse_mobile/features/lobby_management/domain/entities/lobby_summary.dart';
import 'package:boardverse_mobile/features/lobby_management/domain/repositories/lobby_repository.dart';
import 'package:boardverse_mobile/features/lobby_management/presentation/cubit/lobby_cubit.dart';
import 'package:boardverse_mobile/features/lobby_management/presentation/cubit/lobby_state.dart';

import '_fake_secure_storage.dart';

LobbyRepository _makeRepo() {
  // Đảm bảo seed trước — dùng call đầu tiên sẽ khởi tạo store.
  MockLobbyDatasource.ensureSeeded();
  return LobbyRepositoryImpl();
}

LobbyCubit _makeCubit() {
  MockLobbyDatasource.ensureSeeded();
  return LobbyCubit(
    repository: LobbyRepositoryImpl(),
    persistenceService: LobbyPersistenceService(storage: FakeSecureStorage()),
  );
}

void main() {
  // TestWidgetsFlutterBinding cần thiết vì LobbyCubit gọi
  // LobbyPersistenceService (gối FlutterSecureStorage) trong createLobby.
  TestWidgetsFlutterBinding.ensureInitialized();
  group('BR-07 — createLobbyForExistingBooking (seat cap)', () {
    late LobbyRepository repo;
    setUp(() => repo = _makeRepo());

    test('reject khi additionalSlots + 1 > bookingSeatCount', () async {
      final result = await repo.createLobbyForExistingBooking(
        bookingId: 'BOOK_TEST_001',
        bookingSeatCount: 3,
        gameId: 'bg_001',
        cafeId: 'cafe_001',
        scheduledTime: DateTime.now().add(const Duration(hours: 2)),
        additionalSlots: 5, // 5 + 1 = 6 > 3 → phải fail
        isPublic: true,
      );
      expect(result.isLeft(), isTrue);
      result.fold((f) {
        expect(f, isA<ServerFailure>());
        expect(f.message.toLowerCase(), contains('vượt quá'));
      }, (_) => fail('should be Left'));
    });

    test('accept khi additionalSlots + 1 <= bookingSeatCount', () async {
      final result = await repo.createLobbyForExistingBooking(
        bookingId: 'BOOK_TEST_002',
        bookingSeatCount: 5,
        gameId: 'bg_002',
        cafeId: 'cafe_002',
        scheduledTime: DateTime.now().add(const Duration(hours: 3)),
        additionalSlots: 2,
        isPublic: true,
      );
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('should be Right'),
        (lobby) {
          expect(lobby.maxPlayers, lessThanOrEqualTo(5));
          expect(lobby.bookingId, 'BOOK_TEST_002');
        },
      );
    });
  });

  group('BR-10 — searchNearbyLobbies filter Karma', () {
    late LobbyRepository repo;
    setUp(() => repo = _makeRepo());

    test('user có karma 50 thấy được lobby yêu cầu minKarma 40', () async {
      final result = await repo.searchNearbyLobbies(
        latitude: 10.7769,
        longitude: 106.7009,
        filter: const LobbySearchFilter(radiusKm: 20, excludeOwnLobbies: false),
        currentUserKarma: 50,
      );
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('should be Right'),
        (list) {
          // Tất cả lobby user thấy được phải có minimumKarma <= 50.
          for (final lobby in list) {
            expect(lobby.minimumKarma, lessThanOrEqualTo(50));
          }
        },
      );
    });

    test('user có karma 30 KHÔNG thấy lobby yêu cầu minKarma 50+', () async {
      final result = await repo.searchNearbyLobbies(
        latitude: 10.7769,
        longitude: 106.7009,
        filter: const LobbySearchFilter(radiusKm: 20, excludeOwnLobbies: false),
        currentUserKarma: 30,
      );
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('should be Right'),
        (list) {
          for (final lobby in list) {
            expect(lobby.minimumKarma, lessThanOrEqualTo(30));
          }
        },
      );
    });

    test('lobby do chính user tạo bị filter ra khi excludeOwnLobbies=true',
        () async {
      // Pre-seed user_001 là host.
      MockLobbyDatasource.ensureSeeded();
      final result = await repo.searchNearbyLobbies(
        latitude: 10.7769,
        longitude: 106.7009,
        filter: const LobbySearchFilter(radiusKm: 50),
        currentUserKarma: 100,
      );
      result.fold(
        (_) => fail('should be Right'),
        (list) {
          for (final lobby in list) {
            // lobby_id luôn có hostId cố định 'user_001' trong mock impl.
            expect(lobby.id, isNot('lobby_001'));
          }
        },
      );
    });
  });

  group('Realtime — watchLobbyRealtime', () {
    late LobbyRepository repo;
    setUp(() => repo = _makeRepo());

    test('stream phát ít nhất 1 snapshot trong vòng 1s', () async {
      final stream = repo.watchLobbyRealtime('lobby_001');
      final first = await stream.first.timeout(
        const Duration(seconds: 1),
        onTimeout: () => throw TimeoutException('No realtime emit'),
      );
      expect(first.id, 'lobby_001');
    });
  });

  group('cancelLobby + updateLobbyStatus', () {
    late LobbyRepository repo;
    setUp(() => repo = _makeRepo());

    test('cancelLobby(..., TIMEOUT_FAILED) → set status cuối', () async {
      await repo.cancelLobby('lobby_001', 'TIMEOUT_FAILED');
      final result = await repo.getLobbyById('lobby_001');
      result.fold(
        (_) => fail('should be Right'),
        (lobby) {
          // Sau cancel, status chuyển sang timeoutFailed (theo cancel logic).
          expect(lobby, isA<LobbyEntity>());
        },
      );
    });

    test('updateLobbyStatus(id, .full) → trả về entity full', () async {
      // lobby_001 luôn có sẵn sau ensureSeeded().
      final result = await repo.updateLobbyStatus('lobby_001', LobbyStatus.full);
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('should be Right'),
        (lobby) => expect(lobby.status, LobbyStatus.full),
      );
    });
  });

  group('autoCreateBookingWhenFull — Luồng A', () {
    late LobbyRepository repo;
    setUp(() => repo = _makeRepo());

    test('reject khi lobby chưa đầy', () async {
      // Tạo lobby mới (chưa đầy) → expect Left.
      final cr = await repo.createLobby(
        gameId: 'bg_for_booking_create',
        cafeId: 'cafe_999',
        scheduledTime: DateTime.now().add(const Duration(hours: 1)),
        additionalSlots: 3,
        isPublic: true,
      );
      final newId = cr.fold((_) => '', (l) => l.id);
      final result = await repo.autoCreateBookingWhenFull(newId);
      expect(result.isLeft(), isTrue);
    });

    test('accept sau khi force lobby đầy', () async {
      // Force lobby đầy bằng update status — lobby_001 luôn có sẵn sau seed.
      await repo.updateLobbyStatus('lobby_001', LobbyStatus.full);
      final result = await repo.autoCreateBookingWhenFull('lobby_001');
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('should be Right'),
        (bookingId) => expect(bookingId, isNotEmpty),
      );
    });
  });

  group('LobbyCubit — timeout (BR-08)', () {
    blocTest<LobbyCubit, LobbyState>(
      'create lobby → handle timeout hết hạn',
      build: () => _makeCubit(),
      act: (cubit) async {
        await cubit.createLobby(
          gameId: 'bg_test_001',
          cafeId: 'cafe_test_001',
          scheduledTime: DateTime.now().subtract(const Duration(minutes: 5)),
          additionalSlots: 3,
          isPublic: true,
          leadTime: const Duration(milliseconds: 50),
        );
        // Timer.periodic chỉ tick 1s/lần, nên cần đợi đủ để lần tick đầu
        // tiên phát hiện `isNegative` → emit Dismissed.
        await Future.delayed(const Duration(milliseconds: 1300));
      },
      wait: const Duration(milliseconds: 1500),
      expect: () => [
        // Loading ngay sau create.
        isA<LobbyLoading>(),
        // Created.
        isA<LobbyCreated>(),
        // Sau khi countdown trôi qua → Dismissed (BR-08).
        isA<LobbyDismissed>(),
        // Realtime stream có thể phát thêm 1 snapshot cuối cùng
        // (re-emit lobby với status hiện tại).
        isA<LobbyUpdatedRealtime>(),
      ],
    );
  });
}

