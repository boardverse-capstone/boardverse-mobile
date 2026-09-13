import 'package:boardverse/features/player_check_in/data/services/player_qr_token_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lobby_management/_fake_secure_storage.dart';

void main() {
  group('PlayerQrTokenCacheService', () {
    late FakeSecureStorage storage;
    late PlayerQrTokenCacheService service;

    setUp(() {
      storage = FakeSecureStorage();
      service = PlayerQrTokenCacheService(storage: storage);
    });

    const validToken = 'ABCDEFGHJKLMNPQR'; // 16-char, no 0/1/I/O
    const anotherValidToken = 'XYZABCDEFGHJKLMN';

    group('loadLastToken', () {
      test('trả về null khi storage rỗng', () async {
        final result = await service.loadLastToken();
        expect(result, isNull);
      });

      test('trả về null khi token trong storage là empty string', () async {
        // Write empty string directly (bypass saveLastToken validation).
        await storage.write(key: 'player_qr_last_token', value: '');
        final result = await service.loadLastToken();
        expect(result, isNull);
      });

      test('trả về token đã cache (round-trip)', () async {
        await service.saveLastToken(validToken);
        final result = await service.loadLastToken();
        expect(result, validToken);
      });

      test('uppercase token trong storage', () async {
        // Token lưu không uppercase (legacy) → service vẫn normalize.
        await storage.write(
          key: 'player_qr_last_token',
          value: validToken.toLowerCase(),
        );
        final result = await service.loadLastToken();
        expect(result, validToken);
      });

      test('trả về null nếu token trong storage có format sai', () async {
        // Storage có data rác từ version trước hoặc user write thẳng.
        await storage.write(
          key: 'player_qr_last_token',
          value: 'SHORT',
        );
        final result = await service.loadLastToken();
        expect(result, isNull);
      });

      test('trả về null nếu token có ký tự bị loại (0, 1, I, O)', () async {
        // Theo regex của backend, các ký tự 0/1/I/O bị loại trừ.
        await storage.write(
          key: 'player_qr_last_token',
          value: 'ABCDEFGHIJKLMNOP', // chứa I và O
        );
        final result = await service.loadLastToken();
        expect(result, isNull);
      });
    });

    group('saveLastToken', () {
      test('lưu token valid', () async {
        await service.saveLastToken(validToken);
        final stored = await storage.read(key: 'player_qr_last_token');
        expect(stored, validToken);
      });

      test('uppercase token trước khi lưu', () async {
        await service.saveLastToken(validToken.toLowerCase());
        final stored = await storage.read(key: 'player_qr_last_token');
        expect(stored, validToken);
      });

      test('không lưu token ngắn hơn 16 ký tự', () async {
        await service.saveLastToken('ABC123');
        final stored = await storage.read(key: 'player_qr_last_token');
        expect(stored, isNull);
      });

      test('không lưu token rỗng', () async {
        await service.saveLastToken('');
        final stored = await storage.read(key: 'player_qr_last_token');
        expect(stored, isNull);
      });

      test('không lưu token có ký tự ngoài alphabet (0, 1, I, O)', () async {
        await service.saveLastToken('0123456789ABCDEF');
        final stored = await storage.read(key: 'player_qr_last_token');
        expect(stored, isNull);
      });

      test('ghi đè token cũ', () async {
        await service.saveLastToken(validToken);
        await service.saveLastToken(anotherValidToken);
        final loaded = await service.loadLastToken();
        expect(loaded, anotherValidToken);
      });
    });

    group('clear', () {
      test('xoá token đã cache', () async {
        await service.saveLastToken(validToken);
        await service.clear();
        final loaded = await service.loadLastToken();
        expect(loaded, isNull);
      });

      test('không throw khi storage đã rỗng', () async {
        await service.clear();
        final loaded = await service.loadLastToken();
        expect(loaded, isNull);
      });
    });

    group('error handling', () {
      test('loadLastToken trả về null khi storage ném exception', () async {
        final brokenService = PlayerQrTokenCacheService(
          storage: _ThrowingStorage(),
        );
        final result = await brokenService.loadLastToken();
        expect(result, isNull);
      });

      test('saveLastToken không throw khi storage ném exception', () async {
        final brokenService = PlayerQrTokenCacheService(
          storage: _ThrowingStorage(),
        );
        // Should not throw.
        await brokenService.saveLastToken(validToken);
      });

      test('clear không throw khi storage ném exception', () async {
        final brokenService = PlayerQrTokenCacheService(
          storage: _ThrowingStorage(),
        );
        await brokenService.clear();
      });
    });
  });
}

/// Storage luôn throw exception để test error handling.
class _ThrowingStorage extends FakeSecureStorage {
  @override
  Future<String?> read({
    required String key,
    Object? iOptions,
    Object? aOptions,
    Object? lOptions,
    Object? webOptions,
    Object? mOptions,
    Object? wOptions,
  }) async {
    throw Exception('Storage read failed');
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    Object? iOptions,
    Object? aOptions,
    Object? lOptions,
    Object? webOptions,
    Object? mOptions,
    Object? wOptions,
  }) async {
    throw Exception('Storage write failed');
  }

  @override
  Future<void> delete({
    required String key,
    Object? iOptions,
    Object? aOptions,
    Object? lOptions,
    Object? webOptions,
    Object? mOptions,
    Object? wOptions,
  }) async {
    throw Exception('Storage delete failed');
  }
}
