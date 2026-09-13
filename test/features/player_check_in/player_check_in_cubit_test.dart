import 'package:bloc_test/bloc_test.dart';
import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/features/player_check_in/data/services/player_qr_token_cache_service.dart';
import 'package:boardverse/features/player_check_in/domain/entities/player_scan_result_entity.dart';
import 'package:boardverse/features/player_check_in/domain/repositories/player_check_in_repository.dart';
import 'package:boardverse/features/player_check_in/presentation/cubit/player_check_in_cubit.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lobby_management/_fake_secure_storage.dart';

// ─── Test doubles ─────────────────────────────────────────────────────────

/// Hand-rolled mock của [PlayerCheckInRepository] — tránh phụ thuộc
/// mockito (chưa có trong pubspec).
class _FakePlayerCheckInRepository implements PlayerCheckInRepository {
  Either<Failure, PlayerScanResultEntity>? nextResult;
  final List<String> scanCalls = [];

  @override
  Future<Either<Failure, PlayerScanResultEntity>> scanToken({
    required String token,
  }) async {
    scanCalls.add(token);
    final result = nextResult;
    if (result == null) {
      throw StateError('No result stubbed. Set nextResult first.');
    }
    return result;
  }
}

/// Wraps FakeSecureStorage + tracks saveLastToken calls.
class _SpyCacheService extends PlayerQrTokenCacheService {
  final List<String> savedTokens = [];
  String? loadResult;

  _SpyCacheService({FakeSecureStorage? storage})
    : super(storage: storage ?? FakeSecureStorage()) {
    loadResult = null;
  }

  @override
  Future<String?> loadLastToken() async {
    final result = await super.loadLastToken();
    loadResult = result;
    return result;
  }

  @override
  Future<void> saveLastToken(String token) async {
    savedTokens.add(token);
    await super.saveLastToken(token);
  }
}

void main() {
  const validToken = 'ABCDEFGHJKLMNPQR'; // 16-char, loại 0/1/I/O
  const anotherValidToken = 'XYZABCDEFGHJKLMN';

  final tResult = PlayerScanResultEntity(
    activeSessionId: 'session-1',
    reservationId: 'res-1',
    cafeId: 'cafe-1',
    checkedInAt: DateTime(2026, 8, 22, 14, 30),
  );

  group('PlayerCheckInCubit.submitToken', () {
    late _FakePlayerCheckInRepository repository;
    late _SpyCacheService cacheService;

    setUp(() {
      repository = _FakePlayerCheckInRepository();
      cacheService = _SpyCacheService();
    });

    blocTest<PlayerCheckInCubit, PlayerCheckInState>(
      'emit Failure với message "Vui lòng nhập mã QR" khi token rỗng',
      build: () => PlayerCheckInCubit(
        repository: repository,
        cacheService: cacheService,
      ),
      act: (cubit) => cubit.submitToken(''),
      expect: () => [
        const PlayerCheckInFailure(
          message: 'Vui lòng nhập mã QR.',
          lastToken: '',
        ),
      ],
      verify: (_) {
        expect(repository.scanCalls, isEmpty);
        expect(cacheService.savedTokens, isEmpty);
      },
    );

    blocTest<PlayerCheckInCubit, PlayerCheckInState>(
      'emit Failure với message "Vui lòng nhập mã QR" khi token chỉ chứa spaces',
      build: () => PlayerCheckInCubit(
        repository: repository,
        cacheService: cacheService,
      ),
      act: (cubit) => cubit.submitToken('   '),
      expect: () => [
        const PlayerCheckInFailure(
          message: 'Vui lòng nhập mã QR.',
          lastToken: '   ',
        ),
      ],
    );

    blocTest<PlayerCheckInCubit, PlayerCheckInState>(
      'emit Failure khi token quá ngắn (5 chars)',
      build: () => PlayerCheckInCubit(
        repository: repository,
        cacheService: cacheService,
      ),
      act: (cubit) => cubit.submitToken('ABCDE'),
      expect: () => [
        const PlayerCheckInFailure(
          message:
              'Mã phải gồm đúng 16 ký tự in hoa (A–Z, 2–9), ví dụ: ABCDEFGHJKLMNPQR.',
          lastToken: 'ABCDE',
        ),
      ],
      verify: (_) {
        // Repo không bị gọi vì validation fail client-side.
        expect(repository.scanCalls, isEmpty);
      },
    );

    blocTest<PlayerCheckInCubit, PlayerCheckInState>(
      'emit Failure khi token có ký tự bị loại (0, 1, I, O)',
      build: () => PlayerCheckInCubit(
        repository: repository,
        cacheService: cacheService,
      ),
      act: (cubit) => cubit.submitToken('0123456789ABCDEF'), // chứa 0
      expect: () => [
        const PlayerCheckInFailure(
          message:
              'Mã phải gồm đúng 16 ký tự in hoa (A–Z, 2–9), ví dụ: ABCDEFGHJKLMNPQR.',
          lastToken: '0123456789ABCDEF',
        ),
      ],
      verify: (_) {
        expect(repository.scanCalls, isEmpty);
      },
    );

    blocTest<PlayerCheckInCubit, PlayerCheckInState>(
      'emit Failure khi token có chữ thường chứa ký tự bị loại (i, o)',
      build: () => PlayerCheckInCubit(
        repository: repository,
        cacheService: cacheService,
      ),
      act: (cubit) => cubit.submitToken('abcdefghijklmnop'), // chứa i, o
      expect: () => [
        const PlayerCheckInFailure(
          message:
              'Mã phải gồm đúng 16 ký tự in hoa (A–Z, 2–9), ví dụ: ABCDEFGHJKLMNPQR.',
          lastToken: 'ABCDEFGHIJKLMNOP',
        ),
      ],
    );

    blocTest<PlayerCheckInCubit, PlayerCheckInState>(
      'emit Submitting → Success khi token valid + repo trả Right',
      build: () {
        repository.nextResult = Right(tResult);
        return PlayerCheckInCubit(
          repository: repository,
          cacheService: cacheService,
        );
      },
      act: (cubit) => cubit.submitToken(validToken),
      expect: () => [
        const PlayerCheckInSubmitting(validToken),
        PlayerCheckInSuccess(result: tResult, token: validToken),
      ],
      verify: (_) {
        expect(repository.scanCalls, [validToken]);
        // Token phải được cache sau khi success.
        expect(cacheService.savedTokens, contains(validToken));
      },
    );

    blocTest<PlayerCheckInCubit, PlayerCheckInState>(
      'cache token UPPERCASE sau khi success (kể cả khi input là lowercase)',
      build: () {
        repository.nextResult = Right(tResult);
        return PlayerCheckInCubit(
          repository: repository,
          cacheService: cacheService,
        );
      },
      act: (cubit) => cubit.submitToken(validToken.toLowerCase()),
      expect: () => [
        const PlayerCheckInSubmitting(validToken),
        PlayerCheckInSuccess(result: tResult, token: validToken),
      ],
      verify: (_) {
        // Cache lưu uppercase normalized.
        expect(cacheService.savedTokens.first, validToken);
      },
    );

    blocTest<PlayerCheckInCubit, PlayerCheckInState>(
      'trim token trước khi submit',
      build: () {
        repository.nextResult = Right(tResult);
        return PlayerCheckInCubit(
          repository: repository,
          cacheService: cacheService,
        );
      },
      act: (cubit) => cubit.submitToken('  $validToken  '),
      expect: () => [
        const PlayerCheckInSubmitting(validToken),
        PlayerCheckInSuccess(result: tResult, token: validToken),
      ],
      verify: (_) {
        // Repo nhận token đã trim + uppercase.
        expect(repository.scanCalls, [validToken]);
      },
    );

    blocTest<PlayerCheckInCubit, PlayerCheckInState>(
      'emit Failure khi repo trả Left(ServerFailure) — không cache token',
      build: () {
        repository.nextResult = const Left(
          ServerFailure(message: 'Bạn không phải thành viên của quán.'),
        );
        return PlayerCheckInCubit(
          repository: repository,
          cacheService: cacheService,
        );
      },
      act: (cubit) => cubit.submitToken(validToken),
      expect: () => [
        const PlayerCheckInSubmitting(validToken),
        const PlayerCheckInFailure(
          message: 'Bạn không phải thành viên của quán.',
          lastToken: validToken,
        ),
      ],
      verify: (_) {
        // Token KHÔNG được cache khi fail.
        expect(cacheService.savedTokens, isEmpty);
      },
    );

    blocTest<PlayerCheckInCubit, PlayerCheckInState>(
      'emit Failure khi repo trả Left(BadRequestFailure) — giữ token để retry',
      build: () {
        repository.nextResult = const Left(
          BadRequestFailure(message: 'Token không hợp lệ.'),
        );
        return PlayerCheckInCubit(
          repository: repository,
          cacheService: cacheService,
        );
      },
      act: (cubit) => cubit.submitToken(validToken),
      expect: () => [
        const PlayerCheckInSubmitting(validToken),
        const PlayerCheckInFailure(
          message: 'Token không hợp lệ.',
          lastToken: validToken,
        ),
      ],
      verify: (_) {
        expect(cacheService.savedTokens, isEmpty);
      },
    );
  });

  group('PlayerCheckInCubit.loadCachedToken', () {
    test('trả về token đã cache', () async {
      final storage = FakeSecureStorage();
      await storage.write(key: 'player_qr_last_token', value: validToken);
      final cacheService = _SpyCacheService(storage: storage);
      final cubit = PlayerCheckInCubit(
        repository: _FakePlayerCheckInRepository(),
        cacheService: cacheService,
      );
      final result = await cubit.loadCachedToken();
      expect(result, validToken);
    });

    test('trả về null khi không có cache', () async {
      final cubit = PlayerCheckInCubit(
        repository: _FakePlayerCheckInRepository(),
        cacheService: _SpyCacheService(),
      );
      final result = await cubit.loadCachedToken();
      expect(result, isNull);
    });
  });

  group('PlayerCheckInCubit.reset', () {
    blocTest<PlayerCheckInCubit, PlayerCheckInState>(
      'emit Idle khi state hiện tại không phải Idle',
      build: () => PlayerCheckInCubit(
        repository: _FakePlayerCheckInRepository(),
        cacheService: _SpyCacheService(),
      ),
      seed: () => const PlayerCheckInFailure(
        message: 'Some error',
        lastToken: validToken,
      ),
      act: (cubit) => cubit.reset(),
      expect: () => [const PlayerCheckInIdle()],
    );

    blocTest<PlayerCheckInCubit, PlayerCheckInState>(
      'không emit gì khi state đã là Idle',
      build: () => PlayerCheckInCubit(
        repository: _FakePlayerCheckInRepository(),
        cacheService: _SpyCacheService(),
      ),
      seed: () => const PlayerCheckInIdle(),
      act: (cubit) => cubit.reset(),
      expect: () => <PlayerCheckInState>[],
    );
  });

  group('PlayerCheckInCubit integration with cache flow', () {
    test('cache token A → success → loadCachedToken trả về A', () async {
      final repository = _FakePlayerCheckInRepository();
      repository.nextResult = Right(tResult);
      final cacheService = _SpyCacheService();

      final cubit = PlayerCheckInCubit(
        repository: repository,
        cacheService: cacheService,
      );

      // 1. Lần đầu: cache rỗng.
      expect(await cubit.loadCachedToken(), isNull);

      // 2. Submit token A thành công.
      await cubit.submitToken(validToken);
      expect(cubit.state, isA<PlayerCheckInSuccess>());

      // 3. Cache được lưu.
      expect(cacheService.savedTokens, [validToken]);
      expect(await cubit.loadCachedToken(), validToken);
    });

    test('submitToken khác (B) sau khi đã cache A — success cache đè B (không phải A)',
      () async {
        final repository = _FakePlayerCheckInRepository();
        // Cả A và B đều trả Right(tResult).
        repository.nextResult = Right(tResult);
        final cacheService = _SpyCacheService();

        final cubit = PlayerCheckInCubit(
          repository: repository,
          cacheService: cacheService,
        );

        await cubit.submitToken(validToken);
        await cubit.submitToken(anotherValidToken);

        expect(cacheService.savedTokens, [validToken, anotherValidToken]);
        expect(await cubit.loadCachedToken(), anotherValidToken);
      },
    );
  });
}
