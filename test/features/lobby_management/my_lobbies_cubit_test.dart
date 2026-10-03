// Unit tests cho MyLobbiesCubit — verify 2 filter gửi tới backend:
//   1. Active filter (?statuses=...&statusFilter=TimeoutFailed)
//   2. History filter (?statuses=...&statusFilter=HostCancelled)
//
// Bug background BR-NEW-MY-LOBBY-TIMEOUT (2026-10-02): trước đây filter
// chỉ chứa 6 status active, bỏ qua TimeoutFailed=7. Lobby đã đặt chỗ
// nhưng không check-in kịp không hiển thị trong tab "Của tôi".
//
// BR-NEW-MY-LOBBY-FILTER-FIX (2026-10-02): `statuses` bind là List<int>
// trong whitelist swagger, TimeoutFailed+HostCancelled phải đi qua
// `statusFilter` (string CSV enum names).
//
// BR-NEW-MY-LOBBY-HISTORY (2026-10-02): bổ sung tab "Đã kết thúc" với
// filter thứ 2 chứa 5 status terminal. Cubit chạy 2 API song song qua
// Future.wait — order of invocation (active trước, history sau) là
// deterministic vì 2 call được invoke synchronously khi build list.

import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_entity.dart';
import 'package:boardverse/features/lobby_management/domain/repositories/lobby_repository.dart';
import 'package:boardverse/features/lobby_management/presentation/cubit/my_lobbies_cubit.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLobbyRepository extends Mock implements LobbyRepository {}

void main() {
  group('MyLobbiesCubit — BR-NEW-MY-LOBBY-TIMEOUT + FILTER-FIX + HISTORY',
      () {
    late _MockLobbyRepository repo;

    setUp(() {
      repo = _MockLobbyRepository();
      // Stub getMyLobbies để trả list rỗng — test này chỉ verify filter.
      when(() => repo.getMyLobbies(
            statuses: any(named: 'statuses'),
            statusFilter: any(named: 'statusFilter'),
          )).thenAnswer((_) async => const Right<Failure, List<LobbyEntity>>([]));
    });

    // ─── ACTIVE FILTER ──────────────────────────────────────────────

    test('active filter: statuses=[4,16,1,0,6,14] statusFilter=TimeoutFailed',
        () async {
      final cubit = MyLobbiesCubit(repository: repo);
      await cubit.load(null);
      await cubit.close();

      verify(() => repo.getMyLobbies(
            statuses: <int>[4, 16, 1, 0, 6, 14],
            statusFilter: 'TimeoutFailed',
          )).called(1);
    });

    test('active statuses (int) KHÔNG chứa int=7 (TimeoutFailed bị loại cố ý)',
        () async {
      final cubit = MyLobbiesCubit(repository: repo);
      await cubit.load(null);
      await cubit.close();

      final captured = verify(
        () => repo.getMyLobbies(
          statuses: captureAny(named: 'statuses'),
          statusFilter: 'TimeoutFailed',
        ),
      ).captured.single as List<int>;

      expect(
        captured,
        isNot(contains(7)),
        reason: 'int=7 (TimeoutFailed) bị swagger whitelist loại cố ý. '
            'Gửi int 7 → BE 400 "Giá trị status không hợp lệ: 7". '
            'TimeoutFailed phải đi qua statusFilter.',
      );
    });

    test('active statuses (int) KHÔNG chứa int=8 (HostCancelled thuộc history)',
        () async {
      final cubit = MyLobbiesCubit(repository: repo);
      await cubit.load(null);
      await cubit.close();

      final captured = verify(
        () => repo.getMyLobbies(
          statuses: captureAny(named: 'statuses'),
          statusFilter: 'TimeoutFailed',
        ),
      ).captured.single as List<int>;

      expect(
        captured,
        isNot(contains(8)),
        reason: 'int=8 (HostCancelled) cũng bị loại khỏi int whitelist. '
            'Status này thuộc history (terminal) — đi qua history '
            'statusFilter.',
      );
    });

    test('active statuses (int) chứa whitelist int cho 6 status active',
        () async {
      final cubit = MyLobbiesCubit(repository: repo);
      await cubit.load(null);
      await cubit.close();

      final captured = verify(
        () => repo.getMyLobbies(
          statuses: captureAny(named: 'statuses'),
          statusFilter: 'TimeoutFailed',
        ),
      ).captured.single as List<int>;

      // Per swagger whitelist cho /api/v1/lobbies/my:
      // Open=0, Full=1, InProgress=4, RatingOpen=6, Viable=14,
      // WaitingCheckIn=16.
      for (final s in [0, 1, 4, 6, 14, 16]) {
        expect(captured, contains(s),
            reason: 'status active $s phải có trong filter int');
      }
    });

    // ─── HISTORY FILTER ─────────────────────────────────────────────

    test('history filter: statuses=[5,12,13,15] statusFilter=HostCancelled',
        () async {
      final cubit = MyLobbiesCubit(repository: repo);
      await cubit.load(null);
      await cubit.close();

      verify(() => repo.getMyLobbies(
            statuses: <int>[5, 12, 13, 15],
            statusFilter: 'HostCancelled',
          )).called(1);
    });

    test('history statuses (int) chứa whitelist int cho 4 status terminal',
        () async {
      final cubit = MyLobbiesCubit(repository: repo);
      await cubit.load(null);
      await cubit.close();

      final captured = verify(
        () => repo.getMyLobbies(
          statuses: captureAny(named: 'statuses'),
          statusFilter: 'HostCancelled',
        ),
      ).captured.single as List<int>;

      // Per swagger whitelist + BR-NEW-MY-LOBBY-HISTORY:
      // Closed=5, RejectedByCafe=12, ExpiredByCafe=13, Dissolved=15.
      for (final s in [5, 12, 13, 15]) {
        expect(captured, contains(s),
            reason: 'status terminal $s phải có trong history filter');
      }
    });

    test('history statuses (int) KHÔNG chứa int=7 (TimeoutFailed là active)',
        () async {
      final cubit = MyLobbiesCubit(repository: repo);
      await cubit.load(null);
      await cubit.close();

      final captured = verify(
        () => repo.getMyLobbies(
          statuses: captureAny(named: 'statuses'),
          statusFilter: 'HostCancelled',
        ),
      ).captured.single as List<int>;

      expect(
        captured,
        isNot(contains(7)),
        reason: 'TimeoutFailed=7 không nằm trong history — đã có active '
            'filter mượn. Tránh trùng lặp ở UI.',
      );
    });

    // ─── CROSS-CUTTING ──────────────────────────────────────────────

    test('BE bind statuses là List<int> — gửi List<String> sẽ fail '
        'ModelState', () async {
      final cubit = MyLobbiesCubit(repository: repo);
      await cubit.load(null);
      await cubit.close();

      // Verify cả 2 calls với statuses là List<int>
      final activeCaptured = verify(
        () => repo.getMyLobbies(
          statuses: captureAny(named: 'statuses'),
          statusFilter: 'TimeoutFailed',
        ),
      ).captured.single as List<int>;

      final historyCaptured = verify(
        () => repo.getMyLobbies(
          statuses: captureAny(named: 'statuses'),
          statusFilter: 'HostCancelled',
        ),
      ).captured.single as List<int>;

      // BR-NEW-MY-LOBBY-FILTER-FIX (2026-10-02): BE reject string
      // 'InProgress' → "The value 'InProgress' is not valid.". Phải
      // truyền int. Mọi entry phải là int — check cả active + history.
      for (final s in activeCaptured) {
        expect(s, isA<int>(),
            reason: 'Mọi entry active phải là int — BE bind List<int>, '
                'gửi string → ModelState 400.');
      }
      for (final s in historyCaptured) {
        expect(s, isA<int>(),
            reason: 'Mọi entry history phải là int — BE bind List<int>.');
      }
    });

    test('2 API calls được thực hiện song song (Future.wait)', () async {
      // Verify cubit thực sự gọi 2 lần — không phải lazy load.
      final cubit = MyLobbiesCubit(repository: repo);
      await cubit.load(null);
      await cubit.close();

      verify(() => repo.getMyLobbies(
            statuses: any(named: 'statuses'),
            statusFilter: any(named: 'statusFilter'),
          )).called(2);
    });
  });
}