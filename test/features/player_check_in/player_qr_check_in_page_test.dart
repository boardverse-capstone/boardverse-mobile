// Widget tests cho `PlayerQrCheckInPage` — trang check-in tại quán bằng
// QR (BR §21A.7).
//
// Tests tập trung vào UI components mà không cần mock cubit.

import 'package:flutter_test/flutter_test.dart';

import 'package:boardverse/features/player_check_in/presentation/pages/player_qr_check_in_page_args.dart';

void main() {
  const reservationId = 'res-123';
  const lobbyShareCode = 'ABCDEFGH';
  const cafeName = 'BoardVerse Cafe';
  const gameName = 'Catan';

  group('PlayerQrCheckInPageArgs', () {
    test('Tạo args với các tham số bắt buộc', () {
      const args = PlayerQrCheckInPageArgs(
        reservationId: reservationId,
        lobbyShareCode: lobbyShareCode,
        cafeName: cafeName,
        gameName: gameName,
      );

      expect(args.reservationId, reservationId);
      expect(args.lobbyShareCode, lobbyShareCode);
      expect(args.cafeName, cafeName);
      expect(args.gameName, gameName);
      expect(args.tableNumber, 1); // default
      expect(args.onCheckInSuccess, isNull);
    });

    test('Tạo args với các tham số tùy chọn', () {
      const args = PlayerQrCheckInPageArgs(
        reservationId: reservationId,
        lobbyShareCode: lobbyShareCode,
        cafeName: cafeName,
        gameName: gameName,
        tableNumber: 5,
      );

      expect(args.tableNumber, 5);
    });

    test('Callback được gán đúng khi cung cấp', () {
      var callbackCalled = false;
      final args = PlayerQrCheckInPageArgs(
        reservationId: reservationId,
        lobbyShareCode: lobbyShareCode,
        cafeName: cafeName,
        gameName: gameName,
        onCheckInSuccess: () => callbackCalled = true,
      );

      args.onCheckInSuccess?.call();
      expect(callbackCalled, isTrue);
    });
  });
}
