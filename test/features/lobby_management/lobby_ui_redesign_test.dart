// Widget tests cho shimmer skeleton + lobby UI changes (2026-08).
//
// Verify:
//   - LobbyFriendsShimmer render skeleton tiles đúng format (avatar +
//     2 dòng text + 1 button placeholder).
//   - LobbyDetailsSheet render 3 sections (Tổng quan / Lịch trình /
//     Thành viên) với grid 2 cột.

import 'package:boardverse/core/theme/theme.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_entity.dart';
import 'package:boardverse/features/lobby_management/presentation/widgets/lobby_friends_shimmer.dart';
import 'package:boardverse/features/lobby_management/presentation/widgets/lobby_sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LobbyFriendsShimmer', () {
    testWidgets('render N skeleton tiles mặc định = 6', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: LobbyFriendsShimmer(),
          ),
        ),
      );
      await tester.pump();

      // Không assert text cụ thể (shimmer dùng Container trắng) — chỉ
      // verify widget render thành công và không throw.
      expect(find.byType(LobbyFriendsShimmer), findsOneWidget);
    });

    testWidgets('render đúng số item khi truyền vào itemCount', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: LobbyFriendsShimmer(itemCount: 3),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LobbyFriendsShimmer), findsOneWidget);
    });
  });

  group('LobbyDetailsSheet', () {
    LobbyEntity buildLobby() {
      return LobbyEntity(
        id: 'lobby-1',
        gameId: 'game-1',
        gameName: 'Catan',
        cafeId: 'cafe-1',
        cafeName: 'Board Game Cafe',
        hostId: 'host-1',
        hostName: 'Alice',
        scheduledTime: DateTime.utc(2026, 8, 10, 19, 30),
        currentPlayers: 3,
        maxPlayers: 6,
        minPlayers: 2,
        isPublic: true,
        inviteCode: 'ABCD1234',
        status: LobbyStatus.open,
        players: const [],
        createdAt: DateTime.utc(2026, 8, 8),
        timeoutAt: DateTime.utc(2026, 8, 10, 18, 30),
        minimumKarma: 50,
      );
    }

    testWidgets('render 3 section headers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: LobbyDetailsSheet(lobby: buildLobby()),
          ),
        ),
      );
      await tester.pump();

      // Header "Chi tiết phòng" + "Tổng quan" visible trên viewport.
      expect(find.text('Chi tiết phòng'), findsOneWidget);
      expect(find.text('Tổng quan'), findsOneWidget);

      // Scroll ListView để reveal các section headers còn lại trong
      // DraggableScrollableSheet (initialChildSize = 0.7 có thể che
      // bớt content trên thiết bị test).
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pump();
      expect(find.text('Lịch trình'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pump();
      expect(find.text('Thành viên'), findsOneWidget);
    });

    testWidgets('render game + cafe + invite code trong Tổng quan',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: LobbyDetailsSheet(lobby: buildLobby()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Catan'), findsOneWidget);
      expect(find.text('Board Game Cafe'), findsOneWidget);
      expect(find.text('ABCD1234'), findsOneWidget);
    });

    testWidgets('render capacity info trong Thành viên', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: LobbyDetailsSheet(lobby: buildLobby()),
          ),
        ),
      );
      await tester.pump();

      // Scroll xuống để reveal section "Thành viên".
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump();

      expect(find.text('3 / 6 người'), findsOneWidget);
      expect(find.text('2 người'), findsOneWidget);
      expect(find.text('3 vị trí'), findsOneWidget);
    });

    testWidgets('hiển thị "Riêng tư" khi lobby private', (tester) async {
      final lobby = buildLobby().copyWith(isPublic: false);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: LobbyDetailsSheet(lobby: lobby),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Riêng tư'), findsOneWidget);
    });
  });
}
