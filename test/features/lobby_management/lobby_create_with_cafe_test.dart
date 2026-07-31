// Unit tests cho luồng tạo lobby có gắn cafeId.
//
// Mục tiêu: đảm bảo payload POST /api/v1/lobbies bao gồm `cafeId` khi có
// giá trị, bỏ qua khi rỗng, đồng thời các trường chuẩn (gameTemplateId,
// scheduledStartTime, maxMembers, seatCount, isPrivate, ...) được gửi đúng.

import 'package:boardverse_mobile/core/error/failures.dart';
import 'package:boardverse_mobile/features/lobby_management/data/datasources/remote/real_lobby_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Interceptor capture request payload (data) trước khi Dio gửi đi, và
/// resolve với response giả lập.
class _StubInterceptor extends Interceptor {
  Map<String, dynamic>? capturedBody;
  String? capturedMethod;
  String? capturedPath;
  int statusCode = 201;
    Map<String, dynamic>? responseBody = const {
      'statusCode': 201,
      'message': 'Created',
      'data': {
        'id': 'lobby_test_001',
        'hostId': 'user_host',
        'gameId': 'game_123',
        'gameName': 'Catan',
        'cafeId': 'cafe_abc',
        'cafeName': 'BoardVerse Cafe',
        'maxMembers': 4,
        'minPlayers': 2,
        'currentMembers': 1,
        'scheduledStartTime': '2026-08-01T10:00:00.000Z',
        'createdAt': '2026-07-30T08:00:00.000Z',
        'timeoutAt': '2026-07-31T20:00:00.000Z',
        'visibility': 'public',
        'status': 'Open',
      },
    };

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    capturedMethod = options.method;
    capturedPath = options.path;
    final dynamic raw = options.data;
    if (raw is Map<String, dynamic>) {
      capturedBody = raw;
    } else if (raw is Map) {
      capturedBody = Map<String, dynamic>.from(raw);
    } else {
      capturedBody = null;
    }
    handler.resolve(
      Response<dynamic>(
        requestOptions: options,
        statusCode: statusCode,
        data: responseBody,
      ),
    );
  }
}

/// Interceptor reject request bằng DioException (giả lập status code lỗi
/// từ backend) — đúng cách `_mapDioError` được trigger trong datasource.
class _RejectInterceptor extends Interceptor {
  final int statusCode;
  final Map<String, dynamic> responseBody;

  _RejectInterceptor({required this.statusCode, required this.responseBody});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    handler.reject(
      DioException(
        requestOptions: options,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: statusCode,
          data: responseBody,
        ),
        type: DioExceptionType.badResponse,
      ),
      true,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RealLobbyRemoteDatasource.createLobby', () {
    late _StubInterceptor interceptor;
    late RealLobbyRemoteDatasource datasource;
    late Dio dio;

    setUp(() {
      interceptor = _StubInterceptor();
      dio = Dio(BaseOptions(
        baseUrl: 'https://api.boardverse.test',
        contentType: 'application/json',
      ))
        ..interceptors.add(interceptor);
      datasource = RealLobbyRemoteDatasource(dio: dio);
    });

    test(
      'sends cafeId, isPrivate=false, seatCount khi tạo lobby với cafe',
      () async {
        final scheduled = DateTime.utc(2026, 8, 1, 10, 0, 0);

        final result = await datasource.createLobby(
          gameId: 'game_123',
          cafeId: 'cafe_abc',
          scheduledTime: scheduled,
          additionalSlots: 3, // maxMembers = 4
          isPublic: true,
          searchRadiusKm: 5,
          minimumKarma: 0,
          leadTime: const Duration(minutes: 30),
        );

        result.fold(
          (failure) => fail('Expected Right, got Left: ${failure.message}'),
          (_) {},
        );

        expect(interceptor.capturedMethod, 'POST');
        expect(interceptor.capturedPath, contains('/api/v1/lobbies'));
        final body = interceptor.capturedBody;
        expect(body, isNotNull);
        expect(body!['gameTemplateId'], 'game_123');
        expect(body['cafeId'], 'cafe_abc');
        expect(body['maxMembers'], 4); // additionalSlots(3) + 1
        expect(body['seatCount'], 4);
        expect(body['isPrivate'], false);
        expect(body['cancellationLeadTimeMinutes'], 30);
        expect(body['scheduledStartTime'], scheduled.toIso8601String());
      },
    );

    test('isPrivate=true khi lobby công khai = false', () async {
      final scheduled = DateTime.utc(2026, 8, 1, 10, 0, 0);

      final result = await datasource.createLobby(
        gameId: 'game_123',
        cafeId: 'cafe_abc',
        scheduledTime: scheduled,
        additionalSlots: 1,
        isPublic: false,
      );

      expect(result.isRight(), isTrue);
      expect(interceptor.capturedBody!['isPrivate'], true);
    });

    test('bỏ qua cafeId khi cafeId rỗng (lobby không gắn quán)', () async {
      final result = await datasource.createLobby(
        gameId: 'game_123',
        cafeId: '',
        scheduledTime: DateTime.utc(2026, 8, 1, 10, 0, 0),
        additionalSlots: 2,
        isPublic: true,
      );

      expect(result.isRight(), isTrue);
      expect(
        interceptor.capturedBody!.containsKey('cafeId'),
        isFalse,
        reason: 'cafeId rỗng phải được bỏ khỏi payload',
      );
    });

    test('fallback cancellationLeadTimeMinutes = 30 khi không truyền leadTime',
        () async {
      await datasource.createLobby(
        gameId: 'game_123',
        cafeId: 'cafe_abc',
        scheduledTime: DateTime.utc(2026, 8, 1, 10, 0, 0),
        additionalSlots: 1,
        isPublic: true,
      );

      expect(interceptor.capturedBody!['cancellationLeadTimeMinutes'], 30);
    });

    test('parse lobby entity từ response bao gồm cafeId, cafeName', () async {
      final result = await datasource.createLobby(
        gameId: 'game_123',
        cafeId: 'cafe_abc',
        scheduledTime: DateTime.utc(2026, 8, 1, 10, 0, 0),
        additionalSlots: 3,
        isPublic: true,
      );

      await result.fold(
        (failure) async => fail('Expected Right: ${failure.message}'),
        (lobby) async {
          expect(lobby.id, 'lobby_test_001');
          expect(lobby.cafeId, 'cafe_abc');
          expect(lobby.cafeName, 'BoardVerse Cafe');
          expect(lobby.maxPlayers, 4);
          expect(lobby.isPublic, isTrue);
        },
      );
    });

    test('trả Failure khi Dio trả 400 với message từ backend', () async {
      // Stub interceptor riêng để reject (throw DioException) với status 400
      // — đúng cách `_mapDioError` được gọi trong datasource.
      final rejectInterceptor = _RejectInterceptor(
        statusCode: 400,
        responseBody: const {
          'statusCode': 400,
          'message': 'Invalid maxMembers',
          'data': null,
        },
      );
      final failingDio = Dio(BaseOptions(baseUrl: 'https://api.boardverse.test'))
        ..interceptors.add(rejectInterceptor);
      final failingDs = RealLobbyRemoteDatasource(dio: failingDio);

      final result = await failingDs.createLobby(
        gameId: 'game_123',
        cafeId: 'cafe_abc',
        scheduledTime: DateTime.utc(2026, 8, 1, 10, 0, 0),
        additionalSlots: 1,
        isPublic: true,
      );

      await result.fold(
        (failure) async {
          expect(failure, isA<ServerFailure>());
          expect((failure as ServerFailure).statusCode, 400);
          expect(failure.message, contains('Invalid maxMembers'));
        },
        (_) async => fail('Expected Left'),
      );
    });
  });
}
