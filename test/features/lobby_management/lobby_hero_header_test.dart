// Widget tests cho `LobbyHeroHeader` — đảm bảo các icon ở góc trên-phải
// hero header hoạt động đúng theo thiết kế **bidirectional linking**
// (Phase 4 2026-10-02):
//
//   1. Icon "Xem chi tiết phòng" (info) — render mọi lúc, KHÔNG bị thay
//      thành QR code khi lobby ready (user feedback 2026-10-02: info là
//      nút duy nhất để player mở bảng tổng quan).
//   2. Icon "Xem lịch hẹn chi tiết" (booking/calendar) — chỉ render khi
//      parent truyền `onShowReservation` (= lobby có `bookingId` = ID
//      reservation — xem BR-XXI-B.1).
//
// **Regression:** trước đây booking icon check `lobby.reservationId !=
// null` nhưng field này vestigial (luôn null vì backend `LobbyResponseDto`
// chỉ trả `bookingId`) → icon không bao giờ hiện → user không có đường
// liên kết từ lobby → reservation detail page. Test này đảm bảo fix
// được giữ nguyên khi refactor.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardverse/features/lobby_management/domain/entities/lobby_entity.dart';
import 'package:boardverse/features/lobby_management/presentation/widgets/lobby_hero_header.dart';

void main() {
  Widget wrap({
    required LobbyEntity lobby,
    VoidCallback? onShowReservation,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: LobbyHeroHeader(
          lobby: lobby,
          theme: ThemeData.light(),
          onShowDetails: () {},
          onShareInviteCode: () {},
          onShowReservation: onShowReservation,
        ),
      ),
    );
  }

  /// Build lobby với `bookingId` (= reservation ID sau BR-XXI-B.1) —
  /// dùng cho test có liên kết reservation.
  LobbyEntity buildLobbyWithBooking({String? bookingId}) {
    return LobbyEntity(
      id: 'lobby-1',
      gameId: 'g-1',
      gameName: 'Catan',
      cafeId: 'c-1',
      cafeName: 'BoardVerse Cafe',
      hostId: 'h-1',
      hostName: 'Host A',
      scheduledTime: DateTime(2026, 10, 2, 19, 0),
      currentPlayers: 1,
      maxPlayers: 4,
      minPlayers: 2,
      isPublic: true,
      status: LobbyStatus.viable,
      players: const [],
      createdAt: DateTime(2026, 10, 1),
      timeoutAt: DateTime(2026, 10, 2, 17, 0),
      inviteCode: 'K7H3NP9X',
      // bookingId từ backend LobbyResponseDto (BR-XXI-B.1) = reservation ID.
      bookingId: bookingId,
    );
  }

  group('LobbyHeroHeader — bidirectional linking (Phase 4 2026-10-02)', () {
    testWidgets(
      'Icon "Xem chi tiết phòng" (info) LUÔN render — không bị đổi thành QR',
      (tester) async {
        await tester.pumpWidget(wrap(lobby: buildLobbyWithBooking()));
        await tester.pump();

        // Icon info phải luôn có ở hero header (dù lobby ready/viable).
        expect(
          find.bySemanticsLabel('Xem chi tiết phòng'),
          findsOneWidget,
          reason:
              'Info icon là nút duy nhất để player mở bảng tổng quan — '
              'không được phép bị thay bằng QR code khi lobby ready.',
        );
      },
    );

    testWidgets(
      'Icon "Xem lịch hẹn chi tiết" (booking) render khi onShowReservation != null',
      (tester) async {
        await tester.pumpWidget(wrap(
          lobby: buildLobbyWithBooking(bookingId: 'res-123'),
          onShowReservation: () {},
        ));
        await tester.pump();

        // Booking icon phải có khi parent truyền callback (= lobby có
        // bookingId, tức có liên kết reservation).
        expect(find.bySemanticsLabel('Xem lịch hẹn chi tiết'), findsOneWidget);
        // Info icon vẫn luôn có (cặp đôi).
        expect(find.bySemanticsLabel('Xem chi tiết phòng'), findsOneWidget);
      },
    );

    testWidgets(
      'Icon "Xem lịch hẹn chi tiết" KHÔNG render khi onShowReservation == null',
      (tester) async {
        await tester.pumpWidget(wrap(
          lobby: buildLobbyWithBooking(bookingId: null),
          // Không truyền onShowReservation — lobby draft (chưa reserve)
          // hoặc đã terminal chưa map vào reservation.
        ));
        await tester.pump();

        expect(find.bySemanticsLabel('Xem lịch hẹn chi tiết'), findsNothing);
        // Info icon vẫn luôn có.
        expect(find.bySemanticsLabel('Xem chi tiết phòng'), findsOneWidget);
      },
    );

    testWidgets(
      'Bấm booking icon trigger callback (đường liên kết lobby → reservation)',
      (tester) async {
        var tapped = 0;
        await tester.pumpWidget(wrap(
          lobby: buildLobbyWithBooking(bookingId: 'res-123'),
          onShowReservation: () => tapped++,
        ));
        await tester.pump();

        await tester.tap(find.bySemanticsLabel('Xem lịch hẹn chi tiết'));
        await tester.pump();

        expect(tapped, 1, reason: 'Bấm booking icon phải trigger navigation.');
      },
    );

    testWidgets(
      'Bấm info icon trigger onShowDetails (mở LobbyDetailsSheet)',
      (tester) async {
        var tapped = 0;
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: LobbyHeroHeader(
              lobby: buildLobbyWithBooking(),
              theme: ThemeData.light(),
              onShowDetails: () => tapped++,
              onShareInviteCode: () {},
              onShowReservation: () {},
            ),
          ),
        ));
        await tester.pump();

        await tester.tap(find.bySemanticsLabel('Xem chi tiết phòng'));
        await tester.pump();

        expect(tapped, 1);
      },
    );
  });
}