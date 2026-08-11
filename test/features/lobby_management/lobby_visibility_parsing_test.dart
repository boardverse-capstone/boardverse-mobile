import 'package:flutter_test/flutter_test.dart';
import 'package:boardverse_mobile/features/lobby_management/data/models/lobby_model.dart';

/// Verify `LobbyModel.fromJson` correctly handles `isPrivate` field from
/// the backend reservation/lobby DTO.
///
/// Bug background: Backend uses `isPrivate: bool` (not `isPublic`). When
/// the host creates a public lobby (isPrivate: false), the lobby should
/// display as "Công khai" on the page. This test guards against regression.
void main() {
  Map<String, dynamic> baseJson() => {
        'id': 'lobby-1',
        'gameId': 'catan-id',
        'gameName': 'Catan',
        'cafeId': 'cafe-1',
        'cafeName': 'Cafe Test',
        'hostId': 'host-1',
        'hostName': 'Host',
        'scheduledTime': '2026-08-10T18:00:00.000Z',
        'currentPlayers': 1,
        'maxPlayers': 4,
        'minPlayers': 2,
        'inviteCode': 'ABC123',
        'status': 'Open',
        'members': [],
        'createdAt': '2026-08-08T10:00:00.000Z',
        'timeoutAt': '2026-08-10T17:00:00.000Z',
      };

  test('isPrivate: false (public) → isPublic: true', () {
    final json = baseJson()..['isPrivate'] = false;
    final model = LobbyModel.fromJson(json);
    expect(model.isPublic, isTrue,
        reason: 'Host set isPrivate: false → expect public lobby');
  });

  test('isPrivate: true (private) → isPublic: false', () {
    final json = baseJson()..['isPrivate'] = true;
    final model = LobbyModel.fromJson(json);
    expect(model.isPublic, isFalse,
        reason: 'Host set isPrivate: true → expect private lobby');
  });

  test('isPublic: true → isPublic: true (camelCase fallback)', () {
    final json = baseJson()..['isPublic'] = true;
    final model = LobbyModel.fromJson(json);
    expect(model.isPublic, isTrue);
  });

  test('isPublic: false → isPublic: false (camelCase fallback)', () {
    final json = baseJson()..['isPublic'] = false;
    final model = LobbyModel.fromJson(json);
    expect(model.isPublic, isFalse);
  });

  test('isPrivate ưu tiên hơn isPublic nếu cả 2 đều có', () {
    final json = baseJson()
      ..['isPrivate'] = false
      ..['isPublic'] = true;
    final model = LobbyModel.fromJson(json);
    expect(model.isPublic, isTrue);
  });

  test('visibility: "public" string → isPublic: true', () {
    final json = baseJson()..['visibility'] = 'public';
    final model = LobbyModel.fromJson(json);
    expect(model.isPublic, isTrue);
  });

  test('visibility: "private" string → isPublic: false', () {
    final json = baseJson()..['visibility'] = 'private';
    final model = LobbyModel.fromJson(json);
    expect(model.isPublic, isFalse);
  });

  test('không có field nào → isPublic: true (mặc định an toàn)', () {
    final json = baseJson();
    final model = LobbyModel.fromJson(json);
    expect(model.isPublic, isTrue,
        reason: 'Default = public để tránh ẩn lobby ngoài ý muốn');
  });

  // ════════════════════════════════════════════════════════════════════
  // parseVisibility() — test trực tiếp helper public dùng bởi
  // `_summaryFromJson` (search/discoverable) + `LobbyPersistenceService`
  // (cache local). Đây là nơi bug "public lobby hiển thị private" từng
  // xảy ra vì code cũ chỉ đọc `isPublic` (mặc định true) thay vì ưu
  // tiên `isPrivate` (BE mới).
  // ════════════════════════════════════════════════════════════════════

  group('LobbyModel.parseVisibility (public helper)', () {
    test('isPrivate: false → true (public)', () {
      expect(LobbyModel.parseVisibility(isPrivate: false), isTrue);
    });

    test('isPrivate: true → false (private)', () {
      expect(LobbyModel.parseVisibility(isPrivate: true), isFalse);
    });

    test('isPublic: true → true', () {
      expect(LobbyModel.parseVisibility(isPublic: true), isTrue);
    });

    test('isPublic: false → false', () {
      expect(LobbyModel.parseVisibility(isPublic: false), isFalse);
    });

    test('visibility: "public" → true', () {
      expect(LobbyModel.parseVisibility(visibility: 'public'), isTrue);
    });

    test('visibility: "private" → false', () {
      expect(LobbyModel.parseVisibility(visibility: 'private'), isFalse);
    });

    test('isPrivate ưu tiên hơn isPublic (kể cả khi conflict)', () {
      // BE có thể trả cả 2 — `isPrivate: false` (BE mới) phải thắng
      // `isPublic: false` (schema cũ) vì đó là field chính xác hơn.
      expect(
        LobbyModel.parseVisibility(isPublic: false, isPrivate: false),
        isTrue,
        reason: 'isPrivate: false = public, bất chấp isPublic: false',
      );
      expect(
        LobbyModel.parseVisibility(isPublic: true, isPrivate: true),
        isFalse,
        reason: 'isPrivate: true = private, bất chấp isPublic: true',
      );
    });

    test('không truyền gì → true (mặc định an toàn — public)', () {
      expect(LobbyModel.parseVisibility(), isTrue);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // Regression test: bug gốc là `_summaryFromJson` chỉ đọc `isPublic`
  // (mặc định true) → lobby PUBLIC (isPrivate: false) bị mobile hiển
  // thị nhầm thành private trong tab search/discoverable. Test này
  // giữ để đảm bảo bug không tái xuất khi refactor.
  // ════════════════════════════════════════════════════════════════════

  group('Regression: parseVisibility từ summary-style JSON', () {
    test('JSON chỉ có isPrivate: false → public', () {
      // Mô phỏng response từ `/search` / `/discoverable` mà BE chỉ
      // gửi `isPrivate` (không gửi `isPublic`).
      final isPublic = LobbyModel.parseVisibility(
        isPublic: null,
        isPrivate: false,
      );
      expect(isPublic, isTrue,
          reason: 'Public lobby không được hiển thị là private');
    });

    test('JSON chỉ có isPrivate: true → private', () {
      final isPublic = LobbyModel.parseVisibility(isPrivate: true);
      expect(isPublic, isFalse);
    });

    test('JSON có isPublic: false nhưng isPrivate: false → public (isPrivate thắng)',
        () {
      final isPublic = LobbyModel.parseVisibility(
        isPublic: false,
        isPrivate: false,
      );
      expect(isPublic, isTrue);
    });
  });
}
