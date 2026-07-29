import 'package:boardverse_mobile/features/friend_management/data/datasources/remote/_api_guard_mixin.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests cho [ApiGuardMixin.unwrapEnvelope] — verify unwrap envelope response
/// của backend (format `{ statusCode, message, data, ... }`).
class _TestApiGuardMixin extends ApiGuardMixin {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ApiGuardMixin.unwrapEnvelope', () {
    late ApiGuardMixin mixin;

    setUp(() {
      mixin = _TestApiGuardMixin();
    });

    test('unwraps envelope: trả inner `data` object', () {
      final envelope = {
        'statusCode': 200,
        'message': 'OK',
        'data': {
          'userId': 'u1',
          'username': 'alice',
        },
        'timestamp': '2026-07-29T00:00:00Z',
        'path': '/api/v1/friends/u1/profile',
      };

      final result = mixin.unwrapEnvelope(envelope);

      expect(result, {'userId': 'u1', 'username': 'alice'});
    });

    test('fallback về nguyên body khi data không phải Map', () {
      // Một số endpoint có thể trả `data: null` hoặc `data: []` (list).
      // Để tránh mất thông tin diagnostic, trả nguyên body.
      final envelope = {
        'statusCode': 200,
        'message': 'OK',
        'data': null,
      };

      final result = mixin.unwrapEnvelope(envelope);

      expect(result, envelope);
    });

    test('fallback về nguyên body khi data là List (không phải Map)', () {
      final envelope = {
        'statusCode': 200,
        'message': 'OK',
        'data': [
          {'userId': 'u1'},
        ],
      };

      final result = mixin.unwrapEnvelope(envelope);

      expect(result, envelope);
    });

    test('trả về {} khi input null', () {
      final result = mixin.unwrapEnvelope(null);
      expect(result, <String, dynamic>{});
    });

    test('trả về nguyên body khi không có field `data` (flat response)', () {
      // Một số endpoint có thể trả flat (không envelope) — vd error 400.
      final flat = {'userId': 'u1', 'username': 'alice'};
      final result = mixin.unwrapEnvelope(flat);
      expect(result, flat);
    });
  });
}
