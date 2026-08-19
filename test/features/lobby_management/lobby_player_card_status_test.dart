import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardverse/features/lobby_management/domain/entities/lobby_entity.dart';
import 'package:boardverse/features/lobby_management/presentation/widgets/lobby_player_card.dart';

/// Tests cho status label của `LobbyPlayerCard` (BR-LOBBY-READY-01).
///
/// Verify:
/// - `readyAt == null` → "Chưa sẵn sàng" (label mới, thay cho "Đang chờ").
/// - `readyAt != null` → "Sẵn sàng".
/// - Host → "Chủ phòng" (override ready state).
void main() {
  Widget wrap(LobbyPlayer player, LobbyStatus lobbyStatus) {
    return MaterialApp(
      home: Scaffold(
        body: LobbyPlayerCard(
          player: player,
          lobbyStatus: lobbyStatus,
        ),
      ),
    );
  }

  LobbyPlayer player({
    String id = '1',
    bool isHost = false,
    DateTime? readyAt,
  }) {
    return LobbyPlayer(
      id: id,
      userId: id,
      name: 'Player $id',
      avatarUrl: '',
      isHost: isHost,
      joinedAt: DateTime(2026, 8, 10),
      readyAt: readyAt,
    );
  }

  group('LobbyPlayerCard status label (BR-LOBBY-READY-01)', () {
    testWidgets('readyAt null khi lobby full → "Chưa sẵn sàng"',
        (tester) async {
      await tester.pumpWidget(wrap(
        player(readyAt: null),
        LobbyStatus.full,
      ));
      await tester.pump();
      expect(find.text('Chưa sẵn sàng'), findsOneWidget);
      expect(find.text('Sẵn sàng'), findsNothing);
    });

    testWidgets('readyAt set khi lobby full → "Sẵn sàng"', (tester) async {
      await tester.pumpWidget(wrap(
        player(readyAt: DateTime(2026, 8, 10, 19, 0)),
        LobbyStatus.full,
      ));
      await tester.pump();
      expect(find.text('Sẵn sàng'), findsOneWidget);
      expect(find.text('Chưa sẵn sàng'), findsNothing);
    });

    testWidgets('host luôn show "Chủ phòng" (kể cả ready)', (tester) async {
      await tester.pumpWidget(wrap(
        player(isHost: true, readyAt: DateTime(2026, 8, 10, 19, 0)),
        LobbyStatus.full,
      ));
      await tester.pump();
      expect(find.text('Chủ phòng'), findsOneWidget);
      expect(find.text('Sẵn sàng'), findsNothing);
    });

    testWidgets('host chưa ready vẫn show "Chủ phòng"', (tester) async {
      await tester.pumpWidget(wrap(
        player(isHost: true, readyAt: null),
        LobbyStatus.full,
      ));
      await tester.pump();
      expect(find.text('Chủ phòng'), findsOneWidget);
    });

    testWidgets('lobby inProgress + readyAt null → "Chưa sẵn sàng"',
        (tester) async {
      await tester.pumpWidget(wrap(
        player(readyAt: null),
        LobbyStatus.inProgress,
      ));
      await tester.pump();
      expect(find.text('Chưa sẵn sàng'), findsOneWidget);
    });

    testWidgets('lobby ratingOpen + readyAt set → "Sẵn sàng"',
        (tester) async {
      await tester.pumpWidget(wrap(
        player(readyAt: DateTime(2026, 8, 10, 19, 0)),
        LobbyStatus.ratingOpen,
      ));
      await tester.pump();
      expect(find.text('Sẵn sàng'), findsOneWidget);
    });

    testWidgets('lobby open + readyAt null → "Đang tuyển" (không ready)',
        (tester) async {
      await tester.pumpWidget(wrap(
        player(readyAt: null),
        LobbyStatus.open,
      ));
      await tester.pump();
      expect(find.text('Cần thêm người'), findsOneWidget);
    });

    testWidgets('lobby closed → "Đã đóng" (terminal)', (tester) async {
      await tester.pumpWidget(wrap(
        player(readyAt: DateTime(2026, 8, 10, 19, 0)),
        LobbyStatus.closed,
      ));
      await tester.pump();
      expect(find.text('Đã đóng'), findsOneWidget);
    });
  });
}
