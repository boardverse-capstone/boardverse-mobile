import 'package:flutter_test/flutter_test.dart';

import 'package:boardverse/features/lobby_management/data/models/lobby_model.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_entity.dart';

/// Tests cho `LobbyPlayer.readyAt` (BR-LOBBY-READY-01) + JSON mapping.
///
/// Đảm bảo:
/// - `readyAt: null` → chưa sẵn sàng.
/// - `readyAt: DateTime` → đã sẵn sàng.
/// - `isReady` được derive từ `readyAt != null` (getter).
/// - JSON `readyAt` không tồn tại → chưa sẵn sàng.
void main() {
  group('LobbyPlayer entity (BR-LOBBY-READY-01)', () {
    test('readyAt null → isReady false', () {
      final player = LobbyPlayer(
        id: '1',
        userId: 'u1',
        name: 'A',
        avatarUrl: '',
        isHost: false,
        joinedAt: DateTime(2026, 8, 10),
        readyAt: null,
      );
      expect(player.isReady, isFalse);
      expect(player.readyAt, isNull);
    });

    test('readyAt set → isReady true', () {
      final player = LobbyPlayer(
        id: '1',
        userId: 'u1',
        name: 'A',
        avatarUrl: '',
        isHost: false,
        joinedAt: DateTime(2026, 8, 10),
        readyAt: DateTime(2026, 8, 10, 19, 0),
      );
      expect(player.isReady, isTrue);
      expect(player.readyAt, isNotNull);
    });

    test('host cũng có thể ready (note: Host thường isReady = false)', () {
      final player = LobbyPlayer(
        id: '1',
        userId: 'u1',
        name: 'Host',
        avatarUrl: '',
        isHost: true,
        joinedAt: DateTime(2026, 8, 10),
        readyAt: DateTime(2026, 8, 10, 19, 0),
      );
      expect(player.isHost, isTrue);
      expect(player.isReady, isTrue);
    });

    test('Equatable props bao gồm readyAt', () {
      final now = DateTime(2026, 8, 10, 19, 0);
      final a = LobbyPlayer(
        id: '1',
        userId: 'u1',
        name: 'A',
        avatarUrl: '',
        isHost: false,
        joinedAt: now,
        readyAt: now,
      );
      final b = LobbyPlayer(
        id: '1',
        userId: 'u1',
        name: 'A',
        avatarUrl: '',
        isHost: false,
        joinedAt: now,
        readyAt: now,
      );
      expect(a, equals(b));
    });
  });

  group('LobbyPlayerModel.fromJson — readyAt mapping', () {
    test('JSON có readyAt → entity có readyAt', () {
      final json = {
        'id': '1',
        'userId': 'u1',
        'name': 'A',
        'avatarUrl': '',
        'isHost': false,
        'joinedAt': '2026-08-10T18:00:00.000Z',
        'readyAt': '2026-08-10T19:00:00.000Z',
      };
      final model = LobbyPlayerModel.fromJson(json);
      final entity = model.toEntity();
      expect(entity.readyAt, isNotNull);
      expect(entity.isReady, isTrue);
    });

    test('JSON không có readyAt → entity chưa ready', () {
      final json = {
        'id': '1',
        'userId': 'u1',
        'name': 'A',
        'avatarUrl': '',
        'isHost': false,
        'joinedAt': '2026-08-10T18:00:00.000Z',
      };
      final model = LobbyPlayerModel.fromJson(json);
      final entity = model.toEntity();
      expect(entity.readyAt, isNull);
      expect(entity.isReady, isFalse);
    });

    test('JSON có readyAt null → entity chưa ready', () {
      final json = {
        'id': '1',
        'userId': 'u1',
        'name': 'A',
        'avatarUrl': '',
        'isHost': false,
        'joinedAt': '2026-08-10T18:00:00.000Z',
        'readyAt': null,
      };
      final model = LobbyPlayerModel.fromJson(json);
      final entity = model.toEntity();
      expect(entity.readyAt, isNull);
      expect(entity.isReady, isFalse);
    });

    test('JSON có readyAt empty string → entity chưa ready', () {
      final json = {
        'id': '1',
        'userId': 'u1',
        'name': 'A',
        'avatarUrl': '',
        'isHost': false,
        'joinedAt': '2026-08-10T18:00:00.000Z',
        'readyAt': '',
      };
      final model = LobbyPlayerModel.fromJson(json);
      final entity = model.toEntity();
      expect(entity.readyAt, isNull);
      expect(entity.isReady, isFalse);
    });

    test('JSON cũ có isReady: true (no readyAt) → best-effort ready', () {
      final json = {
        'id': '1',
        'userId': 'u1',
        'name': 'A',
        'avatarUrl': '',
        'isHost': false,
        'joinedAt': '2026-08-10T18:00:00.000Z',
        'isReady': true, // schema cũ
      };
      final model = LobbyPlayerModel.fromJson(json);
      final entity = model.toEntity();
      expect(entity.readyAt, isNotNull);
      expect(entity.isReady, isTrue);
    });

    test('JSON cũ có isReady: false (no readyAt) → chưa ready', () {
      final json = {
        'id': '1',
        'userId': 'u1',
        'name': 'A',
        'avatarUrl': '',
        'isHost': false,
        'joinedAt': '2026-08-10T18:00:00.000Z',
        'isReady': false,
      };
      final model = LobbyPlayerModel.fromJson(json);
      final entity = model.toEntity();
      expect(entity.readyAt, isNull);
      expect(entity.isReady, isFalse);
    });

    test('JSON có readyAt invalid → entity chưa ready (graceful)', () {
      final json = {
        'id': '1',
        'userId': 'u1',
        'name': 'A',
        'avatarUrl': '',
        'isHost': false,
        'joinedAt': '2026-08-10T18:00:00.000Z',
        'readyAt': 'invalid-timestamp',
      };
      final model = LobbyPlayerModel.fromJson(json);
      final entity = model.toEntity();
      expect(entity.readyAt, isNull);
      expect(entity.isReady, isFalse);
    });
  });
}
