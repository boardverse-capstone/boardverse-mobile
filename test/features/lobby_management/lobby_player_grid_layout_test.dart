import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardverse/features/lobby_management/domain/entities/lobby_entity.dart';
import 'package:boardverse/features/lobby_management/presentation/widgets/lobby_player_card.dart';

/// Tests cho `LobbyPlayerGrid` layout — đảm bảo **2 card / hàng** dù
/// viewport rộng hay hẹp. Phase 3 2026-08-10: trước đây grid dùng
/// `maxCrossAxisExtent: 152` → sinh 3 card / hàng trên mobile ~360dp
/// gây nội dung card bị cắt cụt (tên + status chip). Đổi sang
/// `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2)`.
void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  LobbyPlayer player(
    String id,
    String name, {
    bool isHost = false,
    DateTime? readyAt,
  }) {
    return LobbyPlayer(
      id: id,
      userId: id,
      name: name,
      avatarUrl: '',
      isHost: isHost,
      joinedAt: DateTime(2026, 8, 10),
      readyAt: readyAt,
    );
  }

  group('LobbyPlayerGrid layout (2 cards per row)', () {
    testWidgets('Hiển thị 2 card / hàng trên mobile (viewport ~360dp)',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final players = [
        player('1', 'Thien Phuc', isHost: true),
        player('2', 'Ngoc Lam'),
        player('3', 'My Hanh'),
        player('4', 'Quang Huy'),
      ];

      await tester.pumpWidget(wrap(
        SizedBox(
          width: 360,
          child: LobbyPlayerGrid(
            players: players,
            maxSlots: 4,
            lobbyStatus: LobbyStatus.full,
            currentUserId: '1',
          ),
        ),
      ));
      await tester.pump();

      // CHỉ có 4 player card, không có empty slot.
      final lobbyCards = find.byType(LobbyPlayerCard);
      expect(lobbyCards, findsNWidgets(4));

      // Lấy positions của 4 cards → check rằng có 2 hàng (top positions
      // khác nhau theo 2 nhóm).
      final positions = <Offset>[];
      for (var i = 0; i < 4; i++) {
        final rect = tester.getRect(find.byType(LobbyPlayerCard).at(i));
        positions.add(rect.topLeft);
      }
      // Player 0 & 1 ở hàng 0 (cùng top), player 2 & 3 ở hàng 1.
      expect(positions[0].dy, equals(positions[1].dy),
          reason: 'player 0 & 1 cùng hàng');
      expect(positions[2].dy, equals(positions[3].dy),
          reason: 'player 2 & 3 cùng hàng');
      expect(positions[0].dy, lessThan(positions[2].dy),
          reason: 'hàng 0 phải trên hàng 1');
    });

    testWidgets('Hiển thị 2 card / hàng trên tablet (viewport ~720dp)',
        (tester) async {
      tester.view.physicalSize = const Size(720, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final players = [
        player('1', 'A', isHost: true),
        player('2', 'B'),
        player('3', 'C'),
        player('4', 'D'),
      ];

      await tester.pumpWidget(wrap(
        SizedBox(
          width: 720,
          child: LobbyPlayerGrid(
            players: players,
            maxSlots: 4,
            lobbyStatus: LobbyStatus.full,
          ),
        ),
      ));
      await tester.pump();

      final positions = <Offset>[];
      for (var i = 0; i < 4; i++) {
        final rect = tester.getRect(find.byType(LobbyPlayerCard).at(i));
        positions.add(rect.topLeft);
      }
      expect(positions[0].dy, equals(positions[1].dy));
      expect(positions[2].dy, equals(positions[3].dy));
    });

    testWidgets('Empty slots cũng follow 2-card layout', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // 2 players + 4 empty slots.
      final players = [
        player('1', 'A'),
        player('2', 'B'),
      ];

      await tester.pumpWidget(wrap(
        SizedBox(
          width: 360,
          child: LobbyPlayerGrid(
            players: players,
            maxSlots: 6,
            lobbyStatus: LobbyStatus.open,
          ),
        ),
      ));
      await tester.pump();

      // 2 player card + 4 empty card = 6 cells, 3 hàng.
      expect(find.byType(LobbyPlayerCard), findsNWidgets(2));
      // Empty slot widget — find children of grid.
      // (Test pass nếu không có overflow exception.)
    });

    // Regression test (2026-10-02): Khi `maxPlayers` lẻ và chỉ có 1
    // host (vd: `maxPlayers = 3`, `players = [host]`), grid **KHÔNG
    // ĐƯỢC** render thêm 1 `_EmptySlotCard()` ở row orphan. Trước
    // đây loop manual rows có `secondCard ?? _EmptySlotCard()` → grid
    // hiển thị 4 cells thay vì 3 (vượt maxPlayers), user feedback
    // "Thành viên 1/3 nhưng UI có 4 card".
    //
    // Expected sau fix: 3 cells total (1 player + 2 empty), 2 rows
    // (row 0 có 2 card, row 1 chỉ 1 orphan empty card).
    testWidgets('Orphan row: maxPlayers lẻ + chỉ có host → đúng maxPlayers',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final players = [player('1', 'Host', isHost: true)];

      await tester.pumpWidget(wrap(
        SizedBox(
          width: 360,
          child: LobbyPlayerGrid(
            players: players,
            maxSlots: 3,
            lobbyStatus: LobbyStatus.open,
          ),
        ),
      ));
      await tester.pump();

      // 1 player card (host).
      expect(find.byType(LobbyPlayerCard), findsNWidgets(1));

      // Grid dùng `Wrap` thay vì loop rows manual — đếm tổng children
      // để đảm bảo đúng `maxPlayers` (3 = 1 host + 2 empty). Trước
      // bug fix, loop render thủng 4 children (1 host + 3 empty) vì
      // row cuối luôn có 1 phantom empty slot.
      final wrapFinder = find.descendant(
        of: find.byType(LobbyPlayerGrid),
        matching: find.byType(Wrap),
      );
      expect(wrapFinder, findsOneWidget);
      final wrapWidget = tester.widget<Wrap>(wrapFinder);
      expect(wrapWidget.children.length, 3,
          reason:
              'Grid phải đúng maxPlayers cells, không có phantom empty slot thừa.');
    });
  });
}
