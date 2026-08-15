// Regression tests cho `RealLobbyRemoteDatasource.acceptInvite`.
//
// Bug background: Backend `POST /api/v1/lobbies/invites/{inviteId}/accept`
// trả về `LobbyInviteResponseDto` (xem `lobby-invite.md`), KHÔNG phải
// `LobbyDto` đầy đủ. Code cũ gọi `LobbyModel.fromJson(_unwrap(res.data))`
// → `json['id'] as String` throw `TypeError: Null is not a subtype of
// String` (vì `LobbyInviteResponseDto` chỉ có `inviteId`/`lobbyId`, không
// có `id`). Lỗi được catch thành `ServerFailure("Lỗi không xác định: ...")`
// → UI hiển thị "Lỗi không xác định" dù backend đã accept thành công.
//
// Fix: parse response as `LobbyInviteModel.fromJson` → lấy `lobbyId` →
// gọi `GET /api/v1/lobbies/{lobbyId}` → return `LobbyEntity`.

import 'dart:convert';
import 'dart:typed_data';

import 'package:boardverse/core/constants/api_endpoints.dart';
import 'package:boardverse/features/lobby_management/data/datasources/remote/real_lobby_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Multi-call fake adapter — lưu call sequence + trả response tuỳ ý cho
/// mỗi request dựa trên (method, path) pattern. Cho phép test "POST accept
// → GET lobby detail" flow trong cùng 1 test.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({
    required this.acceptResponse,
    required this.lobbyResponse,
  });

  final Map<String, dynamic> acceptResponse;
  final Map<String, dynamic> lobbyResponse;

  final List<RequestOptions> calls = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);

    // Route response dựa trên method + path.
    final isAccept = options.method.toUpperCase() == 'POST' &&
        options.path.contains('/invites/') &&
        options.path.contains('/accept');
    final isGet = options.method.toUpperCase() == 'GET' &&
        options.path.contains(ApiEndpoints.lobbyDetail.split('{id}').first);

    final body = isAccept
        ? acceptResponse
        : isGet
            ? lobbyResponse
            : {'statusCode': 200, 'data': null};

    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json; charset=utf-8'],
      },
    );
  }
}

/// Adapter đơn giản luôn trả 500 — dùng cho test DioException handling.
class _ThrowingAdapter implements HttpClientAdapter {
  _ThrowingAdapter({required this.statusCode, required this.message});
  final int statusCode;
  final String message;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({'statusCode': statusCode, 'message': message}),
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json; charset=utf-8'],
      },
    );
  }
}

RealLobbyRemoteDatasource _dsWithAdapter(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.test',
    validateStatus: (_) => true,
  ))
    ..httpClientAdapter = adapter;
  return RealLobbyRemoteDatasource(dio: dio);
}

Map<String, dynamic> _envelope(Map<String, dynamic> data) => {
      'statusCode': 200,
      'message': 'Success',
      'data': data,
      'timestamp': '2026-08-08T10:00:00Z',
      'path': '/api/v1/lobbies/invites/inv-1/accept',
    };

void main() {
  group('acceptInvite parses LobbyInviteResponseDto', () {
    test(
        'trả về Right(LobbyEntity) khi accept 200 + GET lobby detail thành công',
        () async {
      // Response của POST /invites/{id}/accept (LobbyInviteResponseDto).
      final acceptResponse = _envelope({
        'inviteId': 'inv-1',
        'lobbyId': 'lob-1',
        'inviterId': 'host-1',
        'inviterUsername': 'host_main',
        'inviteeId': 'user-2',
        'inviteeUsername': 'minh_an',
        'status': 'Accepted',
        'createdAt': '2026-08-08T09:00:00Z',
        'expiresAt': '2026-08-09T09:00:00Z',
        'respondedAt': '2026-08-08T10:00:00Z',
        'lobbyName': 'Catan 4 người tối CN',
        'gameName': 'Catan',
        'cafeName': 'Board Game Cafe',
      });

      // Response của GET /lobbies/{lobbyId} (LobbyDto đầy đủ).
      final lobbyResponse = _envelope({
        'id': 'lob-1',
        'gameId': 'game-1',
        'gameName': 'Catan',
        'cafeId': 'cafe-1',
        'cafeName': 'Board Game Cafe',
        'hostId': 'host-1',
        'hostName': 'host_main',
        'scheduledTime': '2026-08-10T19:00:00.000Z',
        'currentPlayers': 3,
        'maxPlayers': 4,
        'minPlayers': 2,
        'inviteCode': 'ABCD1234',
        'isPrivate': false,
        'status': 'Open',
        'members': [],
        'createdAt': '2026-08-08T08:00:00.000Z',
        'timeoutAt': '2026-08-10T18:00:00.000Z',
      });

      final adapter = _FakeAdapter(
        acceptResponse: acceptResponse,
        lobbyResponse: lobbyResponse,
      );
      final ds = _dsWithAdapter(adapter);

      final result = await ds.acceptInvite('inv-1');

      expect(result.isRight(), isTrue,
          reason: 'acceptInvite phải trả Right khi parse thành công');
      result.fold(
        (failure) => fail('Không mong đợi failure: ${failure.message}'),
        (lobby) {
          expect(lobby.id, 'lob-1');
          expect(lobby.gameName, 'Catan');
          expect(lobby.cafeName, 'Board Game Cafe');
          expect(lobby.currentPlayers, 3);
          expect(lobby.maxPlayers, 4);
        },
      );

      // Verify đã gọi đúng 2 endpoints: POST accept + GET lobby detail.
      expect(adapter.calls.length, 2);
      expect(adapter.calls[0].method.toUpperCase(), 'POST');
      expect(adapter.calls[1].method.toUpperCase(), 'GET');
    });

    test(
        'trả về Left(Failure) khi POST accept trả envelope thiếu lobbyId',
        () async {
      // Response lỗi: thiếu `lobbyId` → fix hiện tại sẽ trả Left với
      // message "thiếu lobbyId" thay vì crash với TypeError.
      final acceptResponse = _envelope({
        'inviteId': 'inv-2',
        // 'lobbyId' bị thiếu → null
        'status': 'Accepted',
        'createdAt': '2026-08-08T09:00:00Z',
        'expiresAt': '2026-08-09T09:00:00Z',
      });

      final lobbyResponse = _envelope({'id': 'lob-2'});

      final adapter = _FakeAdapter(
        acceptResponse: acceptResponse,
        lobbyResponse: lobbyResponse,
      );
      final ds = _dsWithAdapter(adapter);

      final result = await ds.acceptInvite('inv-2');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure.message, contains('lobbyId'));
        },
        (_) => fail('Không mong đợi Right khi thiếu lobbyId'),
      );
    });

    test(
        'trả về Left(Failure) khi DioException (vd: 500) — không crash',
        () async {
      final adapter = _ThrowingAdapter(
        statusCode: 500,
        message: 'Internal Server Error',
      );
      final ds = _dsWithAdapter(adapter);

      final result = await ds.acceptInvite('inv-3');

      expect(result.isLeft(), isTrue);
    });
  });
}