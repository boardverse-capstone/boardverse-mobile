// Regression tests cho ReservationRemoteDatasourceImpl.
//
// Bug: backend trả về HTTP 201 Created cho
//   POST /api/v1/reservations/confirm
// nhưng datasource cũ chỉ chấp nhận statusCode == 200, dẫn đến UI hiển thị
// "Failed to confirm reservation: 201" dù reservation đã được tạo thành
// công trên server. Các test này verify cả 200 và 201 đều được coi là thành
// công cho createQuote, confirmReservation và cancelReservation.

import 'dart:convert';
import 'dart:typed_data';

import 'package:boardverse/core/constants/api_endpoints.dart';
import 'package:boardverse/features/reservation/data/datasources/reservation_remote_datasource.dart';
import 'package:boardverse/features/reservation/data/models/reservation_quote_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake Dio adapter cho phép test ghi nhận request và trả response tuỳ ý
/// theo statusCode / body. Không phụ thuộc mockito / http_mock_adapter.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final Map<String, dynamic> body;

  RequestOptions? captured;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json; charset=utf-8'],
      },
    );
  }
}

ReservationRemoteDatasourceImpl _datasourceWith(_FakeAdapter adapter) {
  // `validateStatus: (_) => true` để nhận cả 4xx/5xx như response bình
  // thường — giống default của nhiều production codebase (Dio mặc định
  // chỉ chấp nhận 2xx, sẽ throw DioException với 500).
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.test',
    validateStatus: (_) => true,
  ))
    ..httpClientAdapter = adapter;
  return ReservationRemoteDatasourceImpl(dio: dio);
}

void main() {
  group('confirmReservation HTTP status handling', () {
    test('accepts 200 OK as success', () async {
      final adapter = _FakeAdapter(
        statusCode: 200,
        body: {
          'statusCode': 200,
          'message': 'ReservationConfirmed',
          'data': {
            'reservationId': 'res-1',
            'lobbyId': 'lob-1',
            'recruitmentDeadline': '2026-08-08T17:40:00Z',
            'requiresCafeApproval': false,
            'cafeApprovalDeadline': null,
            'heldBvc': 50,
          },
          'timestamp': '2026-08-08T10:00:00Z',
          'path': ApiEndpoints.reservationConfirm,
        },
      );
      final ds = _datasourceWith(adapter);

      final result = await ds.confirmReservation(ConfirmRequestModel(
        cafeId: 'cafe-1',
        gameId: 'game-1',
        playDate: DateTime.utc(2026, 8, 8),
        timeSlot: 'Evening',
        minPlayers: 2,
        maxPlayers: 4,
        expectedFinalDeposit: 50000,
        idempotencyKey: 'idem-200',
      ));

      expect(result.isRight(), isTrue);
      final confirm = result.getOrElse(() => throw StateError('expected right'));
      expect(confirm.reservationId, 'res-1');
      expect(confirm.lobbyId, 'lob-1');
      expect(confirm.heldBvc, 50);
      expect(adapter.captured?.method, 'POST');
      expect(adapter.captured?.path, ApiEndpoints.reservationConfirm);
    });

    test('accepts 201 Created as success (bug fix regression)', () async {
      // Đây là response thực tế từ server:
      //   {"statusCode":201,"message":"ReservationConfirmed","data":{...}}
      final adapter = _FakeAdapter(
        statusCode: 201,
        body: {
          'statusCode': 201,
          'message': 'ReservationConfirmed',
          'data': {
            'reservationId': 'b20b3243-041f-41f3-8540-e7c34a5769ee',
            'lobbyId': 'c9b1cc8f-f794-4f05-8c20-6a31d4de8efd',
            'recruitmentDeadline': '2026-08-08T17:40:00',
            'requiresCafeApproval': false,
            'cafeApprovalDeadline': null,
            'heldBvc': 50,
          },
          'timestamp': '2026-08-08T10:43:23.2403094Z',
          'path': '/api/v1/reservations/confirm',
        },
      );
      final ds = _datasourceWith(adapter);

      final result = await ds.confirmReservation(ConfirmRequestModel(
        cafeId: 'cafe-1',
        gameId: 'game-1',
        playDate: DateTime.utc(2026, 8, 8),
        timeSlot: 'Evening',
        minPlayers: 2,
        maxPlayers: 4,
        expectedFinalDeposit: 50000,
        idempotencyKey: 'idem-201',
      ));

      expect(
        result.isRight(),
        isTrue,
        reason: '201 Created phải được coi là confirm thành công. '
            'Trước fix, UI hiển thị "Failed to confirm reservation: 201".',
      );
      final confirm = result.getOrElse(() => throw StateError('expected right'));
      expect(confirm.reservationId, 'b20b3243-041f-41f3-8540-e7c34a5769ee');
      expect(confirm.lobbyId, 'c9b1cc8f-f794-4f05-8c20-6a31d4de8efd');
      expect(confirm.requiresCafeApproval, isFalse);
      expect(confirm.heldBvc, 50);
    });

    test('rejects 500 Internal Server Error with failure', () async {
      final adapter = _FakeAdapter(
        statusCode: 500,
        body: {
          'statusCode': 500,
          'message': 'boom',
          'data': null,
          'timestamp': '2026-08-08T10:00:00Z',
          'path': ApiEndpoints.reservationConfirm,
        },
      );
      final ds = _datasourceWith(adapter);

      final result = await ds.confirmReservation(ConfirmRequestModel(
        cafeId: 'cafe-1',
        gameId: 'game-1',
        playDate: DateTime.utc(2026, 8, 8),
        timeSlot: 'Evening',
        minPlayers: 2,
        maxPlayers: 4,
        expectedFinalDeposit: 50000,
        idempotencyKey: 'idem-500',
      ));

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f.message, contains('500')),
        (_) => fail('expected Left'),
      );
    });
  });

  group('createQuote HTTP status handling', () {
    test('accepts 201 Created as success', () async {
      final adapter = _FakeAdapter(
        statusCode: 201,
        body: {
          'statusCode': 201,
          'message': 'ReservationQuoteCreated',
          'data': {
            'reservationId': null,
            'cafeId': 'cafe-1',
            'gameId': 'game-1',
            'playDate': '2026-08-08',
            'timeSlot': 'Evening',
            'scheduledTime': '2026-08-08T18:00:00Z',
            'recruitmentDeadline': '2026-08-08T17:40:00Z',
            'minPlayers': 2,
            'maxPlayers': 4,
            'depositRatePerPerson': 5,
            'baseDeposit': 30,
            'riskMultiplier': 1.0,
            'minDepositApplied': 50000,
            'finalDeposit': 50000,
            'currentBalance': 50000,
            'missingAmount': 0,
            'bufferMinutes': 240,
            'bufferWarning': false,
            'requiresCafeApproval': false,
            'expiresAt': '2026-08-08T11:00:00Z',
            'warnings': [],
            'riskLevel': 'low',
          },
          'timestamp': '2026-08-08T10:00:00Z',
          'path': ApiEndpoints.reservationQuote,
        },
      );
      final ds = _datasourceWith(adapter);

      final result = await ds.createQuote(QuoteRequestModel(
        cafeId: 'cafe-1',
        gameId: 'game-1',
        playDate: DateTime.utc(2026, 8, 8),
        timeSlot: 'Evening',
        minPlayers: 2,
        maxPlayers: 4,
        idempotencyKey: 'idem-quote-201',
      ));

      expect(result.isRight(), isTrue,
          reason: '201 Created từ /quote phải được coi là thành công.');
      final quote = result.getOrElse(() => throw StateError('expected right'));
      expect(quote.cafeId, 'cafe-1');
      expect(quote.finalDeposit, 50000);
    });
  });
}
